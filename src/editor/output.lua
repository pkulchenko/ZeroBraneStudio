-- Copyright 2011-16 Paul Kulchenko, ZeroBrane LLC
-- authors: Lomtik Software (J. Winwood & John Labenski)
-- Luxinia Dev (Eike Decker & Christoph Kubisch)
---------------------------------------------------------

local ide = ide
local frame = ide.frame
local bottomnotebook = frame.bottomnotebook
local out = bottomnotebook.errorlog

local MESSAGE_MARKER = StylesGetMarker("message")
local ERROR_MARKER = StylesGetMarker("error")
local PROMPT_MARKER = StylesGetMarker("prompt")
local PROMPT_MARKER_VALUE = 2^PROMPT_MARKER

local config = ide.config.output

out:SetFont(wx.wxFont(config.fontsize or 10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL,
  wx.wxFONTWEIGHT_NORMAL, false, config.fontname or "",
  config.fontencoding or wx.wxFONTENCODING_DEFAULT)
)
out:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, out:GetFont())
out:SetBufferedDraw(not ide.config.hidpi and true or false)
out:StyleClearAll()
out:SetMarginWidth(1, 16) -- marker margin
out:SetMarginType(1, wxstc.wxSTC_MARGIN_SYMBOL)
out:MarkerDefine(StylesGetMarker("message"))
out:MarkerDefine(StylesGetMarker("error"))
out:MarkerDefine(StylesGetMarker("prompt"))
out:SetReadOnly(true)
if config.usewrap then
  out:SetWrapMode(wxstc.wxSTC_WRAP_WORD)
  out:SetWrapStartIndent(0)
  out:SetWrapVisualFlags(wxstc.wxSTC_WRAPVISUALFLAG_END)
  out:SetWrapVisualFlagsLocation(wxstc.wxSTC_WRAPVISUALFLAGLOC_END_BY_TEXT)
end

function OutputAddStyles(styles)
  if ide.config.output.showansi and wxstc.wxSTC_LEX_ERRORLIST
  and type(ide.config.output.ansimap) == type({}) then
    out:SetLexer(wxstc.wxSTC_LEX_ERRORLIST)
    out:SetProperty("lexer.errorlist.escape.sequences","1")

    -- assign ansimap styles
    -- if this styles table is the same as the default one, then make a copy
    -- to avoid modifying all editor styles with "ansi" ones,
    -- as they will conflict with lexer-specific styles
    if ide.config.styles == styles then
      local stylecopy = {}
      for k,v in pairs(styles) do stylecopy[k] = v end
      styles = stylecopy
      ide.config.stylesoutshell = styles
    end
    for k,v in pairs(ide.config.output.ansimap) do styles["ansi"..k] = v end
  end
end

OutputAddStyles(ide.config.stylesoutshell)
StylesApplyToEditor(ide.config.stylesoutshell,out)

function ClearOutput(force)
  if not (force or ide:GetMenuBar():IsChecked(ID.CLEAROUTPUTENABLE)) then return end
  out:SetReadOnly(false)
  out:ClearAll()
  out:SetReadOnly(true)
end

function out:Erase() ClearOutput(true) end

local inputBound = 0 -- to track where partial output ends for input editing purposes
local function getInputLine()
  return out:MarkerPrevious(out:GetLineCount()+1, PROMPT_MARKER_VALUE)
end
local function getInputText(bound)
  return out:GetTextRangeDyn(
    out:PositionFromLine(getInputLine())+(bound or 0), out:GetLength())
end
local function updateInputMarker()
  local lastline = out:GetLineCount()-1
  out:MarkerDeleteAll(PROMPT_MARKER)
  out:MarkerAdd(lastline, PROMPT_MARKER)
  inputBound = #getInputText()
end
function OutputEnableInput() updateInputMarker() end

function DisplayOutputNoMarker(...)
  local message = ""
  local cnt = select('#',...)
  for i=1,cnt do
    local v = select(i,...)
    message = message..tostring(v)..(i<cnt and "\t" or "")
  end

  local promptLine = getInputLine()
  local insertedAt = promptLine == wx.wxNOT_FOUND and out:GetLength() or out:PositionFromLine(promptLine) + inputBound
  local current = out:GetReadOnly()
  out:SetReadOnly(false)
  out:InsertTextDyn(insertedAt, out.useraw and message or FixUTF8(message, "\022"))
  out:EmptyUndoBuffer()
  out:SetReadOnly(current)
  out:GotoPos(out:GetLength())
  out:EnsureVisibleEnforcePolicy(out:GetLineCount()-1)
  if promptLine ~= wx.wxNOT_FOUND then updateInputMarker() end
