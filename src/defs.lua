-- About
-- ----------------------------------------------------
-- This file contains lua table definitons used by
-- automatic loaded files, not part of the
-- editor source.
--
-- /<app>/config.lua
-- /cfg/user.lua
-- /interpreters/*.lua
-- /specs/*.lua
-- /tools/*.lua
-- /api/<apitype>/*.lua

-- style definition
-- ----------------------------------------------------
-- all entries are optional
stattr = {
  fg = {r,g,b}, -- foreground color 0-255
  bg = {r,g,b}, -- background color
  i = false, -- italic
  b = false, -- bold
  u = false, -- underline
  fill = true, -- fill to lineend
  -- fn = "Lucida Console", -- font Face Name
  -- fx = 11, -- font size
  -- hs = true or {r,g,b}, -- turn hotspot on
  --   use the specified color as activeForeground
  --   use "hs = true", to turn it on without changing the color
  --   HotspotActiveUnderline and HotspotSingleLine are on automatically
  -- v = true, -- visibility for symbols of the current style
}

style = {
  -- lexer specific (inherit fg/bg from text)
  lexerdef = stattr,
  comment = stattr,
  stringtxt = stattr,
  stringeol = stattr,
  preprocessor = stattr,
  operator = stattr,
  number = stattr,

  keywords0 = stattr,
  keywords1 = stattr,
  keywords2 = stattr,
  keywords3 = stattr,
  keywords4 = stattr,
  keywords5 = stattr,
  keywords6 = stattr,
  keywords7 = stattr,

  -- common (inherit fg/bg from text)
  text = stattr,
  linenumber = stattr,
  bracematch = stattr,
  bracemiss = stattr,
  ctrlchar = stattr,
  indent = stattr,
  calltip = stattr,

  -- common special (need custom fg & bg )
  calltipbg = nil,
  sel = nil,
  caret = nil,
  caretlinebg = nil,
  fold = nil,
  whitespace = nil,

  -- special, functioncall indicator
  fncall = {
    fg = {r,g,b},
    st = wxstc.wxSTC_INDIC_BOX,
  },
}

-- config definition
-- ----------------------------------------------------
-- tables must exist
-- content is optional
-- config is loaded into existing config table
config = {
  appname = "zbstudio", -- by default the launcher name

  path = { -- path for tools/interpreters
    luxinia = "C:/luxbin/", -- path to luxinia exe
    projectdir = "", -- the project directory, used by some tools/interpreters
  },
  editor = {
    fontname = "Courier New", -- default font
    fontsize = 10, -- default size
    caretline = true, -- show active line
    iofilter = nil, -- input/output filtering of strings
    showfncall = true, -- use indicator to show function calls if spec allows
    tabwidth = 4,
    usetabs = true, -- if false then spaces are used
    usewrap = true, -- if true then the text is wrapped in the editor
    whitespace = false,
    autotabs = true, -- if true test for tabs after file load,
                     -- sets "usetabs" to true for this file
    calltipdelay = nil, -- delay to show calltip (in ms)
    autoactivate = false, -- auto-activate/open files during debugging
    smartindent = false, -- use smart indentation if spec allows
    foldcompact = true, -- use compact fold that includes empty lines
    defaulteol = nil, -- default line-endings for new files; valid values are
                      -- wxstc.wxSTC_EOL_CRLF, wxstc.wxSTC_EOL_LF and nil (OS default)
  },

  default = {
    name = 'untitled',
    fullname = 'untitled.lua',
  },

  debugger = {
    verbose = false,
    hostname = nil, -- hostname to use when the detected one is incorrect
    port = nil, -- port number to use
  }

  outputshell = { -- output and shell settings
    fontname = "Courier New", -- default font
    fontsize = 10, -- defult size
  }

  filetree = { -- filetree settings
    fontname = nil, -- no default font as it is system dependent
    fontsize = nil, -- no default size as it is system dependent
  }

  keymap = {}, -- mapping of menu IDs to hot keys
  messages = {}, -- list of messages in a particular language
  language = "en", -- current UI language

  styles = {}, -- styles table as above for editor
  stylesoutshell = {}, -- styles for output/shell

  interpreter = "luadeb", -- the default "project" lua interpreter

  autocomplete = true, -- whether autocomplete is on by default

  acandtip = {
    shorttip = false,   -- tooltips are compact during typing
    nodynwords = false, -- no dynamic words (user entered words)
    ignorecase = false, -- ignores case when performing comparison with autocomplete list
    startat = 2,        -- start suggesting dynamic words after 2 characters
    strategy = 0,
    -- 0: is string comparison
    -- 1: substring leading characters (camel case or _ separated)
    -- 2: leading + any correctly ordered fragments (default)
    width = 60, -- width of the tooltip text (in characters)
  }

  savebak = false, -- if bak files are created on save

  filehistorylength = 20, -- historylength for files

  projecthistorylength = 15, -- historylength for project directories

  singleinstance = true, -- if true creates a UDP server to run IDE once and to load files
  singleinstanceport = 0xe493, -- UDP port for single instance communication

  activateoutput = false, -- activate output/console on Run/Debug/Compile
  unhidewindow = false, -- to unhide a gui window
  allowinteractivescript = false, -- allow interaction in the output window
  projectautoopen = false, -- allow auto open/close files on a project switch
  autorecoverinactivity = nil, -- period of inactivity (s) for autorecover
}

-- application engine
-- ----------------------------------------------------

app = {
  preinit = function() end, -- post spec/tool loading, but prior subsystems/ui generation
  postinit = function() end, -- post init, prior starting mainloop
  loadfilters = {
    tools = function(file) return true end,
    specs = function(file) return true end,
    interpreters = function(file) return true end,
  }
  stringtable = { -- optional entries uses defaults otherwise
    editor = nil, statuswelcome = nil,
    -- ...
  }
}

-- api definition
-- ----------------------------------------------------
-- hierarchy encoded into children

api = {
  -- global space words, e.g "table"
  ["blah"] = {
    -- "function", "class", "keyword", "value", "lib"
    type = "function",
    description = "this does something",

    -- value and function:
    valuetype = "api.ClassName",

    -- function:
    args = "(blah,blubb)",
    returns = "(foo)",

    -- autogenerated post load:
    -- concated hierarchy name (e.g. "lib.class")
    classname = "blah",

    -- children in the class hierarchy
    childs = {
      --.. recursive
    }
  },
  ["blubb"] = {
    --...
  },
}

-- spec definition
-- ----------------------------------------------------
-- all entries are optional
spec = {
  exts = {"ext","ext2",..},
  -- compatible extensions

  lexer = wxstc.wxSTC_LEX_LUA,
  -- scintilla lexer

  lexerstyleconvert = {
    -- table mapping each styles to
    -- appropriate lexer id
    stringeol = {wxstc.wxSTC_LUA_STRINGEOL,},
    -- ...
  }

  linecomment = "//",
  -- string for linecomments

  sep = "%.:",
  -- class.function separator match string,
  -- e.g in lua both . and : are allowed
  -- default is "\1" which should yield no matches
  -- and therefore disable class.func type autocompletion

  isfncall = function(str) return from,to end
  -- function that detects positions for a substring that
  -- stands for a functioncall, ie " call(..)" -> 2,5

  apitype = "api",
  -- which sub directory of "api" is relevant
  -- api files handle autocomplete and tooltips
  -- api won't affect syntax coloring

  keywords = {
    -- up to 8 strings containing space separated keywords
    -- used by the lexer for coloring (NOT for autocomplete).
    -- however each lexer supports varying amount
    -- of keyword types

    "foo bar word",
    "more words",
  }
}

-- tool definition
-- ----------------------------------------------------
-- main entries are optional
tool = {
  fninit = function(frame,menubar) end,
  -- guarantees that ide is initialized
  -- can be used for init
  -- and adding custom menu

  exec = {
    -- quick exec action, listed under "Tools" menu
    name = "",
    description = "",
    fn = function(wxfilename,projectdir) end,
  }
}

-- debuginterface definition
-- ----------------------------------------------------
debuginterface = {
  update = function(self) end, -- run in idle when active
  close = function(self) end, -- run when closed

  -- following are "debugging" actions and must return
  -- error, running, [filePath, fileLine]
  run = function(self) end,
  step = function(self) end,
  over = function(self) end,
  out = function(self) end,
  terminate = function(self) end,
  breaknow = function(self) end,
  breakpoint = function(self,file,line,state) end, -- set breakpoint state

  -- returns result table if successful
  evaluate = function(self, expressions, fnSetValues) end, -- for watches tables
  stack = function(self) end, -- get stack information
}

-- interpreter definition-- ----------------------------------------------------
interpreter = {
  name = "",
  description = "",
  api = {"apifile_without_extension"} -- (opt) to limit loaded lua apis
  frun = function(self,wfilename,withdebugger) end,
  fprojdir = function(self,wfilename) return "projpath_from_filename" end, -- (opt)
  fattachdebug = function(self) end, -- (opt)
  hasdebugger = false, -- if debugging is available
  scratchextloop = nil, -- (opt) indicates scratchpad support
    -- nil, no support for scratchpad;
    -- false, scratchpad supported;
    -- true, scratchpad supported and requires handling for external loop.
  skipcompile = nil, -- don't compile before running if true
}
