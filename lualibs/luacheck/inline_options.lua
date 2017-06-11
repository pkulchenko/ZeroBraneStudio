local options = require "luacheck.options"
local core_utils = require "luacheck.core_utils"
local utils = require "luacheck.utils"

local inline_options = {}

-- Inline option is a comment starting with "luacheck:".
-- Body can be "push", "pop" or comma delimited options, where option
-- is option name plus space delimited arguments.
-- "push" can also be immediately followed by options.
-- Body can contain comments enclosed in balanced parens.

-- If there is code on line with inline option, it only affects that line;
-- otherwise, it affects everything till the end of current closure.
-- Option scope can also be regulated using "push" and "pop" options:
-- -- luacheck: push ignore foo
-- foo() -- Ignored.
-- -- luacheck: pop
-- foo() -- Not ignored.

local function add_closure_boundaries(ast, events)
   if ast.tag == "Function" then
      table.insert(events, {push = true, closure = true,
         line = ast.location.line, column = ast.location.column})
      table.insert(events, {pop = true, closure = true,
         line = ast.end_location.line, column = ast.end_location.column})
   else
      for _, node in ipairs(ast) do
         if type(node) == "table" then
            add_closure_boundaries(node, events)
         end
      end
   end
end

local max_line_length_opts = utils.array_to_set({
   "max_line_length", "max_code_line_length", "max_string_line_length", "max_comment_line_length"})

-- Parses inline option body, returns options or nil.
local function get_options(body)
   local opts = {}

   for _, name_and_args in ipairs(utils.split(body, ",")) do
      local args = utils.split(name_and_args)
      local name = table.remove(args, 1)

      if not name then
         return
      end

      if name == "std" then
         if #args ~= 1 then
            return
         end

         opts.std = args[1]
      elseif name == "ignore" and #args == 0 then
         opts.ignore = {".*"}
      else
         local flag = true

         if name == "no" then
            flag = false
            name = table.remove(args, 1)
         end

         while true do
            if options.variadic_inline_options[name] then
               if flag then
                  opts[name] = args
                  break
               else
                  -- Array option with 'no' prefix is invalid.
                  return
               end
            elseif max_line_length_opts[name] then
               -- Either `max [type] line length <number>` or `no max [type] line length`.
               if flag and #args == 1 and tonumber(args[1]) then
                  opts[name] = tonumber(args[1])
                  break
               elseif not flag and #args == 0 then
                  opts[name] = false
                  break
               else
                  return
               end
            elseif #args == 0 then
               if options.nullary_inline_options[name] then
                  opts[name] = flag
                  break
               else
                  -- Consumed all arguments but didn't find a valid option name.
                  return
               end
            else
               -- Join name with next argument,
               name = name.."_"..table.remove(args, 1)
            end
         end
      end
   end

   return opts
end

local function invalid_options_error(event)
   return {
      code = "021",
      line = event.line,
      column = event.column,
      end_column = event.end_column
   }
end

local function add_inline_option(events, per_line_opts, body, location, end_column, is_code_line)
   body = utils.strip(body)
   local after_push = body:match("^push%s+(.*)")

   if after_push then
      body = "push"
   end

   if body == "push" or body == "pop" then
      table.insert(events, {[body] = true, line = location.line, column = location.column, end_column = end_column})

      if after_push then
         body = after_push
      else
         return
      end
   end

   local opts = get_options(body)
   local event = {options = opts, line = location.line, column = location.column, end_column = end_column}

   if not opts then
      table.insert(events, invalid_options_error(event))
      return
   end

   if is_code_line and not after_push then
      if not per_line_opts[location.line] then
         per_line_opts[location.line] = {}
      end

      table.insert(per_line_opts[location.line], event)
   else
      table.insert(events, event)
   end
end

-- Adds inline options to events, marks invalid ones as errors.
-- Returns map of per line inline option events (maps line numbers to arrays of event tables).
local function add_inline_options(events, comments, code_lines)
   local per_line_opts = {}
   local invalid_comments = {}

   for _, comment in ipairs(comments) do
      local contents = utils.strip(comment.contents)
      local body = utils.after(contents, "^luacheck:")

      if body then
         -- Remove comments in balanced parens.
         body = body:gsub("%b()", " ")
         add_inline_option(events, per_line_opts, body,
            comment.location, comment.end_column, code_lines[comment.location.line])
      end
   end

   return per_line_opts, invalid_comments
end

local function unpaired_boundary_error(event)
   return {
      code = "02" .. (event.push and "2" or "3"),
      line = event.line,
      column = event.column,
      end_column = event.end_column
   }
end

-- Given sorted events, transforms unpaired push and pop directives into errors.
local function mark_unpaired_boundaries(events)
   local pushes = utils.Stack()

   for i, event in ipairs(events) do
      if event.push then
         pushes:push({index = i, event = event})
      elseif event.pop then
         if pushes.size == 0 then
            events[i] = unpaired_boundary_error(event)
         elseif event.closure then
            -- There could be unpaired push boundaries, pop them.
            while not pushes.top.event.closure do
               local unpaired_push = pushes:pop()
               events[unpaired_push.index] = unpaired_boundary_error(unpaired_push.event)
            end

            pushes:pop()
         elseif pushes.top.event.closure then
            -- User-supplied pop directive but last push is closure start.
            events[i] = unpaired_boundary_error(event)
         else
            pushes:pop()
         end
      end
   end

   -- Remaining push boundaries are unpaired.
   for _, unpaired_push in ipairs(pushes) do
      events[unpaired_push.index] = unpaired_boundary_error(unpaired_push.event)
   end