end
function DisplayOutput(...)
  local line = out:GetLineCount()-1
  DisplayOutputNoMarker(...)
  out:MarkerAdd(line, MESSAGE_MARKER)
end
function DisplayOutputLn(...)
  DisplayOutput(...)
  DisplayOutputNoMarker("\n")
end

function out:Print(...) return ide:Print(...) end
function out:Write(...) return DisplayOutputNoMarker(...) end
function out:Error(...)
  local line = out:GetLineCount()-1
  DisplayOutputNoMarker(...)
  DisplayOutputNoMarker("\n")
  out:MarkerAdd(line, ERROR_MARKER)
end

local streamins = {}
local streamerrs = {}
local streamouts = {}
local customprocs = {}
local textout = '' -- this is a buffer for any text sent to external scripts

function DetachChildProcess()
  for pid, custom in pairs(customprocs) do
    -- since processes are detached, their END_PROCESS event is not going
    -- to be called; call endcallback() manually if registered.
    if custom.endcallback then custom.endcallback(pid) end
    if custom.proc then custom.proc:Detach() end
  end
end

function CommandLineRunning(uid)
  for pid, custom in pairs(customprocs) do
    if (custom.uid == uid and custom.proc and custom.proc.Exists(tonumber(pid))) then
      return pid, custom.proc
    end
  end

  return
end

function CommandLineToShell(uid,state)
  for pid, custom in pairs(customprocs) do
    if (pid == uid or custom.uid == uid) and custom.proc and custom.proc.Exists(tonumber(pid)) then
      if (streamins[pid]) then streamins[pid].toshell = state end
      if (streamerrs[pid]) then streamerrs[pid].toshell = state end
      return true
    end
  end
end

-- logic to "unhide" wxwidget window using winapi
local ok, winapi = pcall(require, 'winapi')
if not ok then winapi = nil end
local checkstart, checknext, checkperiod
local pid = nil
local function unHideWindow(pidAssign)
  -- skip if not configured to do anything
  if not ide.config.unhidewindow then return end
  if pidAssign then
    pid = pidAssign > 0 and pidAssign or nil
  end
  if pid and winapi then -- pid provided and winapi loaded
    local now = ide:GetTime()
    if pidAssign and pidAssign > 0 then
      checkstart, checknext, checkperiod = now, now, 0.02
    end
    if now - checkstart > 1 and checkperiod < 0.5 then
      checkperiod = checkperiod * 2
    end
    if now >= checknext then
      checknext = now + checkperiod
    else
      return
    end
    local wins = winapi.find_all_windows(function(w)
      return w:get_process():get_pid() == pid
    end)
    local any = ide.interpreter.unhideanywindow
    local show, hide, ignore = 1, 2, 0
    for _,win in pairs(wins) do
      -- win:get_class_name() can return nil if the window is already gone
      -- between getting the list and this check.
      local action = ide.config.unhidewindow[win:get_class_name()]
        or (any and show or ignore)
      if action == show and not win:is_visible()
      or action == hide and win:is_visible() then
        -- use show_async call (ShowWindowAsync) to avoid blocking the IDE
        -- if the app is busy or is being debugged
        win:show_async(action == show and winapi.SW_SHOW or winapi.SW_HIDE)
        pid = nil -- indicate that unhiding is done
      end
    end
  end
end

local function nameTab(tab, name)
  local index = bottomnotebook:GetPageIndex(tab)
  if index ~= wx.wxNOT_FOUND then bottomnotebook:SetPageText(index, name) end
end

function OutputSetCallbacks(pid, proc, callback, endcallback)
  local streamin = proc and proc:GetInputStream()
  local streamerr = proc and proc:GetErrorStream()
  if streamin then
    streamins[pid] = {stream=streamin, callback=callback,
      proc=proc, check=proc and proc.IsInputAvailable}
  end
  if streamerr then
    streamerrs[pid] = {stream=streamerr, callback=callback,
      proc=proc, check=proc and proc.IsErrorAvailable}
  end
  customprocs[pid] = {proc=proc, endcallback=endcallback}
