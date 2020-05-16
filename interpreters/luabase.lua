function MakeLuaInterpreter(version, name)

local function exePath(self, version)
  local version = tostring(version or ""):gsub('%.','')
  local mainpath = ide:GetRootPath()
  local macExe = mainpath..([[bin/lua.app/Contents/MacOS/lua%s]]):format(version)
  return (ide.config.path['lua'..version]
    or (ide.osname == "Windows" and mainpath..([[bin\lua%s.exe]]):format(version))
    or (ide.osname == "Unix" and mainpath..([[bin/linux/%s/lua%s]]):format(ide.osarch, version))
    or (wx.wxFileExists(macExe) and macExe or mainpath..([[bin/lua%s]]):format(version))),
  ide.config.path['lua'..version] ~= nil
end

return {
  name = ("Lua%s"):format(name or version or ""),
  description = ("Lua%s interpreter with debugger"):format(name or version or ""),
  api = {"baselib"},
  luaversion = version or '5.1',
  fexepath = exePath,
  frun = function(self,wfilename,rundebug)
    local exe, iscustom = self:fexepath(version or "")
    local filepath = ide:GetShortFilePath(wfilename:GetFullPath())

    if rundebug then
      ide:GetDebugger():SetOptions({runstart = ide.config.debugger.runonstart == true})

      -- update arg to point to the proper file
      rundebug = ('if arg then arg[0] = [[%s]] end '):format(wfilename:GetFullPath())..rundebug

      local tmpfile = wx.wxFileName()
      tmpfile:AssignTempFileName(".")
      filepath = ide:GetShortFilePath(tmpfile:GetFullPath())

      local ok, err = FileWrite(filepath, rundebug)
      if not ok then
        ide:Print(("Can't open temporary file '%s' for writing: %s."):format(filepath, err))
        return
      end
    end
    local params = self:GetCommandLineArg("lua")
    local code = ([[-e "io.stdout:setvbuf('no')" "%s"]]):format(filepath)
    local cmd = '"'..exe..'" '..code..(params and " "..params or "")

    -- modify LUA_CPATH and LUA_PATH to work with other Lua versions
    local envcpath = "LUA_CPATH"
    local envlpath = "LUA_PATH"
    if version then
      local env = "PATH_"..string.gsub(version, '%.', '_')
      if os.getenv("LUA_C"..env) then envcpath = "LUA_C"..env end
      if os.getenv("LUA_"..env) then envlpath = "LUA_"..env end
    end

    local cpath = os.getenv(envcpath)
    if rundebug and cpath and not iscustom then
      -- prepend osclibs as the libraries may be needed for debugging,
      -- but only if no path.lua is set as it may conflict with system libs
      wx.wxSetEnv(envcpath, ide.osclibs..';'..cpath)
    end
    if version and cpath then
      -- adjust references to /clibs/ folders to point to version-specific ones
      local cpath = os.getenv(envcpath)
      local clibs = string.format('/clibs%s/', version):gsub('%.','')
      if not cpath:find(clibs, 1, true) then cpath = cpath:gsub('/clibs/', clibs) end
      wx.wxSetEnv(envcpath, cpath)
    end

    local lpath = version and (not iscustom) and os.getenv(envlpath)
    if lpath then
      -- add oslibs libraries when LUA_PATH_5_x variables are set to allow debugging to work
      wx.wxSetEnv(envlpath, lpath..';'..ide.oslibs)
    end

    -- CommandLineRun(cmd,wdir,tooutput,nohide,stringcallback,uid,endcallback)
    local pid = CommandLineRun(cmd,self:fworkdir(wfilename),true,false,nil,nil,
      function() if rundebug then wx.wxRemoveFile(filepath) end end)

    if (rundebug or version) and cpath then wx.wxSetEnv(envcpath, cpath) end
    if lpath then wx.wxSetEnv(envlpath, lpath) end
    return pid
  end,
  hasdebugger = true,
  scratchextloop = false,
  unhideanywindow = true,
  takeparameters = true,
}

end

return nil -- as this is not a real interpreter
