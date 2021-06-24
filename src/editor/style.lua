-- Copyright 2011-16 Paul Kulchenko, ZeroBrane LLC
-- authors: Luxinia Dev (Eike Decker & Christoph Kubisch)
---------------------------------------------------------
----------
-- Style
--
-- common style attributes
-- ---------------------------
-- fg foreground - {r,g,b} 0-255
-- bg background - {r,g,b} 0-255
-- alpha translucency - 0-255 (0 - transparent, 255 - opaque, 256 - opaque/faster)
-- sel color of the selected block - {r,g,b} 0-255 (only applies to folds)
-- u underline - boolean
-- b bold - boolean
-- i italic - boolean
-- fill fill to end - boolean
-- fn font Face Name - string ("Lucida Console")
-- fs font size - number (11)
-- hs turn hotspot on - true or {r,g,b} 0-255
-- v visibility for symbols of the current style - boolean

local unpack = table.unpack or unpack

local function getLightStyles()
  local fg = {64, 64, 64}
  local bg = {250, 250, 250}
  return {
    -- lexer specific (inherit fg/bg from text)
    lexerdef = {fg = {160, 160, 160}},
    comment = {fg = {128, 128, 128}},
    stringtxt = {fg = {128, 32, 16}},
    stringeol = {fg = {128, 32, 16}, bg = {224, 192, 224}, fill = true},
    preprocessor = {fg = {128, 128, 0}},
    operator = {fg = fg},
    number = {fg = {80, 112, 255}},

    keywords0 = {fg = {32, 32, 192}},
    keywords1 = {fg = {127, 32, 96}},
    keywords2 = {fg = {32, 127, 96}},
    keywords3 = {fg = {64, 32, 96}},
    keywords4 = {fg = {127, 0, 95}},
    keywords5 = {fg = {35, 95, 175}},
    keywords6 = {fg = {0, 127, 127}},
    keywords7 = {fg = {240, 255, 255}},

    -- common (inherit fg/bg from text)
    text = {fg = fg, bg = bg},
    linenumber = {fg = {128, 128, 128}, bg = bg},
    bracematch = {fg = {32, 128, 255}, b = true},
    bracemiss = {fg = {255, 128, 32}, b = true},
    ctrlchar = {},
    indent = {fg = {192, 192, 230}, bg = {255, 255, 255}},
    calltip = {fg = fg, bg = bg},

    -- common special (need custom fg & bg)
    sel = {bg = {208, 208, 208}},
    caret = {fg = {0, 0, 0}},
    caretlinebg = {bg = {240, 240, 230}},
    fold = {fg = {192, 192, 192}, bg = bg, sel = {160, 128, 224}},
    whitespace = {},
    edge = {},

    -- deprecated; allowed for backward compatibility in case someone does
    -- fncall.fg = {...}
    fncall = {},

    -- markup
    ['|'] = {fg = {127, 0, 127}},
    ['`'] = {fg = {64, 128, 64}},
    ['['] = {hs = {32, 32, 127}},

    -- markers
    marker = {
      currentline = {},
      breakpoint = {},
      message = {},
      output = {},
      prompt = {},
      error = {},
      searchmatchfile = {},
    },

    -- indicators
    indicator = {
      fncall = {},
      varlocal = {},
      varglobal = {},
      varmasking = {},
      varmasked = {},
      varself = {},
      searchmatch = {},
      searchselection = {},
    },

    auxwindow = {bg = bg, fg = fg},
  }
end