end

function CommandLineRun(cmd,wdir,tooutput,nohide,stringcallback,uid,endcallback)
  if (not cmd) then return end

  -- expand ~ at the beginning of the command
  if ide.oshome and cmd:find('~') then
    cmd = cmd:gsub([[^(['"]?)~]], '%1'..ide.oshome:gsub('[\\/]$',''), 1)
  end

  -- try to extract the name of the executable from the command
  -- the executable may not have the extension and may be in quotes
  local exename = string.gsub(cmd, "\\", "/")
  local _,_,fullname = string.find(exename,'^[\'"]([^\'"]+)[\'"]')
  exename = fullname and string.match(fullname,'/?([^/]+)$')
    or string.match(exename,'/?([^/]-)%s') or exename

  uid = uid or exename

  if (CommandLineRunning(uid)) then
    DisplayOutputLn(TR("Program can't start because conflicting process is running as '%s'.")
      :format(cmd))
    return
  end

  DisplayOutputLn(TR("Program starting as '%s'."):format(cmd))

  local proc = wx.wxProcess(out)
  if (tooutput) then proc:Redirect() end -- redirect the output if requested

  -- set working directory if specified
  local oldcwd
  if (wdir and #wdir > 0) then -- directory can be empty; ignore in this case
    oldcwd = wx.wxFileName.GetCwd()
    oldcwd = wx.wxFileName.SetCwd(wdir) and oldcwd
  end

  -- launch process
  local params = wx.wxEXEC_ASYNC + wx.wxEXEC_MAKE_GROUP_LEADER + (nohide and wx.wxEXEC_NOHIDE or 0)
  local pid = wx.wxExecute(cmd, params, proc)

  if oldcwd then wx.wxFileName.SetCwd(oldcwd) end

  -- For asynchronous execution, the return value is the process id and
  -- zero value indicates that the command could not be executed.
  -- The return value of -1 in this case indicates that we didn't launch
  -- a new process, but connected to the running one (e.g. DDE under Windows).
  if not pid or pid == -1 or pid == 0 then
    DisplayOutputLn(TR("Program unable to run as '%s'."):format(cmd))
    return
  end

  DisplayOutputLn(TR("Program '%s' started in '%s' (pid: %d).")
    :format(uid, (wdir and wdir or wx.wxFileName.GetCwd()), pid))

  OutputSetCallbacks(pid, proc, stringcallback, endcallback)
  customprocs[pid].uid=uid
  customprocs[pid].started = ide:GetTime()

  local streamout = proc and proc:GetOutputStream()
  if streamout then streamouts[pid] = {stream=streamout, callback=stringcallback, out=true} end

  unHideWindow(pid)
  nameTab(out, TR("Output (running)"))

  return pid
end

ide:GetCodePage() -- populate the codepage value if auto-detection is requested

local readonce = 4096
local maxread = readonce * 10 -- maximum number of bytes to read before pausing
local function getStreams(all)
  local function readStream(tab)
    for _,v in pairs(tab) do
      -- periodically stop reading to get a chance to process other events
      local processed = 0
      while (v.check(v.proc) and (all or processed <= maxread)) do
        local str = v.stream:Read(readonce)
        -- the buffer has readonce bytes, so cut it to the actual size
        str = str:sub(1, v.stream:LastRead())
        processed = processed + #str

        local codepage = ide:GetCodePage()
        if codepage and FixUTF8(str) == nil and winapi then
          -- this looks like invalid UTF-8 content, which may be in a different code page
          str = winapi.encode(codepage, winapi.CP_UTF8, str)
        end

        local pfn
        if (v.callback) then
          str,pfn = v.callback(str)
        end
        if not str then
          -- skip if nothing to display
        elseif (v.toshell) then
          ide:GetConsole():Print(str)
        else
          DisplayOutputNoMarker(str)
          if str and (getInputLine() ~= wx.wxNOT_FOUND or out:GetReadOnly()) then
            ide:GetOutput():Activate()
            updateInputMarker()
          end
        end
        pfn = pfn and pfn()
      end
    end
  end
  local function sendStream(tab)
    local str = textout
    if not str then return end
    textout = nil
    str = str .. "\n"
    for _,v in pairs(tab) do
      local pfn
      if (v.callback) then
        str,pfn = v.callback(str)
      end
      v.stream:Write(str, #str)
      updateInputMarker()
      pfn = pfn and pfn()
    end
  end

  readStream(streamins)
  readStream(streamerrs)
  sendStream(streamouts)
end

function out:ProcessStreams()
  if (#streamins or #streamerrs) then getStreams() end
end

out:Connect(wx.wxEVT_END_PROCESS, function(event)
    local pid = event:GetPid()
    if (pid ~= -1) then
      getStreams(true)
      streamins[pid] = nil
      streamerrs[pid] = nil
      streamouts[pid] = nil

      if not customprocs[pid] then return end
      if customprocs[pid].endcallback then
        local ok, err = pcall(customprocs[pid].endcallback, pid, event:GetExitCode())
        if not ok then ide:GetOutput():Error(("Post processing execution failed: %s"):format(err)) end
      end

      -- if this was started with uid (`CommandLineRun`), then it needs additional processing
      if customprocs[pid].uid then
        -- delete markers and set focus to the editor if there is an input marker
        if out:MarkerPrevious(out:GetLineCount(), PROMPT_MARKER_VALUE) > wx.wxNOT_FOUND then
          out:MarkerDeleteAll(PROMPT_MARKER)
          local editor = ide:GetEditor()
          -- check if editor still exists; it may not if the window is closed
          if editor then editor:SetFocus() end
        end
        unHideWindow(0)
        ide:SetLaunchedProcess(nil)
        nameTab(out, TR("Output"))
        DisplayOutputLn(TR("Program completed in %.2f seconds (pid: %d).")
          :format(ide:GetTime() - customprocs[pid].started, pid))
      end
      customprocs[pid] = nil
    end
  end)

out:Connect(wx.wxEVT_IDLE, function()
    out:ProcessStreams()
    if ide.osname == 'Windows' then unHideWindow() end
  end)

local function activateByPartialName(fname, jumpline, jumplinepos)
  -- fname may include name of executable, as in "path/to/lua: file.lua";
  -- strip it and try to find match again if needed.
  -- try the stripped name first as if it doesn't match, the longer
  -- name may have parts that may be interpreted as a network path and
  -- may take few seconds to check.
  local name
  local fixedname = fname:match(":%s+(.+)")
  if fixedname then
    name = GetFullPathIfExists(ide:GetProject(), fixedname)
      or FileTreeFindByPartialName(fixedname)
  end
  name = name
    or GetFullPathIfExists(ide:GetProject(), fname)
    or FileTreeFindByPartialName(fname)

  local editor = LoadFile(name or fname,nil,true)
  if not editor then
    local ed = ide:GetEditor()
    if ed and ide:GetDocument(ed):GetFileName() == (name or fname) then
      editor = ed
    end
  end
  if not editor then return false end

  jumpline = tonumber(jumpline)
  jumplinepos = tonumber(jumplinepos)

  editor:GotoPos(editor:PositionFromLine(math.max(0,jumpline-1))
    + (jumplinepos and (math.max(0,jumplinepos-1)) or 0))
  editor:EnsureVisibleEnforcePolicy(jumpline)
  editor:SetFocus()
  return true
end

out:Connect(wxstc.wxEVT_STC_DOUBLECLICK,
  function(event)
    local line = out:GetCurrentLine()
    local linetx = out:GetLineDyn(line)

    -- try to detect a filename and line in linetx
    for pattern, multiple in pairs(ide.config.output.lineactivate or {}) do
      local results = {}
      for fname, jumpline, jumplinepos in linetx:gmatch(pattern) do
        -- insert matches in reverse order (if any)
        table.insert(results, 1, {fname, jumpline, jumplinepos})
        if type(multiple) == "function" then results[1] = {multiple(unpack(results[1]))} end
        if multiple ~= true then break end -- one match is enough if no multiple is requested
      end
      for _, result in ipairs(results) do
        if activateByPartialName(unpack(result)) then
          -- doubleclick can set selection, so reset it
          local pos = event:GetPosition()
          if pos == wx.wxNOT_FOUND then pos = out:GetLineEndPosition(event:GetLine()) end
          out:SetSelection(pos, pos)
          return
        end
      end
    end
    event:Skip()
  end)

local function positionInLine(line)
  return out:GetCurrentPos() - out:PositionFromLine(line)
end
local function caretOnInputLine(disallowLeftmost)
  local inputLine = getInputLine()
  local boundary = inputBound + (disallowLeftmost and 0 or -1)
  return (out:GetCurrentLine() > inputLine
    or out:GetCurrentLine() == inputLine
   and positionInLine(inputLine) > boundary)
end

out:Connect(wx.wxEVT_KEY_DOWN,
  function (event)
    local key = event:GetKeyCode()
    if out:GetReadOnly() then
      -- no special processing if it's readonly
    elseif key == wx.WXK_UP or key == wx.WXK_NUMPAD_UP then
      if out:GetCurrentLine() <= getInputLine() then return end
    elseif key == wx.WXK_DOWN or key == wx.WXK_NUMPAD_DOWN then
      -- can go down
    elseif key == wx.WXK_LEFT or key == wx.WXK_NUMPAD_LEFT then
      if not caretOnInputLine(true) then return end
    elseif key == wx.WXK_BACK then
      if not caretOnInputLine(true) then return end
    elseif key == wx.WXK_DELETE or key == wx.WXK_NUMPAD_DELETE then
      if not caretOnInputLine()
      or out:LineFromPosition(out:GetSelectionStart()) < getInputLine() then
        return
      end
    elseif key == wx.WXK_PAGEUP or key == wx.WXK_NUMPAD_PAGEUP
        or key == wx.WXK_PAGEDOWN or key == wx.WXK_NUMPAD_PAGEDOWN
        or key == wx.WXK_END or key == wx.WXK_NUMPAD_END
        or key == wx.WXK_HOME or key == wx.WXK_NUMPAD_HOME
        or key == wx.WXK_RIGHT or key == wx.WXK_NUMPAD_RIGHT
        or key == wx.WXK_SHIFT or key == wx.WXK_CONTROL
        or key == wx.WXK_ALT then
      -- fall through
    elseif key == wx.WXK_RETURN or key == wx.WXK_NUMPAD_ENTER then
      if not caretOnInputLine()
      or out:LineFromPosition(out:GetSelectionStart()) < getInputLine() then
        return
      end
      out:GotoPos(out:GetLength()) -- move to the end
      textout = (textout or '') .. getInputText(inputBound)
      -- remove selection if any, otherwise the text gets replaced
      out:SetSelection(out:GetSelectionEnd()+1,out:GetSelectionEnd())
      -- don't need to do anything else with return
    else
      -- move cursor to end if not already there
      if not caretOnInputLine() then
        out:GotoPos(out:GetLength())
      -- check if the selection starts before the input line and reset it
      elseif out:LineFromPosition(out:GetSelectionStart()) < getInputLine(-1) then
        out:GotoPos(out:GetLength())
        out:SetSelection(out:GetSelectionEnd()+1,out:GetSelectionEnd())
      end
    end
    event:Skip()
  end)

local function inputEditable(line)
  local inputLine = getInputLine()
  local currentLine = line or out:GetCurrentLine()
  return inputLine ~= wx.wxNOT_FOUND and
    (currentLine > inputLine or
     currentLine == inputLine and positionInLine(inputLine) >= inputBound) and
    not (out:LineFromPosition(out:GetSelectionStart()) < getInputLine())
end

out:Connect(wxstc.wxEVT_STC_UPDATEUI, function() out:SetReadOnly(not inputEditable()) end)

-- only allow copy/move text by dropping to the input line
out:Connect(wxstc.wxEVT_STC_DO_DROP,
  function (event)
    if not inputEditable(out:LineFromPosition(event:GetPosition())) then
      event:SetDragResult(wx.wxDragNone)
    end
  end)

if config.nomousezoom then
  -- disable zoom using mouse wheel as it triggers zooming when scrolling
  -- on OSX with kinetic scroll and then pressing CMD.
  out:Connect(wx.wxEVT_MOUSEWHEEL,
    function (event)
      if wx.wxGetKeyState(wx.WXK_CONTROL) then return end
      event:Skip()
    end)
end
