local luacheck = require "luacheck"
local fs = require "luacheck.fs"
local multithreading = require "luacheck.multithreading"

local version = {}

version.luacheck = luacheck._VERSION

if rawget(_G, "jit") then
   version.lua = rawget(_G, "jit").version
else
   version.lua = _VERSION
end

if fs.has_lfs then
   local lfs = require "lfs"
   version.lfs = lfs._VERSION
else
   version.lfs = "Not found"
end

if multithreading.has_lanes then
   version.lanes = multithreading.lanes.ABOUT.version
else
   version.lanes = "Not found"
end

version.string = ([[
Luacheck: %s
Lua: %s
LuaFileSystem: %s
LuaLanes: %s]]):format(version.luacheck, version.lua, version.lfs, version.lanes)

return version
