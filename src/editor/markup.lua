-- Copyright 2011-16 Paul Kulchenko, ZeroBrane LLC
-- styles for comment markup
---------------------------------------------------------

local ide = ide
local MD_MARK_ITAL = '_' -- italic
local MD_MARK_BOLD = '**' -- bold
local MD_MARK_LINK = '[' -- link description start
local MD_MARK_LINZ = ']' -- link description end
local MD_MARK_LINA = '(' -- link URL start
local MD_MARK_LINT = ')' -- link URL end
local MD_MARK_HEAD = '#' -- header
local MD_MARK_CODE = '`' -- code
local MD_MARK_BOXD = '|' -- highlight
local MD_MARK_MARK = ' ' -- separator
local MD_LINK_NEWWINDOW = '+' -- indicator to open a new window for links
-- old versions of Scintilla had only 5-bit styles, so assign styles manually in those cases
local markup = {
  [MD_MARK_BOXD] = {st=ide:AddStyle("markup.boxd", ide.STYLEMASK == 31 and 25 or nil), fg={127,0,127}, b=true},
  [MD_MARK_CODE] = {st=ide:AddStyle("markup.code", ide.STYLEMASK == 31 and 26 or nil), fg={127,127,127}, fs=10},
  [MD_MARK_HEAD] = {st=ide:AddStyle("markup.head", ide.STYLEMASK == 31 and 27 or nil), fn="Lucida Console", b=true},
  [MD_MARK_LINK] = {st=ide:AddStyle("markup.link", ide.STYLEMASK == 31 and 28 or nil), u=true, hs={32,32,127}},
  [MD_MARK_BOLD] = {st=ide:AddStyle("markup.bold", ide.STYLEMASK == 31 and 29 or nil), b=true},
  [MD_MARK_ITAL] = {st=ide:AddStyle("markup.ital", ide.STYLEMASK == 31 and 30 or nil), i=true},
  [MD_MARK_MARK] = {st=ide:AddStyle("markup.mark", ide.STYLEMASK == 31 and 31 or nil), v=false},
}

-- allow other editor features to recognize this special markup
function MarkupIsSpecial(style) return style == markup[MD_MARK_MARK].st end
function MarkupIsAny(style)
  for _, mark in pairs(markup) do
    if style == mark.st then return true end
  end
  return false
end
function MarkupAddStyles(styles)
  local comment = styles.comment or {}
  for key,value in pairs(markup) do
    local style = styles[key] or {}
    -- copy all style features by value
    for feature in pairs(value) do
      style[feature] = style[feature] or value[feature]
    end
    style.fg = style.fg or comment.fg
    style.bg = style.bg or comment.bg
    styles[key] = style
  end
end

local q = EscapeMagic

local MD_MARK_PTRN = ''  -- combination of all markup marks that can start styling
for key in pairs(markup) do
  if key ~= MD_MARK_MARK then MD_MARK_PTRN = MD_MARK_PTRN .. q(key) end
end
MarkupAddStyles(ide.config.styles)

function MarkupHotspotClick(pos, editor)
  -- check if this is "our" hotspot event
  if bit.band(editor:GetStyleAt(pos),ide.STYLEMASK) ~= markup[MD_MARK_LINK].st then
    -- not "our" style, so nothing to do for us here
    return
  end
  local line = editor:LineFromPosition(pos)
  local tx = editor:GetLineDyn(line)
  pos = pos + #MD_MARK_LINK - editor:PositionFromLine(line) -- turn into relative position

  -- extract the URL/command on the right side of the separator
  local _,_,text = string.find(tx, q(MD_MARK_LINZ).."(%b"..MD_MARK_LINA..MD_MARK_LINT..")", pos)
  if text then
    text = text:gsub("^"..q(MD_MARK_LINA), ""):gsub(q(MD_MARK_LINT).."$", "")
    local doc = ide:GetDocument(editor)
    local filepath = doc and doc.filePath or ide:GetProject()
    local _,_,http = string.find(text, [[^(https?:%S+)$]])
    local _,_,command,code = string.find(text, [[^macro:(%w+)%((.*%S)%)$]])
    if not command then _,_,command = string.find(text, [[^macro:(%w+)$]]) end

    if command == 'shell' then
      ShellExecuteCode(code)
    elseif command == 'inline' then
      ShellExecuteInline(code)
    elseif command == 'run' then -- run the current file
      ProjectRun()
    elseif command == 'debug' then -- debug the current file
      ProjectDebug()
    elseif http then -- open the URL in a new browser window
      wx.wxLaunchDefaultBrowser(http, 0)
    elseif filepath then -- only check for saved files
      -- check if requested to open in a new window
      local newwindow = not doc or string.find(text, MD_LINK_NEWWINDOW, 1, true)
      if newwindow then text = string.gsub(text, "^%" .. MD_LINK_NEWWINDOW, "") end
      local filename = GetFullPathIfExists(
        wx.wxFileName(filepath):GetPath(wx.wxPATH_GET_VOLUME), text)
      if filename and
        (newwindow or SaveModifiedDialog(editor, true) ~= wx.wxID_CANCEL) then
        if not newwindow and ide.osname == 'Macintosh' then editor:GotoPos(0) end
        LoadFile(filename,not newwindow and editor or nil,true)
      end
    end
  end
  return true
end

