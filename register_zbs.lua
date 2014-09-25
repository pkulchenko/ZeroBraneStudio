-- This file will register ZeroBrane studio as the editor for .Lua and .Rockspec files
-- on Windows systems.
--
-- Put this file in the same directory as zbstudio.exe and run it from the command line
-- Eg. C:\> lua.exe c:\somepath\register_zbs.lua
--
-- Or load as a function and call using full path to zbstudio.exe as argument
-- Eg.  name_of_func("c:\somepath\zbstudio.exe")
--

local content = [[
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\.lua]
@="Lua.Script"

[HKEY_CLASSES_ROOT\.lua\Content Type]
@="text/plain"

[HKEY_CLASSES_ROOT\.lua\PerceivedType]
@="text"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.lua]
@="Lua.Script"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.lua\Content Type]
@="text/plain"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.lua\PerceivedType]
@="text"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Lua.Script]
@="Lua script"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Lua.Script\Shell]

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Lua.Script\Shell\Edit]
@="Edit Lua script"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Lua.Script\Shell\Edit\Command]
@="\"<ZEROBRANEPATH>zbstudio.exe\" \"%1\""




[HKEY_CLASSES_ROOT\.rockspec]
@="Lua.Rockspec"

[HKEY_CLASSES_ROOT\.rockspec\Content Type]
@="text/plain"

[HKEY_CLASSES_ROOT\.rockspec\PerceivedType]
@="text"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.rockspec]
@="Lua.Rockspec"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.rockspec\Content Type]
@="text/plain"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\.rockspec\PerceivedType]
@="text"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Lua.Rockspec]
@="Lua Rockspec File"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Lua.Rockspec\Shell\Edit]
@="Edit"

[HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Lua.Rockspec\Shell\Edit\command]
@="\"<ZEROBRANEPATH>zbstudio.exe\" \"%1\""
]]

-- Check this script location as same location for 'zbstudio.exe'
-- if run from commandline take arg[0] (the scripts own full-path)
-- if run as function, take first parameter
local f = (arg or {})[0]
if not f then f = ({...})[1] end

if not f then
  print("run from the commandline, or as function with parameter")
  os.exit(1)
end

-- cleanup filepath, remove all double backslashes
while f:match("\\\\") do
  f = f:gsub("\\\\", "\\")
end

-- extract path and name from argument
local p = ""
for i = #f, 1, -1 do
  if f:sub(i,i) == "\\" then
    p = f:sub(1, i)
    break
  end
end

-- create output name
local no = (os.getenv("temp") or os.getenv("tmp")) .. "\\zbstudio_registry_import.reg"
no = no:gsub("\\\\", "\\")

-- create path substitute; escape backslash by doubles
local ps = p:gsub("\\", "\\\\")

-- fill template
content = content:gsub("%<ZEROBRANEPATH%>", ps)

-- write destination file
fh = io.open(no, "w+")
fh:write(content)
fh:close()

-- execute '.reg' file to load it into windows registry, causes prompts!
os.execute(no)

-- delete temporary file
os.remove(no)
