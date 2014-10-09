--[[
Typed Lua description file for coroutine manipulation
]]

userdata thread end

create : ((any*) -> (any*)) -> (thread)
resume : (thread, any*) -> (boolean, string|any, any*)
running : () -> (thread, boolean)
status : (thread) -> (string)
wrap : ((any*) -> (boolean, string|any, any*)) -> ((any*) -> (boolean, string|any, any*))
yield : (any*) -> ()
