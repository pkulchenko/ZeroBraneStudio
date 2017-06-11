local parser = require "luacheck.parser"
local utils = require "luacheck.utils"

local pseudo_labels = utils.array_to_set({"do", "else", "break", "end", "return"})

-- Who needs classes anyway.
local function new_line(node, parent, value)
   return {
      accessed_upvalues = {}, -- Maps variables to arrays of accessing items.
      mutated_upvalues = {}, -- Maps variables to arrays of mutating items.
      set_upvalues = {}, -- Maps variables to arays of setting items.
      lines = {},
      node = node,
      parent = parent,
      value = value,
      items = utils.Stack()
   }
end

local function new_scope(line)
   return {
      vars = {},
      labels = {},
      gotos = {},
      line = line
   }
end

local function new_var(line, node, type_)
   return {
      name = node[1],
      location = node.location,
      type = type_,
      self = node.implicit,
      line = line,
      scope_start = line.items.size + 1,
      values = {}
   }
end

local function new_value(var_node, value_node, item, is_init)
   local value = {
      var = var_node.var,
      location = var_node.location,
      type = is_init and var_node.var.type or "var",
      initial = is_init,
      node = value_node,
      using_lines = {},
      empty = is_init and not value_node and (var_node.var.type == "var"),
      item = item
   }

   if value_node and value_node.tag == "Function" then
      value.type = "func"
      value_node.value = value
   end

   return value
end

local function new_label(line, name, location, end_column)
   return {
      name = name,
      location = location,
      end_column = end_column,
      index = line.items.size + 1
   }
end

local function new_goto(name, jump, location)
   return {
      name = name,
      jump = jump,
      location = location
   }
end

local function new_jump_item(is_conditional)
   return {
      tag = is_conditional and "Cjump" or "Jump"
   }
end

local function new_eval_item(expr)
   return {
      tag = "Eval",
      expr = expr,
      location = expr.location,
      token = expr.first_token,
      accesses = {},
      used_values = {},
      lines = {}
   }
end

local function new_noop_item(node, loop_end)
   return {
      tag = "Noop",
      location = node.location,
      token = node.first_token,
      loop_end = loop_end
   }
end

local function new_local_item(lhs, rhs, location, token)
   return {
      tag = "Local",
      lhs = lhs,
      rhs = rhs,
      location = location,
      token = token,
      accesses = rhs and {},
      used_values = rhs and {},
      lines = rhs and {}
   }
end

local function new_set_item(lhs, rhs, location, token)
   return {
      tag = "Set",
      lhs = lhs,
      rhs = rhs,
      location = location,
      token = token,
      accesses = {},
      mutations = {},
      used_values = {},
      lines = {}
   }
end

local function is_unpacking(node)
   return node.tag == "Dots" or node.tag == "Call" or node.tag == "Invoke"
end

local LinState = utils.class()

function LinState:__init(chstate)
   self.chstate = chstate
   self.lines = utils.Stack()
   self.scopes = utils.Stack()
end

function LinState:enter_scope()
   self.scopes:push(new_scope(self.lines.top))
end

function LinState:leave_scope()
   local left_scope = self.scopes:pop()
   local prev_scope = self.scopes.top

   for _, goto_ in ipairs(left_scope.gotos) do
      local label = left_scope.labels[goto_.name]

      if label then
         goto_.jump.to = label.index
         label.used = true
      else
         if not prev_scope or prev_scope.line ~= self.lines.top then
            if goto_.name == "break" then
               parser.syntax_error(
                  goto_.location, goto_.location.column + 4, "'break' is not inside a loop")
            else
               parser.syntax_error(
                  goto_.location, goto_.location.column + 3, ("no visible label '%s'"):format(goto_.name))
            end
         end

         table.insert(prev_scope.gotos, goto_)
      end
   end

   for name, label in pairs(left_scope.labels) do
      if not label.used and not pseudo_labels[name] then
         self.chstate:warn_unused_label(label)
      end
   end

   for _, var in pairs(left_scope.vars) do
      var.scope_end = self.lines.top.items.size
   end
end

function LinState:register_var(node, type_)
   local var = new_var(self.lines.top, node, type_)
   local prev_var = self:resolve_var(var.name)

   if prev_var then
      local same_scope = self.scopes.top.vars[var.name]
      self.chstate:warn_redefined(var, prev_var, same_scope)

      if same_scope then
         prev_var.scope_end = self.lines.top.items.size
      end
   end

   self.scopes.top.vars[var.name] = var
   node.var = var
   return var
