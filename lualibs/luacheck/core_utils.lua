local core_utils = {}

-- Calls callback with line, stack_set, index, item, ... for each item reachable from starting item.
-- `stack_set` is a set of indices of items in current propogation path from root, excluding current item.
-- Callback can return true to stop walking from current item.
function core_utils.walk_line(line, index, callback, ...)
   local stack = {}
   local stack_set = {}
   local backlog = {}
   local level = 0

   while index do
      local item = line.items[index]

      if not callback(line, stack_set, index, item, ...) and item then
         level = level + 1
         stack[level] = index
         stack_set[index] = true

         if item.tag == "Jump" then
            index = item.to
         elseif item.tag == "Cjump" then
            backlog[level] = index + 1
            index = item.to
         else
            index = index + 1
         end
      else
         while level > 0 and not backlog[level] do
            stack_set[stack[level]] = nil
            level = level - 1
         end

         index = backlog[level]
         backlog[level] = nil
      end
   end
end

local function once_per_item_callback_adapter(line, _, index, item, visited, callback, ...)
   if visited[index] then
      return true
   end

   visited[index] = true
   return callback(line, index, item, ...)
end

-- Calls callback with line, index, item, ... for each item reachable from starting item once.
-- `visited` is a set of already visited indexes.
-- Callback can return true to stop walking from current item.
function core_utils.walk_line_once(line, visited, index, callback, ...)
   return core_utils.walk_line(line, index, once_per_item_callback_adapter, visited, callback, ...)
end

-- Given a "global set" warning, return whether it is an implicit definition.
function core_utils.is_definition(opts, warning)
   return opts.allow_defined or (opts.allow_defined_top and warning.top)
end

local function event_priority(event)
   -- Inline option boundaries have priority over inline option declarations
   -- so that `-- luacheck: push ignore foo` is interpreted correctly (push first).
   if event.push or event.pop then
      return -2
   elseif event.options then
      return -1
   else
      return tonumber(event.code)
   end
end

local function event_comparator(event1, event2)
   if event1.line ~= event2.line then
      return event1.line < event2.line
   elseif event1.column ~= event2.column then
      return event1.column < event2.column
   else
      return event_priority(event1) < event_priority(event2)
   end
end

-- Sorts an array of warnings, inline options (tables with `options` field)
-- or inline option boundaries (tables with `push` or `pop` field) by location
-- information as provided in `line` and `column` fields.
function core_utils.sort_by_location(array)
   table.sort(array, event_comparator)
end

return core_utils
