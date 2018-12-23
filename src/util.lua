-- Copyright 2011-17 Paul Kulchenko, ZeroBrane LLC
-- authors: Lomtik Software (J. Winwood & John Labenski)
-- Luxinia Dev (Eike Decker & Christoph Kubisch)
-- David Manura
---------------------------------------------------------

function EscapeMagic(s) return s:gsub('([%(%)%.%%%+%-%*%?%[%^%$%]])','%%%1') end

function GetPathSeparator()
  return string.char(wx.wxFileName.GetPathSeparator())
end

do
  local sep = GetPathSeparator()
  function IsDirectory(dir) return dir:find(sep.."$") end
end

function PrependStringToArray(t, s, maxstrings, issame)
  if string.len(s) == 0 then return end
  for i = #t, 1, -1 do
    local v = t[i]
    if v == s or issame and issame(s, v) then
      table.remove(t, i) -- remove old copy
      -- don't break here in case there are multiple copies to remove
    end
  end
  table.insert(t, 1, s)
  if #t > (maxstrings or 15) then table.remove(t, #t) end -- keep reasonable length
end

function GetFileModTime(filePath)
  if filePath and #filePath > 0 then
    local fn = wx.wxFileName(filePath)
    if fn:FileExists() then
      return fn:GetModificationTime()
    end
  end

  return nil
end

function GetFileExt(filePath)
  local match = filePath and filePath:gsub("%s+$",""):match("%.([^./\\]*)$")
  return match and match:lower() or ''
end

function GetFileName(filePath)
  return filePath and filePath:gsub("%s+$",""):match("([^/\\]*)$") or ''
end

function IsLuaFile(filePath)
  return filePath and (string.len(filePath) > 4) and
  (string.lower(string.sub(filePath, -4)) == ".lua")
end

function GetPathWithSep(wxfn)
  if type(wxfn) == 'string' then wxfn = wx.wxFileName(wxfn) end
  return wxfn:GetPath(bit.bor(wx.wxPATH_GET_VOLUME, wx.wxPATH_GET_SEPARATOR))
end

function FileDirHasContent(dir)
  local f = wx.wxFindFirstFile(dir, wx.wxFILE + wx.wxDIR)
  return #f>0
end

-- `fs` library provides Windows-specific functions and requires LuaJIT
local ok, fs = pcall(require, "fs")
if not ok then fs = nil end

local function isSymlink(path) return require("lfs").attributes(path).mode == "link" end
if fs then isSymlink = fs.is_symlink end