end

function LinState:register_vars(nodes, type_)
   for _, node in ipairs(nodes) do
      self:register_var(node, type_)
   end
end

function LinState:resolve_var(name)
   for _, scope in utils.ripairs(self.scopes) do
      local var = scope.vars[name]

      if var then
         return var
      end
   end
end

function LinState:check_var(node)
   if not node.var then
      node.var = self:resolve_var(node[1])
   end

   return node.var
end

function LinState:register_label(name, location, end_column)
   if self.scopes.top.labels[name] then
      assert(not pseudo_labels[name])
      parser.syntax_error(location, end_column, ("label '%s' already defined on line %d"):format(
         name, self.scopes.top.labels[name].location.line))
   end

   self.scopes.top.labels[name] = new_label(self.lines.top, name, location, end_column)
end

-- `node` is assignment node (`Local or `Set).
function LinState:check_balance(node)
   if node[2] then
      if #node[1] < #node[2] then
         self.chstate:warn_unbalanced(node.equals_location, true)
      elseif (#node[1] > #node[2]) and node.tag ~= "Local" and not is_unpacking(node[2][#node[2]]) then
         self.chstate:warn_unbalanced(node.equals_location)
      end
   end
end

function LinState:check_empty_block(block)
   if #block == 0 then
      self.chstate:warn_empty_block(block.location, block.tag == "Do")
   end
end

function LinState:emit(item)
   self.lines.top.items:push(item)
end

function LinState:emit_goto(name, is_conditional, location)
   local jump = new_jump_item(is_conditional)
   self:emit(jump)
   table.insert(self.scopes.top.gotos, new_goto(name, jump, location))
end

local tag_to_boolean = {
   Nil = false, False = false,
   True = true, Number = true, String = true, Table = true, Function = true
}

-- Emits goto that jumps to ::name:: if bool(cond_node) == false.
function LinState:emit_cond_goto(name, cond_node)
   local cond_bool = tag_to_boolean[cond_node.tag]

   if cond_bool ~= true then
      self:emit_goto(name, cond_bool ~= false)
   end
end

function LinState:emit_noop(node, loop_end)
   self:emit(new_noop_item(node, loop_end))
end

function LinState:emit_stmt(stmt)
   self["emit_stmt_" .. stmt.tag](self, stmt)
end

function LinState:emit_stmts(stmts)
   for _, stmt in ipairs(stmts) do
      self:emit_stmt(stmt)
   end
end

function LinState:emit_block(block)
   self:enter_scope()
   self:emit_stmts(block)
   self:leave_scope()
end

function LinState:emit_stmt_Do(node)
   self:check_empty_block(node)
   self:emit_noop(node)
   self:emit_block(node)
end

function LinState:emit_stmt_While(node)
   self:emit_noop(node)
   self:enter_scope()
   self:register_label("do")
   self:emit_expr(node[1])
   self:emit_cond_goto("break", node[1])
   self:emit_block(node[2])
   self:emit_noop(node, true)
   self:emit_goto("do")
   self:register_label("break")
   self:leave_scope()
end

function LinState:emit_stmt_Repeat(node)
   self:emit_noop(node)
   self:enter_scope()
   self:register_label("do")
   self:enter_scope()
   self:emit_stmts(node[1])
   self:emit_expr(node[2])
   self:leave_scope()
   self:emit_cond_goto("do", node[2])
   self:register_label("break")
   self:leave_scope()
end

function LinState:emit_stmt_Fornum(node)
   self:emit_noop(node)
   self:emit_expr(node[2])
   self:emit_expr(node[3])

   if node[5] then
      self:emit_expr(node[4])
   end

   self:enter_scope()
   self:register_label("do")
   self:emit_goto("break", true)
   self:enter_scope()
   self:emit(new_local_item({node[1]}))
   self:register_var(node[1], "loopi")
   self:emit_stmts(node[5] or node[4])
   self:leave_scope()
   self:emit_noop(node, true)
   self:emit_goto("do")
   self:register_label("break")
   self:leave_scope()
end

function LinState:emit_stmt_Forin(node)
   self:emit_noop(node)
   self:emit_exprs(node[2])
   self:enter_scope()
   self:register_label("do")
   self:emit_goto("break", true)
   self:enter_scope()
   self:emit(new_local_item(node[1]))
   self:register_vars(node[1], "loop")
   self:emit_stmts(node[3])
   self:leave_scope()
   self:emit_noop(node, true)
   self:emit_goto("do")
   self:register_label("break")
   self:leave_scope()
end

function LinState:emit_stmt_If(node)
   self:emit_noop(node)
   self:enter_scope()

   for i = 1, #node - 1, 2 do
      self:enter_scope()
      self:emit_expr(node[i])
      self:emit_cond_goto("else", node[i])
      self:check_empty_block(node[i + 1])
      self:emit_block(node[i + 1])
      self:emit_goto("end")
      self:register_label("else")
      self:leave_scope()
   end

   if #node % 2 == 1 then
      self:check_empty_block(node[#node])
      self:emit_block(node[#node])
   end

   self:register_label("end")
   self:leave_scope()
end

function LinState:emit_stmt_Label(node)
   self:register_label(node[1], node.location, node.end_column)
end

function LinState:emit_stmt_Goto(node)
   self:emit_noop(node)
   self:emit_goto(node[1], false, node.location)
end

function LinState:emit_stmt_Break(node)
   self:emit_goto("break", false, node.location)
end

function LinState:emit_stmt_Return(node)
   self:emit_noop(node)
   self:emit_exprs(node)
   self:emit_goto("return")
end

function LinState:emit_expr(node)
   local item = new_eval_item(node)
   self:scan_expr(item, node)
   self:emit(item)
end

function LinState:emit_exprs(exprs)
   for _, expr in ipairs(exprs) do
      self:emit_expr(expr)
   end
end

LinState.emit_stmt_Call = LinState.emit_expr
LinState.emit_stmt_Invoke = LinState.emit_expr

function LinState:emit_stmt_Local(node)
   self:check_balance(node)
   local item = new_local_item(node[1], node[2], node.location, node.first_token)
   self:emit(item)

   if node[2] then
      self:scan_exprs(item, node[2])
   end

   self:register_vars(node[1], "var")
end

function LinState:emit_stmt_Localrec(node)
   local item = new_local_item({node[1]}, {node[2]}, node.location, node.first_token)
   self:register_var(node[1], "var")
   self:emit(item)
   self:scan_expr(item, node[2])
end

function LinState:emit_stmt_Set(node)
   self:check_balance(node)
   local item = new_set_item(node[1], node[2], node.location, node.first_token)
   self:scan_exprs(item, node[2])

   for _, expr in ipairs(node[1]) do
      if expr.tag == "Id" then
         local var = self:check_var(expr)

         if var then
            self:register_upvalue_action(item, var, "set_upvalues")
         end
      else
         assert(expr.tag == "Index")
         self:scan_lhs_index(item, expr)
      end
   end

   self:emit(item)
end


function LinState:scan_expr(item, node)
   local scanner = self["scan_expr_" .. node.tag]

   if scanner then
      scanner(self, item, node)
   end
end

function LinState:scan_exprs(item, nodes)
   for _, node in ipairs(nodes) do
      self:scan_expr(item, node)
   end
end

function LinState:register_upvalue_action(item, var, key)
   for _, line in utils.ripairs(self.lines) do
      if line == var.line then
         break
      end

      if not line[key][var] then
         line[key][var] = {}
      end

      table.insert(line[key][var], item)
   end
end

function LinState:mark_access(item, node)
   node.var.accessed = true

   if not item.accesses[node.var] then
      item.accesses[node.var] = {}
   end

   table.insert(item.accesses[node.var], node)
   self:register_upvalue_action(item, node.var, "accessed_upvalues")
end

function LinState:mark_mutation(item, node)
   node.var.mutated = true

   if not item.mutations[node.var] then
      item.mutations[node.var] = {}
   end

   table.insert(item.mutations[node.var], node)
   self:register_upvalue_action(item, node.var, "mutated_upvalues")
end

function LinState:scan_expr_Id(item, node)
   if self:check_var(node) then
      self:mark_access(item, node)
   end
end

function LinState:scan_expr_Dots(item, node)
   local dots = self:check_var(node)

   if not dots or dots.line ~= self.lines.top then
      parser.syntax_error(node.location, node.location.column + 2, "cannot use '...' outside a vararg function")
   end

   self:mark_access(item, node)
end

function LinState:scan_lhs_index(item, node)
   if node[1].tag == "Id" then
      if self:check_var(node[1]) then
         self:mark_mutation(item, node[1])
      end
   elseif node[1].tag == "Index" then
      self:scan_lhs_index(item, node[1])
   else
      self:scan_expr(item, node[1])
   end

   self:scan_expr(item, node[2])
end

LinState.scan_expr_Index = LinState.scan_exprs
LinState.scan_expr_Call = LinState.scan_exprs
LinState.scan_expr_Invoke = LinState.scan_exprs
LinState.scan_expr_Paren = LinState.scan_exprs

local function node_to_lua_value(node)
   if node.tag == "True" then
      return true, "true"
   elseif node.tag == "False" then
      return false, "false"
   elseif node.tag == "String" then
      return node[1], node[1]
   elseif node.tag == "Number" then
      local str = node[1]

      if str:find("[iIuUlL]") then
         -- Ignore LuaJIT cdata literals.
         return
      end

      -- On Lua 5.3 convert to float to get same results as on Lua 5.1 and 5.2.
      if _VERSION == "Lua 5.3" and not str:find("[%.eEpP]") then
         str = str .. ".0"
      end

      local number = tonumber(str)

      if number and number == number and number < 1/0 and number > -1/0 then
         return number, node[1]
      end
   end
end

function LinState:scan_expr_Table(item, node)
   local array_index = 1.0
   local key_to_node = {}

   for _, pair in ipairs(node) do
      local key, field

      if pair.tag == "Pair" then
         key, field = node_to_lua_value(pair[1])
         self:scan_exprs(item, pair)
      else
         key = array_index
         field = tostring(math.floor(key))
         array_index = array_index + 1.0
         self:scan_expr(item, pair)
      end

      if field then
         if key_to_node[key] then
            self.chstate:warn_unused_field_value(key_to_node[key], pair)
         end

         key_to_node[key] = pair
         pair.field = field
         pair.is_index = pair.tag ~= "Pair" or nil
      end
   end
end

function LinState:scan_expr_Op(item, node)
   self:scan_expr(item, node[2])

   if node[3] then
      self:scan_expr(item, node[3])
   end
end

-- Puts tables {var = value{} into field `set_variables` of items in line which set values.
-- Registers set values in field `values` of variables.
function LinState:register_set_variables()
   local line = self.lines.top

   for _, item in ipairs(line.items) do
      if item.tag == "Local" or item.tag == "Set" then
         item.set_variables = {}

         local is_init = item.tag == "Local"
         local unpacking_item -- Rightmost item of rhs which may unpack into several lhs items.

         if item.rhs then
            local last_rhs_item = item.rhs[#item.rhs]

            if is_unpacking(last_rhs_item) then
               unpacking_item = last_rhs_item
            end
         end

         local secondaries -- Array of values unpacked from rightmost rhs item.

         if unpacking_item and (#item.lhs > #item.rhs) then
            secondaries = {}
         end

         for i, node in ipairs(item.lhs) do
            local value

            if node.var then
               value = new_value(node, item.rhs and item.rhs[i] or unpacking_item, item, is_init)
               item.set_variables[node.var] = value
               table.insert(node.var.values, value)
            end

            if secondaries and (i >= #item.rhs) then
               if value then
                  value.secondaries = secondaries
                  table.insert(secondaries, value)
               else
                  -- If one of secondary values is assigned to a global or index,
                  -- it is considered used.
                  secondaries.used = true
               end
            end
         end
      end
   end
end

function LinState:build_line(node)
   self.lines:push(new_line(node, self.lines.top))
   self:enter_scope()
   self:emit(new_local_item(node[1]))
   self:enter_scope()
   self:register_vars(node[1], "arg")
   self:emit_stmts(node[2])
   self:leave_scope()
   self:register_label("return")
   self:leave_scope()
   self:register_set_variables()
   local line = self.lines:pop()

   for _, prev_line in ipairs(self.lines) do
      table.insert(prev_line.lines, line)
   end

   return line
end

function LinState:scan_expr_Function(item, node)
   local line = self:build_line(node)
   table.insert(item.lines, line)

   for _, nested_line in ipairs(line.lines) do
      table.insert(item.lines, nested_line)
   end
end

-- Builds linear representation of AST and returns it.
-- Emits warnings: global, redefined/shadowed, unused field, unused label, unbalanced assignment, empty block.
local function linearize(chstate, ast)
   local linstate = LinState(chstate)
   local line = linstate:build_line({{{tag = "Dots", "..."}}, ast})
   assert(linstate.lines.size == 0)
   assert(linstate.scopes.size == 0)
   return line
end

return linearize
