
-- mcserver_release.lua

-- Implements the MCServer interpreter for release-mode MCServer executable
-- Uses the mcserver_base.lua file for the actual definition, only provides the postfixes





dofile("interpreters/mcserver_base.lua")
return MakeMCServerInterpreter(" - release mode", "")




