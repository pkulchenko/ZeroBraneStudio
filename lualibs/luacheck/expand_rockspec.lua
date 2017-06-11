local utils = require "luacheck.utils"

local function extract_lua_files(rockspec)
   if type(rockspec) ~= "table" then
      return nil, "rockspec is not a table"
   end

   local build = rockspec.build

   if type(build) ~= "table" then
      return nil, "rockspec.build is not a table"
   end

   local res = {}

   local function scan(t)
      if type(t) == "table" then
         for _, file in pairs(t) do
            if type(file) == "string" and file:sub(-#".lua") == ".lua" then
               table.insert(res, file)
            end
         end
      end
   end

   if build.type == "builtin" then
      scan(build.modules)
   end

   if type(build.install) == "table" then
      scan(build.install.lua)
      scan(build.install.bin)
   end

   table.sort(res)
   return res
end

-- Receives a name of a rockspec, returns list of related .lua files or nil and "syntax" or "error" and error message.
local function expand_rockspec(file)
   local rockspec, err, msg = utils.load_config(file)

   if not rockspec then
      return nil, err, msg
   end

   local files, format_err = extract_lua_files(rockspec)

   if not files then
      return nil, "syntax", format_err
   end

   return files
end

return expand_rockspec
