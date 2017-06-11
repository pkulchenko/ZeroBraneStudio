local standards = {}

-- A standard (aka std) defines set of allowed globals, their fields,
-- and whether they are mutable.
--
-- A standard can be in several formats. Internal (normalized) format
-- is a tree. Each node defines a global or its field. Each node may have
-- boolean `read_only` and `other_fields`, and may contain definitions
-- of nested fields in `fields` subtable, which maps field names
-- to definition tables. For example, standard defining globals
-- of some Lua version may start like this:
-- {
--    -- Most globals are read-only by default.
--    read_only = true,
--    fields = {
--       -- The tree can't be recursive, just allow everything for `_G`.
--       _G = {other_fields = true, read_only = false},
--       package = {
--          fields = {
--             -- `other_fields` is false by default, so that an empty table
--             -- defines a field that can't be indexed further (a function in this case).
--             loadlib = {},
--             -- Allow doing everything with `package.loaded`.
--             loaded = {other_fields = true, read_only = false},
--             -- More fields here...
--          }
--       },
--       -- More globals here...
--    }
-- }
--
-- A similar format is used to define standards in table form
-- in config. There are two differences:
-- first, top level table can have two fields, `globals` and `read_globals`,
-- that map global names to definition tables. Default value of `read_only` field
-- for the these tables depends on which table they come from (`true` for `read_globals`
-- and `false` for `globals`). Additionally, all tables that map field or global names
-- to definition tables may have non-string keys, their associated values are interpreted
-- as names instead and their definition table allows indexing with any keys indefinitely.
-- E.g. `{fields = {"foo"}}` is equivalent to `{fields = {foo = {other_fields = true}}}`.
-- This feature makes it easier to create less strict standards that do not care about fields,
-- to ease migration from the old format.
--
-- Additionally, there are some predefined named standards in `luacheck.builtin_standards` module.
-- In config and inline options its possible to use their names as strings to refer to them.

-- Validates an optional table mapping field names to field definitions or non-string keys to names.
-- Returns a truthy value is the table is valid, a falsy value otherwise.
local function validate_fields(fields)
   if fields == nil then
      return true
   end

   if type(fields) ~= "table" then
      return
   end

   for key, value in pairs(fields) do
      if type(key) == "string" then
         if type(value) ~= "table" then
            return
         end

         if value.read_only ~= nil and type(value.read_only) ~= "boolean" then
            return
         end

         if value.other_fields ~= nil and type(value.other_fields) ~= "boolean" then
            return
         end

         if not validate_fields(value.fields) then
            return
         end
      elseif type(value) ~= "string" then
         return
      end
   end

   return true
end

-- Validates an std table in user-side format.
-- Returns a truthy value is the table is valid, a falsy value otherwise.
function standards.validate_std_table(std_table)
   return type(std_table) == "table" and validate_fields(std_table.globals) and validate_fields(std_table.read_globals)
end

local infinitely_indexable_def = {other_fields = true}

local function add_fields(def, fields, overwrite, ignore_array_part, default_read_only)
   if not fields then
      return
   end

   for field_name, field_def in pairs(fields) do
      if type(field_name) == "string" or not ignore_array_part then
         if type(field_name) ~= "string" then
            field_name = field_def
            field_def = infinitely_indexable_def
         end

         if not def.fields then
            def.fields = {}
         end

         if not def.fields[field_name] then
            def.fields[field_name] = {}
         end

         local existing_field_def = def.fields[field_name]
         local new_read_only = field_def.read_only

         if new_read_only == nil then
            new_read_only = default_read_only
         end

         if new_read_only ~= nil then
            if overwrite or new_read_only == false then
               existing_field_def.read_only = new_read_only
            end
         end

         if field_def.other_fields ~= nil then
            if overwrite or field_def.other_fields == true then
               existing_field_def.other_fields = field_def.other_fields
            end
         end

         add_fields(existing_field_def, field_def.fields, overwrite, false, nil)
      end
   end
end

-- Merges in an std table in user-side format.
-- By default the new state of normalized std is a union of the standard tables being merged,
-- e.g. if either table allows some field to be mutated, result should allow it, too.
-- If `overwrite` is truthy, read-only statuses from the new std table overwrite existing values.
-- If `ignore_top_array_part` is truthy, non-string keys in `globals` and `read_globals` tables
-- in `std_table` are not processed.
function standards.add_std_table(final_std, std_table, overwrite, ignore_top_array_part)
   add_fields(final_std, std_table.globals, overwrite, ignore_top_array_part, false)
   add_fields(final_std, std_table.read_globals, overwrite, ignore_top_array_part, true)
end

-- Overwrites or adds definition of a field with given read-only status and any nested keys.
-- Field is specified as an array of field names.
function standards.overwrite_field(final_std, field_names, read_only)
   local field_def = final_std

   for _, field_name in ipairs(field_names) do
      if not field_def.fields then
         field_def.fields = {}
      end

      if not field_def.fields[field_name] then
         field_def.fields[field_name] = {read_only = read_only}
      end

      field_def = field_def.fields[field_name]
   end

   for key in pairs(field_def) do
      field_def[key] = nil
   end

   field_def.read_only = read_only
   field_def.other_fields = true
end

-- Removes definition of a field from a normalized std table.
-- Field is specified as an array of field names.
function standards.remove_field(final_std, field_names)
   local field_def = final_std
   local parent_def

   for _, field_name in ipairs(field_names) do
      parent_def = field_def

      if not field_def.fields or not field_def.fields[field_name] then
         -- The field wasn't defined in the first place.
         return
      end

      field_def = field_def.fields[field_name]
   end

   if parent_def then
      parent_def.fields[field_names[#field_names]] = nil
   end
end

local function infer_deep_read_only_statuses(def, read_only)
   local deep_read_only = not def.other_fields or read_only

   if def.fields then
      for _, field_def in pairs(def.fields) do
         local field_read_only = read_only

         if field_def.read_only ~= nil then
            field_read_only = field_def.read_only
         end

         infer_deep_read_only_statuses(field_def, field_read_only)
         deep_read_only = deep_read_only and field_read_only and field_def.deep_read_only
      end
   end

   if deep_read_only then
      def.deep_read_only = true
   end
end

-- Finishes building a normalized std tables.
-- Adds `deep_read_only` fields with `true` value to definition tables
-- that do not have any writable fields, recursively.
function standards.finalize(final_std)
   infer_deep_read_only_statuses(final_std, true)
end

return standards
