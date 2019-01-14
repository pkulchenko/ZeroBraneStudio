-- Copyright 2011-17 Paul Kulchenko, ZeroBrane LLC
-- authors: Luxinia Dev (Eike Decker & Christoph Kubisch)
---------------------------------------------------------

-- put bin/ and lualibs/ first to avoid conflicts with included modules
-- that may have other versions present somewhere else in path/cpath.
local function isproc()
  local file = io.open("/proc")
  if file then file:close() end
  return file ~= nil
end
local iswindows = os.getenv('WINDIR') or (os.getenv('OS') or ''):match('[Ww]indows')
local islinux = not iswindows and isproc()
local arch = "x86" -- use 32bit by default
local unpack = table.unpack or unpack

if islinux then
  local file = io.popen("uname -m")
  if file then
    local machine=file:read("*l")
    local archtype= {
      x86_64  = "x64",
      armv7l  = "armhf",
      aarch64 = "aarch64",
    }
    arch = archtype[machine] or arch
    file:close()
  end
end

package.cpath = (
  iswindows and 'bin/clibs/?.dll;' or
  islinux and ('bin/linux/%s/clibs/lib?.so;bin/linux/%s/clibs/?.so;'):format(arch,arch) or
  --[[isosx]] 'bin/clibs/lib?.dylib;bin/clibs/?.dylib;')
    .. package.cpath
package.path  = 'lualibs/?.lua;lualibs/?/?.lua;lualibs/?/init.lua;' .. package.path

require("wx")
require("bit")
require("mobdebug")
if jit and jit.on then jit.on() end -- turn jit "on" as "mobdebug" may turn it off for LuaJIT

dofile "src/util.lua"

