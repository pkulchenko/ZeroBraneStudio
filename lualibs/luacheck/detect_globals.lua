local utils = require "luacheck.utils"

local function resolved_to_index(resolution)
   return resolution ~= "unknown" and resolution ~= "not_string" and resolution.tag ~= "String"
end

local literal_tags = utils.array_to_set({"Nil", "True", "False", "Number", "String", "Table", "Function"})

local deep_resolve -- Forward declaration.

local function resolve_node(node, item)
   if node.tag == "Id" or node.tag == "Index" then
      deep_resolve(node, item)
      return node.resolution
   elseif literal_tags[node.tag] then
      return node.tag == "String" and node or "not_string"
   else
      return "unknown"
   end
end

-- Resolves value of an identifier or index node, tracking through simple
-- assignments like `local foo = bar.baz`.
-- Can be given an `Invoke` node to resolve the method field.
-- Sets `node.resolution` to "unknown", "not_string", `string node`, or
-- {previous_indexing_len = index, global_node, key...}.
-- Each key can be "unknown", "not_string" or `string_node`.
function deep_resolve(node, item)
   if node.resolution then
      return
   end

   -- Common case.
   -- Also protects against infinite recursion, if it's even possible.
   node.resolution = "unknown"

   local base = node
   local base_tag = node.tag == "Id" and "Id" or "Index"
   local keys = {}

   while base_tag == "Index" do
      table.insert(keys, 1, base[2])
      base = base[1]
      base_tag = base.tag
   end

   if base_tag ~= "Id" then
      return
   end

   local var = base.var
   local base_resolution
   local previous_indexing_len

   if var then
      if not item.used_values[var] or #item.used_values[var] ~= 1 then
         -- Do not know where the value for the base local came from.
         return
      end

      local value = item.used_values[var][1]

      if not value.node then
         return
      end

      base_resolution = resolve_node(value.node, value.item)

      if resolved_to_index(base_resolution) then
         previous_indexing_len = #base_resolution
      end
   else
      base_resolution = {base}
   end

   if #keys == 0 then
      node.resolution = base_resolution
   elseif not resolved_to_index(base_resolution) then
      -- Indexing something unknown or indexing a literal.
      node.resolution = "unknown"
   else
      local resolution = utils.update({}, base_resolution)
      resolution.previous_indexing_len = previous_indexing_len

      for _, key in ipairs(keys) do
         local key_resolution = resolve_node(key, item)

         if resolved_to_index(key_resolution) then
            key_resolution = "unknown"
         end

         table.insert(resolution, key_resolution)
      end

      -- Assign resolution only after all the recursive calls.
      node.resolution = resolution
   end
end

local function detect_in_node(chstate, item, node, is_top_line, is_lhs)
   if node.tag == "Index" or node.tag == "Invoke" or node.tag == "Id" then
      if node.tag == "Id" and node.var then
         -- Do not warn about assignments to and accesses of local variables
         -- that resolve to globals or their fields.
         return
      end

      deep_resolve(node, item)
      local resolution = node.resolution

      -- Still need to recurse into base and key nodes.
      -- E.g. don't miss a global in `(global1())[global2()].

      if node.tag == "Invoke" then
         for i = 3, #node do
            detect_in_node(chstate, item, node[i], is_top_line)
         end
      end

      if node.tag ~= "Id" then
         repeat
            detect_in_node(chstate, item, node[2], is_top_line)
            node = node[1]
         until node.tag ~= "Index"

         if node.tag ~= "Id" then
            detect_in_node(chstate, item, node, is_top_line)
         end
      end

      if resolved_to_index(resolution) then
         chstate:warn_global(node, resolution, is_lhs, is_top_line)
      end
   elseif node.tag ~= "Function" then
      for _, nested_node in ipairs(node) do
         if type(nested_node) == "table" then
            detect_in_node(chstate, item, nested_node, is_top_line)
         end
      end
   end
end

local function detect_in_nodes(chstate, item, nodes, is_top_line, is_lhs)
   for _, node in ipairs(nodes) do
      detect_in_node(chstate, item, node, is_top_line, is_lhs)
   end
end

local function detect_in_line(chstate, line, is_top_line)
   for _, item in ipairs(line.items) do
      if item.tag == "Eval" then
         detect_in_node(chstate, item, item.expr, is_top_line)
      elseif item.tag == "Local" then
         if item.rhs then
            detect_in_nodes(chstate, item, item.rhs, is_top_line)
         end
      elseif item.tag == "Set" then
         detect_in_nodes(chstate, item, item.lhs, is_top_line, true)
         detect_in_nodes(chstate, item, item.rhs, is_top_line)
      end
   end
end

-- Detects assignments, field accesses and mutations of global variables,
-- tracing through localizing assignments such as `local t = table`.
local function detect_globals(chstate, line)
   detect_in_line(chstate, line, true)

   for _, nested_line in ipairs(line.lines) do
      detect_in_line(chstate, nested_line)
   end
end

return detect_globals
