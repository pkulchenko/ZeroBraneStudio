-- Copyright 2011-12 Paul Kulchenko, ZeroBrane LLC
-- Created by Danny Boisvert (derivated from love2d.lua)

local urho3d
local win = ide.osname == "Windows"
local mac = ide.osname == "Macintosh"

return {
  name = "Urho3D",
  description = "Urho3D game engine",
  api = {"baselib", "urho3d"},
  frun = function(self,wfilename,rundebug)
    urho3d = urho3d or ide.config.path.urho3d -- check if the path is configured
    if not urho3d then
      local sep = win and ';' or ':'
      local default =
           win and ([[C:\Program Files\urho3d]]..sep..[[D:\Program Files\urho3d]]..sep..
                    [[C:\Program Files (x86)\urho3d]]..sep..[[D:\Program Files (x86)\urho3d]]..sep)
        or mac and ('/Applications/urho3d.app/Contents/MacOS'..sep)
        or ''
      local path = default
                 ..(os.getenv('PATH') or '')..sep
                 ..(GetPathWithSep(self:fworkdir(wfilename)))..sep
                 ..(os.getenv('HOME') and GetPathWithSep(os.getenv('HOME'))..'bin' or '')
      local paths = {}
      for p in path:gmatch("[^"..sep.."]+") do
        urho3d = urho3d or GetFullPathIfExists(p, win and 'Urho3DPlayer.exe' or 'Urho3DPlayer')
        table.insert(paths, p)
      end
      if not urho3d then
        DisplayOutput("Can't find urho3d executable in any of the following folders: "
          ..table.concat(paths, ", ").."\n")
        return
      end
    end

    if rundebug then
      DebuggerAttachDefault({runstart = ide.config.debugger.runonstart == true})
    end

    local params = ide.config.arg.any or ide.config.arg.urho3d
    local cmd = ('"%s" "%s" %s'):format(urho3d, wfilename:GetFullName(), params or "")
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
  scratchextloop = true,
  takeparameters = true,
}
