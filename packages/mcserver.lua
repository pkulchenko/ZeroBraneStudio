-- Implements the integration with MCServer
-- MCServer is a custom C++ minecraft server which has plugins written in Lua
-- The MCServer executable can have a postfix depending on the compilation mode (debug / release), so there are actually two interpreters implemented in this package

local function MakeMCServerInterpreter(a_InterpreterPostfix, a_ExePostfix)
    assert(type(a_InterpreterPostfix) == "string")
    assert(type(a_ExePostfix) == "string")

    return
    {
        name = "MCServer" .. a_InterpreterPostfix,
        description = "MCServer - the custom C++ minecraft server",
        api = {"baselib", "mcserver"},

        frun = function(self, wfilename, withdebug)
            if withdebug then
                DebuggerAttachDefault({runstart = (ide.config.debugger.runonstart == true)})
            end

            -- MCServer plugins are always in a "Plugins/<PluginName>" subfolder located at the executable level
            -- Get to the executable by removing the last two dirs:
            local ExePath = wx.wxFileName(wfilename)
            ExePath:RemoveLastDir()
            ExePath:RemoveLastDir()
            ExePath:ClearExt()
            ExePath:SetName("")
            local ExeName = wx.wxFileName(ExePath)

            -- The executable name depends on the debug / non-debug build mode, it can have a postfix
            ExeName:SetName("MCServer" .. a_ExePostfix)

            -- Executable has a .exe ext on Windows
            if (ide.osname == 'Windows') then
                ExeName:SetExt("exe")
            end

            -- Add a "nooutbuf" cmdline param to the server, causing it to call setvbuf to disable output buffering:
            local Cmd = ExeName:GetFullPath() .. " nooutbuf"

            -- Force ZBS not to hide MCS window, save and restore previous state:
            local SavedUnhideConsoleWindow = ide.config.unhidewindow.ConsoleWindowClass
            ide.config.unhidewindow.ConsoleWindowClass = 1  -- show if hidden
            local RestoreUnhide = function()
                ide.config.unhidewindow.ConsoleWindowClass = SavedUnhideConsoleWindow
            end

            -- Run the server:
            local pid = CommandLineRun(
                Cmd,                    -- Command to run
                ExePath:GetFullPath(),  -- Working directory for the debuggee
                false,                  -- Redirect debuggee output to Output pane? (NOTE: This force-hides the MCS window, not desirable!)
                true,                   -- Add a no-hide flag to WX
                nil,                    -- StringCallback, whatever that is
                nil,                    -- UID to identify this running program; nil to auto-assign
                RestoreUnhide           -- Callback to call once the debuggee terminates
            )
        end,

        hasdebugger = true,
    }
end

return {
  name = "MCServer integration",
  description = "Integration with MCServer - the custom C++ minecraft server.",
  author = "Mattes D (https://github.com/madmaxoft)",
  version = 0.1,

  onRegister = function(self)
    ide:AddInterpreter("mcserver_debug", MakeMCServerInterpreter(" - debug mode", "_debug"))
    ide:AddInterpreter("mcserver_release", MakeMCServerInterpreter(" - release mode", ""))
  end,

  onUnRegister = function(self)
    ide:RemoveInterpreter("mcserver_debug")
    ide:RemoveInterpreter("mcserver_release")
  end,
}