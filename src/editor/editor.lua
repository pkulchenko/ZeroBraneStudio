-- Copyright 2011-18 Paul Kulchenko, ZeroBrane LLC
-- authors: Lomtik Software (J. Winwood & John Labenski)
-- Luxinia Dev (Eike Decker & Christoph Kubisch)
---------------------------------------------------------

local editorID = 100 -- window id to create editor pages with, incremented for new editors

local notebook = ide.frame.notebook
local edcfg = ide.config.editor
local styles = ide.config.styles
local unpack = table.unpack or unpack
local q = EscapeMagic

local CURRENT_LINE_MARKER = StylesGetMarker("currentline")
local CURRENT_LINE_MARKER_VALUE = 2^CURRENT_LINE_MARKER

local margin = { LINENUMBER = 0, MARKER = 1, FOLD = 2 }
local linenumlen = 4 + 0.5
local foldtypes = {
  [0] = { wxstc.wxSTC_MARKNUM_FOLDEROPEN, wxstc.wxSTC_MARKNUM_FOLDER,
    wxstc.wxSTC_MARKNUM_FOLDERSUB, wxstc.wxSTC_MARKNUM_FOLDERTAIL, wxstc.wxSTC_MARKNUM_FOLDEREND,
    wxstc.wxSTC_MARKNUM_FOLDEROPENMID, wxstc.wxSTC_MARKNUM_FOLDERMIDTAIL,
  },
  box = { wxstc.wxSTC_MARK_BOXMINUS, wxstc.wxSTC_MARK_BOXPLUS,
    wxstc.wxSTC_MARK_VLINE, wxstc.wxSTC_MARK_LCORNER, wxstc.wxSTC_MARK_BOXPLUSCONNECTED,
    wxstc.wxSTC_MARK_BOXMINUSCONNECTED, wxstc.wxSTC_MARK_TCORNER,
  },
  circle = { wxstc.wxSTC_MARK_CIRCLEMINUS, wxstc.wxSTC_MARK_CIRCLEPLUS,
    wxstc.wxSTC_MARK_VLINE, wxstc.wxSTC_MARK_LCORNERCURVE, wxstc.wxSTC_MARK_CIRCLEPLUSCONNECTED,
    wxstc.wxSTC_MARK_CIRCLEMINUSCONNECTED, wxstc.wxSTC_MARK_TCORNERCURVE,
  },
  plus = { wxstc.wxSTC_MARK_MINUS, wxstc.wxSTC_MARK_PLUS },
  arrow = { wxstc.wxSTC_MARK_ARROWDOWN, wxstc.wxSTC_MARK_ARROW },
}

-- ----------------------------------------------------------------------------
-- Update the statusbar text of the frame using the given editor.
-- Only update if the text has changed.
local statusTextTable = { "OVR?", "R/O?", "Cursor Pos" }

local function updateStatusText(editor)
  local frame = ide:GetMainFrame()
  if not ide:IsValidCtrl(frame) then return end

  local texts = { "", "", "" }
  if frame and editor then
    local pos = editor:GetCurrentPos()
    local selected = #editor:GetSelectedText()
    local selections = ide.wxver >= "2.9.5" and editor:GetSelections() or 1

    texts = {
      (editor:GetOvertype() and TR("OVR") or TR("INS")),
      (editor:GetReadOnly() and TR("R/O") or TR("R/W")),
      table.concat({
        TR("Ln: %d"):format(editor:LineFromPosition(pos) + 1),
        TR("Col: %d"):format(editor:GetColumn(pos) + 1),
        selected > 0 and TR("Sel: %d/%d"):format(selected, selections) or "",
      }, ' ')}
  end

  if frame then
    for n in ipairs(texts) do
      if (texts[n] ~= statusTextTable[n]) then
        ide:SetStatus(texts[n], n)
        statusTextTable[n] = texts[n]
      end
    end
  end
end

local function updateBraceMatch(editor)
  local pos = editor:GetCurrentPos()
  local posp = pos > 0 and pos-1
  local char = editor:GetCharAt(pos)
  local charp = posp and editor:GetCharAt(posp)
  local match = { [string.byte("<")] = true,
    [string.byte(">")] = true,
    [string.byte("(")] = true,
    [string.byte(")")] = true,
    [string.byte("{")] = true,
    [string.byte("}")] = true,
    [string.byte("[")] = true,
    [string.byte("]")] = true,
  }

  pos = (match[char] and pos) or (charp and match[charp] and posp)

  if (pos) then
    -- don't match brackets in markup comments
    local style = bit.band(editor:GetStyleAt(pos), ide.STYLEMASK)
    if (MarkupIsSpecial and MarkupIsSpecial(style)
      or editor.spec.iscomment[style]) then return end

    local pos2 = editor:BraceMatch(pos)
    if (pos2 == wxstc.wxSTC_INVALID_POSITION) then
      editor:BraceBadLight(pos)
    else
      editor:BraceHighlight(pos,pos2)
    end
    editor.matchon = true
  elseif(editor.matchon) then
    editor:BraceBadLight(wxstc.wxSTC_INVALID_POSITION)
    editor:BraceHighlight(wxstc.wxSTC_INVALID_POSITION,-1)
    editor.matchon = false
  end
end

-- Check if file is altered, show dialog to reload it
local function isFileAlteredOnDisk(editor)
  if not editor then return end

  local doc = ide:GetDocument(editor)
  if doc then
    local filePath = doc:GetFilePath()
    local fileName = doc:GetFileName()
    local oldModTime = doc:GetFileModifiedTime()

    if filePath and (string.len(filePath) > 0) and oldModTime and oldModTime:IsValid() then
      local modTime = GetFileModTime(filePath)
      if modTime == nil then
        doc:SetFileModifiedTime(nil)
        wx.wxMessageBox(
          TR("File '%s' no longer exists."):format(fileName),
          ide:GetProperty("editormessage"),
          wx.wxOK + wx.wxCENTRE, ide.frame)
      elseif not editor:GetReadOnly() and modTime:IsValid() and oldModTime:IsEarlierThan(modTime) then
        local ret = edcfg.autoreload and (not doc:IsModified()) and wx.wxYES
          or wx.wxMessageBox(
            TR("File '%s' has been modified on disk."):format(fileName)
            .."\n"..TR("Do you want to reload it?"),
            ide:GetProperty("editormessage"),
            wx.wxYES_NO + wx.wxCENTRE, ide.frame)

        if ret ~= wx.wxYES or ReLoadFile(filePath, editor, true) then
          doc:SetFileModifiedTime(GetFileModTime(filePath))
        end
      end
    end
  end
end

local function navigateToPosition(editor, fromPosition, toPosition, length)
  table.insert(editor.jumpstack, fromPosition)
  editor:GotoPosEnforcePolicy(toPosition)
  if length then
    editor:SetAnchor(toPosition + length)
  end
end

local function navigateBack(editor)
  if #editor.jumpstack == 0 then return end
  local pos = table.remove(editor.jumpstack)
  editor:GotoPosEnforcePolicy(pos)
  return true
end