local function getDarkStyles()
  local fg = {204, 204, 204}
  local bg = {45, 45, 45}
  return {
    lexerdef = {fg = fg},
    comment = {fg = {153, 153, 153}, fill = true},
    stringeol = {fg = {153, 204, 153}, fill = true},
    stringtxt = {fg = {153, 204, 153}},
    preprocessor = {fg = {249, 145, 87}},
    operator = {fg = {102, 204, 204}},
    number = {fg = {242, 119, 122}},

    keywords0 = {b = true, fg = {102, 153, 204}},
    keywords1 = {b = false, fg = {102, 204, 204}},
    keywords2 = {b = true, fg = {102, 204, 204}},
    keywords3 = {b = false, fg = {204, 153, 204}},
    keywords4 = {b = false, fg = {204, 153, 204}},
    keywords5 = {b = false, fg = {204, 153, 204}},
    keywords6 = {b = false, fg = {204, 153, 204}},
    keywords7 = {b = false, fg = {204, 153, 204}},

    text = {bg = bg, fg = fg},
    linenumber = {fg = {153, 153, 153}},
    bracematch = {b = true, fg = {249, 145, 87}},
    bracemiss = {b = true, fg = {242, 119, 122}},
    ctrlchar = {fg = {255, 204, 102}},
    indent = {fg = {153, 153, 153}},
    calltip = {bg = bg, fg = fg},

    sel = {bg = {81, 81, 81}},
    caret = {fg = {204, 204, 204}},
    caretlinebg = {bg = {57, 57, 57}},
    fold = {bg = bg, fg = {153, 153, 153}, sel = {249, 153, 153}},
    whitespace = {fg = {153, 153, 153}},
    edge = {},

    ["["] = {hs = {217, 127, 255}},
    ["|"] = {fg = {217, 153, 217}},

    marker = {
      message = {bg = {81, 81, 81}},
      output = {bg = {57, 57, 57}},
      error = {bg = {77, 45, 45}},
      prompt = {bg = bg, fg = fg},
    },

    indicator = {
      fncall = {fg = {204, 153, 204}, st = wxstc.wxSTC_MARK_EMPTY},
      varglobal = {fg = fg},
      varlocal = {fg = fg},
      varmasked = {fg = fg},
      varmasking = {fg = fg}
    },

    auxwindow = {bg = bg, fg = fg},
  }
end

function StylesGetDefault()
  local isdark = wx.wxSystemSettings.GetAppearance and wx.wxSystemSettings.GetAppearance():IsDark()
  return setmetatable({}, {__index = isdark and getDarkStyles() or getLightStyles()})
end

local markers = {
  breakpoint = {0, wxstc.wxSTC_MARK_CIRCLE, {196, 64, 64}, {220, 64, 64}},
  bookmark = {1, wxstc.wxSTC_MARK_BOOKMARK or wxstc.wxSTC_MARK_SHORTARROW, {16, 96, 128}, {96, 160, 220}},
  currentline = {2, wxstc.wxSTC_MARK_ARROW, {16, 128, 16}, {64, 220, 64}},
  message = {3, wxstc.wxSTC_MARK_CHARACTER+(' '):byte(), {0, 0, 0}, {220, 220, 220}},
  output = {4, wxstc.wxSTC_MARK_BACKGROUND, {0, 0, 0}, {240, 240, 240}},
  prompt = {5, wxstc.wxSTC_MARK_ARROWS, {0, 0, 0}, {220, 220, 220}},
  error = {6, wxstc.wxSTC_MARK_BACKGROUND, {0, 0, 0}, {255, 220, 220}},
  searchmatchfile = {7, wxstc.wxSTC_MARK_EMPTY, {0, 0, 0}, {196, 0, 0}},
}

local function tint(c)
  return ide.config.markertint and ide:GetTintedColor(c, ide.config.imagetint) or c
end

function StylesGetMarker(marker)
  local id, ch, fg, bg = unpack(markers[marker] or {})
  return id, ch, fg and wx.wxColour(unpack(tint(fg))), bg and wx.wxColour(unpack(tint(bg)))
end
function StylesRemoveMarker(marker) markers[marker] = nil end
function StylesAddMarker(marker, ch, fg, bg)
  if type(fg) ~= "table" or type(bg) ~= "table" then return end
  local num = (markers[marker] or {})[1]
  if not num then -- new marker; find the smallest available marker number
    local nums = {}
    for _, mark in pairs(markers) do nums[mark[1]] = true end
    num = #nums + 1
    if num > 24 then return end -- 24 markers with no pre-defined functions
  end
  markers[marker] = {num, ch, fg, bg}
  return num
end

local function iscolor(c) return type(c) == "table" and #c == 3 end
local function applymarker(editor,marker,clrfg,clrbg,clrsel)
  if (clrfg) then editor:MarkerSetForeground(marker,clrfg) end
  if (clrbg) then editor:MarkerSetBackground(marker,clrbg) end
  if (ide.wxver >= "2.9.5" and clrsel) then editor:MarkerSetBackgroundSelected(marker,clrsel) end
