-- Copyright 2013-17 Paul Kulchenko, ZeroBrane LLC
---------------------------------------------------------

local ide = ide
local iscaseinsensitive = wx.wxFileName("A"):SameAs(wx.wxFileName("a"))
local unpack = table.unpack or unpack
local q = EscapeMagic

local function eventHandle(handlers, event, ...)
  local success
  for package, handler in pairs(handlers) do
    local ok, res = pcall(handler, package, ...)
    if ok then
      if res == false then success = false end
    else
      ide:GetOutput():Error(TR("%s event failed: %s"):format(event, res))
    end
  end
  return success
end

local function getEventHandlers(packages, event)
  local handlers = {}
  for _, package in pairs(packages) do
    if package[event] then handlers[package] = package[event] end
  end
  return handlers
end

function PackageEventHandle(event, ...)
  return eventHandle(getEventHandlers(ide.packages, event), event, ...)
end

function PackageEventHandleOnce(event, ...)
  -- copy packages as the event that is handled only once needs to be removed
  local handlers = getEventHandlers(ide.packages, event)
  -- remove all handlers as they need to be called only once
  -- this allows them to be re-installed if needed
  for _, package in pairs(ide.packages) do package[event] = nil end
  return eventHandle(handlers, event, ...)
end

local function PackageEventHandleOne(file, event, ...)
  local package = ide.packages[file]
  if package and type(package[event]) == 'function' then
    local ok, res = pcall(package[event], package, ...)
    if ok then
      if res == false then return false end
    else
      ide:GetOutput():Error(TR("%s event failed: %s"):format(event, res))
    end
  end
end

function PackageUnRegister(file, ...)
  PackageEventHandleOne(file, "onUnRegister", ...)
  -- remove from the list of installed packages
  local package = ide.packages[file]
  ide.packages[file] = nil
  return package
end

function PackageRegister(file, ...)
  if not ide.packages[file] then
    local packages = {}
    local package = MergeFullPath(
      GetPathWithSep(ide.editorFilename), "packages/"..file..".lua")
    LoadLuaFileExt(packages, package, ide.proto.Plugin)
    packages[file].fname = file
    ide.packages[file] = packages[file]
  end
  return PackageEventHandleOne(file, "onRegister", ...)
end

function ide:GetProperty(keyword, default)
  return self.app.stringtable[keyword] or default
end
function ide:GetRootPath(path)
  return MergeFullPath(GetPathWithSep(self.editorFilename), path or '')
end
function ide:GetPackagePath(packname)
  return MergeFullPath(
    self.oshome and MergeFullPath(self.oshome, '.'..self:GetAppName()..'/') or self:GetRootPath(),
    MergeFullPath('packages', packname or '')
  )
end
function ide:GetLaunchPath(addparams)
  local path = self.editorFilename
  if self.osname == "Macintosh" then
    -- find .app folder in the path; there are two options:
    -- 1. `/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio/zbstudio`(installed path)
    -- 2. `...ZeroBraneStudio/zbstudio` (cloned repository path)
    local app = path:match("(.+%.app)/")
    if app then -- check if the application is already in the path
      path = app
    else
      local apps = ide:GetFileList(path, true, "Info.plist", {ondirectory = function(dir)
            -- don't recurse for more than necessary
            return dir:find("%.app/Contents/.+") == nil
          end}
      )
      if #apps == 0 then return nil, "Can't find application path." end

      local fn = wx.wxFileName(apps[1])
      fn:RemoveLastDir()
      path = fn:GetPath(wx.wxPATH_GET_VOLUME)
    end
    -- generate command with `-n` (start a new copy of the application)
    path = ([[open -n -a "%s" --args]]):format(path)
  elseif self.osname == "Unix" then
    path = ([["%s.sh"]]):format(path)
  else
    path = ([["%s"]]):format(path)
  end
  if addparams then
    for n, val in ipairs(self.arg) do
      if val == "-cfg" and #self.arg > n then
        path = path .. ([[ %s "%s"]]):format(self.arg[n], self.arg[n+1])
      end
    end
  end
  return path
end
function ide:Exit(hotexit)
  if hotexit then self.config.hotexit = true end
  self:GetMainFrame():Close()
end
function ide:Restart(hotexit)
  self:AddPackage("core.restart", {
      onAppShutdown = function() wx.wxExecute(self:GetLaunchPath(true), wx.wxEXEC_ASYNC) end
    })
  if self.singleinstanceserver then self.singleinstanceserver:close() end
  self:Exit(hotexit)
end
function ide:GetApp() return self.editorApp end
function ide:GetAppName() return self.appname end
function ide:GetDefaultFileName()
  local default = self.config.default
  local ext = default.extension
  local ed = self:GetEditor()
  if ed and default.usecurrentextension then ext = self:GetDocument(ed):GetFileExt() end
  return default.name..(ext and ext > "" and "."..ext or "")
end

local function isCtrlFocused(e)
  local ctrl = e and e:FindFocus()
  return ctrl and
    (ctrl:GetId() == e:GetId()
     or ide.osname == 'Macintosh' and
       ctrl:GetParent():GetId() == e:GetId()) and ctrl or nil
end
function ide:GetEditor()
  local notebook = self:GetEditorNotebook()
  local win = notebook:GetCurrentPage()
  local editor
  if win and win:GetClassInfo():GetClassName()=="wxStyledTextCtrl" then
    editor = win:DynamicCast("wxStyledTextCtrl")
  end
  -- return the editor if it has focus
  if isCtrlFocused(editor) then return editor end

  -- check the rest of the documents (those not in the EditorNotebook)
  for _, doc in pairs(ide:GetDocuments()) do
    local _, nb = doc:GetTabIndex()
    if nb ~= notebook and isCtrlFocused(doc:GetEditor()) then return doc:GetEditor() end
  end
  -- return the current editor in the notebook, even if it's not focused
  return editor
end
function ide:GetEditorWithFocus(...)
  -- need to distinguish GetEditorWithFocus() and GetEditorWithFocus(nil)
  -- as the latter may happen when GetEditor() is passed and returns `nil`
  if select('#', ...) > 0 then
    local ed = ...
    return isCtrlFocused(ed) and ed or nil
  end

  local editor = self:GetEditor()
  if isCtrlFocused(editor) then return editor end

  local nb = ide:GetOutputNotebook()
  for p = 0, nb:GetPageCount()-1 do
    local ctrl = nb:GetPage(p)
    if ctrl:GetClassInfo():GetClassName() == "wxStyledTextCtrl"
    and isCtrlFocused(ctrl) then
      return ctrl:DynamicCast("wxStyledTextCtrl")
    end
  end
  return nil
end
function ide:GetEditorWithLastFocus()
  -- make sure ide.infocus is still a valid component
  return (self:IsValidCtrl(self.infocus)
    and self.infocus:GetClassInfo():GetClassName() == "wxStyledTextCtrl"
    and self.infocus:DynamicCast("wxStyledTextCtrl") or nil)
end
function ide:GetMenuBar() return self.frame and self.frame.menuBar end
function ide:GetStatusBar() return self.frame and self.frame.statusBar end
function ide:GetToolBar() return self.frame and self.frame.toolBar end
function ide:GetDebugger() return self.debugger end
function ide:SetDebugger(deb)
  self.debugger = deb
  -- if the remote console is already assigned, then assign it based on the new debugger
  local console = self:GetConsole()
  -- `SetDebugger` may be called before console is set, so need to check if it's available
  if self:IsValidProperty(console, 'GetRemote') and console:GetRemote() then console:SetRemote(deb:GetConsole()) end
  return deb
end
function ide:GetMainFrame()
  if not self.frame then
    self.frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, self:GetProperty("editor"),
      wx.wxDefaultPosition, wx.wxSize(1100, 700))
      -- transparency range: 0 == invisible -> 255 == opaque
      -- set lower bound of 50 to prevent accidental invisibility
      local transparency = tonumber(self:GetConfig().transparency)
      if transparency then self.frame:SetTransparent(math.max(50, transparency)) end
  end
  return self.frame