function EditorAutoComplete(editor)
  if not (editor and editor.spec) then return end

  local pos = editor:GetCurrentPos()
  -- don't do auto-complete in comments or strings.
  -- the current position and the previous one have default style (0),
  -- so we need to check two positions back.
  local style = pos >= 2 and bit.band(editor:GetStyleAt(pos-2),ide.STYLEMASK) or 0
  if editor.spec.iscomment[style]
  or editor.spec.isstring[style]
  or (MarkupIsAny and MarkupIsAny(style)) -- markup in comments
  then return end

  -- retrieve the current line and get a string to the current cursor position in the line
  local line = editor:GetCurrentLine()
  local linetx = editor:GetLineDyn(line)
  local linestart = editor:PositionFromLine(line)
  local localpos = pos-linestart

  local lt = linetx:sub(1,localpos)
  lt = lt:gsub("%s*(["..editor.spec.sep.."])%s*", "%1")
  -- strip closed brace scopes
  lt = lt:gsub("%b()","")
  lt = lt:gsub("%b{}","")
  lt = lt:gsub("%b[]",".0")
  -- remove everything that can't be auto-completed
  lt = lt:match("[%w_"..q(editor.spec.sep).."]*$")

  -- if there is nothing to auto-complete for, then don't show the list
  if lt:find("^["..q(editor.spec.sep).."]*$") then return end

  -- know now which string is to be completed
  local userList = CreateAutoCompList(editor, lt, pos)

  -- don't show if what's typed so far matches one of the options
  local right = linetx:sub(localpos+1,#linetx):match("^([%a_]+[%w_]*)")
  local left = lt:match("[%w_]*$") -- extract one word on the left (without separators)
  local compmatch = {
    left = "( ?)%f[%w_]"..left.."%f[^%w_]( ?)",
    leftright = "( ?)%f[%w_]"..left..(right or "").."%f[^%w_]( ?)",
  }
  -- if the multiple selection is active, then remove the match from the `userList`,
  -- as it's going to match a (possibly earlier) copy of the same value
  local selections = ide.wxver >= "2.9.5" and editor:GetSelections() or 1
  if userList and selections > 1 then
    for _, m in pairs(compmatch) do
      -- replace with a space only when there are spaces on both sides
      userList = userList:gsub(m, function(s1, s2) return #(s1..s2) == 2 and " " or "" end)
    end
  end
  if userList and #userList > 0
  -- don't show autocomplete if there is a full match on the list of autocomplete options
  and not (userList:find(compmatch.left) or userList:find(compmatch.leftright)) then
    editor:UserListShow(1, userList)
  elseif editor:AutoCompActive() then
    editor:AutoCompCancel()
  end
end

local ident = "([a-zA-Z_][a-zA-Z_0-9%.%:]*)"
local function getValAtPosition(editor, pos)
  local line = editor:LineFromPosition(pos)
  local linetx = editor:GetLineDyn(line)
  local linestart = editor:PositionFromLine(line)
  local localpos = pos-linestart

  local selected = editor:GetSelectionStart() ~= editor:GetSelectionEnd()
    and pos >= editor:GetSelectionStart() and pos <= editor:GetSelectionEnd()

  -- check if we have a selected text or an identifier.
  -- for an identifier, check fragments on the left and on the right.
  -- this is to match 'io' in 'i^o.print' and 'io.print' in 'io.pr^int'.
  -- remove square brackets to make tbl[index].x show proper values.
  local start = linetx:sub(1,localpos)
    :gsub("%b[]", function(s) return ("."):rep(#s) end)
    :find(ident.."$")

  local right, funccall = linetx:sub(localpos+1,#linetx):match("^([a-zA-Z_0-9]*)%s*(['\"{%(]?)")
  local var = selected
    -- GetSelectedText() returns concatenated text when multiple instances
    -- are selected, so get the selected text based on start/end
    and editor:GetTextRangeDyn(editor:GetSelectionStart(), editor:GetSelectionEnd())
    or (start and linetx:sub(start,localpos):gsub(":",".")..right or nil)

  -- since this function can be called in different contexts, we need
  -- to detect function call of different types:
  -- 1. foo.b^ar(... -- the cursor (pos) is on the function name
  -- 2. foo.bar(..^. -- the cursor (pos) is on the parameter list
  -- "var" has value for #1 and the following fragment checks for #2

  -- check if the style is the right one; this is to ignore
  -- comments, strings, numbers (to avoid '1 = 1'), keywords, and such
  local goodpos = true
  if start and not selected then
    local style = bit.band(editor:GetStyleAt(linestart+start),ide.STYLEMASK)
    if (MarkupIsAny and MarkupIsAny(style)) -- markup in comments
    or editor.spec.iscomment[style]
    or editor.spec.isstring[style]
    or editor.spec.isnumber[style]
    or editor.spec.iskeyword[style] then
      goodpos = false
    end
  end

  local linetxtopos = linetx:sub(1,localpos)
  funccall = (#funccall > 0) and goodpos and var
    or (linetxtopos..")"):match(ident .. "%s*%b()$")
    or (linetxtopos.."}"):match(ident .. "%s*%b{}$")
    or (linetxtopos.."'"):match(ident .. "%s*'[^']*'$")
    or (linetxtopos..'"'):match(ident .. '%s*"[^"]*"$')
    or nil

  -- don't do anything for strings or comments or numbers
  if not goodpos then return nil, funccall end

  return var, funccall
end

local function formatUpToX(s)
  local x = math.max(20, ide.config.acandtip.width)
  local splitstr = "([ \t]*)(%S*)([ \t]*)(\n?)"
  local t = {""}
  for prefix, word, suffix, newline in s:gmatch(splitstr) do
    if #(t[#t]) + #prefix + #word > x and #t > 0 then
      table.insert(t, word..suffix)
    else
      t[#t] = t[#t]..prefix..word..suffix
    end
    if #newline > 0 then table.insert(t, "") end
  end
  return table.concat(t, "\n")
end

local function callTipFitAndShow(editor, pos, tip)
  local point = editor:PointFromPosition(pos)
  local sline = editor:LineFromPosition(pos)
  local height = editor:TextHeight(sline)
  local maxlines = math.max(1, math.floor(
    math.max(editor:GetSize():GetHeight()-point:GetY()-height, point:GetY())/height-1
  ))
  -- cut the tip to not exceed the number of maxlines.
  -- move the position to the left if needed to fit.
  -- find the longest line in terms of width in pixels.
  local maxwidth = 0
  local lines = {}
  for line in formatUpToX(tip):gmatch("[^\n]*\n?") do
    local width = editor:TextWidth(wxstc.wxSTC_STYLE_DEFAULT, line)
    if width > maxwidth then maxwidth = width end
    table.insert(lines, line)
    if #lines >= maxlines then
      lines[#lines] = lines[#lines]:gsub("%s*\n$","")..'...'
      break
    end
  end
  tip = table.concat(lines, '')

  local startpos = editor:PositionFromLine(sline)
  local afterwidth = editor:GetSize():GetWidth()-point:GetX()
  if maxwidth > afterwidth then
    local charwidth = editor:TextWidth(wxstc.wxSTC_STYLE_DEFAULT, 'A')
    pos = math.max(startpos, pos - math.floor((maxwidth - afterwidth) / charwidth))
  end

  editor:CallTipShow(pos, tip)
end

function EditorCallTip(editor, pos, x, y)
  -- don't show anything if the calltip/auto-complete is active;
  -- this may happen after typing function name, while the mouse is over
  -- a different function or when auto-complete is on for a parameter.
  if editor:CallTipActive() or editor:AutoCompActive() then return end

  -- don't activate if the window itself is not active (in the background)
  if not ide.frame:IsActive() then return end

  local var, funccall = editor:ValueFromPosition(pos)
  -- if this is a value type rather than a function/method call, then use
  -- full match to avoid calltip about coroutine.status for "status" vars
  local tip = GetTipInfo(editor, funccall or var, false, not funccall)
  local limit = ide.config.acandtip.maxlength
  local debugger = ide:GetDebugger()
  if debugger and debugger:IsConnected() then
    if var then
      debugger:EvalAsync(var, function(val, err)
        -- val == `nil` if there is any error
        val = val ~= nil and (var.." = "..val) or err
        if #val > limit then val = val:sub(1, limit-3).."..." end
        -- check if the mouse position is specified and the mouse has moved,
        -- then don't show the tooltip as it's already too late for it.
        if x and y then
          local mpos = wx.wxGetMousePosition()
          if mpos.x ~= x or mpos.y ~= y then return end
        end
        if PackageEventHandle("onEditorCallTip", editor, val, funccall or var, true) ~= false then
          callTipFitAndShow(editor, pos, val)
        end
      end, debugger:GetDataOptions({maxlevel = false}))
    end
  elseif tip then
    local oncalltip = PackageEventHandle("onEditorCallTip", editor, tip, funccall or var, false)
    -- only shorten if shown on mouse-over. Use shortcut to get full info.
    local showtooltip = ide.frame.menuBar:FindItem(ID.SHOWTOOLTIP)
    local suffix = "...\n"
        ..TR("Use '%s' to see full description."):format(showtooltip:GetLabel())
    if x and y and #tip > limit then
      tip = tip:sub(1, limit-#suffix):gsub("%W*%w*$","")..suffix
    end
    if oncalltip ~= false then callTipFitAndShow(editor, pos, tip) end
  end
end

function ClosePage(selection, notebook)
  local editor = (notebook and selection
    and notebook:GetPage(selection):DynamicCast("wxStyledTextCtrl")
    or ide:GetEditor()
  )
  if not editor then return false end

  if PackageEventHandle("onEditorPreClose", editor) == false then
    return false
  end

  if SaveModifiedDialog(editor, true) ~= wx.wxID_CANCEL then
    DynamicWordsRemoveAll(editor)
    local debugger = ide:GetDebugger()
    -- check if the window with the scratchpad running is being closed
    if debugger and debugger.scratchpad and debugger.scratchpad.editors
    and debugger.scratchpad.editors[editor] then
      debugger:ScratchpadOff()
    end
    -- check if the debugger is running and is using the current window;
    -- abort the debugger if the current marker is in the window being closed
    if debugger and debugger:IsConnected() and
      (editor:MarkerNext(0, CURRENT_LINE_MARKER_VALUE) >= 0) then
      debugger:Stop()
    end

    -- update the editor status if the active document is being closed
    -- if another editor/document gets focus, it will update the status
    if ide:GetDocument(editor):IsActive() then updateStatusText() end

    -- the event needs to be triggered before the document/editor is removed,
    -- so there is a small chance that the notebook page will not be removed,
    -- despite the event already triggered
    PackageEventHandle("onEditorClose", editor)
    if not ide:RemoveDocument(editor) then return false end
    editor:Destroy()

    ide:SetTitle()

    -- disable full screen if the last tab in the main notebook is closed
    if ide:GetEditorNotebook():GetPageCount() == 0 then ide:ShowFullScreen(false) end
    return true
  end
  return false
end

-- Indicator handling for functions and local/global variables
local indicator = {
  FNCALL = ide:GetIndicator("core.fncall"),
  LOCAL = ide:GetIndicator("core.varlocal"),
  GLOBAL = ide:GetIndicator("core.varglobal"),
  SELF = ide:GetIndicator("core.varself"),
  MASKING = ide:GetIndicator("core.varmasking"),
  MASKED = ide:GetIndicator("core.varmasked"),
}

function IndicateFunctionsOnly(editor, lines, linee)
  local sindic = styles.indicator
  if not (edcfg.showfncall and editor.spec and editor.spec.isfncall)
  or not (sindic and sindic.fncall and sindic.fncall.st ~= wxstc.wxSTC_INDIC_HIDDEN) then return end

  local lines = lines or 0
  local linee = linee or editor:GetLineCount()-1

  if (lines < 0) then return end

  local isfncall = editor.spec.isfncall
  local isinvalid = {}
  for i,v in pairs(editor.spec.iscomment) do isinvalid[i] = v end
  for i,v in pairs(editor.spec.iskeyword) do isinvalid[i] = v end
  for i,v in pairs(editor.spec.isstring) do isinvalid[i] = v end

  editor:SetIndicatorCurrent(indicator.FNCALL)
  for line=lines,linee do
    local tx = editor:GetLineDyn(line)
    local ls = editor:PositionFromLine(line)
    editor:IndicatorClearRange(ls, #tx)

    local from = 1
    local off = -1
    while from do
      tx = from==1 and tx or string.sub(tx,from)

      local f,t,w = isfncall(tx)

      if (f) then
        local p = ls+f+off
        local s = bit.band(editor:GetStyleAt(p),ide.STYLEMASK)
        if not isinvalid[s] then editor:IndicatorFillRange(p, #w) end
        off = off + t
      end
      from = t and (t+1)
    end
  end
end

local delayed = {}

function IndicateIfNeeded()
  local editor = ide:GetEditor()
  -- do the current one first
  if editor and delayed[editor] then
    return editor:IndicateSymbols() or next(delayed) ~= nil
  end
  local ed = next(delayed)
  local needmore = false
  if ide:IsValidCtrl(ed) then
    needmore = ed:IndicateSymbols()
  elseif ed then
    delayed[ed] = nil
  end
  return needmore or next(delayed) ~= nil
end

-- find all instances of a symbol at pos
-- return table with [0] as the definition position (if local)
local function indicateFindInstances(editor, name, pos)
  local tokens = editor:GetTokenList()
  local instances = {{[-1] = 1}}
  local this
  for _, token in ipairs(tokens) do
    local op = token[1]

    if op == 'EndScope' then -- EndScope has "new" level, so need +1
      if this and token.fpos > pos and this == token.at+1 then break end

      if #instances > 1 and instances[#instances][-1] == token.at+1 then
        table.remove(instances)
      end
    elseif token.name == name then
      if op == 'Id' then
        table.insert(instances[#instances], token.fpos)
      elseif op:find("^Var") then
        if this and this == token.at then break end

        -- if new Var is defined at the same level, replace the current frame;
        -- if not, add a new one; skip implicit definition of "self" variable.
        instances[#instances + (token.at > instances[#instances][-1] and 1 or 0)]
          = {[0] = (not token.self and token.fpos or nil), [-1] = token.at}
      end
      if token.fpos <= pos and pos <= token.fpos+#name then this = instances[#instances][-1] end
    end
  end
  instances[#instances][-1] = nil -- remove the current level
  -- only return the list if "this" instance has been found;
  -- this is to avoid reporting (improper) instances when checking for
  -- comments, strings, table fields, etc.
  return this and instances[#instances] or {}
end

local function indicateSymbols(editor, lines)
  if not ide.config.autoanalyzer then return end

  local d = delayed[editor]
  delayed[editor] = nil -- assume this can be finished for now

  -- this function can be called for an editor tab that is already closed
  -- when there are still some pending events for it, so handle it.
  if not ide:IsValidCtrl(editor) then return end

  -- if marksymbols is not set in the spec, nothing else to do
  if not (editor.spec and editor.spec.marksymbols) then return end

  local indic = styles.indicator or {}

  local pos, vars = d and d[1] or 1, d and d[2] or nil
  local start = lines and editor:PositionFromLine(lines)+1 or nil
  if d and start and pos >= start then
    -- ignore delayed processing as the change is earlier in the text
    pos, vars = 1, nil
  end

  local tokens = editor:GetTokenList()

  if start then -- if the range is specified
    local curindic = editor:GetIndicatorCurrent()
    editor:SetIndicatorCurrent(indicator.MASKED)
    for n = #tokens, 1, -1 do
      local token = tokens[n]
      -- find the last token before the range
      if not token.nobreak and token.name and token.fpos+#token.name < start then
        pos, vars = token.fpos+#token.name, token.context
        break
      end
      -- unmask all variables from the rest of the list
      if token[1] == 'Masked' then
        editor:IndicatorClearRange(token.fpos-1, #token.name)
      end
      -- trim the list as it will be re-generated
      table.remove(tokens, n)
    end

    -- Clear masked indicators from the current position to the end as these
    -- will be re-calculated and re-applied based on masking variables.
    -- This step is needed as some positions could have shifted after updates.
    editor:IndicatorClearRange(pos-1, editor:GetLength()-pos+1)

    editor:SetIndicatorCurrent(curindic)

    -- need to cleanup vars as they may include variables from later
    -- fragments (because the cut-point was arbitrary). Also need
    -- to clean variables in other scopes, hence getmetatable use.
    local vars = vars
    while vars do
      for name, var in pairs(vars) do
        -- remove all variables that are created later than the current pos
        -- skip all non-variable elements from the vars table
        if type(name) == 'string' then
          while type(var) == 'table' and var.fpos and (var.fpos > pos) do
            var = var.masked -- restored a masked var
            vars[name] = var
          end
        end
      end
      vars = getmetatable(vars) and getmetatable(vars).__index
    end
  else
    if pos == 1 then -- if not continuing, then trim the list
      tokens = editor:ResetTokenList()
    end
  end

  local cleared = {}
  for _, indic in ipairs {indicator.FNCALL, indicator.LOCAL, indicator.GLOBAL, indicator.MASKING, indicator.SELF} do
    cleared[indic] = pos
  end

  local function IndicateOne(indic, pos, length)
    editor:SetIndicatorCurrent(indic)
    editor:IndicatorClearRange(cleared[indic]-1, pos-cleared[indic])
    editor:IndicatorFillRange(pos-1, length)
    cleared[indic] = pos+length
  end

  local s = ide:GetTime()
  local canwork = start and 0.010 or 0.100 -- use shorter interval when typing
  local f = editor.spec.marksymbols(editor:GetTextDyn(), pos, vars)
  while true do
    local op, name, lineinfo, vars, at, nobreak = f()
    if not op then break end
    local var = vars and vars[name]
    local token = {op, name=name, fpos=lineinfo, at=at, context=vars,
      self = (op == 'VarSelf') or nil, nobreak=nobreak}
    if op == 'Function' then
      vars['function'] = (vars['function'] or 0) + 1
    end
    if op == 'FunctionCall' then
      if indic.fncall and edcfg.showfncall then
        IndicateOne(indicator.FNCALL, lineinfo, #name)
      end
    elseif op ~= 'VarNext' and op ~= 'VarInside' and op ~= 'Statement' and op ~= 'String' then
      table.insert(tokens, token)
    end

    -- indicate local/global variables
    if op == 'Id'
    and (var and indic.varlocal or not var and indic.varglobal) then
      IndicateOne(var and (var.self and indicator.SELF or indicator.LOCAL) or indicator.GLOBAL, lineinfo, #name)
    end

    -- indicate masked values at the same level
    if op == 'Var' and var and (var.masked and at == var.masked.at) then
      local fpos = var.masked.fpos
      -- indicate masked if it's not implicit self
      if indic.varmasked and not var.masked.self then
        editor:SetIndicatorCurrent(indicator.MASKED)
        editor:IndicatorFillRange(fpos-1, #name)
        table.insert(tokens, {"Masked", name=name, fpos=fpos, nobreak=nobreak})
      end

      if indic.varmasking then IndicateOne(indicator.MASKING, lineinfo, #name) end
    end
    -- in some rare cases `nobreak` may be a number indicating a desired
    -- position from which to start in case of a break
    if lineinfo and nobreak ~= true and (op == 'Statement' or op == 'String') and ide:GetTime()-s > canwork then
      delayed[editor] = {tonumber(nobreak) or lineinfo, vars}
      break
    end
  end

  -- clear indicators till the end of processed fragment
  pos = delayed[editor] and delayed[editor][1] or editor:GetLength()+1

  -- don't clear "masked" indicators as those can be set out of order (so
  -- last updated fragment is not always the last in terms of its position);
  -- these indicators should be up-to-date to the end of the code fragment.
  local funconly = ide.config.editor.showfncall and editor.spec.isfncall
  for _, indic in ipairs {indicator.FNCALL, indicator.LOCAL, indicator.GLOBAL, indicator.MASKING} do
    -- don't clear "funccall" indicators as those can be set based on
    -- IndicateFunctionsOnly processing, which is dealt with separately
    if indic ~= indicator.FNCALL or not funconly then IndicateOne(indic, pos, 0) end
  end

  local needmore = delayed[editor] ~= nil
  if ide.config.outlineinactivity then
    if needmore then ide.timers.outline:Stop()
    else ide.timers.outline:Start(ide.config.outlineinactivity*1000, wx.wxTIMER_ONE_SHOT)
    end
  end
  return needmore -- request more events if still need to work
end

-- ----------------------------------------------------------------------------
-- Create an editor
function CreateEditor(bare)
  local editor = ide:CreateStyledTextCtrl(notebook, editorID,
    wx.wxDefaultPosition, wx.wxSize(0, 0), wx.wxBORDER_NONE)

  editorID = editorID + 1 -- increment so they're always unique

  editor.matchon = false
  editor.assignscache = false
  editor.bom = false
  editor.updated = 0
  editor.jumpstack = {}
  editor.ctrlcache = {}
  editor.tokenlist = {}
  editor.onidle = {}
  editor.usedynamicwords = true
  -- populate cache with Ctrl-<letter> combinations for workaround on Linux
  -- http://wxwidgets.10942.n7.nabble.com/Menu-shortcuts-inconsistentcy-issue-td85065.html
  for id, shortcut in pairs(ide.config.keymap) do
    if shortcut:match('%f[%w]Ctrl[-+]') then
      local mask = (wx.wxMOD_CONTROL
        + (shortcut:match('%f[%w]Alt[-+]') and wx.wxMOD_ALT or 0)
        + (shortcut:match('%f[%w]Shift[-+]') and wx.wxMOD_SHIFT or 0)
      )
      local key = shortcut:match('[-+](.)$')
      if key then editor.ctrlcache[key:byte()..mask] = id end
    end
  end

  -- populate editor keymap with configured combinations
  for _, map in pairs(edcfg.keymap or {}) do
    local key, mod, cmd, osname = unpack(map)
    if not osname or osname == ide.osname then
      if cmd then
        editor:CmdKeyAssign(key, mod, cmd)
      else
        editor:CmdKeyClear(key, mod)
      end
    end
  end

  editor:SetBufferedDraw(not ide.config.hidpi and true or false)
  editor:StyleClearAll()

  editor:SetFont(ide.font.editor)
  editor:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, editor:GetFont())

  editor:SetTabWidth(tonumber(edcfg.tabwidth) or 2)
  editor:SetIndent(tonumber(edcfg.tabwidth) or 2)
  editor:SetUseTabs(edcfg.usetabs and true or false)
  editor:SetIndentationGuides(tonumber(edcfg.indentguide) or (edcfg.indentguide and true or false))
  editor:SetViewWhiteSpace(tonumber(edcfg.whitespace) or (edcfg.whitespace and true or false))
  editor:SetEndAtLastLine(edcfg.endatlastline and true or false)

  if (edcfg.usewrap) then
    editor:SetWrapMode(edcfg.wrapmode)
    editor:SetWrapStartIndent(0)
    if ide.wxver >= "2.9.5" then
      if edcfg.wrapflags then
        editor:SetWrapVisualFlags(tonumber(edcfg.wrapflags) or wxstc.wxSTC_WRAPVISUALFLAG_NONE)
      end
      if edcfg.wrapstartindent then
        editor:SetWrapStartIndent(tonumber(edcfg.wrapstartindent) or 0)
      end
      if edcfg.wrapindentmode then
        editor:SetWrapIndentMode(tonumber(edcfg.wrapindentmode) or wxstc.wxSTC_WRAPINDENT_FIXED)
      end
      if edcfg.wrapflagslocation then
        editor:SetWrapVisualFlagsLocation(tonumber(edcfg.wrapflagslocation) or wxstc.wxSTC_WRAPVISUALFLAGLOC_DEFAULT)
      end
    end
  else
    editor:SetScrollWidth(100) -- set default width
    editor:SetScrollWidthTracking(1) -- enable width auto-adjustment
  end

  if edcfg.defaulteol == wxstc.wxSTC_EOL_CRLF
  or edcfg.defaulteol == wxstc.wxSTC_EOL_LF then
    editor:SetEOLMode(edcfg.defaulteol)
  -- else: keep wxStyledTextCtrl default behavior (CRLF on Windows, LF on Unix)
  end

  editor:SetCaretLineVisible(edcfg.caretline and true or false)

  editor:SetVisiblePolicy(wxstc.wxSTC_VISIBLE_STRICT, 3)

  editor:SetMarginType(margin.LINENUMBER, wxstc.wxSTC_MARGIN_NUMBER)
  editor:SetMarginMask(margin.LINENUMBER, 0)
  editor:SetMarginWidth(margin.LINENUMBER,
    edcfg.linenumber and math.floor(linenumlen * editor:TextWidth(wxstc.wxSTC_STYLE_DEFAULT, "8")) or 0)

  editor:SetMarginType(margin.MARKER, wxstc.wxSTC_MARGIN_SYMBOL)
  editor:SetMarginMask(margin.MARKER, 0xffffffff - wxstc.wxSTC_MASK_FOLDERS)
  editor:SetMarginSensitive(margin.MARKER, true)
  editor:SetMarginWidth(margin.MARKER, 18)

  editor:MarkerDefine(StylesGetMarker("currentline"))
  editor:MarkerDefine(StylesGetMarker("breakpoint"))
  editor:MarkerDefine(StylesGetMarker("bookmark"))

  if edcfg.fold then
    editor:SetMarginType(margin.FOLD, wxstc.wxSTC_MARGIN_SYMBOL)
    editor:SetMarginMask(margin.FOLD, wxstc.wxSTC_MASK_FOLDERS)
    editor:SetMarginSensitive(margin.FOLD, true)
    editor:SetMarginWidth(margin.FOLD, 18)
  end

  editor:SetFoldFlags(tonumber(edcfg.foldflags) or wxstc.wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED)
  editor:SetBackSpaceUnIndents(edcfg.backspaceunindent and 1 or 0)

  if ide.wxver >= "2.9.5" then
    -- allow multiple selection and multi-cursor editing if supported
    editor:SetMultipleSelection(1)
    editor:SetAdditionalCaretsBlink(1)
    editor:SetAdditionalSelectionTyping(1)
    -- allow extra ascent/descent
    editor:SetExtraAscent(tonumber(edcfg.extraascent) or 0)
    editor:SetExtraDescent(tonumber(edcfg.extradescent) or 0)
    -- set whitespace size
    editor:SetWhitespaceSize(tonumber(edcfg.whitespacesize) or 1)
    -- set virtual space options
    editor:SetVirtualSpaceOptions(tonumber(edcfg.virtualspace) or 0)
  end

  do
    local fg, bg = wx.wxWHITE, wx.wxColour(128, 128, 128)
    local foldtype = foldtypes[edcfg.foldtype] or foldtypes.box
    local foldmarkers = foldtypes[0]
    for m = 1, #foldmarkers do
      editor:MarkerDefine(foldmarkers[m], foldtype[m] or wxstc.wxSTC_MARK_EMPTY, fg, bg)
    end
    bg:delete()
  end

  if edcfg.calltipdelay and edcfg.calltipdelay > 0 then
    editor:SetMouseDwellTime(edcfg.calltipdelay)
  end

  if edcfg.edgemode ~= wxstc.wxSTC_EDGE_NONE or edcfg.edge then
    editor:SetEdgeMode(edcfg.edgemode ~= wxstc.wxSTC_EDGE_NONE and edcfg.edgemode or wxstc.wxSTC_EDGE_LINE)
    editor:SetEdgeColumn(tonumber(edcfg.edge) or 80)
  end

  editor:AutoCompSetIgnoreCase(ide.config.acandtip.ignorecase)
  if (ide.config.acandtip.strategy > 0) then
    editor:AutoCompSetAutoHide(0)
    editor:AutoCompStops([[ \n\t=-+():.,;*/!"'$%&~'#°^@?´`<>][|}{]])
  end
  if ide.config.acandtip.fillups then
    editor:AutoCompSetFillUps(ide.config.acandtip.fillups)
  end

  if ide:IsValidProperty(editor, "SetMultiPaste") then editor:SetMultiPaste(wxstc.wxSTC_MULTIPASTE_EACH) end

  function editor:UseDynamicWords(val)
    if val == nil then return self.usedynamicwords end
    self.usedynamicwords = val
  end

  function editor:GetTokenList() return self.tokenlist end
  function editor:ResetTokenList() self.tokenlist = {}; return self.tokenlist end

  function editor:IndicateSymbols(...) return indicateSymbols(self, ...) end

  function editor:ValueFromPosition(pos) return getValAtPosition(self, pos) end

  function editor:MarkerGotoNext(marker)
    local value = 2^marker
    local line = editor:MarkerNext(editor:GetCurrentLine()+1, value)
    if line == wx.wxNOT_FOUND then line = editor:MarkerNext(0, value) end
    if line == wx.wxNOT_FOUND then return end
    editor:GotoLine(line)
    editor:EnsureVisibleEnforcePolicy(line)
    return line
  end
  function editor:MarkerGotoPrev(marker)
    local value = 2^marker
    local line = editor:MarkerPrevious(editor:GetCurrentLine()-1, value)
    if line == wx.wxNOT_FOUND then line = editor:MarkerPrevious(editor:GetLineCount(), value) end
    if line == wx.wxNOT_FOUND then return end
    editor:GotoLine(line)
    editor:EnsureVisibleEnforcePolicy(line)
    return line
  end
  function editor:MarkerToggle(marker, line, value)
    if type(marker) == "string" then marker = StylesGetMarker(marker) end
    assert(marker ~= nil, "Marker update requires known marker type")
    line = line or editor:GetCurrentLine()
    local isset = bit.band(editor:MarkerGet(line), 2^marker) > 0
    if value ~= nil and isset == value then return end
    if PackageEventHandle("onEditorMarkerUpdate", editor, marker, line+1, not isset) == false then return end
    if isset then
      editor:MarkerDelete(line, marker)
    else
      editor:MarkerAdd(line, marker)
    end
  end

  function editor:BookmarkToggle(...) return self:MarkerToggle("bookmark", ...) end
  function editor:BreakpointToggle(...) return self:MarkerToggle("breakpoint", ...) end

  function editor:DoWhenIdle(func) table.insert(self.onidle, func) end

  -- GotoPos should work by itself, but it doesn't (wx 2.9.5).
  -- This is likely because the editor window hasn't been refreshed yet,
  -- so its LinesOnScreen method returns 0/-1, which skews the calculations.
  -- To avoid this, the caret line is made visible at the first opportunity.
  do
    local redolater
    function editor:GotoPosDelayed(pos)
      local badtime = self:LinesOnScreen() <= 0 -- -1 on OSX, 0 on Windows
      if pos then
        if badtime then
          redolater = pos
          -- without this GotoPos the content is not scrolled correctly on
          -- Windows, but with this it's not scrolled correctly on OSX.
          if ide.osname ~= 'Macintosh' then self:GotoPos(pos) end
        else
          redolater = nil
          self:GotoPosEnforcePolicy(pos)
        end
      elseif not badtime and redolater then
        -- reset the left margin first to make sure that the position
        -- is set "from the left" to get the best content displayed.
        self:SetXOffset(0)
        self:GotoPosEnforcePolicy(redolater)
        redolater = nil
      end
    end
  end

  if bare then return editor end -- bare editor doesn't have any event handlers

  local mclickpos
  editor:Connect(wx.wxEVT_LEFT_DOWN, function(event)
      event:Skip()
      mclickpos = event:GetPosition()
    end)
  editor:Connect(wx.wxEVT_LEFT_UP, function(event)
      event:Skip()
      if not mclickpos
      or wx.wxGetKeyState(wx.WXK_SHIFT)
      or wx.wxGetKeyState(wx.WXK_CONTROL)
      or wx.wxGetKeyState(wx.WXK_ALT) then return end

      local point = event:GetPosition()
      if mclickpos:GetX() ~= point:GetX() or mclickpos:GetY() ~= point:GetY() then return end

      local pos = editor:PositionFromPoint(point)
      local line = editor:LineFromPosition(pos)
      local header = bit.band(editor:GetFoldLevel(line),
        wxstc.wxSTC_FOLDLEVELHEADERFLAG) == wxstc.wxSTC_FOLDLEVELHEADERFLAG
      local from = header and line or editor:GetFoldParent(line)

      -- check if the click over the LINENUMBER margin
      if editor:MarginFromPoint(point:GetX()) == margin.LINENUMBER then
        -- if the next line is not visible, select the entire block to include folder lines
        if not editor:GetLineVisible(line+1) then
          local to = editor:GetLastChild(from, -1)
          editor:SetSelection(editor:PositionFromLine(from), editor:PositionFromLine(to+1))
          editor:ToggleFold(line)
        end
      end
    end)

  editor.ev = {}
  editor:Connect(wxstc.wxEVT_STC_MARGINCLICK,
    function (event)
      local line = editor:LineFromPosition(event:GetPosition())
      local header = bit.band(editor:GetFoldLevel(line),
        wxstc.wxSTC_FOLDLEVELHEADERFLAG) == wxstc.wxSTC_FOLDLEVELHEADERFLAG
      local from = header and line or editor:GetFoldParent(line)
      local marginno = event:GetMargin()
      if marginno == margin.MARKER then
        editor:BreakpointToggle(line)
      elseif marginno == margin.FOLD then
        local shift, ctrl = wx.wxGetKeyState(wx.WXK_SHIFT), wx.wxGetKeyState(wx.WXK_CONTROL)
        if shift and ctrl then
          editor:FoldSome(line)
        elseif ctrl then -- select the scope that was clicked on
          if from > -1 then -- only select if there is a block to select
            local to = editor:GetLastChild(from, -1)
            editor:SetSelection(editor:PositionFromLine(from), editor:PositionFromLine(to+1))
          end
        elseif header or shift then
          editor:ToggleFold(line)
        end
      end
    end)

  editor:Connect(wxstc.wxEVT_STC_MODIFIED,
    function (event)
      if (editor.assignscache and editor:GetCurrentLine() ~= editor.assignscache.line) then
        editor.assignscache = false
      end
      local evtype = event:GetModificationType()
      if bit.band(evtype, wxstc.wxSTC_MOD_CHANGEMARKER) == 0 then
        -- this event is being called on OSX too frequently, so skip these notifications
        editor.updated = ide:GetTime()
      end
      local pos = event:GetPosition()
      local firstLine = editor:LineFromPosition(pos)
      local inserted = bit.band(evtype, wxstc.wxSTC_MOD_INSERTTEXT) ~= 0
      local deleted = bit.band(evtype, wxstc.wxSTC_MOD_DELETETEXT) ~= 0
      if (inserted or deleted) then
        SetAutoRecoveryMark()

        local linesChanged = inserted and event:GetLinesAdded() or 0
        -- collate events if they are for the same line
        local events = #editor.ev
        if events == 0 or editor.ev[events][1] ~= firstLine then
          editor.ev[events+1] = {firstLine, linesChanged}
        elseif events > 0 and editor.ev[events][1] == firstLine then
          editor.ev[events][2] = math.max(editor.ev[events][2], linesChanged)
        end
        if editor.usedynamicwords then DynamicWordsAdd(editor, nil, firstLine, linesChanged) end
      end

      local beforeInserted = bit.band(evtype,wxstc.wxSTC_MOD_BEFOREINSERT) ~= 0
      local beforeDeleted = bit.band(evtype,wxstc.wxSTC_MOD_BEFOREDELETE) ~= 0

      if (beforeInserted or beforeDeleted) then
        -- unfold the current line being changed if folded, but only if one selection
        local lastLine = editor:LineFromPosition(pos+event:GetLength())
        local selections = ide.wxver >= "2.9.5" and editor:GetSelections() or 1
        if (not editor:GetFoldExpanded(firstLine)
          or not editor:GetLineVisible(firstLine)
          or not editor:GetLineVisible(lastLine))
        and selections == 1 then
          for line = firstLine, lastLine do
            if not editor:GetLineVisible(line) then editor:ToggleFold(editor:GetFoldParent(line)) end
          end
        end
      end

      -- hide calltip/auto-complete after undo/redo/delete
      local undodelete = (wxstc.wxSTC_MOD_DELETETEXT
        + wxstc.wxSTC_PERFORMED_UNDO + wxstc.wxSTC_PERFORMED_REDO)
      if bit.band(evtype, undodelete) ~= 0 then
        editor:DoWhenIdle(function(editor)
            if editor:CallTipActive() then editor:CallTipCancel() end
            if editor:AutoCompActive() then editor:AutoCompCancel() end
          end)
      end
      
      if ide.config.acandtip.nodynwords then return end
      -- only required to track changes

      if beforeDeleted then
        local text = editor:GetTextRangeDyn(pos, pos+event:GetLength())
        local _, numlines = text:gsub("\r?\n","%1")
        if editor.usedynamicwords then DynamicWordsRem(editor,nil,firstLine, numlines) end
      end
      if beforeInserted then
        if editor.usedynamicwords then DynamicWordsRem(editor,nil,firstLine, 0) end
      end
    end)

  editor:Connect(wxstc.wxEVT_STC_CHARADDED,
    function (event)
      local LF = string.byte("\n") -- `CHARADDED` gets `\n` code on all platforms
      local ch = event:GetKey()
      local pos = editor:GetCurrentPos()
      local line = editor:GetCurrentLine()
      local linetx = editor:GetLineDyn(line)
      local linestart = editor:PositionFromLine(line)
      local localpos = pos-linestart
      local linetxtopos = linetx:sub(1,localpos)

      if PackageEventHandle("onEditorCharAdded", editor, event) == false then
        -- this event has already been handled
      elseif (ch == LF) then
        -- auto-indent
        if (line > 0) then
          local indent = editor:GetLineIndentation(line - 1)
          local linedone = editor:GetLineDyn(line - 1)

          -- if the indentation is 0 and the current line is not empty,
          -- but the previous line is empty, then take indentation from the
          -- current line (instead of the previous one). This may happen when
          -- CR is hit at the beginning of a line (rather than at the end).
          if indent == 0 and not linetx:match("^[\010\013]*$")
          and linedone:match("^[\010\013]*$") then
            indent = editor:GetLineIndentation(line)
          end

          local ut = editor:GetUseTabs()
          local tw = ut and editor:GetTabWidth() or editor:GetIndent()
          local style = bit.band(editor:GetStyleAt(editor:PositionFromLine(line-1)), ide.STYLEMASK)

          if edcfg.smartindent
          -- don't apply smartindent to multi-line comments or strings
          and not (editor.spec.iscomment[style]
            or editor.spec.isstring[style]
            or (MarkupIsAny and MarkupIsAny(style)))
          and editor.spec.isdecindent and editor.spec.isincindent then
            local closed, blockend = editor.spec.isdecindent(linedone)
            local opened = editor.spec.isincindent(linedone)

            -- if the current block is already indented, skip reverse indenting
            if (line > 1) and (closed > 0 or blockend > 0)
            and editor:GetLineIndentation(line-2) > indent then
              -- adjust opened first; this is needed when use ENTER after })
              if blockend == 0 then opened = opened + closed end
              closed, blockend = 0, 0
            end
            editor:SetLineIndentation(line-1, indent - tw * closed)
            indent = indent + tw * (opened - blockend)
            if indent < 0 then indent = 0 end
          end
          editor:SetLineIndentation(line, indent)

          indent = ut and (indent / tw) or indent
          editor:GotoPos(editor:GetCurrentPos()+indent)
        end

      elseif ch == ("("):byte() or ch == (","):byte() then
        if ch == (","):byte() then
          -- comma requires special handling: either it's in a list of parameters
          -- and follows an opening bracket, or it does nothing
          if linetxtopos:gsub("%b()",""):find("%(") then
            linetxtopos = linetxtopos:gsub("%b()",""):gsub("%(.+,$", "(")
          else
            linetxtopos = nil
          end
        end
        local var, funccall = editor:ValueFromPosition(pos)
        local tip = GetTipInfo(editor, funccall or var, ide.config.acandtip.shorttip)
        if tip then
          if editor:CallTipActive() then editor:CallTipCancel() end
          if PackageEventHandle("onEditorCallTip", editor, tip) ~= false then
            editor:DoWhenIdle(function(editor) callTipFitAndShow(editor, pos, tip) end)
          end
        end

      elseif ide.config.autocomplete then -- code completion prompt
        local trigger = linetxtopos:match("["..editor.spec.sep.."%w_]+$")
        if trigger and (#trigger > 1 or trigger:match("["..editor.spec.sep.."]")) then
          editor:DoWhenIdle(function(editor) EditorAutoComplete(editor) end)
        end
      end
    end)

  editor:Connect(wxstc.wxEVT_STC_DWELLSTART,
    function (event)
      -- on Linux DWELLSTART event seems to be generated even for those
      -- editor windows that are not active. What's worse, when generated
      -- the event seems to report "old" position when retrieved using
      -- event:GetX and event:GetY, so instead we use wxGetMousePosition.
      local linux = ide.osname == 'Unix'
      if linux and editor ~= ide:GetEditor() then return end

      -- check if this editor has focus; it may not when Stack/Watch window
      -- is on top, but DWELL events are still triggered in this case.
      -- Don't want to show calltip as it is still shown when the focus
      -- is switched to a different application.
      local focus = editor:FindFocus()
      if focus and focus:GetId() ~= editor:GetId() then return end

      -- event:GetX() and event:GetY() positions don't correspond to
      -- the correct positions calculated using ScreenToClient (at least
      -- on Windows and Linux), so use what's calculated.
      local mpos = wx.wxGetMousePosition()
      local cpos = editor:ScreenToClient(mpos)
      local position = editor:PositionFromPointClose(cpos.x, cpos.y)
      if position ~= wxstc.wxSTC_INVALID_POSITION then
        EditorCallTip(editor, position, mpos.x, mpos.y)
      end
      event:Skip()
    end)

  editor:Connect(wxstc.wxEVT_STC_DWELLEND,
    function (event)
      if editor:CallTipActive() then editor:CallTipCancel() end
      event:Skip()
    end)

  editor:Connect(wx.wxEVT_KILL_FOCUS,
    function (event)
      -- on OSX clicking on scrollbar in the popup is causing the editor to lose focus,
      -- which causes canceling of auto-complete, which later cause crash because
      -- the window is destroyed in wxwidgets after already being closed. Skip on OSX.
      if ide.osname ~= 'Macintosh' and editor:AutoCompActive() then editor:AutoCompCancel() end

      PackageEventHandle("onEditorFocusLost", editor)
      event:Skip()
    end)

  local eol = {
    [wxstc.wxSTC_EOL_CRLF] = "\r\n",
    [wxstc.wxSTC_EOL_LF] = "\n",
    [wxstc.wxSTC_EOL_CR] = "\r",
  }
  local function addOneLine(editor, adj)
    local pos = editor:GetLineEndPosition(editor:LineFromPosition(editor:GetCurrentPos())+(adj or 0))
    local added = eol[editor:GetEOLMode()] or "\n"
    editor:InsertTextDyn(pos, added)
    editor:SetCurrentPos(pos+#added)

    local ev = wxstc.wxStyledTextEvent(wxstc.wxEVT_STC_CHARADDED)
    ev:SetKey(string.byte("\n"))
    editor:AddPendingEvent(ev)
  end

  editor:Connect(wxstc.wxEVT_STC_USERLISTSELECTION,
    function (event)
      if PackageEventHandle("onEditorUserlistSelection", editor, event) == false then
        return
      end

      -- if used Shift-Enter, then skip auto complete and just do Enter.
      -- `lastkey` comparison can be replaced with checking `listCompletionMethod`,
      -- but it's not exposed in wxSTC (as of wxwidgets 3.1.1)
      if wx.wxGetKeyState(wx.WXK_SHIFT) and editor.lastkey == ("\r"):byte() then
        return addOneLine(editor)
      end

      if ide.wxver >= "2.9.5" and editor:GetSelections() > 1 then
        local text = event:GetText()
        -- capture all positions as the selection may change
        local positions = {}
        for s = 0, editor:GetSelections()-1 do
          table.insert(positions, editor:GetSelectionNCaret(s))
        end
        -- process all selections from last to first
        table.sort(positions)
        local mainpos = editor:GetSelectionNCaret(editor:GetMainSelection())

        editor:BeginUndoAction()
        for s = #positions, 1, -1 do
          local pos = positions[s]
          local startpos = editor:WordStartPosition(pos, true)
          editor:SetSelection(startpos, pos)
          editor:ReplaceSelection(text)
          -- if this is the main position, save new cursor position to restore
          if pos == mainpos then mainpos = editor:GetCurrentPos()
          elseif pos < mainpos then
            -- adjust main position as earlier changes may affect it
            mainpos = mainpos + #text - (pos - startpos)
          end
        end
        editor:EndUndoAction()

        editor:GotoPos(mainpos)
      else
        local pos = editor:GetCurrentPos()
        local startpos = editor:WordStartPosition(pos, true)
        local endpos = editor:WordEndPosition(pos, true)
        editor:SetSelection(startpos, ide.config.acandtip.droprest and endpos or pos)
        editor:ReplaceSelection(event:GetText())
      end
    end)

  local function updateModified()
    local update = function()
      local doc = ide:GetDocument(editor)
      if doc then doc:SetTabText() end
    end
    -- delay update on Unix/Linux as it seems to hang the application on ArchLinux;
    -- execute immediately on other platforms
    if ide.osname == "Unix" then editor:DoWhenIdle(update) else update() end
  end
  editor:Connect(wxstc.wxEVT_STC_SAVEPOINTREACHED, updateModified)
  editor:Connect(wxstc.wxEVT_STC_SAVEPOINTLEFT, updateModified)

  -- "updateStatusText" should be called in UPDATEUI event, but it creates
  -- several performance problems on Windows (using wx2.9.5+) when
  -- brackets or backspace is used (very slow screen repaint with 0.5s delay).
  -- Moving it to PAINTED event creates problems on OSX (using wx2.9.5+),
  -- where refresh of R/W and R/O status in the status bar is delayed.
  editor:Connect(wxstc.wxEVT_STC_PAINTED,
    function (event)
      PackageEventHandle("onEditorPainted", editor, event)

      if ide.osname == 'Windows' then
        -- STC_PAINTED is called on multiple editors when they point to
        -- the same document; only update status for the active one
        if notebook:GetSelection() == notebook:GetPageIndex(editor) then
          updateStatusText(editor)
        end

        if edcfg.usewrap ~= true and editor:AutoCompActive() then
          -- showing auto-complete list leaves artifacts on the screen,
          -- which can only be fixed by a forced refresh.
          -- shows with wxSTC 3.21 and both wxwidgets 2.9.5 and 3.1
          editor:Update()
          editor:Refresh()
        end
      end

      -- adjust line number margin, but only if it's already shown
      local linecount = #tostring(editor:GetLineCount()) + 0.5
      local mwidth = editor:GetMarginWidth(margin.LINENUMBER)
      if mwidth > 0 then
        local width = math.max(linecount, linenumlen) * editor:TextWidth(wxstc.wxSTC_STYLE_DEFAULT, "8")
        if mwidth ~= width then editor:SetMarginWidth(margin.LINENUMBER, math.floor(width)) end
      end
    end)

  editor.processedUpdateContent = 0
  editor:Connect(wxstc.wxEVT_STC_UPDATEUI,
    function (event)
      -- some of UPDATEUI events may be triggered as the result of editor updates
      -- from subsequent events (like PAINTED, which happens in documentmap plugin).
      -- the reason for the `processed` check is that it is not possible
      -- to completely skip all of these updates as this causes the issue
      -- of markup styling becoming visible after text deletion by Backspace.
      -- to avoid this, we allow the first update after any updates caused
      -- by real changes; the rest of UPDATEUI events are skipped.
      -- (use direct comparison, as need to skip events that just update content)
      if event:GetUpdated() == wxstc.wxSTC_UPDATE_CONTENT
      and not next(editor.ev) then
         if editor.processedUpdateContent > 1 then return end
      else
         editor.processedUpdateContent = 0
      end
      editor.processedUpdateContent = editor.processedUpdateContent + 1

      PackageEventHandle("onEditorUpdateUI", editor, event)

      if ide.osname ~= 'Windows' then updateStatusText(editor) end

      editor:GotoPosDelayed()
      updateBraceMatch(editor)
      local minupdated
      for _,iv in ipairs(editor.ev) do
        local line = iv[1]
        if not minupdated or line < minupdated then minupdated = line end
        IndicateFunctionsOnly(editor,line,line+iv[2])
      end
      if minupdated then
        local ok, res = pcall(indicateSymbols, editor, minupdated)
        if not ok then ide:Print("Internal error: ",res,minupdated) end
      end
      local firstvisible = editor:GetFirstVisibleLine()
      local firstline = editor:DocLineFromVisible(firstvisible)
      local lastline = editor:DocLineFromVisible(firstvisible + editor:LinesOnScreen())
      -- cap last line at the number of lines in the document
      MarkupStyle(editor, minupdated or firstline, math.min(editor:GetLineCount(),lastline))
      editor.ev = {}
    end)

  editor:Connect(wx.wxEVT_IDLE,
    function (event)
      while #editor.onidle > 0 do table.remove(editor.onidle, 1)(editor) end
    end)

  editor:Connect(wx.wxEVT_LEFT_DOWN,
    function (event)
      if MarkupHotspotClick then
        local position = editor:PositionFromPointClose(event:GetX(),event:GetY())
        if position ~= wxstc.wxSTC_INVALID_POSITION then
          if MarkupHotspotClick(position, editor) then return end
        end
      end

      if event:ControlDown() and event:AltDown()
      -- ide.wxver >= "2.9.5"; fix after GetModifiers is added to wxMouseEvent in wxlua
      and not event:ShiftDown() and not event:MetaDown() then
        local point = event:GetPosition()
        local pos = editor:PositionFromPointClose(point.x, point.y)
        local value = pos ~= wxstc.wxSTC_INVALID_POSITION and editor:ValueFromPosition(pos) or nil
        local instances = value and indicateFindInstances(editor, value, pos+1)
        if instances and instances[0] then
          navigateToPosition(editor, pos, instances[0]-1, #value)
          return
        end
      end
      event:Skip()
    end)

  if edcfg.nomousezoom then
    -- disable zoom using mouse wheel as it triggers zooming when scrolling
    -- on OSX with kinetic scroll and then pressing CMD.
    editor:Connect(wx.wxEVT_MOUSEWHEEL,
      function (event)
        if wx.wxGetKeyState(wx.WXK_CONTROL) then return end
        event:Skip()
      end)
  end

  local inhandler = false
  editor:Connect(wx.wxEVT_SET_FOCUS,
    function (event)
      event:Skip()
      if inhandler or ide.exitingProgram then return end
      inhandler = true
      PackageEventHandle("onEditorFocusSet", editor)
      isFileAlteredOnDisk(editor)
      inhandler = false
    end)

  editor:Connect(wx.wxEVT_KEY_DOWN,
    function (event)
      local keycode = event:GetKeyCode()
      local mod = event:GetModifiers()
      if PackageEventHandle("onEditorKeyDown", editor, event) == false then
        -- this event has already been handled
        return
      elseif keycode == wx.WXK_ESCAPE then
        if editor:CallTipActive() or editor:AutoCompActive() then
          event:Skip()
        elseif ide.findReplace:IsShown() then
          ide.findReplace:Hide()
        elseif ide:GetMainFrame():IsFullScreen() then
          ide:ShowFullScreen(false)
        end
      -- Ctrl-Home and Ctrl-End don't work on OSX with 2.9.5+; fix it
      elseif ide.osname == 'Macintosh' and ide.wxver >= "2.9.5"
        and (mod == wx.wxMOD_RAW_CONTROL or mod == (wx.wxMOD_RAW_CONTROL + wx.wxMOD_SHIFT))
        and (keycode == wx.WXK_HOME or keycode == wx.WXK_END) then
        local pos = keycode == wx.WXK_HOME and 0 or editor:GetLength()
        if event:ShiftDown() -- mark selection and scroll to caret
        then editor:SetCurrentPos(pos) editor:EnsureCaretVisible()
        else editor:GotoPos(pos) end
      elseif (keycode == wx.WXK_DELETE or keycode == wx.WXK_BACK)
        and (mod == wx.wxMOD_NONE) then
        -- Delete and Backspace behave the same way for selected text
        if #(editor:GetSelectedText()) > 0 then
          editor:ClearAny()
        else
          local pos = editor:GetCurrentPos()
          if keycode == wx.WXK_BACK then
            pos = pos - 1
            if pos < 0 then return end
          end

          -- check if the modification is to one of "invisible" characters.
          -- if not, proceed with "normal" processing as there are other
          -- events that may depend on Backspace, for example, re-calculating
          -- auto-complete suggestions.
          local style = bit.band(editor:GetStyleAt(pos), ide.STYLEMASK)
          if not MarkupIsSpecial or not MarkupIsSpecial(style) then
            event:Skip()
            return
          end

          editor:SetTargetStart(pos)
          editor:SetTargetEnd(pos+1)
          editor:ReplaceTarget("")
        end
      elseif mod == wx.wxMOD_ALT and keycode == wx.WXK_LEFT then
        -- if no "jump back" is needed, then do normal processing as this
        -- combination can be mapped to some action
        if not navigateBack(editor) then event:Skip() end
      elseif (keycode == wx.WXK_RETURN or keycode == wx.WXK_NUMPAD_ENTER)
      and (mod == wx.wxMOD_CONTROL or mod == (wx.wxMOD_CONTROL + wx.wxMOD_SHIFT)) then
        addOneLine(editor, mod == (wx.wxMOD_CONTROL + wx.wxMOD_SHIFT) and -1 or 0)
      elseif ide.osname == "Unix" and ide.wxver >= "2.9.5"
      and editor.ctrlcache[keycode..mod] then
        ide.frame:AddPendingEvent(wx.wxCommandEvent(
          wx.wxEVT_COMMAND_MENU_SELECTED, editor.ctrlcache[keycode..mod]))
      else
        if ide.osname == 'Macintosh' and mod == wx.wxMOD_META then
          return -- ignore a key press if Command key is also pressed
        end
        event:Skip()
      end

      editor.lastkey = keycode
    end)

  local function selectAllInstances(instances, name, curpos)
    local this
    local idx = 0
    for _, pos in pairs(instances) do
      pos = pos - 1 -- positions are 0-based in Scintilla
      if idx == 0 then
        -- clear selections first as there seems to be a bug (Scintilla 3.2.3)
        -- that doesn't reset selection after right mouse click.
        editor:ClearSelections()
        editor:SetSelection(pos, pos+#name)
      else
        editor:AddSelection(pos+#name, pos)
      end

      -- check if this is the current selection
      if curpos >= pos and curpos <= pos+#name then this = idx end
      idx = idx + 1
    end
    if this then editor:SetMainSelection(this) end
    -- set the current name as the search value to make subsequence searches look for it
    ide.findReplace:SetFind(name)
  end

  editor:Connect(wxstc.wxEVT_STC_DOUBLECLICK,
    function(event)
      -- only activate selection of instances on Ctrl/Cmd-DoubleClick
      if event:GetModifiers() == wx.wxMOD_CONTROL then
        local pos = event:GetPosition()
        local value = pos ~= wxstc.wxSTC_INVALID_POSITION and editor:ValueFromPosition(pos) or nil
        local instances = value and indicateFindInstances(editor, value, pos+1)
        if instances and (instances[0] or #instances > 0) then
          selectAllInstances(instances, value, pos)
          return
        end
      end

      event:Skip()
    end)

  editor:Connect(wxstc.wxEVT_STC_ZOOM,
    function(event)
      -- if Shift+Zoom is used, then zoom all editors, not just the current one
      if wx.wxGetKeyState(wx.WXK_SHIFT) then
        local zoom = editor:GetZoom()
        for _, doc in pairs(ide:GetDocuments()) do
          -- check the editor zoom level to avoid recursion
          if doc:GetEditor():GetZoom() ~= zoom then doc:GetEditor():SetZoom(zoom) end
        end
      end
      event:Skip()
    end)

  if ide.osname == "Windows" then
    editor:DragAcceptFiles(true)
    editor:Connect(wx.wxEVT_DROP_FILES, function(event)
        local files = event:GetFiles()
        if not files or #files == 0 then return end
        -- activate all files/directories one by one
        for _, filename in ipairs(files) do ide:ActivateFile(filename) end
      end)
  elseif ide.osname == "Unix" then
    editor:Connect(wxstc.wxEVT_STC_DO_DROP, function(event)
        local dropped = event:GetText()
        -- this event may get a list of files separated by \n (and the list ends in \n as well),
        -- so check if what's dropped looks like this list
        if dropped:find("^file://.+\n$") then
          for filename in dropped:gmatch("file://(.-)\n") do ide:ActivateFile(filename) end
          event:SetDragResult(wx.wxDragCancel) -- cancel the drag to not paste the text
        end
      end)
  end

  local pos
  local function getPositionValues()
    local p = pos or editor:GetCurrentPos()
    local value = p ~= wxstc.wxSTC_INVALID_POSITION and editor:ValueFromPosition(p) or nil
    local instances = value and indicateFindInstances(editor, value, p+1)
    return p, value, instances
  end
  editor:Connect(wx.wxEVT_CONTEXT_MENU,
    function (event)
      local point = editor:ScreenToClient(event:GetPosition())
      -- capture the position of the click to use in handlers later
      pos = editor:PositionFromPoint(point)
      if pos == 0 and (point:GetX() < 0 or point:GetY() < 0) then pos = nil end

      local _, _, instances = getPositionValues()
      local occurrences = (not instances or #instances == 0) and ""
        or (" (%d)"):format(#instances+(instances[0] and 1 or 0))
      local line = instances and instances[0] and editor:LineFromPosition(instances[0]-1)+1
      local def =  line and " ("..TR("on line %d"):format(line)..")" or ""
      local menu = ide:MakeMenu {
        { ID.UNDO, TR("&Undo")..KSC(ID.UNDO) },
        { ID.REDO, TR("&Redo")..KSC(ID.REDO) },
        { },
        { ID.CUT, TR("Cu&t")..KSC(ID.CUT) },
        { ID.COPY, TR("&Copy")..KSC(ID.COPY) },
        { ID.PASTE, TR("&Paste")..KSC(ID.PASTE) },
        { ID.SELECTALL, TR("Select &All")..KSC(ID.SELECTALL) },
        { },
        { ID.GOTODEFINITION, TR("Go To Definition")..def..KSC(ID.GOTODEFINITION) },
        { ID.RENAMEALLINSTANCES, TR("Rename All Instances")..occurrences..KSC(ID.RENAMEALLINSTANCES) },
        { ID.REPLACEALLSELECTIONS, TR("Replace All Selections")..KSC(ID.REPLACEALLSELECTIONS) },
        { },
        { ID.QUICKADDWATCH, TR("Add Watch Expression")..KSC(ID.QUICKADDWATCH) },
        { ID.QUICKEVAL, TR("Evaluate In Console")..KSC(ID.QUICKEVAL) },
        { ID.ADDTOSCRATCHPAD, TR("Add To Scratchpad")..KSC(ID.ADDTOSCRATCHPAD) },
        { ID.RUNTO, TR("Run To Cursor")..KSC(ID.RUNTO) },
      }
      -- disable calltips that could open over the menu
      local dwelltime = editor:GetMouseDwellTime()
      editor:SetMouseDwellTime(0) -- disable dwelling

      -- cancel calltip if it's already shown as it interferes with popup menu
      if editor:CallTipActive() then editor:CallTipCancel() end

      PackageEventHandle("onMenuEditor", menu, editor, event)

      -- popup statuses are not refreshed on Linux, so do it manually
      if ide.osname == "Unix" then UpdateMenuUI(menu, editor) end

      editor:PopupMenu(menu)
      editor:SetMouseDwellTime(dwelltime) -- restore dwelling
      pos = nil -- reset the position
    end)

  editor:Connect(ID.RUNTO, wx.wxEVT_COMMAND_MENU_SELECTED,
    function()
      local pos = getPositionValues()
      if pos and pos ~= wxstc.wxSTC_INVALID_POSITION then
        ide:GetDebugger():RunTo(editor, editor:LineFromPosition(pos)+1)
      end
    end)

  editor:Connect(ID.GOTODEFINITION, wx.wxEVT_UPDATE_UI, function(event)
      local _, _, instances = getPositionValues()
      event:Enable(instances and instances[0])
    end)
  editor:Connect(ID.GOTODEFINITION, wx.wxEVT_COMMAND_MENU_SELECTED,
    function(event)
      local _, value, instances = getPositionValues()
      if value and instances[0] then
        navigateToPosition(editor, editor:GetCurrentPos(), instances[0]-1, #value)
      end
    end)

  editor:Connect(ID.RENAMEALLINSTANCES, wx.wxEVT_UPDATE_UI, function(event)
      local _, _, instances = getPositionValues()
      event:Enable(instances and (instances[0] or #instances > 0)
        or editor:GetSelectionStart() ~= editor:GetSelectionEnd())
    end)
  editor:Connect(ID.RENAMEALLINSTANCES, wx.wxEVT_COMMAND_MENU_SELECTED,
    function(event)
      local pos, value, instances = getPositionValues()
      if value and pos then
        if not (instances and (instances[0] or #instances > 0)) then
          -- if multiple instances (of a variable) are not detected,
          -- then simply find all instances of (selected) `value`
          instances = {}
          local length, pos = editor:GetLength(), 0
          while true do
            editor:SetTargetStart(pos)
            editor:SetTargetEnd(length)
            pos = editor:SearchInTarget(value)
            if pos == wx.wxNOT_FOUND then break end
            table.insert(instances, pos+1)
            pos = pos + #value
          end
        end
        selectAllInstances(instances, value, pos)
      end
    end)

  editor:Connect(ID.REPLACEALLSELECTIONS, wx.wxEVT_UPDATE_UI, function(event)
      event:Enable((ide.wxver >= "2.9.5" and editor:GetSelections() or 1) > 1)
    end)
  editor:Connect(ID.REPLACEALLSELECTIONS, wx.wxEVT_COMMAND_MENU_SELECTED,
    function(event)
      local main = editor:GetMainSelection()
      local text = wx.wxGetTextFromUser(
        TR("Enter replacement text"),
        TR("Replace All Selections"),
        editor:GetTextRangeDyn(editor:GetSelectionNStart(main), editor:GetSelectionNEnd(main))
      )
      if not text or text == "" then return end

      editor:BeginUndoAction()
      for s = 0, editor:GetSelections()-1 do
        local selst, selend = editor:GetSelectionNStart(s), editor:GetSelectionNEnd(s)
        editor:SetTargetStart(selst)
        editor:SetTargetEnd(selend)
        editor:ReplaceTarget(text)
        editor:SetSelectionNStart(s, selst)
        editor:SetSelectionNEnd(s, selst+#text)
      end
      editor:EndUndoAction()
      editor:SetMainSelection(main)
    end)

  editor:Connect(ID.QUICKADDWATCH, wx.wxEVT_UPDATE_UI, function(event)
      local _, value = getPositionValues()
      event:Enable(value ~= nil)
    end)
  editor:Connect(ID.QUICKADDWATCH, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)
      local _, value = getPositionValues()
      ide:AddWatch(value)
    end)

  editor:Connect(ID.QUICKEVAL, wx.wxEVT_UPDATE_UI, function(event)
      local _, value = getPositionValues()
      event:Enable(value ~= nil)
    end)
  editor:Connect(ID.QUICKEVAL, wx.wxEVT_COMMAND_MENU_SELECTED, function(event)
      local _, value = getPositionValues()
      ShellExecuteCode(value)
    end)

  editor:Connect(ID.ADDTOSCRATCHPAD, wx.wxEVT_UPDATE_UI, function(event)
      local debugger = ide:GetDebugger()
      event:Enable(debugger.scratchpad
        and debugger.scratchpad.editors and not debugger.scratchpad.editors[editor])
    end)
  editor:Connect(ID.ADDTOSCRATCHPAD, wx.wxEVT_COMMAND_MENU_SELECTED,
    function(event) ide:GetDebugger():ScratchpadOn(editor) end)

  return editor
end

-- ----------------------------------------------------------------------------
-- Add an editor to the notebook
function AddEditor(editor, name)
  assert(notebook:GetPageIndex(editor) == wx.wxNOT_FOUND, "Editor being added is not in the notebook: failed")

  -- set the document properties
  local document = ide:CreateDocument(editor, name)

  -- add page only after document is created as there may be handlers
  -- that expect the document (for example, onEditorFocusSet)
  if not notebook:AddPage(editor, name, true) then
    ide:RemoveDocument(editor)
    return
  else
    document:SetTabText(name)
    return document
  end
end

local lexlpegmap = {
  text = {"identifier"},
  lexerdef = {"nothing"},
  comment = {"comment"},
  stringtxt = {"string","longstring"},
  preprocessor= {"preprocessor","embedded"},
  operator = {"operator"},
  number = {"number"},
  keywords0 = {"keyword"},
  keywords1 = {"constant","variable"},
  keywords2 = {"function","regex"},
  keywords3 = {"library","class","type"},
}
local function cleanup(paths)
  for _, path in ipairs(paths) do
    if not FileRemove(path) then wx.wxRmdir(path) end
  end
end
local function setLexLPegLexer(editor, spec)
  local lexername = spec.lexer
  local lexer = lexername:gsub("^lexlpeg%.","")

  local ppath = package.path
  local lpath = ide:GetRootPath("lualibs/lexers")

  package.path = MergeFullPath(lpath, "?.lua") -- update `package.path` to reference `lexers/`
  local ok, lex = pcall(require, "lexer")
  package.path = ppath -- restore the original `package.path`
  if not ok then return nil, "Can't load LexLPeg lexer components: "..lex end

  -- if the requested lexer is a dynamically registered one, then need to create a file for it,
  -- as LexLPeg lexers are loaded in a separate Lua state, which this process has no contol over.
  local dynlexer, dynfile = ide:GetLexer(lexername), nil
  local tmppath = MergeFullPath(wx.wxStandardPaths.Get():GetTempDir(),
    "lexer-"..wx.wxGetLocalTimeMillis():ToString())
  if dynlexer then
    local ok, err = CreateFullPath(tmppath)
    if not ok then return nil, err end
    -- update lex.LEXERPATH to search there
    lex.LEXERPATH = MergeFullPath(tmppath, "?.lua")
    dynfile = MergeFullPath(tmppath, lexer..".lua")
    -- save the file to the temp folder
    ok, err = FileWrite(dynfile, dynlexer)
    if not ok then cleanup({tmppath}); return nil, err end
  end
  local ok, err = pcall(lex.load, lexer)
  if dynlexer then cleanup({dynfile, tmppath}) end
  if not ok then return nil, (err:gsub(".+lexer%.lua:%d+:%s*","")) end
  local lexmod = err

  local lexpath = package.searchpath("lexlpeg", ide.osclibs)
  if not lexpath then return nil, "Can't find LexLPeg lexer." end

  do
    local err = wx.wxSysErrorCode()
    local _ = wx.wxLogNull() -- disable error reporting; will report as needed
    local loaded = pcall(function() editor:LoadLexerLibrary(lexpath) end)
    if not loaded then return nil, "Can't load LexLPeg library." end
    -- the error code may be non-zero, but still needs to be different from the previous one
    -- as it may report non-zero values on Windows (for example, 1447) when no error is generated
    local newerr = wx.wxSysErrorCode()
    if newerr > 0 and newerr ~= err then return nil, wx.wxSysErrorMsg() end
  end

  if dynlexer then
    local ok, err = CreateFullPath(tmppath)
    if not ok then return nil, err end
    -- copy lexer.lua to the temp folder
    ok, err = FileCopy(MergeFullPath(lpath, "lexer.lua"), MergeFullPath(tmppath, "lexer.lua"))
    if not ok then return nil, err end
    -- save the file to the temp folder
    ok, err = FileWrite(dynfile, dynlexer)
    if not ok then FileRemove(MergeFullPath(tmppath, "lexer.lua")); return nil, err end
    -- update lpath to point to the temp folder
    lpath = tmppath
  end

  -- temporarily set the enviornment variable to load the new lua state with proper paths
  -- do here as the Lua state in LexLPeg parser is initialized furing `SetLexerLanguage` call
  local ok, cpath = wx.wxGetEnv("LUA_CPATH")
  if ok then wx.wxSetEnv("LUA_CPATH", ide.osclibs) end
  editor:SetLexerLanguage("lpeg")
  editor:SetProperty("lexer.lpeg.home", lpath)
  editor:PrivateLexerCall(wxstc.wxSTC_SETLEXERLANGUAGE, lexer) --[[ SetLexerLanguage for LexLPeg ]]
  if ok then wx.wxSetEnv("LUA_CPATH", cpath) end

  if dynlexer then cleanup({dynfile, MergeFullPath(tmppath, "lexer.lua"), tmppath}) end

  local styleconvert = {}
  for name, map in pairs(lexlpegmap) do
    styleconvert[name] = {}
    for _, stylename in ipairs(map) do
      if lexmod._TOKENSTYLES[stylename] then
        table.insert(styleconvert[name], lexmod._TOKENSTYLES[stylename])
      end
    end
  end
  spec.lexerstyleconvert = styleconvert
  -- assign line comment value based on the values in the lexer comment table
  for k, v in pairs(lexmod._foldsymbols and lexmod._foldsymbols.comment or {}) do
    if type(v) == 'function' then spec.linecomment = k end
  end
  return true
end

function SetupKeywords(editor, ext, forcespec, styles, font, fontitalic)
  local lexerstyleconvert = nil
  local spec = forcespec or ide:FindSpec(ext, editor:GetLine(0))
  -- found a spec setup lexers and keywords
  if spec and editor.spec == spec then return end
  if spec then
    if type(spec.lexer) == "string" then
      local ok, err = setLexLPegLexer(editor, spec)
      if not ok then
        spec.lexerstyleconvert = {}
        ide:Print(("Can't load LexLPeg '%s' lexer: %s"):format(spec.lexer, err))
        editor:SetLexer(wxstc.wxSTC_LEX_NULL)
      end
      UpdateSpecs(spec)
    else
      editor:SetLexer(spec.lexer or wxstc.wxSTC_LEX_NULL)
    end
    lexerstyleconvert = spec.lexerstyleconvert

    if (spec.keywords) then
      for i,words in ipairs(spec.keywords) do
        editor:SetKeyWords(i-1,words)
      end
    end

    editor.api = GetApi(spec.apitype or "none")
    editor.spec = spec
  else
    editor:SetLexer(wxstc.wxSTC_LEX_NULL)
    editor:SetKeyWords(0, "")

    editor.api = GetApi("none")
    editor.spec = ide.specs.none
  end

  -- need to set folding property after lexer is set, otherwise
  -- the folds are not shown (wxwidgets 2.9.5)
  editor:SetProperty("fold", edcfg.fold and "1" or "0")
  if edcfg.fold then
    editor:SetProperty("fold.compact", edcfg.foldcompact and "1" or "0")
    editor:SetProperty("fold.comment", "1")
    editor:SetProperty("fold.line.comments", "1")
  end
  
  -- quickfix to prevent weird looks, otherwise need to update styling mechanism for cpp
  -- cpp "greyed out" styles are `styleid + 64`
  editor:SetProperty("lexer.cpp.track.preprocessor", "0")
  editor:SetProperty("lexer.cpp.update.preprocessor", "0")

  StylesApplyToEditor(styles or ide.config.styles, editor, font, fontitalic, lexerstyleconvert)
end