end
local specialmapping = {
  sel = function(editor,style)
    if iscolor(style.fg) then
      editor:SetSelForeground(1,wx.wxColour(unpack(style.fg)))
    else
      editor:SetSelForeground(0,wx.wxWHITE)
    end
    if iscolor(style.bg) then
      editor:SetSelBackground(1,wx.wxColour(unpack(style.bg)))
    else
      editor:SetSelBackground(0,wx.wxWHITE)
    end
    if (tonumber(style.alpha) and ide.wxver >= "2.9.5") then
      editor:SetSelAlpha(style.alpha)
    end

    -- set alpha for additional selecton: 0 - transparent, 255 - opaque
    if ide.wxver >= "2.9.5" then editor:SetAdditionalSelAlpha(127) end
  end,

  seladd = function(editor,style)
    if ide.wxver >= "2.9.5" then
      if iscolor(style.fg) then
        editor:SetAdditionalSelForeground(wx.wxColour(unpack(style.fg)))
      end
      if iscolor(style.bg) then
        editor:SetAdditionalSelBackground(wx.wxColour(unpack(style.bg)))
      end
      if tonumber(style.alpha) then
        editor:SetAdditionalSelAlpha(style.alpha)
      end
    end
  end,

  caret = function(editor,style)
    if iscolor(style.fg) then
      editor:SetCaretForeground(wx.wxColour(unpack(style.fg)))
    end
  end,

  caretlinebg = function(editor,style)
    if iscolor(style.bg) then
      editor:SetCaretLineBackground(wx.wxColour(unpack(style.bg)))
    end
    if (tonumber(style.alpha) and ide.wxver >= "2.9.5") then
      editor:SetCaretLineBackAlpha(style.alpha)
    end
  end,

  whitespace = function(editor,style)
    if iscolor(style.fg) then
      editor:SetWhitespaceForeground(1,wx.wxColour(unpack(style.fg)))
    else
      editor:SetWhitespaceForeground(0,wx.wxBLACK) -- color is not used, but needs to be provided
    end
    if iscolor(style.bg) then
      editor:SetWhitespaceBackground(1,wx.wxColour(unpack(style.bg)))
    else
      editor:SetWhitespaceBackground(0,wx.wxBLACK) -- color is not used, but needs to be provided
    end
  end,

  fold = function(editor,style)
    local clrfg = iscolor(style.fg) and wx.wxColour(unpack(style.fg))
    local clrbg = iscolor(style.bg) and wx.wxColour(unpack(style.bg))
    local clrhi = iscolor(style.hi) and wx.wxColour(unpack(style.hi))
    local clrsel = iscolor(style.sel) and wx.wxColour(unpack(style.sel))

    -- if selected background is set then enable support for it
    if ide.wxver >= "2.9.5" and clrsel then editor:MarkerEnableHighlight(true) end

    if (clrfg or clrbg or clrsel) then
      -- foreground and background are defined as opposite to what I'd expect
      -- for fold markers in Scintilla's terminilogy:
      -- background is the color of fold lines/boxes and foreground is the color
      -- of everything around fold lines or inside fold boxes.
      -- in the following code fg and bg are simply reversed
      local clrfg, clrbg = clrbg, clrfg
      applymarker(editor,wxstc.wxSTC_MARKNUM_FOLDEROPEN, clrfg, clrbg, clrsel)
      applymarker(editor,wxstc.wxSTC_MARKNUM_FOLDER, clrfg, clrbg, clrsel)
      applymarker(editor,wxstc.wxSTC_MARKNUM_FOLDERSUB, clrfg, clrbg, clrsel)
      applymarker(editor,wxstc.wxSTC_MARKNUM_FOLDERTAIL, clrfg, clrbg, clrsel)
      applymarker(editor,wxstc.wxSTC_MARKNUM_FOLDEREND, clrfg, clrbg, clrsel)
      applymarker(editor,wxstc.wxSTC_MARKNUM_FOLDEROPENMID, clrfg, clrbg, clrsel)
      applymarker(editor,wxstc.wxSTC_MARKNUM_FOLDERMIDTAIL, clrfg, clrbg, clrsel)
    end
    if clrbg then
      -- the earlier calls only color the actual markers, but not the
      -- overall fold background; SetFoldMargin calls below do this.
      -- http://community.activestate.com/forum-topic/fold-margin-colors
      -- http://www.scintilla.org/ScintillaDoc.html#SCI_SETFOLDMARGINCOLOUR
      editor:SetFoldMarginColour(true, clrbg)
      editor:SetFoldMarginHiColour(true, clrbg)
    end
    if clrhi then
      editor:SetFoldMarginHiColour(true, clrhi)
    end
  end,

  edge = function(editor,style)
    if iscolor(style.fg) then
      editor:SetEdgeColour(wx.wxColour(unpack(style.fg)))
    end
  end,

  marker = function(editor,markers)
    for m, style in pairs(markers) do
      local id, ch, fg, bg = StylesGetMarker(m)
      if style.ch then ch = style.ch end
      if iscolor(style.fg) then fg = wx.wxColour(unpack(tint(style.fg))) end
      if iscolor(style.bg) then bg = wx.wxColour(unpack(tint(style.bg))) end
      editor:MarkerDefine(id, ch, fg, bg)
    end
  end,

  auxwindow = function(editor,style)
    if not style then return end

    -- don't color toolbars as they have their own color/style
    local skipcolor = {wxAuiToolBar = true, wxToolBar = true}
    local default = wxstc.wxSTC_STYLE_DEFAULT
    local bg = iscolor(style.bg) and wx.wxColour(unpack(style.bg)) or editor:StyleGetBackground(default)
    local fg = iscolor(style.fg) and wx.wxColour(unpack(style.fg)) or editor:StyleGetForeground(default)

    local uimgr = ide.frame.uimgr
    local panes = uimgr:GetAllPanes()
    for index = 0, panes:GetCount()-1 do
      local wind = uimgr:GetPane(panes:Item(index).name).window

      -- wxlua compiled with STL doesn't provide GetChildren() method
      -- as per http://sourceforge.net/p/wxlua/mailman/message/32500995/
      local ok, children = pcall(function() return wind:GetChildren() end)
      if not ok then break end

      for child = 0, children:GetCount()-1 do
        local data = children:Item(child):GetData()
        local _, window = pcall(function() return data:DynamicCast("wxWindow") end)
        if window and not skipcolor[window:GetClassInfo():GetClassName()] then
          window:SetBackgroundColour(bg)
          window:SetForegroundColour(fg)
          window:Refresh()
        end
      end
    end
  end,
}

