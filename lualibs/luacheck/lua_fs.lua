local utils = require "luacheck.utils"

local lua_fs = {}

-- Quotes an argument for a command for os.execute or io.popen.
-- Same code has been contributed to pl.
local function quote_arg(argument)
   if utils.is_windows then
      if argument == "" or argument:find('[ \f\t\v]') then
         -- Need to quote the argument.
         -- Quotes need to be escaped with backslashes;
         -- additionally, backslashes before a quote, escaped or not,
         -- need to be doubled.
         -- See documentation for CommandLineToArgvW Windows function.
         argument = '"' .. argument:gsub([[(\*)"]], [[%1%1\"]]):gsub([[\+$]], "%0%0") .. '"'
      end

      -- os.execute() uses system() C function, which on Windows passes command
      -- to cmd.exe. Escape its special characters.
      return (argument:gsub('["^<>!|&%%]', "^%0"))
   else
      if argument == "" or argument:find('[^a-zA-Z0-9_@%+=:,./-]') then
         -- To quote arguments on posix-like systems use single quotes.
         -- To represent an embedded single quote close quoted string ('),
         -- add escaped quote (\'), open quoted string again (').
         argument = "'" .. argument:gsub("'", [['\'']]) .. "'"
      end

      return argument
   end
end

local mode_cmd_template

if utils.is_windows then
   mode_cmd_template = [[if exist %s\* (echo directory) else (if exist %s echo file)]]
else
   mode_cmd_template = [[if [ -d %s ]; then echo directory; elif [ -f %s ]; then echo file; fi]]
end

function lua_fs.get_mode(path)
   local quoted_path = quote_arg(path)
   local fh = assert(io.popen(mode_cmd_template:format(quoted_path, quoted_path)))
   local mode = fh:read("*a"):match("^(%S*)")
   fh:close()
   return mode
end

local pwd_cmd = utils.is_windows and "cd" or "pwd"

function lua_fs.get_current_dir()
   local fh = assert(io.popen(pwd_cmd))
   local current_dir = fh:read("*a"):gsub("\n$", "")
   fh:close()
   return current_dir
end

return lua_fs