end
function ide:GetUIManager() return self.frame.uimgr end
function ide:GetDocument(ed) return self:IsValidCtrl(ed) and self.openDocuments[ed:GetId()] end
function ide:CreateDocument(ed, name)
  if not self:IsValidCtrl(ed) or self.openDocuments[ed:GetId()] then return false end
  local document = setmetatable({editor = ed}, self.proto.Document)
  document:SetFileName(name)
  self.openDocuments[ed:GetId()] = document
  return document
end
function ide:RemoveDocument(ed)
  if not self:IsValidCtrl(ed) or not self.openDocuments[ed:GetId()] then return false end

  local index, notebook = self:GetDocument(ed):GetTabIndex()
  if not notebook:RemovePage(index) then return false end

  -- if the notebook is in a floating pane and has no pages close the pane
  if notebook ~= ide:GetEditorNotebook() and notebook:GetPageCount() == 0 then
    local mgr = self:GetUIManager()
    local pane = mgr:GetPane(notebook)
    if pane:IsOk() then mgr:DetachPane(notebook) end
  end

  self.openDocuments[ed:GetId()] = nil
  return true
end
function ide:GetDocuments() return self.openDocuments end
function ide:GetDocumentList()
  local a = {}
  for _, doc in pairs(self.openDocuments) do table.insert(a, doc) end
  table.sort(a, function(a, b) return a:GetTabIndex() < b:GetTabIndex() end)
  return a
end
function ide:GetKnownExtensions(ext)
  local knownexts, extmatch = {}, ext and ext:lower()
  for _, spec in pairs(self.specs) do
    for _, ext in ipairs(spec.exts or {}) do
      if not extmatch or extmatch == ext:lower() then
        table.insert(knownexts, ext)
      end
    end
  end
  table.sort(knownexts)
  return knownexts
end

function ide:DoWhenIdle(func) table.insert(self.onidle, func) end

function ide:FindTopMenu(item)
  local index = self:GetMenuBar():FindMenu((TR)(item))
  return self:GetMenuBar():GetMenu(index), index
end
function ide:FindMenuItem(itemid, menu)
  local menubar = self:GetMenuBar()
  if not menubar then return end -- no associated menu
  local item, imenu = menubar:FindItem(itemid, menu)
  if menu and not item then item = menu:FindItem(itemid) end
  if not item then return end
  menu = menu or imenu

  for pos = 0, menu:GetMenuItemCount()-1 do
    if menu:FindItemByPosition(pos):GetId() == itemid then
      return item, menu, pos
    end
  end
  return
end
function ide:AttachMenu(...)
  -- AttachMenu([targetmenu,] id, submenu)
  -- `targetmenu` is only needed for menus not attached to the main menubar
  local menu, id, submenu = ...
  if select('#', ...) == 2 then menu, id, submenu = nil, ... end
  local item, menu, pos = self:FindMenuItem(id, menu)
  if not item then return end

  menu:Remove(item)
  item:SetSubMenu(submenu)
  return menu:Insert(pos, item), pos
end
function ide:CloneMenu(menu)
  if not menu then return end
  local newmenu = wx.wxMenu({})
  local ok, node = pcall(function() return menu:GetMenuItems():GetFirst() end)
  -- some wxwidgets versions may not have GetFirst, so return an empty menu in this case
  if not ok then return newmenu end
  while node do
    local item = node:GetData():DynamicCast("wxMenuItem")
    newmenu:Append(item:GetId(), item:GetItemLabel(), item:GetHelp(), item:GetKind())
    node = node:GetNext()
  end
  return newmenu
