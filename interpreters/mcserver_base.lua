
-- mcserver_base.lua

-- Implements the base for MCServer interpreter description and interface for ZBStudio
-- The actual interpreter must be created by another file, providing the executable postfixes,
-- since MCServer executable can have a postfix depending on the compilation mode (debug / release)





function MakeMCServerInterpreter(a_InterpreterPostfix, a_ExePostfix)
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
			
			-- Run the server:
			local pid = CommandLineRun(Cmd, ExePath:GetFullPath(), true, true)
		end,
		
		hasdebugger = true,
	}
end