local defaultmapping = {
  text = wxstc.wxSTC_STYLE_DEFAULT,
  linenumber = wxstc.wxSTC_STYLE_LINENUMBER,
  bracematch = wxstc.wxSTC_STYLE_BRACELIGHT,
  bracemiss = wxstc.wxSTC_STYLE_BRACEBAD,
  ctrlchar = wxstc.wxSTC_STYLE_CONTROLCHAR,
  indent = wxstc.wxSTC_STYLE_INDENTGUIDE,
  calltip = wxstc.wxSTC_STYLE_CALLTIP,
}

function StylesApplyToEditor(styles,editor,font,fontitalic,lexerconvert)
  local defaultfg = styles.text and iscolor(styles.text.fg) and wx.wxColour(unpack(styles.text.fg)) or nil
  local defaultbg = styles.text and iscolor(styles.text.bg) and wx.wxColour(unpack(styles.text.bg)) or nil

  -- get the font as the default one
  if not font then font = editor:GetFont() end

  -- create italic font if only main font is provided
  if font and not fontitalic then
    fontitalic = wx.wxFont(font)
    fontitalic:SetStyle(wx.wxFONTSTYLE_ITALIC)
  end

  local weight = ide:IsValidProperty(font, "GetNumericWeight") and font:GetNumericWeight()

  local function applystyle(style,id)
    editor:StyleSetFont(id, style.i and fontitalic or font)
    editor:StyleSetBold(id, style.b or false)
    if weight and not style.b then editor:StyleSetWeight(id, weight) end
    editor:StyleSetUnderline(id, style.u or false)
    editor:StyleSetEOLFilled(id, style.fill or false)

    if style.fn then editor:StyleSetFaceName(id, style.fn) end
    local fs = tonumber(style.fs)
    if fs then
      -- if the number has no fractional part
      if fs % 1 == 0 then
        editor:StyleSetSize(id, style.fs)
      else
        -- set fractional points; 9.4 => 940
        editor:StyleSetSizeFractional(id, style.fs * 100)
      end
    end
    if style.v ~= nil then editor:StyleSetVisible(id, style.v) end

    if style.hs then
      editor:StyleSetHotSpot(id, 1)
      -- if passed a color (table) as value, set it as foreground
      if iscolor(style.hs) then
        local color = wx.wxColour(unpack(style.hs))
        editor:SetHotspotActiveForeground(1, color)
      end
      editor:SetHotspotActiveUnderline(1)
      editor:SetHotspotSingleLine(1)
    end

    if iscolor(style.fg) or defaultfg then
      editor:StyleSetForeground(id, style.fg and wx.wxColour(unpack(style.fg)) or defaultfg)
    end
    if iscolor(style.bg) or defaultbg then
      editor:StyleSetBackground(id, style.bg and wx.wxColour(unpack(style.bg)) or defaultbg)
    end
  end

  editor:StyleResetDefault()
  editor:SetFont(font)
  if (styles.text) then
    applystyle(styles.text,defaultmapping.text)
  else
    applystyle({},defaultmapping.text)
  end
  editor:StyleClearAll()

  -- set the default linenumber font size based on the editor font size
  if styles.linenumber and not styles.linenumber.fs then
    styles.linenumber.fs = ide.config.editor.fontsize and (ide.config.editor.fontsize - 1) or nil
  end

  function applyallstyles(styles)
    for name,style in pairs(styles) do
      if (specialmapping[name]) then
        specialmapping[name](editor,style)
      elseif (defaultmapping[name]) then
        applystyle(style,defaultmapping[name])
      end

      if (lexerconvert and lexerconvert[name]) then
        local targets = lexerconvert[name]
        for _, outid in pairs(targets) do
          applystyle(style,outid)
        end
      elseif style.st then
        applystyle(style,style.st)
      end
    end
  end

  -- first apply default styles, then configured modifications
  if getmetatable(styles) then applyallstyles(getmetatable(styles).__index or {}) end
  applyallstyles(styles)

  -- additional selection (seladd) attributes can only be set after
  -- normal selection (sel) attributes are set, so handle them again
  if styles.seladd then specialmapping.seladd(editor, styles.seladd) end

  -- calltip has a special style that needs to be enabled
  if styles.calltip then editor:CallTipUseStyle(2) end

  do
    local defaultfg = {127,127,127}
    local indic = styles.indicator or {}

    -- use styles.fncall if not empty and if indic.fncall is empty
    -- for backward compatibility
    if type(styles.fncall) == 'table' and next(styles.fncall)
    and not (type(indic.fncall) == 'table' and next(indic.fncall)) then indic.fncall = styles.fncall end

    local fncall = ide:AddIndicator("core.fncall")
    local varlocal = ide:AddIndicator("core.varlocal")
    local varself = ide:AddIndicator("core.varself")
    local varglobal = ide:AddIndicator("core.varglobal")
    local varmasking = ide:AddIndicator("core.varmasking")
    local varmasked = ide:AddIndicator("core.varmasked")
    local searchmatch = ide:AddIndicator("core.searchmatch")
    local searchselection = ide:AddIndicator("core.searchselection")

    editor:IndicatorSetStyle(fncall, type(indic.fncall) == type{} and indic.fncall.st or ide.wxver >= "2.9.5" and wxstc.wxSTC_INDIC_ROUNDBOX or wxstc.wxSTC_INDIC_TT)
    editor:IndicatorSetForeground(fncall, wx.wxColour(unpack(type(indic.fncall) == type{} and indic.fncall.fg or {128, 128, 255})))
    editor:IndicatorSetStyle(varlocal, type(indic.varlocal) == type{} and indic.varlocal.st or wxstc.wxSTC_INDIC_DOTS or wxstc.wxSTC_INDIC_TT)
    editor:IndicatorSetForeground(varlocal, wx.wxColour(unpack(type(indic.varlocal) == type{} and indic.varlocal.fg or defaultfg)))
    editor:IndicatorSetStyle(varself, type(indic.varself) == type{} and indic.varself.st or wxstc.wxSTC_INDIC_DOTS)
    editor:IndicatorSetForeground(varself, wx.wxColour(unpack(type(indic.varself) == type{} and indic.varself.fg or defaultfg)))
    editor:IndicatorSetStyle(varglobal, type(indic.varglobal) == type{} and indic.varglobal.st or wxstc.wxSTC_INDIC_PLAIN)
    editor:IndicatorSetForeground(varglobal, wx.wxColour(unpack(type(indic.varglobal) == type{} and indic.varglobal.fg or defaultfg)))
    editor:IndicatorSetStyle(varmasking, type(indic.varmasking) == type{} and indic.varmasking.st or wxstc.wxSTC_INDIC_DASH or wxstc.wxSTC_INDIC_DIAGONAL)
    editor:IndicatorSetForeground(varmasking, wx.wxColour(unpack(type(indic.varmasking) == type{} and indic.varmasking.fg or defaultfg)))
    editor:IndicatorSetStyle(varmasked, type(indic.varmasked) == type{} and indic.varmasked.st or wxstc.wxSTC_INDIC_STRIKE)
    editor:IndicatorSetForeground(varmasked, wx.wxColour(unpack(type(indic.varmasked) == type{} and indic.varmasked.fg or defaultfg)))
    editor:IndicatorSetStyle(searchmatch, type(indic.searchmatch) == type{} and indic.searchmatch.st or wxstc.wxSTC_INDIC_BOX)
    editor:IndicatorSetForeground(searchmatch, wx.wxColour(unpack(type(indic.searchmatch) == type{} and indic.searchmatch.fg or {196, 0, 0})))
    editor:IndicatorSetStyle(searchselection, type(indic.searchselection) == type{} and indic.searchselection.st or wxstc.wxSTC_INDIC_FULLBOX or wxstc.wxSTC_INDIC_BOX)
    editor:IndicatorSetForeground(searchselection, wx.wxColour(unpack(type(indic.searchselection) == type{} and indic.searchselection.fg or {160, 128, 224})))
  end
