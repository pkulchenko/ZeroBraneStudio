local core_utils = require "luacheck.core_utils"
local utils = require "luacheck.utils"

local function register_value(values_per_var, var, value)
   if not values_per_var[var] then
      values_per_var[var] = {}
   end

   table.insert(values_per_var[var], value)
end

local function add_resolution(line, item, var, value, mutation)
   register_value(item.used_values, var, value)
   value[mutation and "mutated" or "used"] = true
   value.using_lines[line] = true

   if value.secondaries then
      value.secondaries.used = true
   end
end

local function in_scope(var, index)
   return (var.scope_start <= index) and (index <= var.scope_end)
end

-- Called when value of var is live at an item, maybe several times.
-- Registers value as live where variable is accessed or liveness propogation stops.
-- Stops when out of scope of variable, at another assignment to it or at an item
-- encountered already.
-- When stopping at a visited item, only save value if the item is in the current stack
-- of items, i.e. when propogation followed some path from it to previous item
local function value_propogation_callback(line, stack, index, item, visited, var, value)
   if not item then
      -- Value reach end of line, so even if it's overwritten by a single assignment it's
      -- not dominated by it.
      value.overwriting_item = false
      register_value(line.last_live_values, var, value)
      return true
   end

   if not visited[index] then
      if item.accesses and item.accesses[var] then
         add_resolution(line, item, var, value)
      end

      if item.mutations and item.mutations[var] then
         add_resolution(line, item, var, value, true)
      end
   end

   local is_overwritten = item.set_variables and item.set_variables[var]
   local out_of_scope = not in_scope(var, index)
   local stop_and_save = not visited[index] and (out_of_scope or is_overwritten)

   if stack[index] or stop_and_save then
      if is_overwritten then
         if value.overwriting_item ~= false then
            if value.overwriting_item and value.overwriting_item ~= item then
               value.overwriting_item = false
            else
               value.overwriting_item = item
            end
         end
      elseif out_of_scope then
         -- Value reach end of scope, so even if it's overwritten by a single assignment it's
         -- not dominated by it.
         value.overwriting_item = false
      end

      if not item.live_values then
         item.live_values = {}
      end

      register_value(item.live_values, var, value)
      return true
   end

   if visited[index] then
      return true
   end

   visited[index] = true
end

-- For each node accessing variables, adds table {var = {values}} to field `used_values`.
-- A pair `var = {values}` in this table means that accessed local variable `var` can contain one of values `values`.
-- Values that can be accessed locally are marked as used.
local function propogate_values(line)
   -- {var = values} live at the end of line.
   line.last_live_values = {}

   -- It is not very clever to simply propogate every single assigned value.
   -- Fortunately, performance hit seems small (can be compenstated by inlining a few functions in lexer).
   for i, item in ipairs(line.items) do
      if item.set_variables then
         for var, value in pairs(item.set_variables) do
            if var.line == line then
               -- Values are only live at the item after assignment.
               core_utils.walk_line(line, i + 1, value_propogation_callback, {}, var, value)
            end
         end
      end
   end
end

-- Called when closure (subline) is live at index.
-- Updates variable resolution:
-- When a closure accessing upvalue is live at item where a value of the variable is live,
-- the access can resolve to the value.
-- When a closure setting upvalue is live at item where the variable is accessed,
-- the access can resolve to the value.
-- Live values are only stored when their liveness ends. However, as closure propogation is unrestricted,
-- if there is an intermediate item where value is factually live and closure is live, closure will at some
-- point be propogated to where value liveness ends and is stored as live.
-- (Chances that I will understand this comment six months later: non-existent)
local function closure_propogation_callback(line, _, item, subline)
   local live_values

   if not item then
      live_values = line.last_live_values
   else
      live_values = item.live_values
   end

   if live_values then
      for _, var_map in ipairs({subline.accessed_upvalues, subline.mutated_upvalues}) do
         for var, accessing_items in pairs(var_map) do
            if var.line == line then
               if live_values[var] then
                  for _, accessing_item in ipairs(accessing_items) do
                     for _, value in ipairs(live_values[var]) do
                        add_resolution(subline, accessing_item, var, value, var_map == subline.mutated_upvalues)
                     end
                  end
               end
            end
         end
      end
   end

   if not item then
      return true
   end

   for _, action_key in ipairs({"accesses", "mutations"}) do
      local item_var_map = item[action_key]

      if item_var_map then
         for var, setting_items in pairs(subline.set_upvalues) do
            if var.line == line then
               if item_var_map[var] then
                  for _, setting_item in ipairs(setting_items) do
                     add_resolution(line, item, var, setting_item.set_variables[var], action_key == "mutations")
                  end
               end
            end
         end
      end
   end
