local core_utils = require "luacheck.core_utils"

local reachability

local function noop_callback() end

local function reachability_callback(_, _, item, chstate, nested)
   if not item then
      return true
   end

   if not nested and item.lines then
      for _, subline in ipairs(item.lines) do
         reachability(chstate, subline, true)
      end
   end

   for _, action_key in ipairs({"accesses", "mutations"}) do
      local item_var_map = item[action_key]

      if item_var_map then
         for var, accessing_nodes in pairs(item_var_map) do
            if not var.empty then
               local all_possible_values_empty = true

               for _, possible_value in ipairs(item.used_values[var]) do
                  if not possible_value.empty then
                     all_possible_values_empty = false
                     break
                  end
               end

               if all_possible_values_empty then
                  for _, accessing_node in ipairs(accessing_nodes) do
                     chstate:warn_uninit(accessing_node, action_key == "mutations")
                  end
               end
            end
         end
      end
   end
end

-- Emits warnings: unreachable code, uninitialized access.
function reachability(chstate, line, nested)
   local reachable_indexes = {}
   core_utils.walk_line_once(line, reachable_indexes, 1, reachability_callback, chstate, nested)

   for i, item in ipairs(line.items) do
      if not reachable_indexes[i] then
         if item.location then
            chstate:warn_unreachable(item.location, item.loop_end, item.token)
            core_utils.walk_line_once(line, reachable_indexes, i, noop_callback)
         end
      end
   end
end

return reachability
