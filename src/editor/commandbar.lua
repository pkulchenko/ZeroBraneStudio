-- Copyright 2011-18 Paul Kulchenko, ZeroBrane LLC
---------------------------------------------------------

local ide = ide
local q = EscapeMagic
local unpack = table.unpack or unpack

local dc = wx.wxMemoryDC()
local function getFontHeight(font)
  dc:SetFont(font)
  local _, h = dc:GetTextExtent("AZ")
  dc:SetFont(wx.wxNullFont)
  return h
end

local pending
local function pendingInput()
  if ide.osname ~= 'Unix' then
    ide:GetApp():SafeYieldFor(wx.NULL, wx.wxEVT_CATEGORY_USER_INPUT + wx.wxEVT_CATEGORY_UI)
  end
  return pending
end
local showProgress
local function showCommandBar(params)
  local onDone, onUpdate, onItem, onSelection, defaultText, selectedText =
    params.onDone, params.onUpdate, params.onItem, params.onSelection,
    params.defaultText, params.selectedText
  local row_width = ide.config.commandbar.width or 0
  if row_width < 1 then
    row_width = math.max(450, math.floor(row_width * ide:GetMainFrame():GetClientSize():GetWidth()))
  end

  local maxlines = ide.config.commandbar.maxlines
  local lines = {}
  local linenow = 0

  local sash = ide:GetUIManager():GetArtProvider():GetMetric(wxaui.wxAUI_DOCKART_SASH_SIZE)
  local border = sash + 2

  local nb = ide:GetEditorNotebook()
  local pos = nb:GetScreenPosition()
  if pos then
    local minx, miny
    for p = 0, nb:GetPageCount()-1 do
      local sp = nb:GetPage(p):GetScreenPosition()
      local x, y = sp:GetX(), sp:GetY()
      -- just in case, compare with the position of the notebook itself;
      -- this is needed because the tabs that haven't been refreshed yet
      -- may report 0 as their screen position on Linux, which is incorrect.
      if y > pos:GetY() and (not miny or y < miny) then miny = y end
      if x > pos:GetX() and (not minx or x < minx) then minx = x end
    end
    local anchorx = pos:GetX()+nb:GetClientSize():GetWidth()-row_width-16
    local cp = nb:GetCurrentPage()
    if cp and cp:GetScreenPosition():GetX() ~= minx then
      anchorx = pos:GetX()+border
    end
    pos:SetX(anchorx)
    pos:SetY((miny or pos:GetY())+2)
  else
    pos = wx.wxDefaultPosition
  end

  local tempctrl = ide:IsValidCtrl(ide:GetProjectTree()) and ide:GetProjectTree() or wx.wxTreeCtrl()
  local tfont = tempctrl:GetFont()
  local ffont = (ide:GetEditor() or ide:CreateBareEditor()):GetFont()
  ffont:SetPointSize(ffont:GetPointSize()+2)
  local sfont = wx.wxFont(tfont)
  tfont:SetPointSize(tfont:GetPointSize()+2)

  local hoffset = 4
  local voffset = 2

  local line_height = getFontHeight(ffont)
  local row_height = line_height + getFontHeight(sfont) + voffset * 3 -- before, after, and between

  local frame = wx.wxFrame(ide:GetMainFrame(), wx.wxID_ANY, "Command Bar",
    pos, wx.wxDefaultSize,
    wx.wxFRAME_NO_TASKBAR + wx.wxFRAME_FLOAT_ON_PARENT + wx.wxNO_BORDER)
  local panel = wx.wxPanel(frame or ide:GetMainFrame(), wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxFULL_REPAINT_ON_RESIZE)
  local search = wx.wxTextCtrl(panel, wx.wxID_ANY, "\1",
    wx.wxDefaultPosition,
    -- make the text control proportional to the font size
    wx.wxSize(row_width, getFontHeight(tfont) + voffset),
    wx.wxTE_PROCESS_ENTER + wx.wxTE_PROCESS_TAB + wx.wxNO_BORDER)
  local results = wx.wxScrolledWindow(panel, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxSize(0, 0))

  local style, styledef = ide.config.styles, StylesGetDefault()
  local textcolor = wx.wxColour(unpack(style.text.fg or styledef.text.fg))
  local backcolor = wx.wxColour(unpack(style.text.bg or styledef.text.bg))
  local selcolor = wx.wxColour(unpack(style.caretlinebg.bg or styledef.caretlinebg.bg))
  local pancolor = ide:GetUIManager():GetArtProvider():GetColour(wxaui.wxAUI_DOCKART_SASH_COLOUR)
  local borcolor = ide:GetUIManager():GetArtProvider():GetColour(wxaui.wxAUI_DOCKART_BORDER_COLOUR)

  search:SetBackgroundColour(backcolor)
  search:SetForegroundColour(textcolor)
  search:SetFont(tfont)

  local nbrush = wx.wxBrush(backcolor, wx.wxSOLID)
  local sbrush = wx.wxBrush(selcolor, wx.wxSOLID)
  local bbrush = wx.wxBrush(pancolor, wx.wxSOLID)
  local lpen = wx.wxPen(borcolor, 1, wx.wxDOT)
  local bpen = wx.wxPen(borcolor, 1, wx.wxSOLID)
  local npen = wx.wxPen(backcolor, 1, wx.wxSOLID)

  local topSizer = wx.wxFlexGridSizer(2, 1, -border*2, 0)
  topSizer:SetFlexibleDirection(wx.wxVERTICAL)
  topSizer:AddGrowableRow(1, 1)
  topSizer:Add(search, wx.wxSizerFlags(0):Expand():Border(wx.wxALL, border))
  topSizer:Add(results, wx.wxSizerFlags(1):Expand():Border(wx.wxALL, border))
  panel:SetSizer(topSizer)
  topSizer:Fit(frame) -- fit the frame/panel around the controls

  local minheight = frame:GetClientSize():GetHeight()

  -- make a one-time callback;
  -- needed because KILL_FOCUS handler can be called after closing window
  local function onExit(index)
    -- delay destroying the frame until all the related processing is done
    ide:DoWhenIdle(function() if ide:IsValidCtrl(frame) then frame:Destroy() end end)

    onExit = function() end
    onDone(index and lines[index], index, search:GetValue())
  end

  local linesnow
  local function onPaint(event)
    if not ide:IsValidCtrl(frame) then return end

    -- adjust the scrollbar before working with the canvas
    local _, starty = results:GetViewStart()
    -- recalculate the scrollbars if the number of lines shown has changed
    if #lines ~= linesnow then
      -- adjust the starting line when the current line is the last one
      if linenow > starty+maxlines then starty = starty + 1 end
      results:SetScrollbars(1, row_height, 1, #lines, 0, starty*row_height, false)
      linesnow = #lines
    end

    local dc = wx.wxMemoryDC(results)
    results:PrepareDC(dc)

    local size = results:GetVirtualSize()
    local w,h = size:GetWidth(),size:GetHeight()
    local bitmap = wx.wxBitmap(w,h)
    dc:SelectObject(bitmap)

    -- clear the background
    dc:SetBackground(nbrush)
    dc:Clear()

    dc:SetTextForeground(textcolor)
    dc:SetBrush(sbrush)
    for r = 1, #lines do
      if r == linenow then
        dc:SetPen(wx.wxTRANSPARENT_PEN)
        dc:DrawRectangle(0, row_height*(r-1), row_width, row_height+1)
      end
      dc:SetPen(lpen)
      dc:DrawLine(hoffset, row_height*(r-1), row_width-hoffset*2, row_height*(r-1))

      local fline, sline = onItem(lines[r])
      if fline then
        dc:SetFont(ffont)
        dc:DrawText(fline, hoffset, row_height*(r-1)+voffset)
      end
      if sline then
        dc:SetFont(sfont)
        dc:DrawText(sline, hoffset, row_height*(r-1)+line_height+voffset*2)
      end
    end

    dc:SetPen(wx.wxNullPen)
    dc:SetBrush(wx.wxNullBrush)
    dc:SelectObject(wx.wxNullBitmap)
    dc:delete()

    dc = wx.wxPaintDC(results)
    dc:DrawBitmap(bitmap, 0, 0, true)
    dc:delete()
  end

  local progress = 0
  showProgress = function(newprogress)
    progress = newprogress
    if not ide:IsValidCtrl(panel) then return end
    panel:Refresh()
    panel:Update()
  end

  local function onPanelPaint(event)
    if not ide:IsValidCtrl(frame) then return end

    local dc = wx.wxBufferedPaintDC(panel)
    dc:SetBrush(bbrush)
    dc:SetPen(bpen)

    local psize = panel:GetClientSize()
    dc:DrawRectangle(0, 0, psize:GetWidth(), psize:GetHeight())
    dc:DrawRectangle(sash+1, sash+1, psize:GetWidth()-2*(sash+1), psize:GetHeight()-2*(sash+1))

    if progress > 0 then
      dc:SetBrush(nbrush)
      dc:SetPen(npen)
      dc:DrawRectangle(sash+2, 1, math.floor((row_width-4)*progress), sash)
    end

    dc:SetPen(wx.wxNullPen)
    dc:SetBrush(wx.wxNullBrush)
    dc:delete()
  end

  local linewas -- line that was reported when updated
  local function onTextUpdated()
    if ide:IsValidProperty(ide:GetApp(), "GetMainLoop") then
      pending = ide:GetApp():GetMainLoop():IsYielding()
    end
    if pending then return end

    local text = search:GetValue()
    lines = onUpdate(text)
    linenow = #text > 0 and #lines > 0 and 1 or 0
    linewas = nil

    -- the control can disappear during onUpdate as it can be closed, so check for that
    if not ide:IsValidCtrl(frame) then return end

    local size = frame:GetClientSize()
    local height = minheight + row_height*math.min(maxlines,#lines)
    if height ~= size:GetHeight() then
      results:SetScrollbars(1, 1, 1, 1, 0, 0, false)
      size:SetHeight(height)
      frame:SetClientSize(size)
    end

    results:Refresh()
  end

  local function onKeyDown(event)
    if ide:IsValidProperty(ide:GetApp(), "GetMainLoop")
    and ide:GetApp():GetMainLoop():IsYielding() then
      event:Skip()
      return
    end

    local linesnow = #lines
    local keycode = event:GetKeyCode()
    if keycode == wx.WXK_RETURN then
      onExit(linenow)
      return
    elseif event:GetModifiers() ~= wx.wxMOD_NONE then
      event:Skip()
      return
    elseif keycode == wx.WXK_UP then
      if linesnow > 0 then
        linenow = linenow - 1
        if linenow <= 0 then linenow = linesnow end
      end
    elseif keycode == wx.WXK_DOWN then
      if linesnow > 0 then
        linenow = linenow % linesnow + 1
      end
    elseif keycode == wx.WXK_PAGEDOWN then
      if linesnow > 0 then
        linenow = linenow + maxlines
        if linenow > linesnow then linenow = linesnow end
      end
    elseif keycode == wx.WXK_PAGEUP then
      if linesnow > 0 then
        linenow = linenow - maxlines
        if linenow <= 0 then linenow = 1 end
      end
    elseif keycode == wx.WXK_ESCAPE then
      onExit(false)
      return
    else
      event:Skip()
      return
    end

    local _, starty = results:GetViewStart()
    if linenow < starty+1 then results:Scroll(-1, linenow-1)
    elseif linenow > starty+maxlines then results:Scroll(-1, linenow-maxlines) end
    results:Refresh()
  end

  local function onMouseLeftDown(event)
    local pos = event:GetPosition()
    local _, y = results:CalcUnscrolledPosition(pos.x, pos.y)
    onExit(math.floor(y / row_height)+1)
  end

  local function onIdle(event)
    if pending then return onTextUpdated() end
    if linewas == linenow then return end
    linewas = linenow
    if linenow == 0 then return end

    -- save the selection/insertion point as it's reset on Linux (wxwidgets 2.9.5)
    local ip = search:GetInsertionPoint()
    local f, t = search:GetSelection()

    -- this may set focus to a different object/tab,
    -- so disable the focus event and then set the focus back
    search:SetEvtHandlerEnabled(false)
    onSelection(lines[linenow], search:GetValue())
    search:SetFocus()
    search:SetEvtHandlerEnabled(true)
    if ide.osname == 'Unix' then
      search:SetInsertionPoint(ip)
      search:SetSelection(f, t)
    end
  end

  panel:Connect(wx.wxEVT_PAINT, onPanelPaint)
  panel:Connect(wx.wxEVT_ERASE_BACKGROUND, function() end)
  panel:Connect(wx.wxEVT_IDLE, onIdle)

  results:Connect(wx.wxEVT_PAINT, onPaint)
  results:Connect(wx.wxEVT_LEFT_DOWN, onMouseLeftDown)
  results:Connect(wx.wxEVT_ERASE_BACKGROUND, function() end)

  search:SetFocus()
  search:Connect(wx.wxEVT_KEY_DOWN, onKeyDown)
  search:Connect(wx.wxEVT_COMMAND_TEXT_UPDATED, onTextUpdated)
  search:Connect(wx.wxEVT_COMMAND_TEXT_ENTER, function() onExit(linenow) end)
  -- this could be done with calling `onExit`, but on OSX KILL_FOCUS is called before
  -- mouse LEFT_DOWN, which closes the panel before the results are taken;
  -- to avoid this, `onExit` call is delayed and handled in IDLE event
  search:Connect(wx.wxEVT_KILL_FOCUS, function() onExit() end)

  frame:Show(true)
  frame:Update()
  frame:Refresh()

  search:SetValue((defaultText or "")..(selectedText or ""))
  search:SetSelection(#(defaultText or ""), -1)
end

local sep = "[/\\%-_ ]+"
local weights = {onegram = 0.1, digram = 0.4, trigram = 0.5}
local cache = {}
local missing = 3 -- penalty for missing symbols (1 missing == N matching)
local casemismatch = 0.9 -- score for case mismatch (%% of full match)
local function score(p, v)
  local function ngrams(str, num, low, needcache)
    local key = str..(low and '\1' or '\2')..num
    if cache[key] then return unpack(cache[key]) end

    local t, l, p = {}, {}, 0
    for i = 1, #str-num+1 do
      local pair = str:sub(i, i+num-1)
      p = p + (t[pair] and 0 or 1)
      if low and pair:find('%u') then l[pair:lower()] = casemismatch end
      t[pair] = 1
    end
    if needcache then cache[key] = {t, p, l} end
    return t, p, l
  end

  local function overlap(pattern, value, num)
    local ph, ps = ngrams(pattern, num, false, true)
    local vh, vs, vl = ngrams(value, num, true)
    if ps + vs == 0 then return 0 end

    local is = 0 -- intersection of two sets of ngrams
    for k in pairs(ph) do is = is + (vh[k] or vl[k:lower()] or 0) end
    return is / (ps + vs) - (num == 1 and missing * (ps - is) / (ps + vs) or 0)
  end

  local key = p..'\3'..v
  if not cache[key] then
    -- ignore all whitespaces in the pattern for one-gram comparison
    local score = weights.onegram * overlap(p:gsub("%s+",""), v, 1)
    if score > 0 then -- don't bother with those that can't even score 1grams
      p = ' '..(p:gsub(sep, ' '))
      v = ' '..(v:gsub(sep, ' '))
      score = score + weights.digram * overlap(p, v, 2)
      score = score + weights.trigram * overlap(' '..p, ' '..v, 3)
    end
    cache[key] = 2 * 100 * score
  end
  return cache[key]
end

local function commandBarScoreItems(t, pattern, limit)
  local r, plen = {}, #(pattern:gsub("%s+",""))
  local maxp = 0
  local num = 0
  local total = #t
  local prefilter = ide.config.commandbar and tonumber(ide.config.commandbar.prefilter)
  -- anchor for 1-2 symbol patterns to speed up search
  local needanchor = prefilter and prefilter * 4 <= #t and plen <= 2
  local pref = pattern:gsub("[^%w_]+",""):sub(1,4):lower()
  local filter = prefilter and prefilter <= #t
    -- expand `abc` into `a.*b.*c`, but limit the prefix to avoid penalty for `s.*s.*s.*....`
    -- if there are too many records to filter (prefilter*20), then only search for substrings
    and (prefilter * 10 <= #t and pref or pref:gsub(".", "%1.*"):gsub("%.%*$",""))
    or nil
  local lastpercent = 0
  for n, v in ipairs(t) do
    -- there was additional input while scoring, so abort to check for it
    local timeToCheck = n % ((prefilter or 250) * 10) == 0
    if timeToCheck and pendingInput() then r = {}; break end
    local progress = n/total
    local percent = math.floor(progress * 100 + 0.5)
    if timeToCheck and percent ~= lastpercent then
      lastpercent = percent
      if showProgress then showProgress(progress) end
    end

    if #v >= plen then
      local match = filter and v:lower():find(filter)
      -- check if the current name needs to be prefiltered or anchored (for better performance);
      -- if it needs to be anchored, then anchor it at the beginning of the string or the word
      if not filter or (match and (not needanchor or match == 1 or v:find("^[%p%s]", match-1))) then
        local p = score(pattern, v)
        maxp = math.max(p, maxp)
        if p > 1 and p > maxp / 4 then
          num = num + 1
          r[num] = {v, p}
        end
      end
    end
  end
  table.sort(r, function(a, b) return a[2] > b[2] end)
  -- limit the list to be displayed
  -- `r[limit+1] = nil` is not desired as the resulting table may be sorted incorrectly
  if tonumber(limit) and limit < #r then
    local tmp = r
    r = {}
    for i = 1, limit do r[i] = tmp[i] end
  end
  if showProgress then showProgress(0) end
  return r
end

local markername = "commandbar.background"
local mac = ide.osname == 'Macintosh'
local win = ide.osname == 'Windows'
local special = {SYMBOL = '@', LINE = ':', METHOD = ';'}
local tabsep = "\0"
local function name2index(name)
  local p = name:find(tabsep)
  return p and tonumber(name:sub(p + #tabsep)) or nil
end
local files
function ShowCommandBar(default, selected)
  local styles = ide.config.styles
  -- re-register the marker as the colors might have changed
  local marker = ide:AddMarker(markername,
    wxstc.wxSTC_MARK_BACKGROUND, styles.text.fg, styles.caretlinebg.bg)

  local nb = ide:GetEditorNotebook()
  local selection = nb:GetSelection()
  local maxitems = ide.config.commandbar.maxitems
  local preview, origline, functions, methods

  local function markLine(ed, toline)
    ed:MarkerDefine(ide:GetMarker(markername))
    ed:MarkerDeleteAll(marker)
    ed:MarkerAdd(toline-1, marker)
    -- store the original line if not stored yet
    origline = origline or (ed:GetCurrentLine()+1)
    ed:EnsureVisibleEnforcePolicy(toline-1)
  end

  showCommandBar({
    defaultText = default or "",
    selectedText = selected or "",
    onDone = function(t, enter, text)
      if not mac then nb:Freeze() end

      -- delete all current line markers if any; restore line position
      local ed = ide:GetEditor()
      if ed and origline then
        ed:MarkerDeleteAll(marker)
        -- only restore original line if Escape was used (enter == false)
        if enter == false then ed:EnsureVisibleEnforcePolicy(origline-1) end
      end

      if enter then
        local fline, sline, docindex = unpack(t or {})

        -- jump to symbol; docindex has the position of the symbol
        if text and text:find(special.SYMBOL) then
          if sline and docindex then
            local index = name2index(sline)
            local editor = index and nb:GetPage(index):DynamicCast("wxStyledTextCtrl")
            if not editor then
              local doc = ide:FindDocument(sline)
              -- reload the file (including the preview to refresh its symbols in the outline)
              editor = LoadFile(sline, (not doc or doc:GetEditor() == preview) and preview or nil)
            end
            if editor then
              if preview and preview ~= editor then ide:GetDocument(preview):Close() end
              editor:GotoPos(docindex-1)
              editor:EnsureVisibleEnforcePolicy(editor:LineFromPosition(docindex-1))
              ide:DoWhenIdle(function() ide:GetDocument(editor):SetActive() end)
            end
          end
        -- insert selected method
        elseif text and text:find('^%s*'..special.METHOD) then
          if ed then -- clean up text and insert at the current location
            local method = sline
            local isfunc = methods.desc[method][1]:find(q(method).."%s*%(")
            local text = method .. (isfunc and "()" or "")
            local pos = ed:GetCurrentPos()
            ed:InsertTextDyn(pos, text)
            ed:EnsureVisibleEnforcePolicy(ed:LineFromPosition(pos))
            ed:GotoPos(pos + #method + (isfunc and 1 or 0))
            if isfunc then -- show the tooltip
              local frame = ide:GetMainFrame()
              frame:SetFocus()
              frame:AddPendingEvent(
                wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED, ID.SHOWTOOLTIP))
            end
          end
        -- set line position in the (current) editor if requested
        elseif text and text:find(special.LINE..'(%d*)%s*$') then
          local toline = tonumber(text:match(special.LINE..'(%d+)'))
          if toline and ed then
            ed:GotoLine(toline-1)
            ed:EnsureVisibleEnforcePolicy(toline-1)
            ide:DoWhenIdle(function() ide:GetDocument(ed):SetActive() end)
          end
        elseif docindex then -- switch to existing document
          local doc = ide:GetDocumentList()[docindex]
          if preview and preview ~= doc:GetEditor() then ide:GetDocument(preview):Close() end
          -- delay switching to allow the panel to be destroyed, as it may pull the focus away
          ide:DoWhenIdle(function() doc:SetActive() end)
        -- load a new file (into preview if set)
        elseif sline or text then
          -- 1. use "text" if Ctrl/Cmd-Enter is used
          -- 2. otherwise use currently selected file
          -- 3. otherwise use "text"
          local file = (wx.wxGetKeyState(wx.WXK_CONTROL) and text) or sline or text
          local fullPath = MergeFullPath(ide:GetProject(), file)
          local doc = ide:FindDocument(fullPath)
          -- if the document is already opened (not in the preview)
          -- or can't be opened as a file or folder, then close the preview
          if doc and doc:GetEditor() ~= preview
          or not LoadFile(fullPath, preview or nil) and not ide:SetProject(fullPath) then
            if preview then ide:GetDocument(preview):Close() end
          end
        end
      else
        -- close preview
        if preview then ide:GetDocument(preview):Close() end
        -- restore original selection if canceled
        if nb:GetSelection() ~= selection then nb:SetSelection(selection) end
      end
      preview = nil
      if not mac then nb:Thaw() end

      -- reset file cache if it's not needed
      if not ide.config.commandbar.filecache then files = nil end
    end,
    onUpdate = function(text)
      local lines = {}
      local projdir = ide:GetProject()

      -- delete all current line markers if any
      -- restore the original position if search text is updated
      local ed = ide:GetEditor()
      if ed and origline then ed:MarkerDeleteAll(marker) end

      -- reset cached functions if no symbol search
      if text and not text:find(special.SYMBOL) then
        functions = nil
        if ed and origline then ed:EnsureVisibleEnforcePolicy(origline-1) end
      end
      -- reset cached methods if no method search
      if text and not text:find(special.METHOD) then methods = nil end

      if text and text:find(special.SYMBOL) then
        local file, symbol = text:match('^(.*)'..special.SYMBOL..'(.*)')
        if not functions then
          local nums, paths = {}, {}
          functions = {pos = {}, src = {}}

          local function populateSymbols(path, symbols)
            for _, func in ipairs(symbols) do
              table.insert(functions, func.name)
              nums[func.name] = (nums[func.name] or 0) + 1
              local num = nums[func.name]
              functions.src[func.name..num] = path
              functions.pos[func.name..num] = func.pos
            end
          end

          local currentonly = #file > 0 and ed
          local outline = ide:GetOutline()
          for _, doc in pairs(currentonly and {ide:GetDocument(ed)} or ide:GetDocuments()) do
            local path, editor = doc:GetFilePath(), doc:GetEditor()
            if path then paths[path] = true end
            local index = doc:GetTabIndex()
            populateSymbols(path or doc:GetFileName()..tabsep..index, outline:GetEditorSymbols(editor))
          end

          -- now add all other files in the project
          if not currentonly and ide.config.commandbar.showallsymbols then
            local n = 0
            outline:RefreshSymbols(projdir, function(path)
                local symbols = outline:GetFileSymbols(path)
                if not paths[path] and symbols then populateSymbols(path, symbols) end
                if not symbols then n = n + 1 end
              end)
            if n > 0 then ide:SetStatusFor(TR("Queued %d files to index."):format(n)) end
          end
        end
        local nums = {}
        if #symbol > 0 then
          local topscore
          for _, item in ipairs(commandBarScoreItems(functions, symbol, maxitems)) do
            local func, score = unpack(item)
            topscore = topscore or score
            nums[func] = (nums[func] or 0) + 1
            local num = nums[func]
            if score > topscore / 4 and score > 1 then
              table.insert(lines, {("%2d %s"):format(score, func),
                  functions.src[func..num], functions.pos[func..num]})
            end
          end
        else
          for n, name in ipairs(functions) do
            if n > maxitems then break end
            nums[name] = (nums[name] or 0) + 1
            local num = nums[name]
            lines[n] = {name, functions.src[name..num], functions.pos[name..num]}
          end
        end
      elseif ed and text and text:find('^%s*'..special.METHOD) then
        if not methods then
          methods = {desc = {}}
          local num = 1
          if ed.api and ed.api.tip and ed.api.tip.shortfinfoclass then
            for libname, lib in pairs(ed.api.tip.shortfinfoclass) do
              for method, val in pairs(lib) do
                local signature, desc = val:match('(.-)\n(.*)')
                local m = (libname > "" and libname..'.' or "")..method
                desc = desc and desc:gsub("\n", " ") or val
                methods[num] = m
                methods.desc[m] = {signature or m, desc}
                num = num + 1
              end
            end
          end
        end
        local method = text:match(special.METHOD..'(.*)')
        if #method > 0 then
          local topscore
          for _, item in ipairs(commandBarScoreItems(methods, method, maxitems)) do
            local method, score = unpack(item)
            topscore = topscore or score
            if score > topscore / 4 and score > 1 then
              table.insert(lines, { score, method })
            end
          end
        end
      elseif text and text:find(special.LINE..'(%d*)%s*$') then
        local toline = tonumber(text:match(special.LINE..'(%d+)'))
        if toline and ed then markLine(ed, toline) end
      elseif text and #text > 0 and projdir and #projdir > 0 then
        -- populate the list of files
        files = files or ide:GetFileList(projdir, true, "*",
          {sort = false, path = false, folder = false, skipbinary = true})
        local topscore
        for _, item in ipairs(commandBarScoreItems(files, text, maxitems)) do
          local file, score = unpack(item)
          topscore = topscore or score
          if score > topscore / 4 and score > 1 then
            table.insert(lines, {
                ("%2d %s"):format(score, wx.wxFileName(file):GetFullName()),
                file,
            })
          end
        end
      else
        for index, doc in pairs(ide:GetDocumentList()) do
          lines[index] = {doc:GetFileName(), doc:GetFilePath(), index}
        end
      end
      return lines
    end,
    onItem = function(t)
      if methods then
        local score, method = unpack(t)
        return ("%2d %s"):format(score, methods.desc[method][1]), methods.desc[method][2]
      else
        return unpack(t)
      end
    end,
    onSelection = function(t, text)
      local _, file, docindex = unpack(t)
      local pos
      if text and text:find(special.SYMBOL) then
        pos, docindex = docindex, name2index(file)
      elseif text and text:find(special.METHOD) then
        return
      end

      if file then file = MergeFullPath(ide:GetProject(), file) end
      -- disabling event handlers for the notebook and the editor
      -- to minimize changes in the UI when editors are switched
      -- or files in the preview are updated.
      nb:SetEvtHandlerEnabled(false)
      local doc = file and ide:FindDocument(file)
      if docindex or doc then
        local doc = docindex and ide:GetDocumentList()[docindex] or doc
        local index, nb = doc:GetTabIndex()
        local ed = nb:GetPage(index)
        ed:SetEvtHandlerEnabled(false)
        if nb:GetSelection() ~= index then nb:SetSelection(index) end
        ed:SetEvtHandlerEnabled(true)
      elseif file then
        -- skip binary files with unknown extensions
        if #ide:GetKnownExtensions(GetFileExt(file)) > 0
        -- file may not be read if there is an error, so provide a default for that case
        or not IsBinary(FileRead(file, 2048) or "") then
          preview = preview or NewFile()
          preview:SetEvtHandlerEnabled(false)
          LoadFile(file, preview, true, true)
          preview:SetFocus()
          -- force refresh since the panel covers the editor on OSX/Linux
          -- this fixes the preview window not always redrawn on Linux
          if not win then preview:Update() preview:Refresh() end
          preview:SetEvtHandlerEnabled(true)
        elseif preview then
          ide:GetDocument(preview):Close()
          preview = nil
        end
      end
      nb:SetEvtHandlerEnabled(true)

      if text and text:find(special.SYMBOL) then
        local ed = ide:GetEditor()
        if ed then markLine(ed, ed:LineFromPosition(pos-1)+1) end
      end
    end,
  })
end

ide.test.commandBarScoreItems = commandBarScoreItems

local fsep = GetPathSeparator()
local function relpath(path, filepath)
  local pathpatt = "^"..EscapeMagic(path:gsub("[\\/]$",""):gsub("[\\/]", fsep))..fsep.."?"
  return (filepath:gsub(pathpatt, ""))
end

local addremove = {}
ide:AddPackage('core.commandbar', {
    onProjectLoad = function()
      cache = {} -- reset ngram cache when switching projects to conserve memory
      files = nil -- reset files cache when switching projects
    end,
    onFiletreeFileAdd =  function(self, tree, item, filepath)
      if not files or tree:IsDirectory(item) then return end
      addremove[relpath(ide:GetProject(), filepath)] = true
    end,
    onFiletreeFileRemove = function(self, tree, item, filepath)
      if not files or tree:IsDirectory(item) then return end
      addremove[relpath(ide:GetProject(), filepath)] = false
    end,
    onFiletreeFileRefresh = function(self)
      if not files then return end

      -- to save time only keep the file cache up-to-date if it's used
      if ide.config.commandbar.filecache then
        for key, val in ipairs(files or {}) do
          local ar = addremove[val]
          -- removed file, purge it from cache
          if ar == false then table.remove(files, key) end
          -- remove from the add-remove list, so that only non-existing files are left
          if ar ~= nil then addremove[val] = nil end
        end
        -- go over non-existing files and add them to the cache
        for key in pairs(addremove) do table.insert(files, key) end
      end
      addremove = {}
    end,
  })
