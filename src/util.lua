-- authors: Lomtik Software (J. Winwood & John Labenski)
-- Luxinia Dev (Eike Decker & Christoph Kubisch)
-- David Manura
---------------------------------------------------------

-- Equivalent to C's "cond ? a : b", all terms will be evaluated
function iff(cond, a, b) if cond then return a else return b end end

-- Does the num have all the bits in value
function HasBit(value, num)
  for n = 32, 0, -1 do
    local b = 2^n
    local num_b = num - b
    local value_b = value - b
    if num_b >= 0 then
      num = num_b
    else
      return true -- already tested bits in num
    end
    if value_b >= 0 then
      value = value_b
    end
    if (num_b >= 0) and (value_b < 0) then
      return false
    end
  end

  return true
end

function GetPathSeparator()
  return string.char(wx.wxFileName.GetPathSeparator())
end

do
  local sep = GetPathSeparator()
  function IsDirectory(dir) return dir:find(sep.."$") end
end

function StripCommentsC(tx)
  local out = ""
  local lastc = ""
  local skip
  local skipline
  local skipmulti
  local tx = string.gsub(tx, "\r\n", "\n")
  for c in tx:gmatch(".") do
    local oc = c
    local tu = lastc..c
    skip = c == '/'

    if ( not (skipmulti or skipline)) then
      if (tu == "//") then
        skipline = true
      elseif (tu == "/*") then
        skipmulti = true
        c = ""
      elseif (lastc == '/') then
        oc = tu
      end
    elseif (skipmulti and tu == "*/") then
      skipmulti = false
      c = ""
    elseif (skipline and lastc == "\n") then
      out = out.."\n"
      skipline = false
    end

    lastc = c
    if (not (skip or skipline or skipmulti)) then
      out = out..oc
    end
  end

  return out..lastc
end

-- http://lua-users.org/wiki/EnhancedFileLines
function FileLines(f)
  local CHUNK_SIZE = 1024
  local buffer = ""
  local pos_beg = 1
  return function()
    local pos, chars
    while 1 do
      pos, chars = buffer:match('()([\r\n].)', pos_beg)
      if pos or not f then
        break
      elseif f then
        local chunk = f:read(CHUNK_SIZE)
        if chunk then
          buffer = buffer:sub(pos_beg) .. chunk
          pos_beg = 1
        else
          f = nil
        end
      end
    end
    if not pos then
      pos = #buffer
    elseif chars == '\r\n' then
      pos = pos + 1
    end
    local line = buffer:sub(pos_beg, pos)
    pos_beg = pos + 1
    if #line > 0 then
      return line
    end
  end
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
  local match = filePath and filePath:match("%.([a-zA-Z_0-9]+)$")
  return match and (string.lower(match))
end

function IsLuaFile(filePath)
  return filePath and (string.len(filePath) > 4) and
  (string.lower(string.sub(filePath, -4)) == ".lua")
end

function GetFileNameExt(filePath)
  if (not filePath) then return end
  local wxn = wx.wxFileName(filePath)
  return (wxn:GetName()..(wxn:HasExt() and ("."..wxn:GetExt()) or ""))
end

function GetPathWithSep(wxfn)
  if type(wxfn) == 'string' then wxfn = wx.wxFileName(wxfn) end
  return wxfn:GetPath(bit.bor(wx.wxPATH_GET_VOLUME, wx.wxPATH_GET_SEPARATOR))
end

function FileSysHasContent(dir)
  local f = wx.wxFindFirstFile(dir,wx.wxFILE + wx.wxDIR)
  return #f>0
end

function FileSysGetRecursive(path, recursive, spec, skip)
  spec = spec or "*"
  local content = {}
  local sep = string.char(wx.wxFileName.GetPathSeparator())

  -- recursion is done in all folders but only those folders that match
  -- the spec are returned. This is the pattern that matches the spec.
  local specmask = spec:gsub("%.", "%%."):gsub("%*", ".*").."$"

  local function getDir(path, spec)
    local dir = wx.wxDir(path)
    if not dir:IsOpened() then return end

    local found, file = dir:GetFirst("*", wx.wxDIR_DIRS + wx.wxDIR_NO_FOLLOW)
    while found do
      if not skip or not file:find(skip) then
        local fname = wx.wxFileName(path, file):GetFullPath()
        if fname:find(specmask) then table.insert(content, fname..sep) end
        if recursive then getDir(fname, spec) end
      end
      found, file = dir:GetNext()
    end
    local found, file = dir:GetFirst(spec, wx.wxDIR_FILES)
    while found do
      if not skip or not file:find(skip) then
        local fname = wx.wxFileName(path, file):GetFullPath()
        table.insert(content, fname)
      end
      found, file = dir:GetNext()
    end
  end
  getDir(path, spec)

  -- explicitly sort files on Linux; directories first
  if ide.osname == 'Unix' then
    table.sort(content, function(a,b)
      local ad, bd = a:sub(-1) == sep, b:sub(-1) == sep
      -- both are folders or both are files
      if ad and bd or not ad and not bd then return a < b
      -- only one is folder; return true if it's the first one
      else return ad end
    end)
  end

  return content