function FileSysGetRecursive(path, recursive, spec, opts)
  local content = {}
  local showhidden = ide.config and ide.config.showhiddenfiles
  local sep = GetPathSeparator()
  -- trim trailing separator and adjust the separator in the path
  path = path:gsub("[\\/]$",""):gsub("[\\/]", sep)
  local queue = {path}
  local pathpatt = "^"..EscapeMagic(path)..sep.."?"
  local optyield = (opts or {}).yield
  local optfolder = (opts or {}).folder ~= false
  local optsort = (opts or {}).sort ~= false
  local optpath = (opts or {}).path ~= false
  local optfollowsymlink = (opts or {}).followsymlink ~= false
  local optskipbinary = (opts or {}).skipbinary
  local optondirectory = (opts or {}).ondirectory
  local optmaxnum = tonumber((opts or {}).maxnum)

  local function spec2list(spect, list)
    -- return empty list if no spec is provided
    if spect == nil or spect == "*" or spect == "*.*" then return {}, 0 end
    -- accept "*.lua" and "*.txt,*.wlua" combinations
    local masknum, list = 0, list or {}
    for spec, specopt in pairs(type(spect) == 'table' and spect or {spect}) do
      -- specs can be kept as `{[spec] = true}` or `{spec}`, so handle both cases
      if type(spec) == "number" then spec = specopt end
      if specopt == false then spec = "" end -- skip keys with `false` values
      for m in spec:gmatch("[^%s;,]+") do
        m = m:gsub("[\\/]", sep)
        if m:find("^%*%.%w+"..sep.."?$") then
          list[m:sub(2)] = true
        else
          -- escape all special characters
          table.insert(list, EscapeMagic(m)
            :gsub("%%%*%%%*", ".*") -- replace (escaped) ** with .*
            :gsub("%%%*", "[^/\\]*") -- replace (escaped) * with [^\//]*
            :gsub("^"..sep, ide:GetProject() or "") -- replace leading separator with project directory (if set)
            .."$")
        end
        masknum = masknum + 1
      end
    end
    return list, masknum
  end

  local inmasks, masknum = spec2list(spec)
  if masknum >= 2 then spec = nil end

  local exmasks = spec2list(ide.config.excludelist or {})
  if optskipbinary then -- add any binary files to the list to skip
    exmasks = spec2list(type(optskipbinary) == 'table' and optskipbinary
      or ide.config.binarylist or {}, exmasks)
  end

  local function ismatch(file, inmasks, exmasks)
    -- convert extension 'foo' to '.foo', as need to distinguish file
    -- from extension with the same name
    local ext = '.'..GetFileExt(file)
    -- check exclusions if needed
    if exmasks[file] or exmasks[ext] then return false end
    for _, mask in ipairs(exmasks) do
      if file:find(mask) then return false end
    end

    -- return true if none of the exclusions match and no inclusion list
    if not inmasks or not next(inmasks) then return true end

    -- now check inclusions
    if inmasks[file] or inmasks[ext] then return true end
    for _, mask in ipairs(inmasks) do
      if file:find(mask) then return true end
    end
    return false
  end

  local function report(fname)
    if optyield then return coroutine.yield(fname) end
    table.insert(content, fname)
  end

  local dir = wx.wxDir()
  local num = 0
  local function getDir(path)
    dir:Open(path)
    if not dir:IsOpened() then
      if TR then ide:Print(TR("Can't open '%s': %s"):format(path, wx.wxSysErrorMsg())) end
      return true -- report and continue
    end

    -- recursion is done in all folders if requested,
    -- but only those folders that match the spec are returned
    local _ = wx.wxLogNull() -- disable error reporting; will report as needed
    local found, file = dir:GetFirst("*",
      wx.wxDIR_DIRS + ((showhidden == true or showhidden == wx.wxDIR_DIRS) and wx.wxDIR_HIDDEN or 0))
    while found do
      local fname = path..sep..file
      if optfolder and ismatch(fname..sep, inmasks, exmasks) then
        report((optpath and fname or fname:gsub(pathpatt, ""))..sep)
      end

      -- `optondirectory` may return:
      -- `true` to traverse the directory and continue
      -- `false` to skip the directory and continue
      -- `nil` to abort the process
      local ondirectory = optondirectory and optondirectory(fname)
      if optondirectory and ondirectory == nil then return false end

      if recursive and ismatch(fname..sep, nil, exmasks) and (ondirectory ~= false)
      and (optfollowsymlink or not isSymlink(fname))
      -- check if this name already appears in the path earlier;
      -- Skip the processing if it does as it could lead to infinite
      -- recursion with circular references created by symlinks.
      and select(2, fname:gsub(EscapeMagic(file..sep),'')) <= 2 then
        table.insert(queue, fname)
      end

      num = num + 1
      if optmaxnum and num >= optmaxnum then return false end

      found, file = dir:GetNext()
    end
    found, file = dir:GetFirst(spec or "*",
      wx.wxDIR_FILES + ((showhidden == true or showhidden == wx.wxDIR_FILES) and wx.wxDIR_HIDDEN or 0))
    while found do
      local fname = path..sep..file
      if ismatch(fname, inmasks, exmasks) then
        report(optpath and fname or fname:gsub(pathpatt, ""))
      end

      num = num + 1
      if optmaxnum and num >= optmaxnum then return false end

      found, file = dir:GetNext()
    end
    -- wxlua < 3.1 doesn't provide Close method for the directory, so check for it
    if ide:IsValidProperty(dir, "Close") then dir:Close() end
    return true
  end
  while #queue > 0 and getDir(table.remove(queue)) do end

  if optyield then
    if #queue > 0 then coroutine.yield(false) end -- signal aborted processing
    return
  end

  if optsort then
    local prefix = '\001' -- prefix to sort directories first
    local shadow = {}
    for _, v in ipairs(content) do
      shadow[v] = (v:sub(-1) == sep and prefix or '')..v:lower()
    end
    table.sort(content, function(a,b) return shadow[a] < shadow[b] end)
  end

  return content
end

local normalflags = wx.wxPATH_NORM_ABSOLUTE + wx.wxPATH_NORM_DOTS + wx.wxPATH_NORM_TILDE
function MergeFullPath(p, f)
  if not p or not f then return end
  local file = wx.wxFileName(f)
  -- Normalize call is needed to make the case of p = '/abc/def' and
  -- f = 'xyz/main.lua' work correctly. Normalize() returns true if done.
  -- Normalization with PATH_NORM_DOTS removes leading dots, which need to be added back.
  -- This allows things like `-cfg ../myconfig.lua` to work.
  local rel, rest = p:match("^(%.[/\\.]*[/\\])(.*)")
  if rel and rest then p = rest end
  return (file:Normalize(normalflags, p)
    and (rel or ""):gsub("[/\\]", GetPathSeparator())..file:GetFullPath()
    or nil)
end

function FileNormalizePath(path)
  local filePath = wx.wxFileName(path)
  filePath:Normalize()
  filePath:SetVolume(filePath:GetVolume():upper())
  return filePath:GetFullPath()
end

function FileGetLongPath(path)
  local fn = wx.wxFileName(path)
  local vol = fn:GetVolume():upper()
  local volsep = vol and vol:byte() and wx.wxFileName.GetVolumeSeparator(vol:byte()-("A"):byte()+1)
  local dir = wx.wxDir()
  local dirs = fn:GetDirs()
  table.insert(dirs, fn:GetFullName())
  local normalized = vol and volsep and vol..volsep or (path:match("^[/\\]") or ".")
  local hasclose = ide:IsValidProperty(dir, "Close")
  while #dirs > 0 do
    dir:Open(normalized)
    if not dir:IsOpened() then return path end
    local p = table.remove(dirs, 1)
    local ok, segment = dir:GetFirst(p)
    if not ok then return path end
    normalized = MergeFullPath(normalized,segment)
    if hasclose then dir:Close() end
  end
  local file = wx.wxFileName(normalized)
  file:Normalize(wx.wxPATH_NORM_DOTS) -- remove leading dots, if any
  return file:GetFullPath()
end

function CreateFullPath(path)
  local ok = wx.wxFileName.Mkdir(path, tonumber(755,8), wx.wxPATH_MKDIR_FULL)
  return ok, not ok and wx.wxSysErrorMsg() or nil
end
function GetFullPathIfExists(p, f)
  local path = MergeFullPath(p, f)
  return path and wx.wxFileExists(path) and path or nil
end

function FileWrite(file, content)
  local _ = wx.wxLogNull() -- disable error reporting; will report as needed

  if not wx.wxFileExists(file)
  and not wx.wxFileName(file):Mkdir(tonumber(755,8), wx.wxPATH_MKDIR_FULL) then
    return nil, wx.wxSysErrorMsg()
  end

  local file = wx.wxFile(file, wx.wxFile.write)
  if not file:IsOpened() then return nil, wx.wxSysErrorMsg() end

  local ok = file:Write(content, #content) == #content
  file:Close()
  return ok, not ok and wx.wxSysErrorMsg() or nil
end

function ShowLocation(fname)
  local osxcmd = [[osascript -e 'tell application "Finder" to reveal POSIX file "%s"']]
    .. [[ -e 'tell application "Finder" to activate']]
  local wincmd = [[explorer /select,"%s"]]
  local lnxcmd = [[xdg-open "%s"]] -- takes path, not a filename
  local cmd =
    ide.osname == "Windows" and wincmd:format(fname) or
    ide.osname == "Macintosh" and osxcmd:format(fname) or
    ide.osname == "Unix" and lnxcmd:format(wx.wxFileName(fname):GetPath())
  if cmd then wx.wxExecute(cmd, wx.wxEXEC_ASYNC) end
end

-- check if fs library is available and provide better versions of available functions
if fs then
  function FileWrite(file, content)
    local _ = wx.wxLogNull() -- disable error reporting; will report as needed

    if not wx.wxFileExists(file)
    and not wx.wxFileName(file):Mkdir(tonumber(755,8), wx.wxPATH_MKDIR_FULL) then
      return nil, wx.wxSysErrorMsg()
    end

    -- use `fs` library to write a file, as this preserves its attributes
    local f, errmsg, errcode = fs.open(file,
      { access = 'write', creation = 'open_always', flags = 'rdwr backup_semantics'})
    if not f then return nil, errmsg end

    local ok, errmsg = f:truncate()
    if ok then
      local bytes, errmsg = f:write(content, #content)
      ok = bytes == #content
    end

    f:close()
    return ok, not ok and errmsg or nil
  end

  function ShowLocation(fname)
    fs.shell_open_and_select(fname)
  end
end

function FileSize(fname)
  if not wx.wxFileExists(fname) then return end
  local size = wx.wxFileSize(fname)
  -- size can be returned as 0 for symlinks, so check with wxFile:Length();
  -- can't use wxFile:Length() as it's reported incorrectly for some non-seekable files
  -- (see https://github.com/pkulchenko/ZeroBraneStudio/issues/458);
  -- the combination of wxFileSize and wxFile:Length() should do the right thing.
  if size == 0 then size = wx.wxFile(fname, wx.wxFile.read):Length() end
  return size
end

function FileRead(fname, length, callback)
  -- on OSX "Open" dialog allows to open applications, which are folders
  if wx.wxDirExists(fname) then return nil, "Can't read directory as file." end

  local _ = wx.wxLogNull() -- disable error reporting; will report as needed
  local file = wx.wxFile(fname, wx.wxFile.read)
  if not file:IsOpened() then return nil, wx.wxSysErrorMsg() end

  if type(callback) == 'function' then
    length = length or 8192
    local pos = 0
    while true do
      local len, content = file:Read(length)
      local res, msg = callback(content) -- may return `false` to signal to stop
      if res == false then
        file:Close()
        return false, msg or "Unknown error"
      end
      if len < length then break end
      pos = pos + len
      file:Seek(pos)
    end
    file:Close()
    return true, wx.wxSysErrorMsg()
  end

  local _, content = file:Read(length or FileSize(fname))
  file:Close()
  return content, wx.wxSysErrorMsg()
end

function FileRemove(file)
  local _ = wx.wxLogNull() -- disable error reporting; will report as needed
  return wx.wxRemoveFile(file), wx.wxSysErrorMsg()
end

function FileRename(file1, file2)
  local _ = wx.wxLogNull() -- disable error reporting; will report as needed
  return wx.wxRenameFile(file1, file2), wx.wxSysErrorMsg()
end

function FileCopy(file1, file2)
  local _ = wx.wxLogNull() -- disable error reporting; will report as needed
  return wx.wxCopyFile(file1, file2), wx.wxSysErrorMsg()
end

function IsBinary(text) return text:find("[^\7\8\9\10\12\13\27\32-\255]") and true or false end

function pairsSorted(t, f)
  local a = {}
  for n in pairs(t) do table.insert(a, n) end
  table.sort(a, f)
  local i = 0 -- iterator variable
  local iter = function () -- iterator function
    i = i + 1
    if a[i] == nil then return nil
    else return a[i], t[a[i]]
    end
  end
  return iter
end

function FixUTF8(s, repl)
  local p, len, invalid = 1, #s, {}
  while p <= len do
    if     s:find("^[%z\1-\127]", p) then p = p + 1
    elseif s:find("^[\194-\223][\128-\191]", p) then p = p + 2
    elseif s:find(       "^\224[\160-\191][\128-\191]", p)
        or s:find("^[\225-\236][\128-\191][\128-\191]", p)
        or s:find(       "^\237[\128-\159][\128-\191]", p)
        or s:find("^[\238-\239][\128-\191][\128-\191]", p) then p = p + 3
    elseif s:find(       "^\240[\144-\191][\128-\191][\128-\191]", p)
        or s:find("^[\241-\243][\128-\191][\128-\191][\128-\191]", p)
        or s:find(       "^\244[\128-\143][\128-\191][\128-\191]", p) then p = p + 4
    else
      if not repl then return end -- just signal invalid UTF8 string
      local repl = type(repl) == 'function' and repl(s:sub(p,p)) or repl
      s = s:sub(1, p-1)..repl..s:sub(p+1)
      table.insert(invalid, p)
      -- adjust position/length as the replacement may be longer than one char
      p = p + #repl
      len = len + #repl - 1
    end
  end
  return s, invalid
end

function TR(msg, count)
  local messages = ide.messages
  local lang = ide.config.language
  local counter = messages[lang] and messages[lang][0]
  local message = messages[lang] and messages[lang][msg]
  -- if there is count and no corresponding message, then
  -- get the message from the (default) english language,
  -- otherwise the message is not going to be pluralized properly
  if count and (not message or type(message) == 'table' and not next(message)) then
    message, counter = messages.en[msg], messages.en[0]
  end
  return count and counter and message and type(message) == 'table'
    and message[counter(count)] or (type(message) == 'string' and message or msg)
end

-- wxwidgets 2.9.x may report the last folder twice (depending on how the
-- user selects the folder), which makes the selected folder incorrect.
-- check if the last segment is repeated and drop it.
function FixDir(path)
  if wx.wxDirExists(path) then return path end

  local dir = wx.wxFileName.DirName(path)
  local dirs = dir:GetDirs()
  if #dirs > 1 and dirs[#dirs] == dirs[#dirs-1] then dir:RemoveLastDir() end
  return dir:GetFullPath()
end

function LoadLuaFileExt(tab, file, proto)
  local cfgfn,err = loadfile(file)
  if not cfgfn then
    ide:Print(("Error while loading file: '%s'."):format(err))
  else
    local name = file:match("([a-zA-Z_0-9%-]+)%.lua$")
    if not name then return end

    -- check if os/arch matches to allow packages for different systems
    local osvals = {windows = true, unix = true, macintosh = true}
    local archvals = {x64 = true, x86 = true}
    local os, arch = name:match("-(%w+)-?(%w*)")
    if os and os:lower() ~= ide.osname:lower() and osvals[os:lower()]
    or arch and #arch > 0 and arch:lower() ~= ide.osarch:lower() and archvals[arch:lower()]
    then return end
    if os and osvals[os:lower()] then name = name:gsub("-.*","") end

    local success, result = pcall(function()return cfgfn(assert(_G or _ENV))end)
    if not success then
      ide:Print(("Error while processing file: '%s'."):format(result))
    else
      if (tab[name]) then
        local out = tab[name]
        for i,v in pairs(result) do
          out[i] = v
        end
      else
        tab[name] = proto and result and setmetatable(result, proto) or result
        if tab[name] then tab[name].fpath = file end
      end
    end
  end
  return tab
end

function LoadLuaConfig(filename,isstring)
  if not filename then return end
  -- skip those files that don't exist
  if not isstring and not wx.wxFileExists(filename) then return end
  -- if it's marked as command, but exists as a file, load it as a file
  if isstring and wx.wxFileExists(filename) then isstring = false end

  local cfgfn, err, msg
  if isstring
  then msg, cfgfn, err = "string", loadstring(filename)
  else msg, cfgfn, err = "file", loadfile(filename) end

  if not cfgfn then
    ide:Print(("Error while loading configuration %s: '%s'."):format(msg, err))
  else
    setfenv(cfgfn,ide.config)
    table.insert(ide.configqueue, (wx.wxFileName.SplitPath(filename)))
    local _, err = pcall(function()cfgfn(assert(_G or _ENV))end)
    table.remove(ide.configqueue)
    if err then
      ide:Print(("Error while processing configuration %s: '%s'."):format(msg, err))
    end
  end
  return true
end

function LoadSafe(data)
  local f, res = loadstring(data)
  if not f then return f, res end

  local count = 0
  debug.sethook(function ()
    count = count + 1
    if count >= 3 then error("cannot call functions") end
  end, "c")
  local ok, res = pcall(f)
  count = 0
  debug.sethook()
  return ok, res
end

function GenerateProgramFilesPath(exec, sep)
  local env = os.getenv('ProgramFiles')
  return
    (env and env..'\\'..exec..sep or '')..
    [[C:\Program Files\]]..exec..sep..
    [[D:\Program Files\]]..exec..sep..
    [[C:\Program Files (x86)\]]..exec..sep..
    [[D:\Program Files (x86)\]]..exec
end

function MergeSettings(localSettings, savedSettings)
  for name in pairs(localSettings) do
    if savedSettings[name] ~= nil
    and type(savedSettings[name]) == type(localSettings[name]) then
      if type(localSettings[name]) == 'table'
      and next(localSettings[name]) ~= nil then
        -- check every value in the table to make sure that it's possible
        -- to add new keys to the table and they get correct default values
        -- (even though that are absent in savedSettings)
        for setting in pairs(localSettings[name]) do
          if savedSettings[name][setting] ~= nil then
            localSettings[name][setting] = savedSettings[name][setting]
           end
        end
      else
        localSettings[name] = savedSettings[name]
      end
    end
  end
end

function UpdateMenuUI(menu, obj)
  if not menu or not obj then return end
  for pos = 0, menu:GetMenuItemCount()-1 do
    local id = menu:FindItemByPosition(pos):GetId()
    local uievent = wx.wxUpdateUIEvent(id)
    obj:ProcessEvent(uievent)
    menu:Enable(id, not uievent:GetSetEnabled() or uievent:GetEnabled())
  end
end

local function plaindump(val, opts, done)
  local keyignore = opts and opts.keyignore or {}
  local final = done == nil
  opts, done = opts or {}, done or {}
  local t = type(val)
  if t == "table" then
    done[#done+1] = '{'
    done[#done+1] = ''
    for key, value in pairs (val) do
      if not keyignore[key] then
        done[#done+1] = '['
        plaindump(key, opts, done)
        done[#done+1] = ']='
        plaindump(value, opts, done)
        done[#done+1] = ","
      end
    end
    done[#done] = '}'
  elseif t == "string" then
    done[#done+1] = ("%q"):format(val):gsub("\010","n"):gsub("\026","\\026")
  elseif t == "number" then
    done[#done+1] = ("%.17g"):format(val)
  else
    done[#done+1] = tostring(val)
  end
  return final and table.concat(done, '')
end

DumpPlain = plaindump