end
function ide:MakeMenu(t)
  local menu = wx.wxMenu({})
  local menuicon = self.config.menuicon -- menu items need to have icons
  local iconmap = self.config.toolbar.iconmap
  for p = 1, #(t or {}) do
    if type(t[p]) == "table" then
      if #t[p] == 0 then -- empty table signals a separator
        menu:AppendSeparator()
      else
        local id, label, help, kind = unpack(t[p])
        local submenu
        if type(kind) == "table" then
          submenu, kind = self:MakeMenu(kind)
        elseif type(kind) == "userdata" then
          submenu, kind = kind
        end
        if submenu then
          menu:Append(id, label, submenu, help or "")
        else
          local item = wx.wxMenuItem(menu, id, label, help or "", kind or wx.wxITEM_NORMAL)
          if menuicon and type(iconmap[id]) == "table"
          -- only add icons to "normal" items (OSX can take them on checkbox items too),
          -- otherwise this causes asert on Linux (http://trac.wxwidgets.org/ticket/17123)
          and (ide.osname == "Macintosh" or item:GetKind() == wx.wxITEM_NORMAL) then
            local bitmap = ide:GetBitmap(iconmap[id][1], "TOOLBAR", wx.wxSize(16,16))
            item:SetBitmap(bitmap)
          end
          menu:Append(item)
        end
      end
    end
  end
  return menu
end

function ide:SetTitle(title)
  if not self:IsValidCtrl(self.frame) then return end
  self.frame:SetTitle(title or self:ExpandPlaceholders(self.config.format.apptitle))
end

function ide:FindDocument(path)
  local fileName = wx.wxFileName(path)
  for _, doc in pairs(self:GetDocuments()) do
    local path = doc:GetFilePath()
    if path and fileName:SameAs(wx.wxFileName(path)) then return doc end
  end
  return
end
function ide:FindDocumentsByPartialPath(path)
  local seps = "[\\/]"
  -- add trailing path separator to make sure full directory match
  if not path:find(seps.."$") then path = path .. GetPathSeparator() end
  local pattern = "^"..q(path):gsub(seps, seps)
  local lpattern = pattern:lower()

  local docs = {}
  for _, doc in pairs(self:GetDocuments()) do
    local path = doc:GetFilePath()
    if path and (path:find(pattern) or iscaseinsensitive and path:lower():find(lpattern)) then
      table.insert(docs, doc)
    end
  end
  return docs
end
function ide:SetInterpreter(name) return ProjectSetInterpreter(name) end
function ide:GetInterpreter(name) return name == nil and self.interpreter or name and self.interpreters[name] or nil end
function ide:GetInterpreters() return self.interpreters end
function ide:GetConfig() return self.config end
function ide:GetOutput() return self.frame.bottomnotebook.errorlog end
function ide:GetConsole() return self.frame.bottomnotebook.shellbox end
function ide:GetEditorNotebook() return self.frame.notebook end
function ide:GetOutputNotebook() return self.frame.bottomnotebook end
function ide:GetOutline() return self.outline end
function ide:GetProjectNotebook() return self.frame.projnotebook end
function ide:GetProject()
  local dir = ide.filetree and ide.filetree.projdir
  return dir and #dir > 0 and wx.wxFileName.DirName(dir):GetFullPath() or nil
end
function ide:SetProject(projdir,skiptree)
  -- strip trailing spaces as this may create issues with "path/ " on Windows
  projdir = projdir:gsub("%s+$","")
  local dir = wx.wxFileName.DirName(FixDir(projdir))
  dir:Normalize() -- turn into absolute path if needed
  if not wx.wxDirExists(dir:GetFullPath()) then return self.filetree:updateProjectDir(projdir) end

  projdir = dir:GetPath(wx.wxPATH_GET_VOLUME) -- no trailing slash

  self.config.path.projectdir = projdir ~= "" and projdir or nil
  self:SetStatus(projdir)
  self.frame:SetTitle(self:ExpandPlaceholders(self.config.format.apptitle))

  if skiptree then return true end
  return self.filetree:updateProjectDir(projdir)
end
function ide:GetProjectStartFile()
  local projectdir = self:GetProject()
  local startfile = self.filetree.settings.startfile[projectdir]
  return MergeFullPath(projectdir, startfile), startfile
end
function ide:GetLaunchedProcess() return self.debugger and self.debugger.pid end
function ide:SetLaunchedProcess(pid) if self.debugger then self.debugger.pid = pid; return pid end end
function ide:GetProjectTree() return self.filetree.projtreeCtrl end
function ide:GetOutlineTree() return self.outline.outlineCtrl end
function ide:GetWatch() return self.debugger and self.debugger.watchCtrl end
function ide:GetStack() return self.debugger and self.debugger.stackCtrl end

function ide:GetTextFromUser(message, caption, value)
  local dlg = wx.wxTextEntryDialog(self.frame, message, caption, value)
  local res = dlg:ShowModal()
  return res == wx.wxID_OK and dlg:GetValue() or nil, res
end

local statusreset
function ide:SetStatusFor(text, interval, field)
  field = field or 0
  interval = interval or 2
  local statusbar = self:GetStatusBar()
  if not self.timers.status then
    self.timers.status = self:AddTimer(statusbar, function(event) if statusreset then statusreset() end end)
  end
  statusreset = function()
    if statusbar:GetStatusText(field) == text then statusbar:SetStatusText("", field) end
  end
  self.timers.status:Start(interval*1000, wx.wxTIMER_ONE_SHOT)
  statusbar:SetStatusText(text, field)
end
function ide:SetStatus(text, field) self:GetStatusBar():SetStatusText(text, field or 0) end
function ide:GetStatus(field) return self:GetStatusBar():GetStatusText(field or 0) end
function ide:PushStatus(text, field) self:GetStatusBar():PushStatusText(text, field or 0) end
function ide:PopStatus(field) self:GetStatusBar():PopStatusText(field or 0) end
function ide:Yield() wx.wxYield() end
function ide:CreateBareEditor() return CreateEditor(true) end
function ide:ShowCommandBar(...) return ShowCommandBar(...) end

function ide:RequestAttention()
  local ide = self
  -- first check if the active editor has focus (it may be in a floating panel)
  local ed = ide:GetEditor()
  local frame = ide:GetMainFrame()
  if ed and isCtrlFocused(ed) then
    local frameci = frame:GetClassInfo()
    local parent = ed:GetParent()
    while parent do
      if parent:GetClassInfo():IsKindOf(frameci) and parent:DynamicCast("wxFrame"):IsActive() then
        parent:Raise()
        return true
      end
      parent = parent:GetParent()
    end
  end
  -- then check if the main frame should have the focus
  if not frame:IsActive() then
    frame:RequestUserAttention()
    if ide.osname == "Macintosh" then
      local cmd = [[osascript -e 'tell application "%s" to activate']]
      wx.wxExecute(cmd:format(ide.editorApp:GetAppName()), wx.wxEXEC_ASYNC)
    elseif ide.osname == "Unix" then
      if frame:IsIconized() then frame:Iconize(false) end
    elseif ide.osname == "Windows" then
      if frame:IsIconized() then frame:Iconize(false) end
      frame:Raise() -- raise the window

      local ok, winapi = pcall(require, 'winapi')
      if ok then
        local pid = winapi.get_current_pid()
        local wins = winapi.find_all_windows(function(w)
          return w:get_process():get_pid() == pid
             and w:get_class_name() == 'wxWindowNR'
        end)
        if wins and #wins > 0 then
          -- found the window, now need to activate it:
          -- send some input to the window and then
          -- bring our window to foreground (doesn't work without some input)
          -- send Attn key twice (down and up)
          winapi.send_to_window(0xF6, false)
          winapi.send_to_window(0xF6, true)
          for _, w in ipairs(wins) do w:set_foreground() end
        end
      end
    end
  end
end

function ide:ReportError(msg)
  self:RequestAttention() -- request attention first in case the app is minimized or in the background
  return wx.wxMessageBox(msg, TR("Error"), wx.wxICON_ERROR + wx.wxOK + wx.wxCENTRE, self.frame)
end

local rawMethods = {"AddTextDyn", "InsertTextDyn", "AppendTextDyn", "SetTextDyn",
  "GetTextDyn", "GetLineDyn", "GetSelectedTextDyn", "GetTextRangeDyn",
  "ReplaceTargetDyn", -- this method is not available in wxlua 3.1, so it's simulated
}
local useraw = nil

local invalidUTF8, invalidLength
local suffix = "\1\0"
local DF_TEXT = wx.wxDataFormat(wx.wxDF_TEXT)

function ide:CreateStyledTextCtrl(...)
  local editor = wxstc.wxStyledTextCtrl(...)
  if not editor then return end

  if useraw == nil then
    useraw = true
    for _, m in ipairs(rawMethods) do
      if not pcall(function() return editor[m:gsub("Dyn", "Raw")] end) then useraw = false; break end
    end
  end

  if not self:IsValidProperty(editor, "ReplaceTargetRaw") then
    editor.ReplaceTargetRaw = function(self, ...)
      self:ReplaceTarget("")
      self:InsertTextDyn(self:GetTargetStart(), ...)
    end
  end

  -- map all `GetTextDyn` to `GetText` or `GetTextRaw` if `*Raw` methods are present
  editor.useraw = useraw
  for _, m in ipairs(rawMethods) do
    -- some `*Raw` methods return `nil` instead of `""` as their "normal" calls do
    -- (for example, `GetLineRaw` and `GetTextRangeRaw` for parameters outside of text)
    local def = m:find("^Get") and "" or nil
    editor[m] = function(...) return editor[m:gsub("Dyn", useraw and "Raw" or "")](...) or def end
  end

  function editor:CopyDyn()
    invalidUTF8 = nil
    if not self.useraw then return self:Copy() end
    -- check if selected fragment is a valid UTF-8 sequence
    local text = self:GetSelectedTextRaw()
    if text == "" or wx.wxString.FromUTF8(text) ~= "" then return self:Copy() end
    local tdo = wx.wxTextDataObject()
    -- append suffix as wxwidgets (3.1+ on Windows) truncate last char for odd-length strings
    local workaround = ide.osname == "Windows" and (#text % 2 > 0) and suffix or ""
    tdo:SetData(DF_TEXT, text..workaround)
    invalidUTF8, invalidLength = text, tdo:GetDataSize()

    local clip = wx.wxClipboard.Get()
    clip:Open()
    clip:SetData(tdo)
    clip:Close()
  end

  function editor:PasteDyn()
    if not self.useraw then return self:Paste() end
    local tdo = wx.wxTextDataObject()
    local clip = wx.wxClipboard.Get()
    clip:Open()
    clip:GetData(tdo)
    clip:Close()
    local ok, text = tdo:GetDataHere(DF_TEXT)
    -- check if the fragment being pasted is a valid UTF-8 sequence
    if ide.osname == "Windows" then text = text and text:gsub(suffix.."+$","") end
    if not ok or wx.wxString.FromUTF8(text) ~= ""
    or not invalidUTF8 or invalidLength ~= tdo:GetDataSize() then return self:Paste() end

    self:AddTextRaw(ide.osname ~= "Windows" and invalidUTF8 or text)
    self:GotoPos(self:GetCurrentPos())
  end

  function editor:GotoPosEnforcePolicy(pos)
    self:GotoPos(pos)
    self:EnsureVisibleEnforcePolicy(self:LineFromPosition(pos))
  end

  function editor:MarginFromPoint(x)
    if x < 0 then return nil end
    local pos = 0
    for m = 0, ide.MAXMARGIN do
      pos = pos + self:GetMarginWidth(m)
      if x < pos then return m end
    end
    return nil -- position outside of margins
  end

  function editor:CanFold()
    for m = 0, ide.MAXMARGIN do
      if self:GetMarginWidth(m) > 0
      and self:GetMarginMask(m) == wxstc.wxSTC_MASK_FOLDERS then
        return true
      end
    end
    return false
  end

  -- cycle through "fold all" => "hide base lines" => "unfold all"
  function editor:FoldSome(line)
    local foldall = false -- at least one header unfolded => fold all
    local hidebase = false -- at least one base is visible => hide all

    local header = line and bit.band(self:GetFoldLevel(line),
      wxstc.wxSTC_FOLDLEVELHEADERFLAG) == wxstc.wxSTC_FOLDLEVELHEADERFLAG
    local from = line and (header and line or self:GetFoldParent(line)) or 0
    local to = line and from > -1 and self:GetLastChild(from, -1) or self:GetLineCount()-1

    for ln = from, to do
      local foldRaw = self:GetFoldLevel(ln)
      local foldLvl = foldRaw % 4096
      local foldHdr = (math.floor(foldRaw / 8192) % 2) == 1

      -- at least one header is expanded
      foldall = foldall or (foldHdr and self:GetFoldExpanded(ln))

      -- at least one base can be hidden
      hidebase = hidebase or (
        not foldHdr
        and ln > 1 -- first line can't be hidden, so ignore it
        and foldLvl == wxstc.wxSTC_FOLDLEVELBASE
        and bit.band(foldRaw, wxstc.wxSTC_FOLDLEVELWHITEFLAG) == 0
        and self:GetLineVisible(ln))
    end

    -- shows lines; this doesn't change fold status for folded lines
    if not foldall and not hidebase then self:ShowLines(from, to) end

    for ln = from, to do
      local foldRaw = self:GetFoldLevel(ln)
      local foldLvl = foldRaw % 4096
      local foldHdr = (math.floor(foldRaw / 8192) % 2) == 1

      if foldall then
        if foldHdr and self:GetFoldExpanded(ln) then
          self:ToggleFold(ln)
        end
      elseif hidebase then
        if not foldHdr and (foldLvl == wxstc.wxSTC_FOLDLEVELBASE) then
          self:HideLines(ln, ln)
        end
      else -- unfold all
        if foldHdr and not self:GetFoldExpanded(ln) then
          self:ToggleFold(ln)
        end
      end
    end
    -- if the entire file is being un/folded, make sure the cursor is on the screen
    -- (although it may be inside a folded fragment)
    if not line then self:EnsureCaretVisible() end
  end

  function editor:GetAllMarginWidth()
    local width = 0
    for m = 0, ide.MAXMARGIN do width = width + self:GetMarginWidth(m) end
    return width
  end

  function editor:ShowPosEnforcePolicy(pos)
    local line = self:LineFromPosition(pos)
    self:EnsureVisibleEnforcePolicy(line)
    -- skip the rest if line wrapping is on
    if self:GetWrapMode() ~= wxstc.wxSTC_WRAP_NONE then return end
    local xwidth = self:GetClientSize():GetWidth() - self:GetAllMarginWidth()
    local xoffset = self:GetTextExtent(self:GetLineDyn(line):sub(1, pos-self:PositionFromLine(line)+1))
    self:SetXOffset(xoffset > xwidth and xoffset-xwidth or 0)
  end

  function editor:GetLineWrapped(pos, direction)
    local function getPosNear(editor, pos, direction)
      local point = editor:PointFromPosition(pos)
      local height = editor:TextHeight(editor:LineFromPosition(pos))
      return editor:PositionFromPoint(wx.wxPoint(point:GetX(), point:GetY() + direction * height))
    end
    direction = tonumber(direction) or 1
    local line = self:LineFromPosition(pos)
    if self:WrapCount(line) < 2
    or direction < 0 and line == 0
    or direction > 0 and line == self:GetLineCount()-1 then return false end
    return line == self:LineFromPosition(getPosNear(self, pos, direction))
  end

  -- wxSTC included with wxlua didn't have ScrollRange defined, so substitute if not present
  if not ide:IsValidProperty(editor, "ScrollRange") then
    function editor:ScrollRange() end
  end

  -- ScrollRange moves to the correct position, but doesn't unfold folded region
  function editor:ShowRange(secondary, primary)
    self:ShowPosEnforcePolicy(primary)
    self:ScrollRange(secondary, primary)
  end

  function editor:ClearAny()
    local length = self:GetLength()
    local selections = ide.wxver >= "2.9.5" and self:GetSelections() or 1
    self:Clear() -- remove selected fragments

    -- check if the modification has failed, which may happen
    -- if there is "invisible" text in the selected fragment.
    -- if there is only one selection, then delete manually.
    if length == self:GetLength() and selections == 1 then
      self:SetTargetStart(self:GetSelectionStart())
      self:SetTargetEnd(self:GetSelectionEnd())
      self:ReplaceTarget("")
    end
  end

  function editor:MarkerGetAll(mask, from, to)
    mask = mask or ide.ANYMARKERMASK
    local markers = {}
    local line = self:MarkerNext(from or 0, mask)
    while line ~= wx.wxNOT_FOUND do
      table.insert(markers, {line, self:MarkerGet(line)})
      if to and line > to then break end
      line = self:MarkerNext(line + 1, mask)
    end
    return markers
  end

  function editor:IsLineEmpty(line)
    local text = self:GetLineDyn(line or self:GetCurrentLine())
    local lc = self.spec and self.spec.linecomment
    return not text:find("%S") or (lc and text:find("^%s*"..q(lc)) ~= nil)
  end

  function editor:Activate(force)
    -- check for `activateoutput` if the current component is the same as `Output`
    if self == ide:GetOutput() and not ide.config.activateoutput and not force then return end

    local nb = self:GetParent()
    -- check that the parent is of the correct type
    if nb:GetClassInfo():GetClassName() ~= "wxAuiNotebook" then return end
    nb = nb:DynamicCast("wxAuiNotebook")

    local uimgr = ide:GetUIManager()
    local pane = uimgr:GetPane(nb)
    if pane:IsOk() and not pane:IsShown() then
      pane:Show(true)
      uimgr:Update()
    end
    -- activate output/errorlog window
    local index = nb:GetPageIndex(self)
    if nb:GetSelection() == index then return false end
    nb:SetSelection(index)
    return true
  end

  function editor:GetModifiedTime() return self.updated end

  function editor:SetupKeywords(...) return SetupKeywords(self, ...) end

  editor:Connect(wx.wxEVT_KEY_DOWN,
    function (event)
      local keycode = event:GetKeyCode()
      local mod = event:GetModifiers()
      if (keycode == wx.WXK_DELETE and mod == wx.wxMOD_SHIFT)
      or (keycode == wx.WXK_INSERT and mod == wx.wxMOD_CONTROL)
      or (keycode == wx.WXK_INSERT and mod == wx.wxMOD_SHIFT) then
        local id = keycode == wx.WXK_DELETE and ID.CUT or mod == wx.wxMOD_SHIFT and ID.PASTE or ID.COPY
        ide.frame:AddPendingEvent(wx.wxCommandEvent(wx.wxEVT_COMMAND_MENU_SELECTED, id))
      elseif keycode == wx.WXK_CAPITAL and mod == wx.wxMOD_CONTROL then
        -- ignore Ctrl+CapsLock
      else
        event:Skip()
      end
    end)
  return editor
end

function ide:CreateNotebook(...)
  local ctrl = wxaui.wxAuiNotebook(...)
  if not ctrl then return end

  if not self:IsValidProperty(ctrl, "GetCurrentPage") then
    -- versions of wxlua prior to 3.1 may not have GetCurrentPage
    function ctrl:GetCurrentPage()
      local index = self:GetSelection()
      return index >= 0 and self:GetPage(index) or nil
    end
  end
  return ctrl
end

function ide:CreateTreeCtrl(...)
  local ctrl = wx.wxTreeCtrl(...)
  if not ctrl then return end

  if not self:IsValidProperty(ctrl, "SetFocusedItem") then
    -- versions of wxlua prior to 3.1 may not have SetFocuseditem
    function ctrl:SetFocusedItem(item)
      self:UnselectAll() -- unselect others in case MULTIPLE selection is allowed
      return self:SelectItem(item)
    end
  end

  local hasGetFocused = self:IsValidProperty(ctrl, "GetFocusedItem")
  if not hasGetFocused then
    -- versions of wxlua prior to 3.1 may not have SetFocuseditem
    function ctrl:GetFocusedItem() return self:GetSelections()[1] end
  end

  -- LeftArrow on Linux doesn't collapse expanded nodes as it does on Windows/OSX; do it manually
  if ide.osname == "Unix" and hasGetFocused then
    ctrl:Connect(wx.wxEVT_KEY_DOWN, function (event)
        local keycode = event:GetKeyCode()
        local mod = event:GetModifiers()
        local item = ctrl:GetFocusedItem()
        if keycode == wx.WXK_LEFT and mod == wx.wxMOD_NONE and item:IsOk() and ctrl:IsExpanded(item) then
          ctrl:Collapse(item)
        else
          event:Skip()
        end
      end)
  end
  return ctrl
end

function ide:LoadFile(...) return LoadFile(...) end

function ide:CopyToClipboard(text)
  if wx.wxClipboard:Get():Open() then
    wx.wxClipboard:Get():SetData(wx.wxTextDataObject(text))
    wx.wxClipboard:Get():Close()
    return true
  end
  return false
end

function ide:GetSetting(path, setting)
  local settings = self.settings
  local curpath = settings:GetPath()
  settings:SetPath(path)
  local ok, value = settings:Read(setting)
  settings:SetPath(curpath)
  return ok and value or nil
end

function ide:RemoveMenuItem(id, menu)
  local _, menu, pos = self:FindMenuItem(id, menu)
  if menu then
    self:GetMainFrame():Disconnect(id, wx.wxID_ANY, wx.wxEVT_COMMAND_MENU_SELECTED)
    self:GetMainFrame():Disconnect(id, wx.wxID_ANY, wx.wxEVT_UPDATE_UI)
    menu:Disconnect(id, wx.wxID_ANY, wx.wxEVT_COMMAND_MENU_SELECTED)
    menu:Disconnect(id, wx.wxID_ANY, wx.wxEVT_UPDATE_UI)
    menu:Remove(id)

    local positem = menu:FindItemByPosition(pos)
    if (not positem or positem:GetKind() == wx.wxITEM_SEPARATOR)
    and pos > 0 and (menu:FindItemByPosition(pos-1):GetKind() == wx.wxITEM_SEPARATOR) then
      menu:Destroy(menu:FindItemByPosition(pos-1)) -- remove last or double separator
    elseif positem and pos == 0 and positem:GetKind() == wx.wxITEM_SEPARATOR then
      menu:Destroy(menu:FindItemByPosition(pos)) -- remove first separator
    end
    return true
  end
  return false
end

function ide:ExecuteCommand(cmd, wdir, callback, endcallback)
  local proc = wx.wxProcess(self:GetOutput())
  proc:Redirect()

  local cwd
  if (wdir and #wdir > 0) then -- ignore empty directory
    cwd = wx.wxFileName.GetCwd()
    cwd = wx.wxFileName.SetCwd(wdir) and cwd
  end

  local _ = wx.wxLogNull() -- disable error reporting; will report as needed
  local pid = wx.wxExecute(cmd, wx.wxEXEC_ASYNC, proc)
  pid = pid ~= -1 and pid ~= 0 and pid or nil
  if cwd then wx.wxFileName.SetCwd(cwd) end -- restore workdir
  if not pid then return pid, wx.wxSysErrorMsg() end

  OutputSetCallbacks(pid, proc, callback or function() end, endcallback)
  return pid
end

function ide:CreateImageList(group, ...)
  local _ = wx.wxLogNull() -- disable error reporting in popup
  local size = wx.wxSize(16,16)
  local imglist = wx.wxImageList(16,16)

  for i = 1, select('#', ...) do
    local icon, file = self:GetBitmap(select(i, ...), group, size)
    if imglist:Add(icon) == -1 then
      self:Print(("Failed to add image '%s' to the image list."):format(file or select(i, ...)))
    end
  end
  return imglist
end

local tintdef = 100
local function iconFilter(bitmap, tint)
  if type(tint) == 'function' then return tint(bitmap) end
  if type(tint) ~= 'table' or #tint ~= 3 then return bitmap end

  local tr, tg, tb = tint[1]/255, tint[2]/255, tint[3]/255
  local pi = 0.299*tr + 0.587*tg + 0.114*tb -- pixel intensity
  local perc = (tint[0] or tintdef)/tintdef
  tr, tg, tb = tr*perc, tg*perc, tb*perc

  local img = bitmap:ConvertToImage()
  for x = 0, img:GetWidth()-1 do
    for y = 0, img:GetHeight()-1 do
      if not img:IsTransparent(x, y) then
        local r, g, b = img:GetRed(x, y)/255, img:GetGreen(x, y)/255, img:GetBlue(x, y)/255
        local gs = (r + g + b) / 3
        local weight = 1-4*(gs-0.5)*(gs-0.5)
        r = math.max(0, math.min(255, math.floor(255 * (gs + (tr-pi) * weight))))
        g = math.max(0, math.min(255, math.floor(255 * (gs + (tg-pi) * weight))))
        b = math.max(0, math.min(255, math.floor(255 * (gs + (tb-pi) * weight))))
        img:SetRGB(x, y, r, g, b)
      end
    end
  end
  return wx.wxBitmap(img)
end

function ide:GetTintedColor(color, tint)
  if type(tint) == 'function' then return tint(color) end
  if type(tint) ~= 'table' or #tint ~= 3 then return color end
  if type(color) ~= 'table' then return color end

  local tr, tg, tb = tint[1]/255, tint[2]/255, tint[3]/255
  local pi = 0.299*tr + 0.587*tg + 0.114*tb -- pixel intensity
  local perc = (tint[0] or tintdef)/tintdef
  tr, tg, tb = tr*perc, tg*perc, tb*perc

  local r, g, b = color[1]/255, color[2]/255, color[3]/255
  local gs = (r + g + b) / 3
  local weight = 1-4*(gs-0.5)*(gs-0.5)
  r = math.max(0, math.min(255, math.floor(255 * (gs + (tr-pi) * weight))))
  g = math.max(0, math.min(255, math.floor(255 * (gs + (tg-pi) * weight))))
  b = math.max(0, math.min(255, math.floor(255 * (gs + (tb-pi) * weight))))
  return {r, g, b}
end

local icons = {} -- icon cache to avoid reloading the same icons
function ide:GetBitmap(id, client, size)
  local im = self.config.imagemap
  local width = size:GetWidth()
  local key = width.."/"..id
  local keyclient = key.."-"..client
  local mapped = im[keyclient] or im[id.."-"..client] or im[key] or im[id]
  -- mapped may be a file name/path or wxImage object; take that into account
  if type(im[id.."-"..client]) == 'string' then keyclient = width.."/"..im[id.."-"..client]
  elseif type(im[keyclient]) == 'string' then keyclient = im[keyclient]
  elseif type(im[id]) == 'string' then
    id = im[id]
    key = width.."/"..id
    keyclient = key.."-"..client
  end

  local fileClient = self:GetAppName() .. "/res/" .. keyclient .. ".png"
  local fileKey = self:GetAppName() .. "/res/" .. key .. ".png"
  local isImage = type(mapped) == 'userdata' and mapped:GetClassInfo():GetClassName() == 'wxImage'
  local file
  if mapped and (isImage or wx.wxFileName(mapped):FileExists()) then file = mapped
  elseif wx.wxFileName(fileClient):FileExists() then file = fileClient
  elseif wx.wxFileName(fileKey):FileExists() then file = fileKey
  else
    if width > 16 and width % 2 == 0 then
      local _, f = self:GetBitmap(id, client, wx.wxSize(width/2, width/2))
      if f then
        local img = wx.wxBitmap(f):ConvertToImage()
        file = img:Rescale(width, width, wx.wxIMAGE_QUALITY_NEAREST)
      end
    end
    if not file then return wx.wxArtProvider.GetBitmap(id, client, size) end
  end
  local icon = icons[file] or iconFilter(wx.wxBitmap(file), self.config.imagetint)
  icons[file] = icon
  return icon, file
end

local function str2rgb(str)
  local a = ('a'):byte()
  -- `red`/`blue` are more prominent colors; use them for the first two letters; suppress `green`
  local r = (((str:sub(1,1):lower():byte() or a)-a) % 27)/27
  local b = (((str:sub(2,2):lower():byte() or a)-a) % 27)/27
  local g = (((str:sub(3,3):lower():byte() or a)-a) % 27)/27/3
  local ratio = 256/(r + g + b + 1e-6)
  return {math.floor(r*ratio), math.floor(g*ratio), math.floor(b*ratio)}
end
local clearbmps = {}
function ide:CreateFileIcon(ext)
  local iconmap = ide.config.filetree.iconmap
  local color = type(iconmap)=="table" and type(iconmap[ext])=="table" and iconmap[ext].fg
  local size = 16
  local bitmap = wx.wxBitmap(size, size)
  if not clearbmps[size] then
    clearbmps[size] = ide:GetBitmap("FILE-NORMAL-CLR", "PROJECT", wx.wxSize(size,size))
  end
  local clearbmp = clearbmps[size]
  local font = wx.wxFont(ide.font.editor)
  font:SetPointSize(ide.osname == "Macintosh" and 6 or 5)
  local mdc = wx.wxMemoryDC()
  mdc:SelectObject(bitmap)
  mdc:SetFont(font)
  mdc:SetBackground(wx.wxTRANSPARENT_BRUSH)
  mdc:Clear()
  mdc:DrawBitmap(clearbmp, 0, 0, true)
  mdc:SetTextForeground(wx.wxColour(0, 0, 32)) -- used fixed neutral color for text
  mdc:DrawText(ext:sub(1,3), 2, 6) -- take first three letters only
  if #ext > 0 then
    local clr = wx.wxColour(unpack(type(color)=="table" and color or str2rgb(ext)))
    mdc:SetPen(wx.wxPen(clr, 1, wx.wxSOLID))
    mdc:SetBrush(wx.wxBrush(clr, wx.wxSOLID))
    mdc:DrawRectangle(1, 2, 14, 3)
  end
  mdc:SelectObject(wx.wxNullBitmap)
  bitmap:SetMask(wx.wxMask(bitmap, wx.wxBLACK)) -- set transparent background
  return bitmap
end

function ide:AddPackage(name, package)
  self.packages[name] = setmetatable(package, self.proto.Plugin)
  self.packages[name].fname = name
  return self.packages[name]
end
function ide:RemovePackage(name) self.packages[name] = nil end
function ide:GetPackage(name) return self.packages[name] end

function ide:AddWatch(watch, value)
  local mgr = self.frame.uimgr
  local pane = mgr:GetPane("watchpanel")
  if (pane:IsOk() and not pane:IsShown()) then
    pane:Show()
    mgr:Update()
  end

  local watchCtrl = self.debugger.watchCtrl
  if not watchCtrl then return end

  local root = watchCtrl:GetRootItem()
  if not root or not root:IsOk() then return end

  local item = watchCtrl:GetFirstChild(root)
  while true do
    if not item:IsOk() then break end
    if watchCtrl:GetItemExpression(item) == watch then
      if value then watchCtrl:SetItemText(item, watch .. ' = ' .. tostring(value)) end
      return item
    end
    item = watchCtrl:GetNextSibling(item)
  end

  item = watchCtrl:AppendItem(root, watch, 1)
  watchCtrl:SetItemExpression(item, watch, value)
  return item
end

function ide:AddInterpreter(name, interpreter)
  self.interpreters[name] = setmetatable(interpreter, self.proto.Interpreter)
  ProjectUpdateInterpreters()
end
function ide:RemoveInterpreter(name)
  self.interpreters[name] = nil
  ProjectUpdateInterpreters()
end

function ide:AddSpec(name, spec)
  self.specs[name] = spec
  UpdateSpecs()
  if spec.apitype then ReloadAPIs(spec.apitype) end
end
function ide:RemoveSpec(name) self.specs[name] = nil end

function ide:FindSpec(ext, firstline)
  if not ext then return end
  for _,curspec in pairs(self.specs) do
    for _,curext in ipairs(curspec.exts or {}) do
      if curext == ext then return curspec end
    end
  end
  -- check for extension to spec mapping and create the spec on the fly if present
  local edcfg = self.config.editor
  local name = type(edcfg.specmap) == "table" and edcfg.specmap[ext]
  local shebang = false
  if not name and firstline then
    name = firstline:match("#!.-(%w+)%s*$")
    shebang = true
  end
  if name then
    -- check if there is already spec with this name, but doesn't have this extension registered;
    -- don't register the extension if the format was set based on the shebang
    if self.specs[name] then
      if not self.specs[name].exts then self.specs[name].exts = {} end
      if not shebang then table.insert(self.specs[name].exts, ext) end
      return self.specs[name]
    end
    local spec = { exts = shebang and {} or {ext}, lexer = "lexlpeg."..name }
    self:AddSpec(name, spec)
    return spec
  end
end

function ide:AddAPI(type, name, api)
  self.apis[type] = self.apis[type] or {}
  self.apis[type][name] = api
  ReloadAPIs(type)
end
function ide:RemoveAPI(type, name) self.apis[type][name] = nil end

function ide:AddConsoleAlias(alias, table) return ShellSetAlias(alias, table) end
function ide:RemoveConsoleAlias(alias) return ShellSetAlias(alias, nil) end

function ide:AddMarker(...) return StylesAddMarker(...) end
function ide:GetMarker(marker) return StylesGetMarker(marker) end
function ide:RemoveMarker(marker) StylesRemoveMarker(marker) end

local styles = {}
function ide:AddStyle(style, num)
  num = num or styles[style]
  if not num then -- new style; find the smallest available number
    local nums = {}
    for _, stylenum in pairs(styles) do nums[stylenum] = true end
    num = wxstc.wxSTC_STYLE_MAX
    while nums[num] and num > wxstc.wxSTC_STYLE_LASTPREDEFINED do num = num - 1 end
    if num <= wxstc.wxSTC_STYLE_LASTPREDEFINED then return end
  end
  styles[style] = num
  return num
end
function ide:GetStyle(style) return styles[style] end
function ide:GetStyles() return styles end
function ide:RemoveStyle(style) styles[style] = nil end

local indicators = {}
function ide:AddIndicator(indic, num)
  num = num or indicators[indic]
  if not num then -- new indicator; find the smallest available number
    local nums = {}
    for _, indicator in pairs(indicators) do
      -- wxstc.wxSTC_INDIC_CONTAINER is the first available style
      if indicator >= wxstc.wxSTC_INDIC_CONTAINER then
        nums[indicator-wxstc.wxSTC_INDIC_CONTAINER+1] = true
      end
    end
    -- can't do `#nums + wxstc.wxSTC_INDIC_CONTAINER` as #nums can be calculated incorrectly
    -- on tables that have gaps before 2^n values (`1,2,nil,4`)
    num = wxstc.wxSTC_INDIC_CONTAINER
    for _ in ipairs(nums) do num = num + 1 end
    if num > wxstc.wxSTC_INDIC_MAX then return end
  end
  indicators[indic] = num
  return num
end
function ide:GetIndicator(indic) return indicators[indic] end
function ide:GetIndicators() return indicators end
function ide:RemoveIndicator(indic) indicators[indic] = nil end

-- this provides a simple stack for saving/restoring current configuration
local configcache = {}
function ide:AddConfig(name, files)
  if not name or configcache[name] then return end -- don't overwrite existing slots
  if type(files) ~= "table" then files = {files} end -- allow to pass one value
  configcache[name] = {
    config = require('mobdebug').dump(self.config, {nocode = true}),
    configmeta = getmetatable(self.config),
    packages = {},
    overrides = {},
  }
  -- build a list of existing packages
  local packages = {}
  for package in pairs(self.packages) do packages[package] = true end
  -- load config file(s)
  for _, file in pairs(files) do LoadLuaConfig(MergeFullPath(name, file)) end
  -- register newly added packages (if any)
  for package in pairs(self.packages) do
    if not packages[package] then -- this is a newly added package
      PackageEventHandleOne(package, "onRegister")
      configcache[name].packages[package] = true
    end
  end
  ReApplySpecAndStyles() -- apply current config to the UI
end
local function setLongKey(tbl, key, value)
  local paths = {}
  for path in key:gmatch("([^%.]+)") do table.insert(paths, path) end
  while #paths > 0 do
    local lastkey = table.remove(paths, 1)
    if #paths > 0 then
      if tbl[lastkey] == nil then tbl[lastkey] = {} end
      tbl = tbl[lastkey]
      if type(tbl) ~= "table" then return end
    else
      tbl[lastkey] = value
    end
  end
end
function ide:RemoveConfig(name)
  if not name or not configcache[name] then return end
  -- unregister cached packages
  for package in pairs(configcache[name].packages) do PackageUnRegister(package) end
  -- load original config
  local ok, res = LoadSafe(configcache[name].config)
  if ok then
    self.config = res
    -- restore overrides
    for key, value in pairs(configcache[name].overrides) do setLongKey(self.config, key, value) end
    if configcache[name].configmeta then setmetatable(self.config, configcache[name].configmeta) end
  else
    ide:Print(("Error while restoring configuration: '%s'."):format(res))
  end
  configcache[name] = nil -- clear the slot after use
  ReApplySpecAndStyles() -- apply current config to the UI
end
function ide:SetConfig(key, value, name)
  setLongKey(self.config, key, value) -- set config["foo.bar"] as config.foo.bar
  if not name or not configcache[name] then return end
  configcache[name].overrides[key] = value
end

local panels = {}
function ide:AddPanel(ctrl, panel, name, conf)
  if not self:IsValidCtrl(ctrl) then return end
  local width, height = 360, 200
  local notebook = ide:CreateNotebook(self.frame, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize,
    wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE
    - wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB + wx.wxNO_BORDER)
  notebook:AddPage(ctrl, name, true)
  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_BG_DCLICK,
    function() PaneFloatToggle(notebook) end)
  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CLOSE,
    function(event) event:Veto() end)

  local mgr = self.frame.uimgr
  mgr:AddPane(notebook, wxaui.wxAuiPaneInfo():
              Name(panel):Float():CaptionVisible(false):PaneBorder(false):
              MinSize(width/2,height/2):
              BestSize(width,height):FloatingSize(width,height):
              PinButton(true):Hide())
  if type(conf) == "function" then conf(mgr:GetPane(panel)) end
  mgr.defaultPerspective = mgr:SavePerspective() -- resave default perspective

  panels[name] = {ctrl, panel, name, conf}
  return mgr:GetPane(panel), notebook
end

function ide:RemovePanel(panel)
  local mgr = self.frame.uimgr
  local pane = mgr:GetPane(panel)
  if pane:IsOk() then
    local win = pane.window
    mgr:DetachPane(win)
    win:Destroy()
    mgr:Update()
  end
end

function ide:IsPanelDocked(panel)
  local layout = self:GetSetting("/view", "uimgrlayout")
  return layout and not layout:find(panel)
end
function ide:AddPanelDocked(notebook, ctrl, panel, name, conf, activate)
  notebook:AddPage(ctrl, name, activate ~= false)
  panels[name] = {ctrl, panel, name, conf}
  return notebook
end
function ide:AddPanelFlex(notebook, ctrl, panel, name, conf)
  local nb
  if self:IsPanelDocked(panel) then
    nb = self:AddPanelDocked(notebook, ctrl, panel, name, conf, false)
  else
    self:AddPanel(ctrl, panel, name, conf)
  end
  return nb
end

function ide:IsValidCtrl(ctrl)
  return ctrl and pcall(function() ctrl:GetId() end)
end

function ide:IsValidProperty(ctrl, prop)
  -- some control may return `nil` values for non-existing properties, so check for that
  return pcall(function() return ctrl[prop] end) and ctrl[prop] ~= nil
end

function ide:IsValidHotKey(ksc)
  return ksc and wx.wxAcceleratorEntry():FromString(ksc)
end

function ide:IsWindowShown(win)
  while win do
    if not win:IsShown() then return false end
    win = win:GetParent()
  end
  return true
end

function ide:RestorePanelByLabel(name)
  if not panels[name] then return end
  return self:AddPanel(unpack(panels[name]))
end

local function tool2id(name) return ID("tools.exec."..name) end

function ide:AddTool(name, command, updateui)
  local toolMenu = self:FindTopMenu('&Tools')
  if not toolMenu then
    local helpMenu, helpindex = self:FindTopMenu('&Help')
    if not helpMenu then helpindex = self:GetMenuBar():GetMenuCount() end

    toolMenu = self:MakeMenu {}
    self:GetMenuBar():Insert(helpindex, toolMenu, TR("&Tools"))
  end
  local id = tool2id(name)
  toolMenu:Append(id, name)
  if command then
    toolMenu:Connect(id, wx.wxEVT_COMMAND_MENU_SELECTED,
      function (event)
        local editor = self:GetEditor()
        if not editor then return end

        command(self:GetDocument(editor):GetFilePath(), self:GetProject())
        return true
      end)
    toolMenu:Connect(id, wx.wxEVT_UPDATE_UI,
      updateui or function(event) event:Enable(self:GetEditor() ~= nil) end)
  end
  return id, toolMenu
end

function ide:RemoveTool(name)
  self:RemoveMenuItem(tool2id(name))
  local toolMenu, toolindex = self:FindTopMenu('&Tools')
  if toolMenu and toolMenu:GetMenuItemCount() == 0 then self:GetMenuBar():Remove(toolindex) end
end

local lexers = {}
function ide:AddLexer(name, lexer)
  lexers[name] = lexer
end
function ide:RemoveLexer(name)
  lexers[name] = nil
end
function ide:GetLexer(name)
  return lexers[name]
end

local timers = {}
local function evhandler(event)
  local callback = timers[event:GetId()]
  if callback then callback(event) end
end
function ide:AddTimer(ctrl, callback)
  table.insert(timers, callback or function() end)
  ctrl:Connect(wx.wxEVT_TIMER, evhandler)
  return wx.wxTimer(ctrl, #timers)
end

local function setAcceleratorTable(accelerators)
  local at = {}
  for id, ksc in pairs(accelerators) do
    local ae = wx.wxAcceleratorEntry(); ae:FromString(ksc)
    table.insert(at, wx.wxAcceleratorEntry(ae:GetFlags(), ae:GetKeyCode(), id))
  end
  ide:GetMainFrame():SetAcceleratorTable(#at > 0 and wx.wxAcceleratorTable(at) or wx.wxNullAcceleratorTable)
end
local at = {}
function ide:SetAccelerator(id, ksc)
  if (not id) or (ksc and not self:IsValidHotKey(ksc)) then return false end
  at[id] = ksc
  setAcceleratorTable(at)
  return true
end
function ide:GetAccelerator(id) return at[id] end
function ide:GetAccelerators() return at end

function ide:GetHotKey(idOrKsc)
  if not idOrKsc then return nil, "GetHotKey requires id or key shortcut." end

  local id, ksc = idOrKsc
  if type(idOrKsc) == type("") then id, ksc = ksc, id end

  local accelerators = ide:GetAccelerators()
  local keymap = self.config.keymap
  if id then
    ksc = keymap[id] or accelerators[id]
  else -- ksc is provided
    -- search the keymap for the match
    local kscpat = "^"..(ksc:gsub("[+-]", "[+-]"):lower()).."$"
    for gid, ksc in pairs(keymap) do
      if ksc:lower():find(kscpat) then
        id = gid
        break
      end
    end

    -- if `SetHotKey` is used, there shouldn't be any conflict between keymap and accelerators,
    -- but accelerators can be set directly and will take precedence, so search them as well.
    -- this will overwrite the value from the keymap
    for gid, ksc in pairs(accelerators) do
      if ksc:lower():find(kscpat) then
        id = gid
        break
      end
    end
  end
  if id and ksc then return id, ksc end
  return -- couldn't find the match
end

function ide:SetHotKey(id, ksc)
  if ksc and not self:IsValidHotKey(ksc) then
    self:Print(("Can't set invalid hotkey value: '%s'."):format(ksc))
    return
  end

  -- this function handles several cases
  -- 1. shortcut is assigned to an ID listed in keymap
  -- 2. shortcut is assigned to an ID used in a menu item
  -- 3. shortcut is assigned to an ID linked to an item (but not present in keymap or menu)
  -- 4. shortcut is assigned to a function (passed instead of ID)
  local keymap = self.config.keymap

  if ksc then
    -- remove any potential conflict with this hotkey
    -- since the hotkey can be written as `Ctrl+A` and `Ctrl-A`, account for both
    -- this doesn't take into account different order in `Ctrl-Shift-F1` and `Shift-Ctrl-F1`.
    local kscpat = "^"..(ksc:gsub("[+-]", "[+-]"):lower()).."$"
    for gid, ksc in pairs(keymap) do
      -- if the same hotkey is used elsewhere (not one of IDs being checked)
      if ksc:lower():find(kscpat) then
        keymap[gid] = ""
        -- try to find a menu item with this ID (if any) to remove the hotkey
        local item = self:FindMenuItem(gid)
        if item then item:SetText(item:GetText():gsub("\t.+","").."") end
      end
      -- continue with the loop as there may be multiple associations with the same hotkey
    end

    -- remove an existing accelerator (if any)
    local acid = self:GetHotKey(ksc)
    if acid then self:SetAccelerator(acid) end

    -- if the hotkey is associated with a function, handle it first
    if type(id) == "function" then
      local fakeid = NewID()
      self:GetMainFrame():Connect(fakeid, wx.wxEVT_COMMAND_MENU_SELECTED, function() id() end)
      self:SetAccelerator(fakeid, ksc)
      return fakeid, ksc
    end
  end

  -- if the keymap is already asigned, then reassign it
  -- if not, then it may need an accelerator, which will be set later
  if keymap[id] then keymap[id] = ksc end

  local item = self:FindMenuItem(id)
  if item then
    -- get the item text and replace the shortcut
    -- since it also needs to keep the accelerator (if any), so can't use `GetLabel`
    item:SetText(item:GetText():gsub("\t.+","")..KSC(nil, ksc))
  end

  -- if there is no keymap or menu item, then use the accelerator
  if not keymap[id] and not item then self:SetAccelerator(id, ksc) end
  return id, ksc
end

function ide:IsProjectSubDirectory(dir)
  local projdir = self:GetProject()
  if not projdir then return end
  -- normalize and check if directory when cut is the same as the project directory;
  -- this relies on the project directory ending in a path separator.
  local path = wx.wxFileName(dir:sub(1, #projdir))
  path:Normalize()
  return path:SameAs(wx.wxFileName(projdir))
end

function ide:IsSameDirectoryPath(s1, s2)
  return wx.wxFileName.DirName(s1):SameAs(wx.wxFileName.DirName(s2))
end

function ide:SetCommandLineParameters(params)
  if not params then return end
  self:SetConfig("arg.any", #params > 0 and params or nil, self:GetProject())
  if #params > 0 then self:GetPackage("core.project"):AddCmdLine(params) end
  local interpreter = self:GetInterpreter()
  if interpreter then interpreter:UpdateStatus() end
end

function ide:ActivateFile(filename)
  if wx.wxDirExists(filename) then
    self:SetProject(filename)
    return true
  end

  local name, suffix, value = filename:match('(.+):([lLpP]?)(%d+)$')
  if name and not wx.wxFileExists(filename) then filename = name end

  -- check if non-existing file can be loaded from the project folder;
  -- this is to handle: "project file" used on the command line
  if not wx.wxFileExists(filename) and not wx.wxIsAbsolutePath(filename) then
    filename = GetFullPathIfExists(self:GetProject(), filename) or filename
  end

  local opened = LoadFile(filename, nil, true)
  if opened and value then
    if suffix:upper() == 'P' then opened:GotoPosDelayed(tonumber(value))
    else opened:GotoPosDelayed(opened:PositionFromLine(value-1))
    end
  end

  if not opened then
    self:Print(TR("Can't open file '%s': %s"):format(filename, wx.wxSysErrorMsg()))
  end
  return opened
end

function ide:MergePath(...) return MergeFullPath(...) end

function ide:GetFileList(...) return FileSysGetRecursive(...) end

function ide:AnalyzeString(...) return AnalyzeString(...) end

function ide:AnalyzeFile(...) return AnalyzeFile(...) end

--[[ format placeholders
    - %f -- full project name (project path)
    - %s -- short project name (directory name)
    - %i -- interpreter name
    - %S -- file name
    - %F -- file path
    - %n -- line number
    - %c -- line content
    - %T -- application title
    - %v -- application version
    - %t -- current tab name
--]]
function ide:ExpandPlaceholders(msg, ph)
  ph = ph or {}
  if type(msg) == 'function' then return msg(ph) end
  local editor = self:GetEditor()
  local proj = self:GetProject() or ""
  local dirs = wx.wxFileName(proj):GetDirs()
  local doc = editor and self:GetDocument(editor)
  local index, nb
  if doc then index, nb = doc:GetTabIndex() end
  local def = {
    f = proj,
    s = dirs[#dirs] or "",
    i = self:GetInterpreter():GetName() or "",
    S = doc and doc:GetFileName() or "",
    F = doc and doc:GetFilePath() or "",
    n = editor and editor:GetCurrentLine()+1 or 0,
    c = editor and editor:GetLineDyn(editor:GetCurrentLine()) or "",
    T = self:GetProperty("editor") or "",
    v = self.VERSION,
    t = index and nb:GetPageText(index) or "",
  }
  return(msg:gsub('%%(%w)', function(p) return ph[p] or def[p] or '?' end))
end

do
  local codepage
  function ide:GetCodePage()
    if self.osname ~= "Windows" then return end
    if codepage == nil then
      codepage = tonumber(self.config.codepage) or self.config.codepage
      if codepage == true then
        -- auto-detect the codepage;
        -- this is done asynchronously, so the current method may still return `nil`
        self:ExecuteCommand("cmd /C chcp", nil, function(s) codepage = s:match(":%s*(%d+)") end)
      end
    end
    return tonumber(codepage)
  end
end

function ide:GetShortFilePath(filepath)
  -- if running on Windows and can't open the file, this may mean that
  -- the file path includes unicode characters that need special handling
  -- when passing to applications not set up to handle them
  if ide.osname == 'Windows' and pcall(require, "winapi") then
    local fh = io.open(filepath, "r")
    if fh then fh:close() end
    if not fh and wx.wxFileExists(filepath) then
      winapi.set_encoding(winapi.CP_UTF8)
      local shortpath = winapi.short_path(filepath)
      if shortpath ~= filepath then return shortpath end
      ide:Print(
        ("Can't get short path for a Unicode file name '%s' to use the file.")
        :format(filepath))
      ide:Print(
        ("You can enable short names by using `fsutil 8dot3name set %s: 0` and recreate the file or directory.")
        :format(wx.wxFileName(filepath):GetVolume()))
    end
  end
  return filepath
end

do
  local beforeFullScreenPerspective
  local statusbarShown

  function ide:ShowFullScreen(setFullScreen)
    local uimgr = self:GetUIManager()
    local frame = self:GetMainFrame()
    if setFullScreen then
      beforeFullScreenPerspective = uimgr:SavePerspective()

      local panes = uimgr:GetAllPanes()
      for index = 0, panes:GetCount()-1 do
        local name = panes:Item(index).name
        if name ~= "notebook" then uimgr:GetPane(name):Hide() end
      end
      uimgr:Update()
      local ed = ide:GetEditor()
      if ed then ide:GetDocument(ed):SetActive() end
    end

    -- On OSX, status bar is not hidden when switched to
    -- full screen: http://trac.wxwidgets.org/ticket/14259; do manually.
    -- need to turn off before showing full screen and turn on after,
    -- otherwise the window is restored incorrectly and is reduced in size.
    if self.osname == 'Macintosh' and setFullScreen then
      statusbarShown = frame:GetStatusBar():IsShown()
      frame:GetStatusBar():Hide()
    end

    -- protect from systems that don't have ShowFullScreen (GTK on linux?)
    pcall(function() frame:ShowFullScreen(setFullScreen) end)

    if not setFullScreen and beforeFullScreenPerspective then
      uimgr:LoadPerspective(beforeFullScreenPerspective, true)
      beforeFullScreenPerspective = nil
    end

    if self.osname == 'Macintosh' and not setFullScreen then
      if statusbarShown then
        frame:GetStatusBar():Show()
        -- refresh AuiManager as the statusbar may be shown below the border
        uimgr:Update()
      end
    end

    -- accelerator table gets removed on Linux when setting full screen mode, so put it back;
    -- see wxwidgets ticket https://trac.wxwidgets.org/ticket/18053
    if self.osname == 'Unix' and setFullScreen then
      self:SetAccelerator(-1) -- only refresh the accelerator table after setting full screen
    end
  end
end