end

-- Updates variable resolution to account for closures and upvalues.
local function propogate_closures(line)
   for i, item in ipairs(line.items) do
      if item.lines then
         for _, subline in ipairs(item.lines) do
            -- Closures are considered live at the item they are created.
            core_utils.walk_line_once(line, {}, i, closure_propogation_callback, subline)
         end
      end
   end

   -- It is assumed that all closures are live at the end of the line.
   -- Therefore, all accesses and sets inside closures can resolve to each other.
   for _, subline in ipairs(line.lines) do
      for _, var_map in ipairs({subline.accessed_upvalues, subline.mutated_upvalues}) do
         for var, accessing_items in pairs(var_map) do
            if var.line == line then
               for _, accessing_item in ipairs(accessing_items) do
                  for _, another_subline in ipairs(line.lines) do
                     if another_subline.set_upvalues[var] then
                        for _, setting_item in ipairs(another_subline.set_upvalues[var]) do
                           add_resolution(subline, accessing_item, var,
                              setting_item.set_variables[var], var_map == subline.mutated_upvalues)
                        end
                     end
                  end
               end
            end
         end
      end
   end
end

local function analyze_line(line)
   propogate_values(line)
   propogate_closures(line)
end

local function is_function_var(var)
   return (#var.values == 1 and var.values[1].type == "func") or (
      #var.values == 2 and var.values[1].empty and var.values[2].type == "func")
end

local externally_accessible_tags = utils.array_to_set({"Id", "Index", "Call", "Invoke", "Op", "Paren", "Dots"})

local function externally_accessible(value)
   return value.type ~= "var" or (value.node and externally_accessible_tags[value.node.tag])
end

local function find_overwriting_lhs_node(item, value)
   for _, node in ipairs(item.lhs) do
      if node.var == value.var then
         return node
      end
   end
end

local function get_overwriting_node_in_dup_assignment(item, value)
   local after_value_node

   for _, node in ipairs(item.lhs) do
      if node.var == value.var then
         if after_value_node then
            return node
         elseif node.location == value.location then
            after_value_node = true
         end
      end
   end
end

-- Emits warnings for variable.
local function check_var(chstate, var)
   if is_function_var(var) then
      local value = var.values[2] or var.values[1]

      if not value.used then
         chstate:warn_unused_variable(value)
      end
   elseif #var.values == 1 then
      if not var.values[1].used then
         if var.values[1].mutated then
            if not externally_accessible(var.values[1]) then
               chstate:warn_unaccessed(var, true)
            end
         else
            chstate:warn_unused_variable(var.values[1], nil, nil, var.values[1].empty)
         end
      elseif var.values[1].empty then
         var.empty = true
         chstate:warn_unset(var)
      end
   elseif not var.accessed and not var.mutated then
      chstate:warn_unaccessed(var)
   else
      local no_values_externally_accessible = true

      for _, value in ipairs(var.values) do
         if externally_accessible(value) then
            no_values_externally_accessible = false
         end
      end

      if not var.accessed and no_values_externally_accessible then
         chstate:warn_unaccessed(var, true)
      end

      for _, value in ipairs(var.values) do
         if not value.empty then
            if not value.used and not value.mutated then
               local overwriting_node

               if value.overwriting_item then
                  overwriting_node = find_overwriting_lhs_node(value.overwriting_item, value)

                  if overwriting_node == value.node then
                     overwriting_node = nil
                  end
               else
                  overwriting_node = get_overwriting_node_in_dup_assignment(value.item, value)
               end

               chstate:warn_unused_value(value, false, overwriting_node)
            elseif not value.used and not externally_accessible(value) then
               if var.accessed or not no_values_externally_accessible then
                  chstate:warn_unused_value(value, true)
               end
            end
         end
      end
   end
end

-- Emits warnings for unused variables and values and unset variables in line.
local function check_for_warnings(chstate, line)
   for _, item in ipairs(line.items) do
      if item.tag == "Local" then
         for var in pairs(item.set_variables) do
            -- Do not check implicit top level vararg.
            if var.location then

               check_var(chstate, var)
            end
         end
      end
   end
end

local function mark_reachable_lines(edges, marked, line)
   for connected_line in pairs(edges[line]) do
      if not marked[connected_line] then
         marked[connected_line] = true
         mark_reachable_lines(edges, marked, connected_line)
      end
   end
end

-- Detects unused recursive and mutually recursive functions.
local function check_unused_recursive_funcs(chstate, line)
   -- Build a graph of usage relations of all closures.
   -- Closure A is used by closure B iff either B is parent
   -- of A and A is not assigned to a local/upvalue, or
   -- B uses local/upvalue value that is A.
   -- Closures not reachable from root closure are unused,
   -- report corresponding values/variables if not done already.

   -- Initialize edges maps.
   local forward_edges = {[line] = {}}
   local backward_edges = {[line] = {}}

   for _, nested_line in ipairs(line.lines) do
      forward_edges[nested_line] = {}
      backward_edges[nested_line] = {}
   end

   -- Add edges leading to each nested line.
   for _, nested_line in ipairs(line.lines) do
      if nested_line.node.value then
         for using_line in pairs(nested_line.node.value.using_lines) do
            forward_edges[using_line][nested_line] = true
            backward_edges[nested_line][using_line] = true
         end
      elseif nested_line.parent then
         forward_edges[nested_line.parent][nested_line] = true
         backward_edges[nested_line][nested_line.parent] = true
      end
   end

   -- Recursively mark all closures reachable from root closure and unused closures.
   -- Closures reachable from main chunk are used; closure reachable from unused closures
   -- depend on that closure; that is, fixing warning about parent unused closure
   -- fixes warning about the child one, so issuing a warning for the child is superfluous.
   local marked = {[line] = true}
   mark_reachable_lines(forward_edges, marked, line)

   for _, nested_line in ipairs(line.lines) do
      if nested_line.node.value and not nested_line.node.value.used then
         marked[nested_line] = true
         mark_reachable_lines(forward_edges, marked, nested_line)
      end
   end

   -- Deal with unused closures.
   for _, nested_line in ipairs(line.lines) do
      local value = nested_line.node.value

      if value and value.used and not marked[nested_line] then
         -- This closure is used by some closure, but is not marked as reachable
         -- from main chunk or any of reported closures.
         -- Find candidate group of mutually recursive functions containing this one:
         -- mark sets of closures reachable from it by forward and backward edges,
         -- intersect them. Ignore already marked closures in the process to avoid
         -- issuing superfluous, dependent warnings.
         local forward_marked = setmetatable({}, {__index = marked})
         local backward_marked = setmetatable({}, {__index = marked})
         mark_reachable_lines(forward_edges, forward_marked, nested_line)
         mark_reachable_lines(backward_edges, backward_marked, nested_line)

         -- Iterate over closures in the group.
         for mut_rec_line in pairs(forward_marked) do
            if rawget(backward_marked, mut_rec_line) then
               marked[mut_rec_line] = true
               value = mut_rec_line.node.value

               if value then
                  -- Report this closure as simply recursive or mutually recursive.
                  local simply_recursive = forward_edges[mut_rec_line][mut_rec_line]

                  if is_function_var(value.var) then
                     chstate:warn_unused_variable(value, true, simply_recursive)
                  else
                     chstate:warn_unused_value(value, true, simply_recursive)
                  end
               end
            end
         end
      end
   end
end

-- Finds reaching assignments for all variable accesses.
-- Emits warnings: unused variable, unused value, unset variable.
local function analyze(chstate, line)
   analyze_line(line)

   for _, nested_line in ipairs(line.lines) do
      analyze_line(nested_line)
   end

   check_for_warnings(chstate, line)

   for _, nested_line in ipairs(line.lines) do
      check_for_warnings(chstate, nested_line)
   end

   check_unused_recursive_funcs(chstate, line)
end

return analyze
