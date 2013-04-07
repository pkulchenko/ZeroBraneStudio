local torch
local win = false

return {
  name = "Torch-7",
  description = "Torch machine learning package",
  api = {"baselib", "torch"},
  frun = function(self,wfilename,rundebug)
    torch = torch or ide.config.path.torch -- check if the path is configured
    -- Go search for torch
    if not torch then
      local sep = ':'
      local default = ''
      local path = default
                 ..(os.getenv('PATH') or '')..sep
                 ..(os.getenv('TORCH_BIN') or '')..sep
                 ..(os.getenv('HOME') and os.getenv('HOME') .. '/bin' or '')
      local paths = {}
      for p in path:gmatch("[^"..sep.."]+") do
        torch = torch or GetFullPathIfExists(p, 'torch')
        table.insert(paths, p)
      end
      if not torch then
        DisplayOutput("Can't find torch executable in any of the folders in PATH or TORCH_BIN: "
          ..table.concat(paths, ", ").."\n")
        return
      end
    end
    -- end of search for torch
    torch = torch

    -- make minor modifications to the cpath to take care of OSX
    -- make sure the root is using Torch exe location
    local torchroot = GetPathWithSep(torch).. '../'
    local luapath =      ''
    luapath = luapath .. torchroot .. "share/lua/5.1/?.lua;"
    luapath = luapath .. torchroot .. "share/lua/5.1/?/init.lua;"
    luapath = luapath .. torchroot .. "share/torch/lua/?.lua;"
    luapath = luapath .. torchroot .. "share/torch/lua/?/init.lua;"
    luapath = luapath .. torchroot .. "lib/lua/5.1/?.lua;"
    luapath = luapath .. torchroot .. "lib/lua/5.1/?/init.lua"
    local _, path = wx.wxGetEnv("LUA_PATH")
    if path then
       wx.wxSetEnv("LUA_PATH", luapath..";"..path)
    end
    local luacpath = ''
    luacpath = luacpath .. torchroot .. "lib/lua/5.1/?.so;"
    luacpath = luacpath .. torchroot .. "lib/lua/5.1/?.dylib;"
    luacpath = luacpath .. torchroot .. "lib/torch/?.so;"
    luacpath = luacpath .. torchroot .. "lib/torch/?.dylib;"
    luacpath = luacpath .. torchroot .. "lib/lua/5.1/loadall.so;"
    luacpath = luacpath .. torchroot .. "lib/lua/5.1/loadall.dylib;"
    luacpath = luacpath .. torchroot .. "lib/torch/loadall.so;"
    luacpath = luacpath .. torchroot .. "lib/torch/loadall.dylib;"
    local _, cpath = wx.wxGetEnv("LUA_CPATH")
    if cpath then
       wx.wxSetEnv("LUA_CPATH", luacpath..";"..cpath)
    end
    local filepath = wfilename:GetFullPath()
    local script
    if rundebug then
       -- make minor modifications to the cpath to take care of OSX 64-bit
       -- as ZBS is shipped with 32-bit socket libs
       local _,pwd = wx.wxGetEnv('PWD')
      DebuggerAttachDefault({runstart = ide.config.debugger.runonstart == true})
      script = rundebug
    else
      -- if running on Windows and can't open the file, this may mean that
      -- the file path includes unicode characters that need special handling
      local fh = io.open(filepath, "r")
      if fh then fh:close() end
      if ide.osname == 'Windows' and pcall(require, "winapi")
      and wfilename:FileExists() and not fh then
        winapi.set_encoding(winapi.CP_UTF8)
        filepath = winapi.short_path(filepath)
      end

      script = ('dofile [[%s]]'):format(filepath)
    end
    local code = ([[xpcall(function() io.stdout:setvbuf('no'); %s end,function(err) print(debug.traceback(err)) end)]]):format(script)
    local cmd = '"'..torch..'" -e "'..code..'"'
    -- CommandLineRun(cmd,wdir,tooutput,nohide,stringcallback,uid,endcallback)
    return CommandLineRun(cmd,self:fworkdir(wfilename),true,false,nil,nil,
      function() ide.debugger.pid = nil end)
  end,
  fprojdir = function(self,wfilename)
     return wfilename:GetPath(wx.wxPATH_GET_VOLUME)
  end,
  fworkdir = function(self,wfilename)
    return ide.config.path.projectdir or wfilename:GetPath(wx.wxPATH_GET_VOLUME)
  end,
  hasdebugger = true,
  fattachdebug = function(self) DebuggerAttachDefault() end,
  skipcompile = true,
  scratchextloop = true,
}
