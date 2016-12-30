return {
  name = "LuaJIT gfx sandbox",
  description = "LuaJIT GFX Sandbox interpreter with debugger",
  api = {"baselib","luajit2","glfw3","glewgl", "shaderc", "vulkan1",},
  luaversion = '5.1',
  frun = function(self,wfilename,rundebug)
    local binpath = ide.config.path.luajitgfxsandbox or os.getenv("LUAJIT_GFX_SANDBOX_PATH")
    if not binpath then
      ide:Print("Failed to determine binary directory")
      return
    end
    local exe = binpath.."/luajit.cmd"
    local filepath = wfilename:GetFullPath()

    do
      -- if running on Windows and can't open the file, this may mean that
      -- the file path includes unicode characters that need special handling
      local fh = io.open(filepath, "r")
      if fh then fh:close() end
      if ide.osname == 'Windows' and pcall(require, "winapi")
      and wfilename:FileExists() and not fh then
        winapi.set_encoding(winapi.CP_UTF8)
        local shortpath = winapi.short_path(filepath)
        if shortpath == filepath then
          ide:Print(
            ("Can't get short path for a Unicode file name '%s' to open the file.")
            :format(filepath))
          ide:Print(
            ("You can enable short names by using `fsutil 8dot3name set %s: 0` and recreate the file or directory.")
            :format(wfilename:GetVolume()))
        end
        filepath = shortpath
      end
    end

    if rundebug then
      ide:GetDebugger():SetOptions({runstart = ide.config.debugger.runonstart == true})

      -- update arg to point to the proper file
      rundebug = ('if arg then arg[0] = [[%s]] end '):format(filepath)..rundebug

      local tmpfile = wx.wxFileName()
      tmpfile:AssignTempFileName(".")
      filepath = tmpfile:GetFullPath()
      local f = io.open(filepath, "w")
      if not f then
        ide:Print("Can't open temporary file '"..filepath.."' for writing.")
        return
      end
      f:write(rundebug)
      f:close()
    end
    local params = self:GetCommandLineArg("lua")
    local code = ([["%s"]]):format(filepath)
    local cmd = '"'..exe..'" '..code..(params and " "..params or "")

    -- CommandLineRun(cmd,wdir,tooutput,nohide,stringcallback,uid,endcallback)
    local pid = CommandLineRun(cmd,self:fworkdir(wfilename),true,false,nil,nil,
      function() if rundebug then wx.wxRemoveFile(filepath) end end)

    return pid
  end,
  hasdebugger = true,
  scratchextloop = false,
  unhideanywindow = true,
  takeparameters = true,
}