-----------
-- IDE
--
local pendingOutput = {}
local config = dofile("src/config.lua")
config.path = {
  projectdir = "",
  app = nil,
}
ide = {
  GetTime = (function(ok, socket) return ok and socket.gettime or os.clock end)(pcall(require, "socket")),
  MODPREF = "* ",
  MAXMARGIN = wxstc.wxSTC_MAX_MARGIN or 4,
  ANYMARKERMASK = 2^24-1,
  config = config,
  specs = {
    none = {
      sep = "\1",
    }
  },
  messages = {},
  tools = {},
  iofilters = {},
  interpreters = {},
  packages = {},
  apis = {},
  timers = {},
  onidle = {},

  proto = {}, -- prototypes for various classes
  filenames = {}, -- names for files to load

  app = nil, -- application engine
  interpreter = nil, -- current Lua interpreter
  frame = nil, -- gui related
  debugger = {}, -- debugger related info
  filetree = nil, -- filetree
  findReplace = nil, -- find & replace handling
  settings = nil, -- user settings (window pos, last files..)
  session = {
    projects = {}, -- project configuration for the current session
    lastupdated = nil, -- timestamp of the last modification in any of the editors
    lastsaved = nil, -- timestamp of the last recovery information saved
  },

  -- misc
  exitingProgram = false, -- are we currently exiting?
  infocus = nil, -- last component with a focus
  editorApp = wx.wxGetApp(),
  editorFilename = nil,
  openDocuments = {}, -- see `Document` prototype in proto.lua for the methods
  ignoredFilesList = {},
  font = {
    eNormal = nil,
    eItalic = nil,
    oNormal = nil,
    oItalic = nil,
    fNormal = nil,
  },

  osname = wx.wxPlatformInfo.Get():GetOperatingSystemFamilyName(),
  osarch = arch,
  oshome = os.getenv("HOME") or (iswindows and os.getenv('HOMEDRIVE') and os.getenv('HOMEPATH')
    and (os.getenv('HOMEDRIVE')..os.getenv('HOMEPATH'))),
  wxver = string.match(wx.wxVERSION_STRING, "[%d%.]+"),

  test = {}, -- local functions used for testing

  Print = function(self, ...)
    if DisplayOutputLn then
      -- flush any pending output
      while #pendingOutput > 0 do DisplayOutputLn(unpack(table.remove(pendingOutput, 1))) end
      -- print without parameters can be used for flushing, so skip the printing
      if select('#', ...) > 0 then DisplayOutputLn(...) end
      return
    end
    pendingOutput[#pendingOutput + 1] = {...}
  end,
}
ide.startedat = ide:GetTime()

-- Scintilla switched to using full byte for style numbers from using only first 5 bits
ide.STYLEMASK = ide.wxver <= "2.9.5" and 31 or 255

-- add wx.wxMOD_RAW_CONTROL as it's missing in wxlua 2.8.12.3;
-- provide default for wx.wxMOD_CONTROL as it's missing in wxlua 2.8 that
-- is available through Linux package managers
if not wx.wxMOD_CONTROL then wx.wxMOD_CONTROL = 0x02 end
if not wx.wxMOD_RAW_CONTROL then
  wx.wxMOD_RAW_CONTROL = ide.osname == 'Macintosh' and 0x10 or wx.wxMOD_CONTROL
end
if not wx.WXK_RAW_CONTROL then
  wx.WXK_RAW_CONTROL = ide.osname == 'Macintosh' and 396 or wx.WXK_CONTROL
end
-- ArchLinux running 2.8.12.2 doesn't have wx.wxMOD_SHIFT defined
if not wx.wxMOD_SHIFT then wx.wxMOD_SHIFT = 0x04 end
-- wxDIR_NO_FOLLOW is missing in wxlua 2.8.12 as well
if not wx.wxDIR_NO_FOLLOW then wx.wxDIR_NO_FOLLOW = 0x10 end
if not wxaui.wxAUI_TB_PLAIN_BACKGROUND then wxaui.wxAUI_TB_PLAIN_BACKGROUND = 2^8 end
if not wx.wxNOT_FOUND then wx.wxNOT_FOUND = -1 end
if not wx.wxEXEC_NOEVENTS then wx.wxEXEC_NOEVENTS = 16 end
if not wx.wxEXEC_HIDE_CONSOLE then wx.wxEXEC_HIDE_CONSOLE = 32 end
if not wx.wxEXEC_BLOCK then wx.wxEXEC_BLOCK = wx.wxEXEC_SYNC + wx.wxEXEC_NOEVENTS end

for k,v in pairs({
    VS_NONE = 0, VS_RECTANGULARSELECTION = 1, VS_USERACCESSIBLE = 2, VS_NOWRAPLINESTART = 4
  }) do
  if not wxstc["wxSTC_"..k] then wxstc["wxSTC_"..k] = wxstc["wxSTC_SC"..k] or v end
end

-- wxwidgets 3.1.1+ replaced wxSTC_SCMOD_* with wxSTC_KEYMOD_*; map both for compatibility
for _, key in ipairs({"ALT", "CTRL", "SHIFT", "META", "SUPER", "NORM"}) do
  local scmod = "wxSTC_SCMOD_"..key
  local keymod = "wxSTC_KEYMOD_"..key
  if wxstc[scmod] and not wxstc[keymod] then
    wxstc[keymod] = wxstc[scmod]
  elseif not wxstc[scmod] and wxstc[keymod] then
    wxstc[scmod] = wxstc[keymod]
  end
end

-- it's an interface constant and is not public in wxlua, so add it
if not wxstc.wxSTC_SETLEXERLANGUAGE then wxstc.wxSTC_SETLEXERLANGUAGE = 4006 end

if not setfenv then -- Lua 5.2
  -- based on http://lua-users.org/lists/lua-l/2010-06/msg00314.html
  -- this assumes f is a function
  local function findenv(f)
    local level = 1
    repeat
      local name, value = debug.getupvalue(f, level)
      if name == '_ENV' then return level, value end
      level = level + 1
    until name == nil
    return nil end
  getfenv = function (f) return(select(2, findenv(f)) or _G) end
  setfenv = function (f, t)
    local level = findenv(f)
    if level then debug.setupvalue(f, level, t) end
    return f end
end

if not package.searchpath then
  -- from Scintillua by Mitchell (mitchell.att.foicica.com).
  -- Searches for the given *name* in the given *path*.
  -- This is an implementation of Lua 5.2's `package.searchpath()` function for Lua 5.1.
  function package.searchpath(name, path)
    local tried = {}
    for part in path:gmatch('[^;]+') do
      local filename = part:gsub('%?', name)
      local f = io.open(filename, 'r')
      if f then f:close() return filename end
      tried[#tried + 1] = ("no file '%s'"):format(filename)
    end
    return nil, table.concat(tried, '\n')
  end
end

local function loadToTab(folder, tab, recursive, proto)
  local files = (wx.wxFileExists(folder) and {folder}
    or wx.wxDirExists(folder) and ide:GetFileList(folder, recursive, "*.lua")
    or {})
  for _, file in ipairs(files) do LoadLuaFileExt(tab, file, proto) end
  return tab
end

function ide:LoadSpec(path)
  loadToTab(path or "spec", ide.specs, true)
  UpdateSpecs()
end

function ide:LoadTool(path)
  local tools = {}
  for name,tool in pairs(loadToTab(path or "tools", {}, false)) do
    if tool.fninit then
      local ok, err = pcall(tool.fninit, ide:GetMainFrame(), ide:GetMenuBar())
      if not ok then ide:Print(("Error when initializing tool %s: %s"):format(name, err)) end
    end
    if tool.exec and tool.exec.name then table.insert(tools,tool) end
  end

  -- sort tools
  table.sort(tools,function(a,b) return a.exec.name < b.exec.name end)

  for _, tool in ipairs(tools) do
    -- add menus for each
    local id, menu = ide:AddTool(tool.exec.name, tool.exec.fn)
    -- add descriptions
    if id and tool.exec.description then menu:SetHelpString(id, tool.exec.description) end
  end

  return #tools
end

function ide:LoadInterpreter(path)
  loadToTab(path or "interpreters", ide.interpreters, false, ide.proto.Interpreter)
end

function ide:LoadAPI(path)
  local folder = path or "api"
  local files = (wx.wxFileExists(folder) and {folder}
    or wx.wxDirExists(folder) and ide:GetFileList(folder, true, "*.lua")
    or {})
  for _, file in ipairs(files) do
    if not IsDirectory(file) then
      local ftype, fname = file:match("api[/\\]([^/\\]+)[/\\](.*)%.")
      if not ftype or not fname then
        ide:Print(TR("The API file must be located in a subdirectory of the API directory."))
      else
        ide.apis[ftype] = ide.apis[ftype] or {}
        -- make sure the path is absolute to access it if the current directory changes
        ide.apis[ftype][fname] = ide:GetShortFilePath(MergeFullPath("", file))
      end
    end
  end
  ReloadAPIs("*")
end

dofile "src/version.lua"

for _, file in ipairs({"proto", "ids", "style", "keymap", "toolbar", "package"}) do
  dofile("src/editor/"..file..".lua")
end

ide.config.styles = StylesGetDefault()
ide.config.stylesoutshell = StylesGetDefault()

local function setLuaPaths(mainpath, osname)
  -- use LUA_DEV to setup paths for Lua for Windows modules if installed
  local luadev = osname == "Windows" and os.getenv('LUA_DEV')
  if luadev and not wx.wxDirExists(luadev) then luadev = nil end
  local luadev_path = (luadev
    and ('LUA_DEV/?.lua;LUA_DEV/?/init.lua;LUA_DEV/lua/?.lua;LUA_DEV/lua/?/init.lua')
      :gsub('LUA_DEV', (luadev:gsub('[\\/]$','')))
    or nil)
  local luadev_cpath = (luadev
    and ('LUA_DEV/?.dll;LUA_DEV/?51.dll;LUA_DEV/clibs/?.dll;LUA_DEV/clibs/?51.dll')
      :gsub('LUA_DEV', (luadev:gsub('[\\/]$','')))
    or nil)

  if luadev then
    local path, clibs = os.getenv('PATH'), luadev:gsub('[\\/]$','')..'\\clibs'
    if not path:find(clibs, 1, true) then wx.wxSetEnv('PATH', path..';'..clibs) end
  end

  -- (luaconf.h) in Windows, any exclamation mark ('!') in the path is replaced
  -- by the path of the directory of the executable file of the current process.
  -- this effectively prevents any path with an exclamation mark from working.
  -- if the path has an excamation mark, allow Lua to expand it as this
  -- expansion happens only once.
  if osname == "Windows" and mainpath:find('%!') then mainpath = "!/../" end

  -- if LUA_PATH or LUA_CPATH is not specified, then add ;;
  -- ;; will be replaced with the default (c)path by the Lua interpreter
  wx.wxSetEnv("LUA_PATH",
    (os.getenv("LUA_PATH") or ';') .. ';'
    .. "./?.lua;./?/init.lua;./lua/?.lua;./lua/?/init.lua" .. ';'
    .. mainpath.."lualibs/?/?.lua;"..mainpath.."lualibs/?.lua;"
    .. mainpath.."lualibs/?/?/init.lua;"..mainpath.."lualibs/?/init.lua"
    .. (luadev_path and (';' .. luadev_path) or ''))

  ide.osclibs = -- keep the list to use for various Lua versions
    osname == "Windows" and table.concat({
        mainpath.."bin/clibs/?.dll",
      },";") or
    osname == "Macintosh" and table.concat({
        mainpath.."bin/clibs/?.dylib",
        mainpath.."bin/clibs/lib?.dylib",
      },";") or
    osname == "Unix" and table.concat({
        mainpath..("bin/linux/%s/clibs/?.so"):format(arch),
        mainpath..("bin/linux/%s/clibs/lib?.so"):format(arch),
      },";") or
    assert(false, "Unexpected OS name")

  ide.oslibs = table.concat({
        mainpath.."lualibs/?.lua",
        mainpath.."lualibs/?/?.lua",
        mainpath.."lualibs/?/init.lua",
      },";")

  wx.wxSetEnv("LUA_CPATH",
    (os.getenv("LUA_CPATH") or ';') .. ';' .. ide.osclibs
    .. (luadev_cpath and (';' .. luadev_cpath) or ''))

  -- on some OSX versions, PATH is sanitized to not include even /usr/local/bin; add it
  if osname == "Macintosh" then
    local ok, path = wx.wxGetEnv("PATH")
    if ok then wx.wxSetEnv("PATH", (#path > 0 and path..":" or "").."/usr/local/bin") end
  end
end

ide.test.setLuaPaths = setLuaPaths

---------------
-- process args
local configs = {}
do
  -- application parameters are passed as script parameters on Windows
  local arg = ide.osname == "Windows" and {...} or arg
  -- application name is expected as the first argument
  local fullPath = arg[1] or "zbstudio"

  ide.arg = arg

  -- on Windows use GetExecutablePath, which is Unicode friendly,
  -- whereas wxGetCwd() is not (at least in wxlua 2.8.12.2).
  -- some wxlua version on windows report wx.dll instead of *.exe.
  -- (although wxGetCwd() is Unicode friendly in wxwidgets 3.x)
  local exepath = wx.wxStandardPaths.Get():GetExecutablePath()
  if ide.osname == "Windows" and exepath:find("%.exe$") then
    fullPath = exepath
  -- path handling only works correctly on UTF8-valid strings, so check for that.
  -- This may be caused by the launcher on Windows using ANSI methods for command line
  -- processing. Keep the path as is for UTF-8 invalid strings as it's still good enough
  elseif not wx.wxIsAbsolutePath(fullPath) and wx.wxString().FromUTF8(fullPath) == fullPath then
    fullPath = MergeFullPath(wx.wxGetCwd(), fullPath)
  end

  ide.editorFilename = ide:GetShortFilePath(fullPath)
  ide.appname = fullPath:match("([%w_-%.]+)$"):gsub("%.[^%.]*$","")
  assert(ide.appname, "no application path defined")

  for index = 2, #arg do
    if (arg[index] == "-cfg" and index+1 <= #arg) then
      table.insert(configs,arg[index+1])
    elseif (arg[index] == "-cwd" and index+1 <= #arg) then
      ide.cwd = arg[index+1]
    elseif arg[index-1] ~= "-cfg" and arg[index-1] ~= "-cwd"
    -- on OSX command line includes -psn... parameter, don't include these
    and (ide.osname ~= 'Macintosh' or not arg[index]:find("^-psn")) then
      table.insert(ide.filenames,arg[index])
    end
  end

  setLuaPaths(GetPathWithSep(ide.editorFilename), ide.osname)
end

----------------------
-- process application

ide.app = dofile(ide.appname.."/app.lua")
local app = assert(ide.app)

-- load packages
local function processPackages(packages)
  -- check dependencies and assign file names to each package
  local skip = {}
  for fname, package in pairs(packages) do
    if type(package.dependencies) == 'table'
    and package.dependencies.osname
    and not package.dependencies.osname:find(ide.osname, 1, true) then
      ide:Print(("Package '%s' not loaded: requires %s platform, but you are running %s.")
        :format(fname, package.dependencies.osname, ide.osname))
      skip[fname] = true
    end

    local needsversion = tonumber(package.dependencies)
      or type(package.dependencies) == 'table' and tonumber(package.dependencies[1])
      or -1
    local isversion = tonumber(ide.VERSION)
    if isversion and needsversion > isversion then
      ide:Print(("Package '%s' not loaded: requires version %s, but you are running version %s.")
        :format(fname, needsversion, ide.VERSION))
      skip[fname] = true
    end
    package.fname = fname
  end

  for fname, package in pairs(packages) do
    if not skip[fname] then ide.packages[fname] = package end
  end
end

function UpdateSpecs(spec)
  for _, spec in pairs(spec and {spec} or ide.specs) do
    spec.sep = spec.sep or "\1" -- default separator doesn't match anything
    spec.iscomment = {}
    spec.iskeyword = {}
    spec.isstring = {}
    spec.isnumber = {}
    if spec.lexerstyleconvert then
      for _, s in pairs(spec.lexerstyleconvert.comment or {}) do spec.iscomment[s] = true end
      for _, s in pairs(spec.lexerstyleconvert.keywords0 or {}) do spec.iskeyword[s] = true end
      for _, s in pairs(spec.lexerstyleconvert.stringtxt or {}) do spec.isstring[s] = true end
      for _, s in pairs(spec.lexerstyleconvert.number or {}) do spec.isnumber[s] = true end
    end
  end
end

----------------------
-- process config

-- set ide.config environment
do
  ide.configs = {
    system = MergeFullPath("cfg", "user.lua"),
    user = ide.oshome and MergeFullPath(ide.oshome, "."..ide.appname.."/user.lua"),
  }
  ide.configqueue = {}

  local num = 0
  local package = setmetatable({}, {
      __index = function(_,k) return package[k] end,
      __newindex = function(_,k,v) package[k] = v end,
      __call = function(_,p)
        -- package can be defined inline, like "package {...}"
        if type(p) == 'table' then
          num = num + 1
          return ide:AddPackage('config'..num..'package', p)
        -- package can be included as "package 'file.lua'" or "package 'folder/'"
        elseif type(p) == 'string' then
          local config = ide.configqueue[#ide.configqueue]
          local pkg
          for _, packagepath in ipairs({
              '.', 'packages/', '../packages/',
              ide.oshome and MergeFullPath(ide.oshome, "."..ide.appname.."/packages")}) do
            local p = MergeFullPath(config and MergeFullPath(config, packagepath) or packagepath, p)
            pkg = wx.wxDirExists(p) and loadToTab(p, {}, false, ide.proto.Plugin)
              or wx.wxFileExists(p) and LoadLuaFileExt({}, p, ide.proto.Plugin)
              or wx.wxFileExists(p..".lua") and LoadLuaFileExt({}, p..".lua", ide.proto.Plugin)
            if pkg then
              processPackages(pkg)
              break
            end
          end
          if not pkg then ide:Print(("Can't find '%s' to load package from."):format(p)) end
        else
          ide:Print(("Can't load package based on parameter of type '%s'."):format(type(p)))
        end
      end,
    })

  local includes = {}
  local include = function(c)
    if c then
      for _, config in ipairs({
          -- `or ""` is needed to make sure that the loop is not stopped on `nil`
          ide.configqueue[#ide.configqueue] or "",
          (wx.wxFileName.SplitPath(ide.configs.user or "")),
          (wx.wxFileName.SplitPath(ide.configs.system or "")),
      }) do
        if config > "" then
          local p = MergeFullPath(config, c)
          includes[p] = (includes[p] or 0) + 1
          if includes[p] > 1 or LoadLuaConfig(p) or LoadLuaConfig(p..".lua") then return end
          includes[p] = includes[p] - 1
        end
      end
      ide:Print(("Can't find configuration file '%s' to process."):format(c))
    end
  end

  setmetatable(ide.config, {
    __index = setmetatable({
        -- these are provided for compatibility only to avoid breaking configs using `load.*`
        load = {
          interpreters = function() ide:Print("Warning: using `load.interpreters()` in configuration settings is deprecated.") end,
          specs = function() ide:Print("Warning: using `load.specs()` in configuration settings is deprecated.") end,
          tools = function() ide:Print("Warning: using `load.tools()` in configuration settings is deprecated.") end,
        },
        package = package,
        include = include,
    }, {__index = _G or _ENV})
  })
end

LoadLuaConfig(ide.appname.."/config.lua")

ide.editorApp:SetAppName(ide:GetProperty("settingsapp"))

-- check if the .ini file needs to be migrated on Windows
if ide.osname == 'Windows' and ide.wxver >= "2.9.5" then
  -- Windows used to have local ini file kept in wx.wxGetHomeDir (before 2.9),
  -- but since 2.9 it's in GetUserConfigDir(), so migrate it.
  local ini = ide.editorApp:GetAppName() .. ".ini"
  local old = wx.wxFileName(wx.wxGetHomeDir(), ini)
  local new = wx.wxFileName(wx.wxStandardPaths.Get():GetUserConfigDir(), ini)
  if old:FileExists() and not new:FileExists() then
    FileCopy(old:GetFullPath(), new:GetFullPath())
    ide:Print(("Migrated configuration file from '%s' to '%s'.")
      :format(old:GetFullPath(), new:GetFullPath()))
  end
end

----------------------
-- process plugins

if app.preinit then app.preinit() end

ide:LoadInterpreter()
ide:LoadSpec()

do
  -- process configs
  LoadLuaConfig(ide.configs.system)
  LoadLuaConfig(ide.configs.user)

  -- process all other configs (if any)
  for _, v in ipairs(configs) do LoadLuaConfig(v, true) end
  configs = nil

  -- check and apply default styles in case a user resets styles in the config
  for _, styles in ipairs({"styles", "stylesoutshell"}) do
    if not ide.config[styles] then
      ide:Print(("Ignored incorrect value of '%s' setting in the configuration file")
        :format(styles))
      ide.config[styles] = StylesGetDefault()
    end
  end

  local sep = GetPathSeparator()
  if ide.config.language then
    LoadLuaFileExt(ide.messages, "cfg"..sep.."i18n"..sep..ide.config.language..".lua")
  end
  -- always load 'en' as it's required as a fallback for pluralization
  if ide.config.language ~= 'en' then
    LoadLuaFileExt(ide.messages, "cfg"..sep.."i18n"..sep.."en.lua")
  end
end

processPackages(loadToTab("packages", {}, false, ide.proto.Plugin))
if ide.oshome then
  local userpackages = MergeFullPath(ide.oshome, "."..ide.appname.."/packages")
  if wx.wxDirExists(userpackages) then
    processPackages(loadToTab(userpackages, {}, false, ide.proto.Plugin))
  end
end

---------------
-- Load App

for _, file in ipairs({
    "settings", "singleinstance", "iofilters", "markup",
    "gui", "filetree", "output", "debugger", "outline", "commandbar",
    "editor", "findreplace", "commands", "autocomplete", "shellbox", "markers",
    "menu_file", "menu_edit", "menu_search", "menu_view", "menu_project", "menu_help",
    "print", "inspect" }) do
  dofile("src/editor/"..file..".lua")
end

-- delay loading tools until everything is loaded as it modifies the menus
ide:LoadTool()
-- delay loading APIs until auto-complete is loaded
ide:LoadAPI()

-- register the rest of the shortcuts to allow them to be overwritten from onRegister
if ide.osname == 'Macintosh' then ide:SetAccelerator(ID.VIEWMINIMIZE, "Ctrl-M") end
for _, sc in ipairs({ID.RESTART, ID.CLEAROUTPUT, ID.CLEARCONSOLE}) do
  if ide.config.keymap[sc] then ide:SetAccelerator(sc, ide.config.keymap[sc]) end
end

-- register all the plugins
PackageEventHandle("onRegister")

-- initialization that was delayed until configs processed and packages loaded
ProjectUpdateInterpreters()

-- load rest of settings
SettingsRestoreFramePosition(ide.frame, "MainFrame")
SettingsRestoreFileHistory(SetFileHistory)
SettingsRestoreEditorSettings()
SettingsRestoreProjectSession(FileTreeSetProjects)
SettingsRestoreFileSession(function(tabs, params)
  if params and params.recovery
  then return SetOpenTabs(params)
  else return SetOpenFiles(tabs, params) end
end)
SettingsRestoreView()

-- ---------------------------------------------------------------------------
-- Load the filenames

do
  for _, filename in ipairs(ide.filenames) do
    ide:ActivateFile(ide.cwd and GetFullPathIfExists(ide.cwd, filename) or filename)
  end
  if ide:GetEditorNotebook():GetPageCount() == 0 then NewFile() end
end

if app.postinit then app.postinit() end

-- this is a workaround for a conflict between global shortcuts and local
-- shortcuts (like F2) used in the file tree or a watch panel.
-- because of several issues on OSX (as described in details in this thread:
-- https://groups.google.com/d/msg/wx-dev/juJj_nxn-_Y/JErF1h24UFsJ),
-- the workaround installs a global event handler that manually re-routes
-- conflicting events when the current focus is on a proper object.
-- non-conflicting shortcuts are handled through key-down events.
local remap = {
  [ID.ADDWATCH]    = ide:GetWatch(),
  [ID.EDITWATCH]   = ide:GetWatch(),
  [ID.DELETEWATCH] = ide:GetWatch(),
  [ID.RENAMEFILE]  = ide:GetProjectTree(),
  [ID.DELETEFILE]  = ide:GetProjectTree(),
}

local function rerouteMenuCommand(obj, id)
  -- check if the conflicting shortcut is enabled:
  -- (1) SetEnabled wasn't called or (2) Enabled was set to `true`.
  local uievent = wx.wxUpdateUIEvent(id)
  obj:ProcessEvent(uievent)
  if not uievent:GetSetEnabled() or uievent:GetEnabled() then
    obj:AddPendingEvent(wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED, id))
  end
end

local function remapkey(event)
  local keycode = event:GetKeyCode()
  local mod = event:GetModifiers()
  for id, obj in pairs(remap) do
    local focus = obj:FindFocus()
    if focus and focus:GetId() == obj:GetId() then
      local ae = wx.wxAcceleratorEntry(); ae:FromString(KSC(id))
      if ae:GetFlags() == mod and ae:GetKeyCode() == keycode then
        rerouteMenuCommand(obj, id)
        return
      end
    end
  end
  event:Skip()
end
ide:GetWatch():Connect(wx.wxEVT_KEY_DOWN, remapkey)
ide:GetProjectTree():Connect(wx.wxEVT_KEY_DOWN, remapkey)

local function resolveConflict(localid, globalid)
  return function(event)
    local shortcut = ide.config.keymap[localid]
    for id, obj in pairs(remap) do
      if ide.config.keymap[id]:lower() == shortcut:lower() then
        local focus = obj:FindFocus()
        if focus and focus:GetId() == obj:GetId() then
          obj:AddPendingEvent(wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED, id))
          return
        -- also need to check for children of objects
        -- to avoid re-triggering events when labels are being edited
        elseif focus and focus:GetParent():GetId() == obj:GetId() then
          return
        end
      end
    end
    rerouteMenuCommand(ide.frame, globalid)
  end
end

for lid in pairs(remap) do
  local shortcut = ide.config.keymap[lid]
  -- find a (potential) conflict for this shortcut (if any)
  for gid, ksc in pairs(ide.config.keymap) do
    -- if the same shortcut is used elsewhere (not one of IDs being checked)
    if shortcut:lower() == ksc:lower() and not remap[gid] then
      local fakeid = NewID()
      ide.frame:Connect(fakeid, wx.wxEVT_COMMAND_MENU_SELECTED, resolveConflict(lid, gid))
      ide:SetAccelerator(fakeid, ksc)
    end
  end
end

-- these shortcuts need accelerators handling as they are not present anywhere in the menu
for _, id in ipairs({ ID.GOTODEFINITION, ID.RENAMEALLINSTANCES,
    ID.REPLACEALLSELECTIONS, ID.QUICKADDWATCH, ID.QUICKEVAL, ID.ADDTOSCRATCHPAD}) do
  local ksc = ide.config.keymap[id]
  if ksc and ksc > "" then
    local fakeid = NewID()
    ide.frame:Connect(fakeid, wx.wxEVT_COMMAND_MENU_SELECTED, function()
        local editor = ide:GetEditorWithFocus(ide:GetEditor())
        if editor then rerouteMenuCommand(editor, id) end
      end)
    ide:SetAccelerator(fakeid, ksc)
  end
end

for _, id in ipairs({ ID.NOTEBOOKTABNEXT, ID.NOTEBOOKTABPREV }) do
  local ksc = ide.config.keymap[id]
  if ksc and ksc > "" then
    local nbc = "wxAuiNotebook"
    ide.frame:Connect(id, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)
        local win = ide.frame:FindFocus()
        if not win then return end

        local notebook = win:GetClassInfo():GetClassName() == nbc and win:DynamicCast(nbc)
        or win:GetParent():GetClassInfo():GetClassName() == nbc and win:GetParent():DynamicCast(nbc)
        or nil
        if not notebook then return end

        local first, last = 0, notebook:GetPageCount()-1
        local fwd = event:GetId() == ID.NOTEBOOKTABNEXT
        if fwd and notebook:GetSelection() == last then
          notebook:SetSelection(first)
        elseif not fwd and notebook:GetSelection() == first then
          notebook:SetSelection(last)
        else
          notebook:AdvanceSelection(fwd)
        end
      end)
    ide:SetAccelerator(id, ksc)
  end
end

-- only set menu bar *after* postinit handler as it may include adding
-- app-specific menus (Help/About), which are not recognized by MacOS
-- as special items unless SetMenuBar is done after menus are populated.
ide.frame:SetMenuBar(ide.frame.menuBar)

ide:Print() -- flush pending output (if any)

PackageEventHandle("onAppLoad")

-- this provides a workaround for Ctrl-(Shift-)Tab not navigating over tabs on OSX
-- http://trac.wxwidgets.org/ticket/17064
if ide.osname == 'Macintosh' then
  local frame = ide.frame
  local focus
  ide.timers.ctrltab = ide:AddTimer(frame, function(event)
      local mouse = wx.wxGetMouseState()
      -- if anything other that Ctrl (along with Shift) is pressed, then cancel the timer
      if not ide:IsValidCtrl(focus)
      or not wx.wxGetKeyState(wx.WXK_RAW_CONTROL)
      or wx.wxGetKeyState(wx.WXK_ALT) or wx.wxGetKeyState(wx.WXK_CONTROL)
      or mouse:LeftDown() or mouse:RightDown() or mouse:MiddleDown() then
        ide.timers.ctrltab:Stop()
        return
      end
      local ctrl = frame:FindFocus()
      if not ctrl then return end
      local nb = focus:GetParent():DynamicCast("wxAuiNotebook")
      -- when moving backward from the very first tab, the focus moves
      -- to wxAuiTabCtrl on OSX, so need to take that into account
      if nb:GetId() ~= ctrl:GetParent():GetId()
      or ctrl:GetClassInfo():GetClassName() == "wxAuiTabCtrl" then
        local frwd = not wx.wxGetKeyState(wx.WXK_SHIFT)
        if nb:GetId() ~= ctrl:GetParent():GetId()
        or not frwd and nb:GetSelection() == 0
        or frwd and nb:GetSelection() == nb:GetPageCount()-1 then
          nb:AdvanceSelection(frwd)
          focus = nb:GetPage(nb:GetSelection())
          focus:SetFocus()
        end
        -- don't cancel the timer as the user may be cycling through tabs
      end
    end)

  frame:Connect(wx.wxEVT_CHAR_HOOK, function(event)
      local key = event:GetKeyCode()
      if key == wx.WXK_RAW_CONTROL then
        local ctrl = frame:FindFocus()
        local parent = ctrl and ctrl:GetParent()
        if parent and parent:GetClassInfo():GetClassName() == "wxAuiNotebook" then
          local nb = parent:DynamicCast("wxAuiNotebook")
          focus = nb:GetPage(nb:GetSelection())
          focus:SetFocus()
          ide.timers.ctrltab:Start(20) -- check periodically
        end
      elseif key == wx.WXK_SHIFT then -- Shift
        -- timer is started when `Ctrl` is pressed; even when `Shift` is pressed first,
        -- the Ctrl will still be pressed eventually, which will start the timer
      else
        ide.timers.ctrltab:Stop()
      end
      event:Skip()
    end)
end

-- add Ctrl-Tab and Ctrl-Shift-Tab processing on Linux as there is a similar issue
-- to the one on OSX: http://trac.wxwidgets.org/ticket/17064,
-- but at least on Linux the handling of Tab from CHAR_HOOK works.
if ide.osname == 'Unix' then
  ide.frame:Connect(wx.wxEVT_CHAR_HOOK, function(event)
      local key = event:GetKeyCode()
      if key == wx.WXK_TAB and wx.wxGetKeyState(wx.WXK_CONTROL)
      and not wx.wxGetKeyState(wx.WXK_ALT) then
        ide.frame:AddPendingEvent(wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED,
            wx.wxGetKeyState(wx.WXK_SHIFT) and ID.NOTEBOOKTABPREV or ID.NOTEBOOKTABNEXT
        ))
      else
        event:Skip()
      end
    end)
end

-- The status bar content is drawn incorrectly if it is shown
-- after being initially hidden.
-- Show the statusbar and hide it after showing the frame, which fixes the issue.
local statusbarfix = ide.osname == 'Windows' and not ide.frame:GetStatusBar():IsShown()
if statusbarfix then ide.frame:GetStatusBar():Show(true) end

ide.frame:Show(true)

if statusbarfix then ide.frame:GetStatusBar():Show(false) end

-- somehow having wxAuiToolbar "steals" the focus from the editor on OSX;
-- have to set the focus implicitly on the current editor (if any)
if ide.osname == 'Macintosh' then
  local editor = ide:GetEditor()
  if editor then editor:SetFocus() end
end

-- enable full screen view if supported (for example, on OSX)
if ide:IsValidProperty(ide:GetMainFrame(), "EnableFullScreenView") then
  ide:GetMainFrame():EnableFullScreenView()
end

if ide.osname == 'Macintosh' then
  local args = {}
  for _, a in ipairs(ide.arg or {}) do args[a] = true end

  wx.wxGetApp().MacOpenFiles = function(files)
    for _, filename in ipairs(files) do
      -- in some cases, OSX sends the last command line parameter that looks like a filename
      -- to OpenFile callback, which gets reported to MacOpenFiles.
      -- I've tried to trace why this happens, but the only reference I could find
      -- is this one: http://lists.apple.com/archives/cocoa-dev/2009/May/msg00480.html
      -- To avoid this issue, the filename is skipped if it's present in `arg`.
      -- Also see http://trac.wxwidgets.org/ticket/14558 for related discussion.
      if not args[filename] then ide:ActivateFile(filename) end
    end
    args = {} -- reset the argument cache as it only needs to be checked on the initial launch
  end
end

-- check for deprecated items in the config
if type(ide.config.outputshell) == type({}) and next(ide.config.outputshell) then
  ide:Print("Warning: using `outputshell.*` in configuration settings is no longer supported; use `output.*` and `console.*` instead.")
end

wx.wxGetApp():MainLoop()

-- There are several reasons for this call:
-- (1) to fix a crash on OSX when closing with debugging in progress.
-- (2) to fix a crash on Linux 32/64bit during GC cleanup in wxlua
-- after an external process has been started from the IDE.
-- (3) to fix exit on Windows when started as "bin\lua src\main.lua".
os.exit()
