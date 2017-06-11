local fs = {}

local utils = require "luacheck.utils"

fs.has_lfs = pcall(require, "lfs")

local base_fs

if fs.has_lfs then
   base_fs = require "luacheck.lfs_fs"
else
   base_fs = require "luacheck.lua_fs"
end

local function ensure_dir_sep(path)
   if path:sub(-1) ~= utils.dir_sep then
      return path .. utils.dir_sep
   end

   return path
end

function fs.split_base(path)
   if utils.is_windows then
      if path:match("^%a:\\") then
         return path:sub(1, 3), path:sub(4)
      else
         -- Disregard UNC paths and relative paths with drive letter.
         return "", path
      end
   else
      if path:match("^/") then
         if path:match("^//") then
            return "//", path:sub(3)
         else
            return "/", path:sub(2)
         end
      else
         return "", path
      end
   end
end

local function is_absolute(path)
   return fs.split_base(path) ~= ""
end

function fs.normalize(path)
   local base, rest = fs.split_base(path)
   rest = rest:gsub("[/\\]", utils.dir_sep)

   local parts = {}

   for part in rest:gmatch("[^"..utils.dir_sep.."]+") do
      if part ~= "." then
         if part == ".." and #parts > 0 and parts[#parts] ~= ".." then
            parts[#parts] = nil
         else
            parts[#parts + 1] = part
         end
      end
   end

   if base == "" and #parts == 0 then
      return "."
   else
      return base..table.concat(parts, utils.dir_sep)
   end
end

local function join_two_paths(base, path)
   if base == "" or is_absolute(path) then
      return path
   else
      return ensure_dir_sep(base) .. path
   end
end

function fs.join(base, ...)
   local res = base

   for i = 1, select("#", ...) do
      res = join_two_paths(res, select(i, ...))
   end

   return res
end

function fs.is_subpath(path, subpath)
   local base1, rest1 = fs.split_base(path)
   local base2, rest2 = fs.split_base(subpath)

   if base1 ~= base2 then
      return false
   end

   if rest2:sub(1, #rest1) ~= rest1 then
      return false
   end

   return rest1 == rest2 or rest2:sub(#rest1 + 1, #rest1 + 1) == utils.dir_sep
end

function fs.is_dir(path)
   return base_fs.get_mode(path) == "directory"
end

function fs.is_file(path)
   return base_fs.get_mode(path) == "file"
end

-- Searches for file starting from path, going up until the file
-- is found or root directory is reached.
-- Path must be absolute.
-- Returns absolute and relative paths to directory containing file or nil.
function fs.find_file(path, file)
   if is_absolute(file) then
      return fs.is_file(file) and path, ""
   end

   path = fs.normalize(path)
   local base, rest = fs.split_base(path)
   local rel_path = ""

   while true do
      if fs.is_file(fs.join(base..rest, file)) then
         return base..rest, rel_path
      elseif rest == "" then
         break
      end

      rest = rest:match("^(.*)"..utils.dir_sep..".*$") or ""
      rel_path = rel_path..".."..utils.dir_sep
   end
end

-- Returns list of all files in directory matching pattern.
-- Returns nil, error message on error.
function fs.extract_files(dir_path, pattern)
   assert(fs.has_lfs)
   local res = {}

   local function scan(dir)
      local ok, iter, state, var = pcall(base_fs.dir_iter, dir)

      if not ok then
         local err = utils.unprefix(iter, "cannot open " .. dir .. ": ")
         return "couldn't recursively check " .. dir .. ": " .. err
      end

      for path in iter, state, var do
         if path ~= "." and path ~= ".." then
            local full_path = fs.join(dir, path)

            if fs.is_dir(full_path) then
               local err = scan(full_path)

               if err then
                  return err
               end
            elseif path:match(pattern) and fs.is_file(full_path) then
               table.insert(res, full_path)
            end
         end
      end
   end

   local err = scan(dir_path)

   if err then
      return nil, err
   end

   table.sort(res)
   return res
end

-- Returns modification time for a file.
function fs.get_mtime(path)
   assert(fs.has_lfs)
   return base_fs.get_mtime(path)
end

-- Returns absolute path to current working directory, with trailing directory separator.
function fs.get_current_dir()
   return ensure_dir_sep(base_fs.get_current_dir())
end

return fs