end

-- Removes push/pop pairs that do no have any options inbetween.
-- Returns new, sorted array of events.
local function filter_useless_boundaries(events)
   local pushes = utils.Stack()
   local filtered_events = {}

   for _, event in ipairs(events) do
      if event.push then
         table.insert(filtered_events, event)
         pushes:push({filtered_index = #filtered_events, has_options = false})
      elseif event.pop then
         local push = pushes:pop()

         if push.has_options then
            table.insert(filtered_events, event)
         else
            table.remove(filtered_events, push.filtered_index)
         end
      else
         if event.options and pushes.size ~= 0 then
            pushes.top.has_options = true
         end

         table.insert(filtered_events, event)
      end
   end

   return filtered_events
end

-- Adds events and errors related to inline options to the warning list.
-- Returns a new list, sorted by location, plus a map of per line inline option events
-- (maps line numbers to arrays of event tables).
-- Inline option events are tables marked with `push`, `pop`, or `options` key.
-- Push and pop events create and remove scopes that limit effects of inline options,
-- and option events carry inline option tables themselves.
-- Inline option errors have codes `02[123]`, issued for invalid option syntax,
-- unpaired push directives and unpaired pop directives.
function inline_options.get_events(ast, comments, code_lines, warnings)
   local events = utils.update({}, warnings)
   add_closure_boundaries(ast, events)
   local per_line_opts = add_inline_options(events, comments, code_lines)
   core_utils.sort_by_location(events)
   mark_unpaired_boundaries(events)
   events = filter_useless_boundaries(events)
   return events, per_line_opts
end

local function stack_to_array(stack)
   local res = {}

   for i = 1, stack.size do
      res[i] = stack[i]
   end

   return res
end

-- Validates inline options within events and per-line options.
-- Returns a new array of events and a new per-line option map
-- with invalid options replaced with errors.
-- This is require because of `std` option which has to be validated
-- at join/filter time, not at check time, because of possible
-- custom stds.
function inline_options.validate_options(events, per_line_opts)
   local new_events = {}
   local new_per_line_opts = {}
   local added_errors = false

   for i, event in ipairs(events) do
      if event.options and not options.validate(options.all_options, event.options) then
         new_events[i] = invalid_options_error(event)
      else
         new_events[i] = event
      end
   end

   for line, line_events in pairs(per_line_opts) do
      for _, event in ipairs(line_events) do
         if options.validate(options.all_options, event.options) then
            if not new_per_line_opts[line] then
               new_per_line_opts[line] = {}
            end

            table.insert(new_per_line_opts[line], event)
         else
            table.insert(new_events, invalid_options_error(event))
            added_errors = true
         end
      end
   end

   -- This optimization is rather useless, it's mostly used here
   -- to allow testing filtering without providing location information.
   if added_errors then
      core_utils.sort_by_location(new_events)
   end

   return new_events, new_per_line_opts
end

-- Takes an array of events and a map of per-line options as returned from
-- `get_events()`, possibly with location information stripped from push/pop events.
-- Returns an array of pairs {issue, option_attay} that matches each
-- warning or error with an array of inline option tables that affect it.
-- Some option arrays may share identity.
-- Returned array is sorted by warning location.
function inline_options.get_issues_and_affecting_options(events, per_line_opts)
   local pushes = utils.Stack()
   local option_stack = utils.Stack()
   local res = {}
   local empty_option_array = {}

   for _, event in ipairs(events) do
      if event.code then
         local option_array

         if option_stack.size == 0 then
            option_array = empty_option_array
         elseif option_stack.top.option_array then
            option_array = option_stack.top.option_array
         else
            option_array = stack_to_array(option_stack)
            option_stack.top.option_array = option_array
         end

         if per_line_opts[event.line] then
            local line_options = {}

            for i, inline_event in ipairs(per_line_opts[event.line]) do
               line_options[i] = inline_event.options
            end

            option_array = utils.concat_arrays({option_array, line_options})
         end

         table.insert(res, {event, option_array})
      elseif event.options then
         option_stack:push(event.options)
      elseif event.push then
         -- New push boundary. Save size of the option stack to rollback later
         -- when boundary is popped.
         pushes:push(option_stack.size)
      else
         -- Rollback option stack.
         local new_option_stack_size = pushes:pop()

         while option_stack.size ~= new_option_stack_size do
            option_stack:pop()
         end
      end
   end

   return res
end

-- Extract only warnings and errors from an array of events.
function inline_options.get_issues(events)
   local res = {}

   for _, event in ipairs(events) do
      if event.code then
         table.insert(res, event)
      end
   end

   return res
end

return inline_options
