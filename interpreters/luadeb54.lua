dofile 'interpreters/luabase.lua'
local interpreter = MakeLuaInterpreter(5.4, ' 5.4')
interpreter.skipcompile = true
return interpreter