local function ismarkup (tx)
  local start = 1
  local marksep = "[%s!%?%.,;:%(%)]"
  while true do
    -- find a separator first
    local st,_,sep,more = string.find(tx, "(["..MD_MARK_PTRN.."])(.)", start)
    if not st then return end

    -- check if this is a first character of a multi-character separator
    if not markup[sep] then sep = sep .. (more or '') end

    local s,e,cap
    local qsep = q(sep)
    local nonspace = "[^%s]"
    if sep == MD_MARK_HEAD then
      -- always search from the start of the line
      -- [%w%p] set is needed to avoid continuing this markup to the next line
      s,e,cap = string.find(tx,"^("..q(MD_MARK_HEAD)..".+[%w%p])")
    elseif sep == MD_MARK_LINK then
      -- allow everything based on balanced link separators
      s,e,cap = string.find(tx,
        "^(%b"..MD_MARK_LINK..MD_MARK_LINZ
        .."%b"..MD_MARK_LINA..MD_MARK_LINT..")", st)
      -- if either part of the link is empty `[]` or `()`, skip the match
      if cap and cap:find("^"..q(MD_MARK_LINK..MD_MARK_LINZ))
      or cap and cap:find(q(MD_MARK_LINA..MD_MARK_LINT).."$") then s = nil end
    elseif markup[sep] then
      -- try a single character first, then 2+ characters between separators;
      -- this is to handle "`5` `6`" as two sequences, not one.
      s,e,cap = string.find(tx,"^("..qsep..nonspace..qsep..")".."%f"..marksep, st)
      if not s then s,e,cap = string.find(tx,"^("..qsep..nonspace..".-"..nonspace..qsep..")".."%f"..marksep, st) end
    end
    if s and -- selected markup is surrounded by spaces or punctuation marks
      (s == 1   or tx:sub(s-1, s-1):match(marksep)) and
      (e == #tx or tx:sub(e+1, e+1):match(marksep))
      then return s,e,cap,sep end
    start = st+1
  end
end

function MarkupStyle(editor, lines, linee)
  local lines = lines or 0
  if (lines < 0) then return end

  -- if the current spec doesn't have any comments, nothing to style
  if not next(editor.spec.iscomment) then return end

  -- always style to the end as there may be comments that need re-styling
  -- technically, this should be GetLineCount()-1, but we want to style
  -- beyond the last line to make sure it is styled correctly
  local linec = editor:GetLineCount()
  local linee = linee or linec

  local linecomment = editor.spec.linecomment
  local iscomment = {}
  for i,v in pairs(editor.spec.iscomment) do
    iscomment[i] = v
  end

  local es = editor:GetEndStyled()
  local needfix = false

  for line=lines,linee do
    local tx = editor:GetLineDyn(line)
    local ls = editor:PositionFromLine(line)

    local from = 1
    local off = -1

    -- doing WrapCount(line) when line == linec (which may be beyond
    -- the last line) occasionally crashes the application on OSX.
    local wrapped = line < linec and editor:WrapCount(line) or 0

    while from do
      tx = string.sub(tx,from)
      local f,t,w,mark = ismarkup(tx)

      if (f) then
        local p = ls+f+off
        local s = bit.band(editor:GetStyleAt(p), ide.STYLEMASK)
        -- only style comments and only those that are not at the beginning
        -- of the file to avoid styling shebang (#!) lines
        -- also ignore matches for line comments (as defined in the spec)
        if iscomment[s] and p > 0 and mark ~= linecomment then
          local smark = #mark
          local emark = #mark -- assumes end mark is the same length as start mark
          if mark == MD_MARK_HEAD then
            -- grab multiple MD_MARK_HEAD if present
            local _,_,full = string.find(w,"^("..q(MD_MARK_HEAD).."+)")
            smark,emark = #full,0
          elseif mark == MD_MARK_LINK then
            local lsep = w:find(q(MD_MARK_LINZ)..q(MD_MARK_LINA))
            if lsep then emark = #w-lsep+#MD_MARK_LINT end
          end
          local sp = bit.band(editor:GetStyleAt(p-1), ide.STYLEMASK) -- previous position style
          if mark == MD_MARK_HEAD and not iscomment[sp] then
            p = p + 1
            smark = smark - 1
          end
          editor:StartStyling(p, ide.STYLEMASK)
          editor:SetStyling(smark, markup[MD_MARK_MARK].st)
          editor:SetStyling(t-f+1-smark-emark, markup[mark].st or markup[MD_MARK_MARK].st)
          editor:SetStyling(emark, markup[MD_MARK_MARK].st)
        end

        off = off + t
      end
      from = t and (t+1)
    end

    -- has this line changed its wrapping because of invisible styling?
    if wrapped > 1 and editor:WrapCount(line) < wrapped then needfix = true end
  end
  editor:StartStyling(es, ide.STYLEMASK)

  -- if any wrapped lines have changed, then reset WrapMode to fix the drawing
  if needfix then
    -- this fixes an issue with duplicate lines in Scintilla when
    -- invisible styles hide some of the content that would be wrapped.
    local wrapmode = editor:GetWrapMode()
    if wrapmode ~= wxstc.wxSTC_WRAP_NONE then
      -- change the wrap mode to force recalculation
      editor:SetWrapMode(wxstc.wxSTC_WRAP_NONE)
      editor:SetWrapMode(wrapmode)
    end
    -- if some of the lines have folded, this can make not styled lines visible
    MarkupStyle(editor, linee+1) -- style to the end in this case
  end
end