end

function GetFullPathIfExists(p, f)
  if not p or not f then return end
  local file = wx.wxFileName(f)
  -- Normalize call is needed to make the case of p = '/abc/def' and
  -- f = 'xyz/main.lua' work correctly. Normalize() returns true if done.
  return (file:Normalize(wx.wxPATH_NORM_ALL, p)
    and file:FileExists()
    and file:GetFullPath()
    or nil)
end

function MergeFullPath(p, f)
  if not p or not f then return end
  local file = wx.wxFileName(f)
  -- Normalize call is needed to make the case of p = '/abc/def' and
  -- f = 'xyz/main.lua' work correctly. Normalize() returns true if done.
  return (file:Normalize(wx.wxPATH_NORM_ALL, p)
    and file:GetFullPath()
    or nil)
end

function FileWrite(file, content)
  local log = wx.wxLogNull() -- disable error reporting; will report as needed
  local file = wx.wxFile(file, wx.wxFile.write)
  if not file:IsOpened() then return nil, wx.wxSysErrorMsg() end

  file:Write(content, #content)
  file:Close()
  return true
end

function FileRead(file)
  -- on OSX "Open" dialog allows to open applications, which are folders
  if wx.wxDirExists(file) then return nil, "Can't read directory as file." end

  local log = wx.wxLogNull() -- disable error reporting; will report as needed
  local file = wx.wxFile(file, wx.wxFile.read)
  if not file:IsOpened() then return nil, wx.wxSysErrorMsg() end

  local _, content = file:Read(file:Length())
  file:Close()
  return content, wx.wxSysErrorMsg()
end

function FileRename(file1, file2) return wx.wxRenameFile(file1, file2) end

function FileCopy(file1, file2)
  local log = wx.wxLogNull() -- disable error reporting; will report as needed
  return wx.wxCopyFile(file1, file2)
end

TimeGet = pcall(require, "socket") and socket.gettime or os.clock

function isBinary(text) return text:find("[^\7\8\9\10\12\13\27\32-\255]") end

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
    if     p == s:find("[%z\1-\127]", p) then p = p + 1
    elseif p == s:find("[\194-\223][\123-\191]", p) then p = p + 2
    elseif p == s:find(       "\224[\160-\191][\128-\191]", p)
        or p == s:find("[\225-\236][\128-\191][\128-\191]", p)
        or p == s:find(       "\237[\128-\159][\128-\191]", p)
        or p == s:find("[\238-\239][\128-\191][\128-\191]", p) then p = p + 3
    elseif p == s:find(       "\240[\144-\191][\128-\191][\128-\191]", p)
        or p == s:find("[\241-\243][\128-\191][\128-\191][\128-\191]", p)
        or p == s:find(       "\244[\128-\143][\128-\191][\128-\191]", p) then p = p + 4
    else
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

function RequestAttention()
  local frame = ide.frame
  if not frame:IsActive() then
    frame:RequestUserAttention()
    if ide.osname == "Macintosh" then
      local cmd = [[osascript -e 'tell application "%s" to activate']]
      wx.wxExecute(cmd:format(ide.editorApp:GetAppName()), wx.wxEXEC_ASYNC)
    elseif ide.osname == "Windows" then
      frame:Raise() -- raise the window

      local winapi = require 'winapi'
      if winapi then
        local pid = winapi.get_current_pid()
        local wins = winapi.find_all_windows(function(w)
          return w:get_process():get_pid() == pid
             and w:get_class_name() == 'wxWindowNR'
        end)
        if wins and #wins > 0 then
          -- found the window, now need to activate it:
          -- send some input to the window and then
          -- bring our window to foreground (doesn't work without some input)
          winapi.send_to_window(0x1B)
          for _, w in ipairs(wins) do w:set_foreground() end
        end
      end
    end
  end
end

local messages, lang, counter
function TR(msg, count)
  lang = lang or ide.config.language
  messages = messages or ide.config.messages
  counter = counter or (messages[lang] and messages[lang][0])
  local message = messages[lang] and messages[lang][msg]
  return count and counter and message and type(message) == 'table'
    and message[counter(count)] or message or msg
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

function LoadLuaFileExt(tab, file, proto)
  local cfgfn,err = loadfile(file)
  if not cfgfn then
    print(("Error while loading file: '%s'."):format(err))
  else
    local name = file:match("([a-zA-Z_0-9%-]+)%.lua$")
    if not name then return end

    -- check if os/arch matches to allow packages for different systems
    local os, arch = name:match("-(%w+)-?(%w*)")
    if os and os:lower() ~= ide.osname:lower()
    or arch and #arch > 0 and arch:lower() ~= ide.osarch:lower()
    then return end
    if os then name = name:gsub("-.*","") end

    local success, result = pcall(function()return cfgfn(assert(_G or _ENV))end)
    if not success then
      print(("Error while processing file: '%s'."):format(result))
    else
      if (tab[name]) then
        local out = tab[name]
        for i,v in pairs(result) do
          out[i] = v
        end
      else
        tab[name] = proto and result and setmetatable(result, proto) or result
      end
    end
  end
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
