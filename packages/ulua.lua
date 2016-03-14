local ulua_root, ulua_lpath, ulua_lcpath, prev_root, prev_lpath, prev_lcpath
local prev_package_path, prev_package_cpath, prev_require, prev_loaders
local ffi

local function get_env(name)
  local has, value = wx.wxGetEnv(name)
  if has then
    return value
  end
end

local function restore_env(name, value)
  if not value then
    wx.wxUnsetEnv(name)
  else
    wx.wxSetEnv(name, value)
  end
end

prev_root = get_env("LUA_ROOT")
ulua_root = prev_root or ide.config.path.ulua
if not ulua_root then
  error("failed to find ULua, set wither LUA_ROOT or path.ulua in ZeroBrane settings")
end

ulua_lpath = (";%s/?/init.lua;%s/?.lua"):format(ulua_root, ulua_root)

local win = ide.osname == "Windows"
local lib_ext = win and "dll" or "so"
ulua_lcpath = (";%s/?.%s;%s/loadall.%s"):format(ulua_root, lib_ext, ulua_root, lib_ext)

if win then
  ffi = require "ffi"
  ffi.cdef[[int SetDllDirectoryA(const char* path);]]
end

local function set_noconfirm(opt)
  opt = opt or { }
  opt.noconfirm = true
  return opt
end

local function find_win_runtime(root)
  local lfs = require "lfs"
  for path in lfs.dir(root..[[\luajit]]) do
    if path ~= "." and path ~= ".." then
      local runtime = root..[[\luajit\]]..path..[[\Windows\]]..jit.arch
      -- DisplayShell(runtime)
      return runtime
    end
  end
end

return {
  name = "ULua plugin",
  description = "Adds ULua integration to ZeroBrane.",
  author = "Stefano Peluchetti",
  version = 1.0,

  onRegister = function(self)
    wx.wxSetEnv("LUA_ROOT", ulua_root)

    prev_package_path = package.path 
    package.path = package.path..ulua_lpath

    prev_package_cpath = package.cpath
    package.cpath = package.cpath..ulua_lcpath

    prev_require = require
    prev_loaders = { unpack(package.loaders) }
    local ok, pkg = pcall(require, "host.init.__pkg")
    if not ok then
      DisplayShellErr("failed requiring ULua package manager, wrong LUA_ROOT or path.ulua setting? "..tostring(pkg))
      return
    end

    if win then
      local ulua_runtime = find_win_runtime(ulua_root)
      -- TODO: For some reason vcruntime140.dll cannot be loaded anyway, why?!
      ffi.C.SetDllDirectoryA(ulua_runtime)
    end

    -- Force no-confirm for now, user input not supported in local console:
    local commands = {
      status = pkg.status,
      available = pkg.available,
      add = function(name, version, opt) return pkg.add(name, version, set_noconfirm(opt)) end,
      remove = function(name, version, opt) return pkg.remove(name, version, set_noconfirm(opt)) end,
      update = function(opt) return pkg.update(set_noconfirm(opt)) end,
    }

    -- TODO: On Windows damned console is spawned on commands, improve via wx.
    ide:AddConsoleAlias("ulua", commands)
  end,

  onUnRegister = function(self)
    restore_env("LUA_ROOT", prev_root)
    package.path = prev_package_path
    package.cpath = prev_package_cpath
    require = prev_require
    for i=1,#package.loaders do
      package.loaders[i] = nil
    end
    for i=1,#prev_loaders do
      package.loaders[i] = prev_loaders[i]
    end
    if win then
      ffi.C.SetDllDirectoryA("")
    end
    ide:RemoveConsoleAlias("ulua")
  end,

  onInterpreterLoad = function(self, interpreter) 
    prev_lpath = get_env("LUA_PATH")
    wx.wxSetEnv("LUA_PATH", (prev_lpath or "")..ulua_lpath) 
    prev_lcpath = get_env("LUA_CPATH")
    wx.wxSetEnv("LUA_CPATH", (prev_lcpath or "")..ulua_lcpath)
    -- TODO: I need the equivalent of './lua -lhost.init.__pkg' in order to 
    -- TODO: initialize the package manager.
  end,

  onInterpreterClose = function(self, interpreter)
    restore_env("LUA_PATH", prev_lpath)
    restore_env("LUA_CPATH", prev_lcpath)
  end,
}