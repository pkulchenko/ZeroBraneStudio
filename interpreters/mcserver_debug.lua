
-- mcserver_debug.lua

-- Implements the MCServer interpreter for debug-mode MCServer executable
-- Uses the mcserver_base.lua file for the actual definition, only provides the postfixes





dofile("interpreters/mcserver_base.lua")
return MakeMCServerInterpreter(" - debug mode", "_debug")




