local parser = require "luacheck.parser"
local linearize = require "luacheck.linearize"
local analyze = require "luacheck.analyze"
local reachability = require "luacheck.reachability"
local inline_options = require "luacheck.inline_options"
local utils = require "luacheck.utils"
local check_whitespace = require "luacheck.whitespace"
local detect_globals = require "luacheck.detect_globals"

local function is_secondary(value)
   return value.secondaries and value.secondaries.used
end

local ChState = utils.class()

function ChState:__init()
   self.warnings = {}
end

function ChState:warn(warning, implicit_self)
   if not warning.end_column then
      warning.end_column = implicit_self and warning.column or (warning.column + #warning.name - 1)
   end

   table.insert(self.warnings, warning)
end

local action_codes = {
   set = "1",
   mutate = "2",
   access = "3"
}

local type_codes = {
   var = "1",
   func = "1",
   arg = "2",
   loop = "3",
   loopi = "3"
}

-- `index` describes an indexing, where `index[1]` is a global node
-- and other items describe keys: each one is a string node, "not_string",
-- or "unknown". `node` is literal base node that's indexed.
-- E.g. in `local a = table.a; a.b = "c"` `node` is `a` node of the second
-- statement and `index` describes `table.a.b`.
-- `index.previous_indexing_len` is optional length of prefix of `index` array representing last assignment
-- in the aliasing chain, e.g. `2` in the previous example (because last indexing
-- is `table.a`).
function ChState:warn_global(node, index, is_lhs, is_top_scope)
   local global = index[1]
   local action = is_lhs and (#index == 1 and "set" or "mutate") or "access"

   local indexing = {}

   for i, field in ipairs(index) do
      if field == "unknown" then
         indexing[i] = true
      elseif field == "not_string" then
         indexing[i] = false
      else
         indexing[i] = field[1]
      end
   end

   -- and filter out the warning if the base of last indexing is already
   -- undefined and has been reported.
   -- E.g. avoid useless warning in the second statement of `local t = tabell; t.concat(...)`.
   self:warn({
      code = "11" .. action_codes[action],
      name = global[1],
      indexing = indexing,
      previous_indexing_len = index.previous_indexing_len,
      line = node.location.line,
      column = node.location.column,
      end_column = node.location.column + #node[1] - 1,
      top = is_top_scope and (action == "set") or nil,
      indirect = node ~= global or nil
   })
end

-- W12* (read-only global) and W131 (unused global) are patched in during filtering.

function ChState:warn_unused_variable(value, recursive, self_recursive, useless)
   self:warn({
      code = "21" .. type_codes[value.var.type],
      name = value.var.name,
      line = value.location.line,
      column = value.location.column,
      secondary = is_secondary(value) or nil,
      func = (value.type == "func") or nil,
      mutually_recursive = not self_recursive and recursive or nil,
      recursive = self_recursive,
      self = value.var.self,
      useless = value.var.name == "_" and useless or nil
   }, value.var.self)
end

function ChState:warn_unset(var)
   self:warn({
      code = "221",
      name = var.name,
      line = var.location.line,
      column = var.location.column
   })
end

function ChState:warn_unaccessed(var, mutated)
   -- Mark as secondary if all assigned values are secondary.
   -- It is guaranteed that there are at least two values.
   local secondary = true

   for _, value in ipairs(var.values) do
      if not value.empty and not is_secondary(value) then
         secondary = nil
         break
      end
   end

   self:warn({
      code = "2" .. (mutated and "4" or "3") .. type_codes[var.type],
      name = var.name,
      line = var.location.line,
      column = var.location.column,
      secondary = secondary
   }, var.self)
end

function ChState:warn_unused_value(value, mutated, overwriting_node)
   self:warn({
      code = "3" .. (mutated and "3" or "1") .. type_codes[value.type],
      name = value.var.name,
      overwritten_line = overwriting_node and overwriting_node.location.line,
      overwritten_column = overwriting_node and overwriting_node.location.column,
      line = value.location.line,
      column = value.location.column,
      secondary = is_secondary(value) or nil,
   }, value.type == "arg" and value.var.self)
end

function ChState:warn_unused_field_value(node, overwriting_node)
   self:warn({
      code = "314",
      field = node.field,
      index = node.is_index,
      overwritten_line = overwriting_node.location.line,
      overwritten_column = overwriting_node.location.column,
      line = node.location.line,
      column = node.location.column,
      end_column = node.location.column + #node.first_token - 1
   })
end

function ChState:warn_uninit(node, mutation)
   self:warn({
      code = mutation and "341" or "321",
      name = node[1],
      line = node.location.line,
      column = node.location.column
   })
end

function ChState:warn_redefined(var, prev_var, same_scope)
   if var.name ~= "..." then
      self:warn({
         code = "4" .. (same_scope and "1" or (var.line == prev_var.line and "2" or "3")) .. type_codes[prev_var.type],
         name = var.name,
         line = var.location.line,
         column = var.location.column,
         self = var.self and prev_var.self,
         prev_line = prev_var.location.line,
         prev_column = prev_var.location.column
      }, var.self)
   end
end

function ChState:warn_unreachable(location, unrepeatable, token)
   self:warn({
      code = "51" .. (unrepeatable and "2" or "1"),
      line = location.line,
      column = location.column,
      end_column = location.column + #token - 1
   })
end

function ChState:warn_unused_label(label)
   self:warn({
      code = "521",
      label = label.name,
      line = label.location.line,
      column = label.location.column,
      end_column = label.end_column
   })
end

function ChState:warn_unbalanced(location, shorter_lhs)
   -- Location points to `=`.
   self:warn({
      code = "53" .. (shorter_lhs and "1" or "2"),
      line = location.line,
      column = location.column,
      end_column = location.column
   })
end

function ChState:warn_empty_block(location, do_end)
   -- Location points to `do`, `then` or `else`.
   self:warn({
      code = "54" .. (do_end and "1" or "2"),
      line = location.line,
      column = location.column,
      end_column = location.column + (do_end and 1 or 3)
   })
end

function ChState:warn_empty_statement(location)
   self:warn({
      code = "551",
      line = location.line,
      column = location.column,
      end_column = location.column
   })
end

local function check_or_throw(src)
   local ast, comments, code_lines, line_endings, semicolons = parser.parse(src)
   local chstate = ChState()
   local line = linearize(chstate, ast)

   for _, location in ipairs(semicolons) do
      chstate:warn_empty_statement(location)
   end

   local lines = utils.split_lines(src)
   local line_lengths = utils.map(function(s) return #s end, lines)
   check_whitespace(chstate, lines, line_endings)
   analyze(chstate, line)
   reachability(chstate, line)
   detect_globals(chstate, line)
   local events, per_line_opts = inline_options.get_events(ast, comments, code_lines, chstate.warnings)
   return {events = events, per_line_options = per_line_opts, line_lengths = line_lengths, line_endings = line_endings}
end

--- Checks source.
-- Returns a table with results, with the following fields:
--    `events`: array of issues and inline option events (options, push, or pop).
--    `per_line_options`: map from line numbers to arrays of inline option events.
local function check(src)
   local ok, res = utils.try(check_or_throw, src)

   if ok then
      return res
   elseif utils.is_instance(res.err, parser.SyntaxError) then
      local syntax_error = {
         code = "011",
         line = res.err.line,
         column = res.err.column,
         end_column = res.err.end_column,
         msg = res.err.msg
      }

      return {events = {syntax_error}, per_line_options = {}, line_lengths = {}}
   else
      error(res, 0)
   end
end

return check