end

function ReApplySpecAndStyles()
  -- re-register markup styles as they are special:
  -- these styles need to be updated as they are based on comment styles
  MarkupAddStyles(ide.config.styles)
  OutputAddStyles(ide.config.stylesoutshell)

  local console = ide:GetConsole()
  console:SetupKeywords("lua", console.spec, ide.config.stylesoutshell)
  StylesApplyToEditor(ide.config.stylesoutshell, ide:GetOutput())

  for _, doc in pairs(ide:GetDocuments()) do
    local editor = doc:GetEditor()
    if editor.spec then editor:SetupKeywords(nil, editor.spec) end
  end
end

function ApplyStyleConfig(config, style)
  if not wx.wxIsAbsolutePath(config) then config = ide:GetRootPath(config) end

  local cfg = {wxstc = wxstc, math = math, print = function(...) ide:Print(...) end}
  local cfgfn, err = loadfile(config)
  if not cfgfn then
    ide:Print(TR("Error while loading configuration file: %s"):format(err))
    return
  end

  setfenv(cfgfn,cfg)
  cfgfn, err = pcall(cfgfn,style)
  if not cfgfn then
    ide:Print(TR("Error while processing configuration file: %s"):format(err))
    return
  end

  -- if no style assigned explicitly, but a table is returned, use it
  if not (cfg.styles or cfg.stylesoutshell) and type(err) == 'table' then
    cfg.styles = err
  end

  if cfg.styles or cfg.stylesoutshell then
    if (cfg.styles) then
      ide.config.styles = StylesGetDefault()
      -- copy
      for i,s in pairs(cfg.styles) do
        ide.config.styles[i] = s
      end
    end
    if (cfg.stylesoutshell) then
      ide.config.stylesoutshell = StylesGetDefault()
      -- copy
      for i,s in pairs(cfg.stylesoutshell) do
        ide.config.stylesoutshell[i] = s
      end
    end
    ReApplySpecAndStyles()
  end
end
