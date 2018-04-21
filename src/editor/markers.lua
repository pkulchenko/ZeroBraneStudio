-- Copyright 2015-18 Paul Kulchenko, ZeroBrane LLC

local ide = ide
ide.markers = {
  markersCtrl = nil,
  imglist = ide:CreateImageList("MARKERS", "FILE-NORMAL", "DEBUG-BREAKPOINT-TOGGLE", "BOOKMARK-TOGGLE"),
  needrefresh = {},
  settings = {markers = {}},
}

local unpack = table.unpack or unpack
local markers = ide.markers
local caches = {}
local image = { FILE = 0, BREAKPOINT = 1, BOOKMARK = 2 }
local markertypes = {breakpoint = 0, bookmark = 0}
local maskall = 0
for markertype in pairs(markertypes) do
  markertypes[markertype] = 2^ide:GetMarker(markertype)
  maskall = maskall + markertypes[markertype]
end

-- make these two IDs local to this menu,
-- as their status differs from bookmarks/breakpoints in the editor
local BOOKMARKTOGGLE = ID("markers.bookmarktoggle")
local BREAKPOINTTOGGLE = ID("markers.breakpointtoggle")

ide.config.toolbar.iconmap[BOOKMARKTOGGLE] = ide.config.toolbar.iconmap[ID.BOOKMARKTOGGLE]
ide.config.toolbar.iconmap[BREAKPOINTTOGGLE] = ide.config.toolbar.iconmap[ID.BREAKPOINTTOGGLE]

local function resetMarkersTimer()
  if ide.config.markersinactivity then
    ide.timers.markers:Start(ide.config.markersinactivity*1000, wx.wxTIMER_ONE_SHOT)
  end
end

local function needRefresh(editor)
  ide.markers.needrefresh[editor] = true
  resetMarkersTimer()
end

local function getMarkers(editor, mtype)
  local edmarkers = {}
  local line = editor:MarkerNext(0, maskall)
  while line ~= wx.wxNOT_FOUND do
    local markerval = editor:MarkerGet(line)
    for markertype, val in pairs(markertypes) do
      if bit.band(markerval, val) > 0 and (not mtype or markertype == mtype) then
        table.insert(edmarkers, {line, markertype})
      end
    end
    line = editor:MarkerNext(line + 1, maskall)
  end
  return edmarkers
end

local function markersRefresh()
  local ctrl = ide.markers.markersCtrl
  local win = ide:GetMainFrame():FindFocus()
  ctrl:Freeze()

  for editor in pairs(ide.markers.needrefresh) do
    local cache = caches[editor]
    if cache then
      local fileitem = cache.fileitem
      if not fileitem then
        local filename = ide:GetDocument(editor):GetTabText()
        local root = ctrl:GetRootItem()
        if not root or not root:IsOk() then return end
        fileitem = ctrl:AppendItem(root, filename, image.FILE)
        ctrl:SortChildren(root)
        cache.fileitem = fileitem
      end

      -- disabling event handlers is not strictly necessary, but it's expected
      -- to fix a crash on Windows that had DeleteChildren in the trace (#442).
      ctrl:SetEvtHandlerEnabled(false)
      ctrl:DeleteChildren(fileitem)
      ctrl:SetEvtHandlerEnabled(true)

      for _, edmarker in ipairs(getMarkers(editor)) do
        local line, markertype = unpack(edmarker)
        local text = ("%d: %s"):format(line+1,
          FixUTF8(editor:GetLineDyn(line), function(s) return '\\'..string.byte(s) end))
        ctrl:AppendItem(fileitem, text:gsub("[\r\n]+$",""), image[markertype:upper()])
      end

      -- if no markers added, then remove the file from the markers list
      ctrl:Expand(fileitem)
      if not ctrl:ItemHasChildren(fileitem) then
        ctrl:Delete(fileitem)
        cache.fileitem = nil
      end
    end
  end

  ctrl:Thaw()
  if win and win ~= ide:GetMainFrame():FindFocus() then win:SetFocus() end
end

local function item2editor(item_id)
  for editor, cache in pairs(caches) do
    if cache.fileitem and cache.fileitem:GetValue() == item_id:GetValue() then return editor end
  end
end

local function clearAllEditorMarkers(mtype, editor)
  for _, edmarker in ipairs(getMarkers(editor, mtype)) do
    local line = unpack(edmarker)
    editor:MarkerToggle(mtype, line, false)
  end
end

local function clearAllProjectMarkers(mtype)
  for filepath, markers in pairs(markers.settings.markers) do
    if ide:IsProjectSubDirectory(filepath) then
      local doc = ide:FindDocument(filepath)
      local editor = doc and doc:GetEditor()
      for m = #markers, 1, -1 do
        local line, markertype = unpack(markers[m])
        if markertype == mtype then
          if editor then
            editor:MarkerToggle(markertype, line, false)
          else
            table.remove(markers, m)
          end
        end
      end
    end
  end
end

local function createMarkersWindow()
  local width, height = 360, 200
  local ctrl = ide:CreateTreeCtrl(ide.frame, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxSize(width, height),
    wx.wxTR_LINES_AT_ROOT + wx.wxTR_HAS_BUTTONS + wx.wxTR_HIDE_ROOT + wx.wxNO_BORDER)

  markers.markersCtrl = ctrl
  ide.timers.markers = ide:AddTimer(ctrl, function() markersRefresh() end)

  ctrl:AddRoot("Markers")
  ctrl:SetImageList(markers.imglist)
  ctrl:SetFont(ide.font.tree)

  function ctrl:ActivateItem(item_id, marker)
    local itemimage = ctrl:GetItemImage(item_id)
    if itemimage == image.FILE then
      -- activate editor tab
      local editor = item2editor(item_id)
      if editor then ide:GetDocument(editor):SetActive() end
    else -- clicked on the marker item
      local parent = ctrl:GetItemParent(item_id)
      if parent:IsOk() and ctrl:GetItemImage(parent) == image.FILE then
        local editor = item2editor(parent)
        if editor then
          local line = tonumber(ctrl:GetItemText(item_id):match("^(%d+):"))
          if line then
            if marker then
              editor:MarkerToggle(marker, line-1, false)
              ctrl:Delete(item_id)
              return -- don't activate the editor when the breakpoint is toggled
            end
            editor:GotoLine(line-1)
            editor:EnsureVisibleEnforcePolicy(line-1)
          end
          ide:GetDocument(editor):SetActive()
        end
      end
    end
  end

  local function activateByPosition(event)
    local mask = (wx.wxTREE_HITTEST_ONITEMINDENT + wx.wxTREE_HITTEST_ONITEMLABEL
      + wx.wxTREE_HITTEST_ONITEMICON + wx.wxTREE_HITTEST_ONITEMRIGHT)
    local item_id, flags = ctrl:HitTest(event:GetPosition())

    if item_id and item_id:IsOk() and bit.band(flags, mask) > 0 then
      local marker
      local itemimage = ctrl:GetItemImage(item_id)
      if bit.band(flags, wx.wxTREE_HITTEST_ONITEMICON) > 0 then
        for iname, itype in pairs(image) do
          if itemimage == itype then marker = iname:lower() end
        end
      end
      ctrl:ActivateItem(item_id, marker)
    else
      event:Skip()
    end
    return true
  end

  local function clearMarkersInFile(item_id, marker)
    local editor = item2editor(item_id)
    local itemimage = ctrl:GetItemImage(item_id)
    if itemimage ~= image.FILE then
      local parent = ctrl:GetItemParent(item_id)
      if parent:IsOk() and ctrl:GetItemImage(parent) == image.FILE then
        editor = item2editor(parent)
      end
    end
    if editor then clearAllEditorMarkers(marker, editor) end
  end

  ctrl:Connect(wx.wxEVT_LEFT_DOWN, activateByPosition)
  ctrl:Connect(wx.wxEVT_LEFT_DCLICK, activateByPosition)
  ctrl:Connect(wx.wxEVT_COMMAND_TREE_ITEM_ACTIVATED, function(event)
      ctrl:ActivateItem(event:GetItem())
    end)

  ctrl:Connect(wx.wxEVT_COMMAND_TREE_ITEM_MENU,
    function (event)
      local item_id = event:GetItem()
      local menu = ide:MakeMenu {
        { BOOKMARKTOGGLE, TR("Toggle Bookmark"), TR("Toggle bookmark") },
        { BREAKPOINTTOGGLE, TR("Toggle Breakpoint"), TR("Toggle breakpoint") },
        { },
        { ID.BOOKMARKFILECLEAR, TR("Clear Bookmarks In File")..KSC(ID.BOOKMARKFILECLEAR) },
        { ID.BREAKPOINTFILECLEAR, TR("Clear Breakpoints In File")..KSC(ID.BREAKPOINTFILECLEAR) },
        { },
        { ID.BOOKMARKPROJECTCLEAR, TR("Clear Bookmarks In Project")..KSC(ID.BOOKMARKPROJECTCLEAR) },
        { ID.BREAKPOINTPROJECTCLEAR, TR("Clear Breakpoints In Project")..KSC(ID.BREAKPOINTPROJECTCLEAR) },
      }
      local itemimage = ctrl:GetItemImage(item_id)

      menu:Enable(BOOKMARKTOGGLE, itemimage == image.BOOKMARK)
      menu:Connect(BOOKMARKTOGGLE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() ctrl:ActivateItem(item_id, "bookmark") end)

      menu:Enable(BREAKPOINTTOGGLE, itemimage == image.BREAKPOINT)
      menu:Connect(BREAKPOINTTOGGLE, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() ctrl:ActivateItem(item_id, "breakpoint") end)

      menu:Enable(ID.BOOKMARKFILECLEAR, itemimage == image.BOOKMARK or itemimage == image.FILE)
      menu:Connect(ID.BOOKMARKFILECLEAR, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() clearMarkersInFile(item_id, "bookmark") end)

      menu:Enable(ID.BREAKPOINTFILECLEAR, itemimage == image.BREAKPOINT or itemimage == image.FILE)
      menu:Connect(ID.BREAKPOINTFILECLEAR, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() clearMarkersInFile(item_id, "breakpoint") end)

      PackageEventHandle("onMenuMarkers", menu, ctrl, event)

      ctrl:PopupMenu(menu)
    end)

  local function reconfigure(pane)
    pane:TopDockable(false):BottomDockable(false)
        :MinSize(150,-1):BestSize(300,-1):FloatingSize(200,300)
  end

  local layout = ide:GetSetting("/view", "uimgrlayout")
  if not layout or not layout:find("markerspanel") then
    ide:AddPanelDocked(ide:GetOutputNotebook(), ctrl, "markerspanel", TR("Markers"), reconfigure, false)
  else
    ide:AddPanel(ctrl, "markerspanel", TR("Markers"), reconfigure)
  end
end

local package = ide:AddPackage('core.markers', {
    onRegister = function(self)
      if not ide.config.markersinactivity then return end

      createMarkersWindow()

      local bmmenu = ide:FindMenuItem(ID.BOOKMARK):GetSubMenu()
      bmmenu:AppendSeparator()
      bmmenu:Append(ID.BOOKMARKFILECLEAR, TR("Clear Bookmarks In File")..KSC(ID.BOOKMARKFILECLEAR))
      bmmenu:Append(ID.BOOKMARKPROJECTCLEAR, TR("Clear Bookmarks In Project")..KSC(ID.BOOKMARKPROJECTCLEAR))

      local bpmenu = ide:FindMenuItem(ID.BREAKPOINT):GetSubMenu()
      bpmenu:AppendSeparator()
      bpmenu:Append(ID.BREAKPOINTFILECLEAR, TR("Clear Breakpoints In File")..KSC(ID.BREAKPOINTFILECLEAR))
      bpmenu:Append(ID.BREAKPOINTPROJECTCLEAR, TR("Clear Breakpoints In Project")..KSC(ID.BREAKPOINTPROJECTCLEAR))

      ide:GetMainFrame():Connect(ID.BOOKMARKFILECLEAR, wx.wxEVT_COMMAND_MENU_SELECTED,
        function()
          local editor = ide:GetEditor()
          if editor then clearAllEditorMarkers("bookmark", editor) end
        end)
      ide:GetMainFrame():Connect(ID.BOOKMARKPROJECTCLEAR, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() clearAllProjectMarkers("bookmark") end)

      ide:GetMainFrame():Connect(ID.BREAKPOINTFILECLEAR, wx.wxEVT_COMMAND_MENU_SELECTED,
        function()
          local editor = ide:GetEditor()
          if editor then clearAllEditorMarkers("breakpoint", editor) end
        end)
      ide:GetMainFrame():Connect(ID.BREAKPOINTPROJECTCLEAR, wx.wxEVT_COMMAND_MENU_SELECTED,
        function() clearAllProjectMarkers("breakpoint") end)
    end,

    -- save markers; remove tab from the list
    onEditorClose = function(self, editor)
      local cache = caches[editor]
      if not cache then return end
      if cache.fileitem then markers.markersCtrl:Delete(cache.fileitem) end
      caches[editor] = nil
    end,

    -- schedule marker update if the change is for one of the editors with markers
    onEditorUpdateUI = function(self, editor, event)
      if not caches[editor] then return end
      if bit.band(event:GetUpdated(), wxstc.wxSTC_UPDATE_CONTENT) == 0 then return end
      needRefresh(editor)
    end,

    onEditorMarkerUpdate = function(self, editor)
      -- if no marker, then all markers in a file need to be refreshed
      if not caches[editor] then caches[editor] = {} end
      needRefresh(editor)
      -- delay saving markers as other EditorMarkerUpdate handlers may still modify them,
      -- but check to make sure that the editor is still valid
      ide:DoWhenIdle(function()
          if ide:IsValidCtrl(editor) then markers:SaveMarkers(editor) end
        end)
    end,

    onEditorSave = function(self, editor) markers:SaveMarkers(editor) end,
    onEditorLoad = function(self, editor) markers:LoadMarkers(editor) end,
  })

function markers:SaveSettings() package:SetSettings(self.settings) end

function markers:SaveMarkers(editor, force)
  -- if the file has the name and has not been modified, save the breakpoints
  -- this also works when the file is saved as the modified flag is already set to `false`
  local doc = ide:GetDocument(editor)
  local filepath = doc:GetFilePath()
  if filepath and (force or not doc:IsModified()) then
    -- remove it from the list if it has no breakpoints
    local edmarkers = getMarkers(editor)
    self.settings.markers[filepath] = #edmarkers > 0 and edmarkers or nil
    self:SaveSettings()
  end
end

function markers:LoadMarkers(editor)
  local doc = ide:GetDocument(editor)
  local filepath = doc:GetFilePath()
  if filepath then
    for _, edmarker in ipairs(self.settings.markers[filepath] or {}) do
      local line, markertype = unpack(edmarker)
      editor:MarkerToggle(markertype, line, true)
    end
  end
end

MergeSettings(markers.settings, package:GetSettings())
