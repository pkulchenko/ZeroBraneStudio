-- Copyright 2011-18 Paul Kulchenko, ZeroBrane LLC
-- authors: Luxinia Dev (Eike Decker & Christoph Kubisch)
-- Lomtik Software (J. Winwood & John Labenski)
---------------------------------------------------------

local ide = ide
local unpack = table.unpack or unpack

do local config = ide.config.editor
  ide.font.editor = wx.wxFont(config.fontsize or 10, wx.wxFONTFAMILY_MODERN,
    wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, false, config.fontname or "",
    config.fontencoding or wx.wxFONTENCODING_DEFAULT)
end

-- treeCtrl font requires slightly different handling
do local font, config = wx.wxTreeCtrl():GetFont(), ide.config.filetree
  if config.fontsize then font:SetPointSize(config.fontsize) end
  if config.fontname then font:SetFaceName(config.fontname) end
  ide.font.tree = font
end

-- ----------------------------------------------------------------------------
-- Create the wxFrame
-- ----------------------------------------------------------------------------
local function createFrame()
  local frame = ide:GetMainFrame() -- retrieve or create as needed
  frame:Center()

  -- update best size of the toolbar after resizing
  frame:Connect(wx.wxEVT_SIZE, function(event)
      local mgr = ide:GetUIManager()
      local toolbar = mgr:GetPane("toolbar")
      if toolbar and toolbar:IsOk() then
        toolbar:BestSize(event:GetSize():GetWidth(), ide:GetToolBar():GetClientSize():GetHeight())
        mgr:Update()
      end
    end)

  local menuBar = wx.wxMenuBar()
  local statusBar = frame:CreateStatusBar(5)
  local section_width = statusBar:GetTextExtent("OVRW")
  statusBar:SetStatusStyles({wx.wxSB_FLAT, wx.wxSB_FLAT, wx.wxSB_FLAT, wx.wxSB_FLAT, wx.wxSB_FLAT})
  statusBar:SetStatusWidths({-1, section_width, section_width, section_width*5, section_width*5})
  statusBar:SetStatusText(ide:GetProperty("statuswelcome", ""))
  statusBar:Connect(wx.wxEVT_LEFT_DOWN, function (event)
      local rect = wx.wxRect()
      statusBar:GetFieldRect(4, rect)
      if rect:Contains(event:GetPosition()) then -- click on the interpreter section
        local interpreter = ide:GetInterpreter()
        if interpreter and interpreter.takeparameters and interpreter:GetCommandLineArg() then
          rect:SetWidth(statusBar:GetTextExtent(ide:GetInterpreter():GetName()..": "))
          if not rect:Contains(event:GetPosition()) then
            local menuitem = ide:FindMenuItem(ID.COMMANDLINEPARAMETERS)
            if menuitem then
              local menu = ide:MakeMenu {
                { ID.COMMANDLINEPARAMETERS, TR("Command Line Parameters...")..KSC(ID.COMMANDLINEPARAMETERS) },
              }
              local cmdargs = ide:GetPackage("core.project"):GetCmdLines()
              local curargs = interpreter:GetCommandLineArg()
              if #cmdargs > 1 or cmdargs[1] ~= curargs then menu:PrependSeparator() end
              local function setParams(ev) ide:SetCommandLineParameters(menu:GetLabel(ev:GetId())) end
              -- do in the reverse order as `Prepend` is used;
              -- skip the currently set parameters
              for i = #cmdargs, 1, -1 do
                if cmdargs[i] ~= curargs then
                  local id = ID("status.commandparameters."..i)
                  menu:Prepend(id, cmdargs[i])
                  menu:Connect(id, wx.wxEVT_COMMAND_MENU_SELECTED, setParams)
                end
              end
              statusBar:PopupMenu(menu)
            end
            return
          end
        end
        local menuitem = ide:FindMenuItem(ID.INTERPRETER)
        if menuitem then
          local menu = ide:CloneMenu(menuitem:GetSubMenu())
          if menu then statusBar:PopupMenu(menu) end
        end
      end
    end)

  local mgr = wxaui.wxAuiManager()
  mgr:SetManagedWindow(frame)
  -- allow the panes to be larger than the defalt 1/3 of the main window size
  mgr:SetDockSizeConstraint(0.8,0.8)

  frame.menuBar = menuBar
  frame.statusBar = statusBar
  frame.uimgr = mgr

  return frame
end

local function SCinB(id) -- shortcut in brackets
  local osx = ide.osname == "Macintosh"
  local shortcut = KSC(id):gsub("\t","")
  return shortcut and #shortcut > 0 and (" ("..shortcut:gsub("%f[%w]Ctrl", osx and "Cmd" or "Ctrl")..")") or ""
end

local function menuDropDownPosition(event)
  local tb = event:GetEventObject():DynamicCast('wxAuiToolBar')
  local rect = tb:GetToolRect(event:GetId())
  return ide.frame:ScreenToClient(tb:ClientToScreen(rect:GetBottomLeft()))
end

local function tbIconSize()
  -- use large icons by default on OSX and on large screens
  local iconsize = tonumber(ide.config.toolbar and ide.config.toolbar.iconsize)
  return (iconsize and (iconsize % 8) == 0 and iconsize
    or ((ide.osname == 'Macintosh' or wx.wxGetClientDisplayRect():GetWidth() >= 1500) and 24 or 16))
end

local function createToolBar(frame)
  local toolBar = wxaui.wxAuiToolBar(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,
    wxaui.wxAUI_TB_PLAIN_BACKGROUND)

  -- there are two sets of icons: use 24 on OSX and 16 on others.
  local iconsize = tbIconSize()
  local toolBmpSize = wx.wxSize(iconsize, iconsize)
  local icons = ide.config.toolbar.icons
  local needseparator = false
  for _, id in ipairs(icons) do
    if icons[id] ~= false then -- skip explicitly disabled icons
      if id == ID.SEPARATOR and toolBar:GetToolCount() > 0 then
        needseparator = true
      else
        local iconmap = ide.config.toolbar.iconmap[id]
        if iconmap then
          if needseparator then
            toolBar:AddSeparator()
            needseparator = false
          end
          local icon, description = unpack(iconmap)
          local isbitmap = type(icon) == "userdata" and icon:GetClassInfo():GetClassName() == "wxBitmap"
          local bitmap = isbitmap and icon or ide:GetBitmap(icon, "TOOLBAR", toolBmpSize)
          toolBar:AddTool(id, "", bitmap, (TR)(description)..SCinB(id))
        end
      end
    end
  end

  toolBar:SetToolDropDown(ID.OPEN, true)
  toolBar:Connect(ID.OPEN, wxaui.wxEVT_COMMAND_AUITOOLBAR_TOOL_DROPDOWN, function(event)
      if event:IsDropDownClicked() then
        local menu = wx.wxMenu({})
        FileRecentListUpdate(menu)
        toolBar:PopupMenu(menu, menuDropDownPosition(event))
      else
        event:Skip()
      end
    end)

  toolBar:SetToolDropDown(ID.PROJECTDIRCHOOSE, true)
  toolBar:Connect(ID.PROJECTDIRCHOOSE, wxaui.wxEVT_COMMAND_AUITOOLBAR_TOOL_DROPDOWN, function(event)
      if event:IsDropDownClicked() then
        local menu = wx.wxMenu({})
        FileTreeProjectListUpdate(menu, 0)
        toolBar:PopupMenu(menu, menuDropDownPosition(event))
      else
        event:Skip()
      end
    end)

  toolBar:GetArtProvider():SetElementSize(wxaui.wxAUI_TBART_GRIPPER_SIZE, 0)
  toolBar:Realize()

  frame.toolBar = toolBar
  return toolBar
end

local function getTabWindow(event, nb)
  local tabctrl = event:GetEventObject():DynamicCast("wxAuiTabCtrl")
  local idx = event:GetSelection() -- index within the current tab ctrl
  local win = tabctrl:GetPage(idx).window
  return win and idx ~= wx.wxNOT_FOUND and nb:GetPageIndex(win) or wx.wxNOT_FOUND, tabctrl
end

local function isPreview(win)
  return ide.findReplace ~= nil and ide.findReplace:IsPreview(win)
end

local function createNotebook(frame)
  -- notebook for editors
  local notebook = ide:CreateNotebook(frame, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize,
    wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE
    + wxaui.wxAUI_NB_WINDOWLIST_BUTTON + wx.wxNO_BORDER)

  -- there is a protected method in wxwidgets, but it's not available in wxlua,
  -- so use a workaround to find the tab control that the page belongs to.
  function notebook:GetTabCtrl(win)
    local pg = win and self:GetPageIndex(win) >= 0 and win or self:GetCurrentPage()
    if not pg then return nil end
    local px,py = pg:GetScreenPosition():GetXY()
    local point = wx.wxPoint(px,py-10) -- right above the page in the notebook
    local ctrl = wx.wxFindWindowAtPoint(point)
    return ctrl and ctrl:DynamicCast("wxAuiTabCtrl") or nil
  end

  -- wxEVT_SET_FOCUS could be used, but it only works on Windows with wx2.9.5+
  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CHANGED,
    function (event)
      local doc = ide:GetDocument(notebook:GetCurrentPage())

      -- skip activation when any of the following is true:
      -- (1) there is no document yet, the editor tab was just added,
      -- so no changes needed as there will be a proper later call;
      -- (2) on OSX from AddPage event when changing from the last tab
      -- (this is to work around a duplicate event generated in this case
      -- that first activates the added tab and then some other tab (2.9.5)).

      local double = (ide.osname == 'Macintosh'
        and event:GetOldSelection() == notebook:GetPageCount()
        and debug:traceback():find("'AddPage'"))

      if doc and doc:GetTabIndex() and not double then
        doc:SetActive()
      end
    end)

  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CLOSE,
    function (event)
      local idx = event:GetSelection()
      if idx ~= wx.wxNOT_FOUND then
        local doc = ide:GetDocument(notebook:GetPage(idx))
        if doc then
          -- make sure that the doc is in the same notebook and is not moved somewhere
          local i, nb = doc:GetTabIndex()
          if i == idx and nb == notebook then doc:Close() end
        end
      end
      event:Veto() -- don't propagate the event as the page is already closed
    end)

  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_BG_DCLICK,
    function (event)
      -- as this event can be on different tab controls,
      -- need to find the control to add the page to
      local tabctrl = event:GetEventObject():DynamicCast("wxAuiTabCtrl")
      -- check if the active page is in the current control
      local active = tabctrl:GetActivePage()
      if (active >= 0 and tabctrl:GetPage(active).window
        ~= notebook:GetPage(notebook:GetSelection())) then
        -- if not, need to activate the control that was clicked on;
        -- find the last window and switch to it (assuming there is always one)
        assert(tabctrl:GetPageCount() >= 1, "Expected at least one page in a notebook tab control.")
        local lastwin = tabctrl:GetPage(tabctrl:GetPageCount()-1).window
        notebook:SetSelection(notebook:GetPageIndex(lastwin))
      end
      NewFile()
    end)

  -- tabs can be dragged around which may change their indexes;
  -- when this happens stored indexes need to be updated to reflect the change.
  -- there is DRAG_DONE event that I'd prefer to use, but it
  -- doesn't fire for some reason using wxwidgets 2.9.5 (tested on Windows).
  if ide.wxver >= "2.9.5" then
    notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_END_DRAG,
      function (event)
        local selection = getTabWindow(event, notebook)
        if selection == wx.wxNOT_FOUND then return end
        -- set the selection on the dragged tab to reset its state
        -- workaround for wxwidgets issue http://trac.wxwidgets.org/ticket/15071
        notebook:SetSelection(selection)
        -- select the content of the tab after drag is done
        local doc = ide:GetDocument(notebook:GetPage(selection))
        if doc then doc:SetActive() end
        event:Skip()
      end)
  end

  local selection
  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_TAB_RIGHT_UP,
    function (event)
      -- event:GetSelection() returns the index *inside the current tab*;
      -- for split notebooks, this may not be the same as the index
      -- in the notebook we are interested in here
      local idx = event:GetSelection()
      if idx == wx.wxNOT_FOUND then return end
      local tabctrl = event:GetEventObject():DynamicCast("wxAuiTabCtrl")

      -- save the editor from the tab initiating the event
      selection = tabctrl:GetPage(idx).window
      -- save tab index the event is for
      local curindex = notebook:GetSelection()
      local selindex = notebook:GetPageIndex(selection)
      if curindex ~= selindex then notebook:SetSelection(selindex) end

      local tree = ide:GetProjectTree()
      local startfile = tree:GetStartFile()

      local menu = ide:MakeMenu {
        { ID.CLOSE, TR("&Close Page") },
        { ID.CLOSEALL, TR("Close A&ll Pages") },
        { ID.CLOSEOTHER, TR("Close &Other Pages") },
        { ID.CLOSESEARCHRESULTS, TR("Close Search Results Pages") },
        { },
        { ID.SAVE, TR("&Save") },
        { ID.SAVEAS, TR("Save &As...") },
        { },
        { ID.SETSTARTFILE, TR("Set As Start File") },
        { ID.UNSETSTARTFILE, TR("Unset '%s' As Start File"):format(startfile or "<none>") },
        { },
        { ID.COPYFULLPATH, TR("Copy Full Path") },
        { ID.SHOWLOCATION, TR("Open Containing Folder") },
        { ID.REFRESHSEARCHRESULTS, TR("Refresh Search Results") },
      }

      local fpath = ide:GetDocument(selection):GetFilePath()
      if not fpath or not tree:FindItem(fpath) then menu:Enable(ID.SETSTARTFILE, false) end
      if not startfile then menu:Destroy(ID.UNSETSTARTFILE) end

      PackageEventHandle("onMenuEditorTab", menu, notebook, event, notebook:GetPageIndex(selection))

      -- popup statuses are not refreshed on Linux, so do it manually
      if ide.osname == "Unix" then UpdateMenuUI(menu, notebook) end
      notebook:PopupMenu(menu)
      -- restore selection if it has changed
      if curindex ~= selindex then notebook:SetSelection(curindex) end
    end)

  local function IfAtLeastOneTab(event) event:Enable(notebook:GetPageCount() > 0) end

  notebook:Connect(ID.SETSTARTFILE, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      local fpath = ide:GetDocument(selection):GetFilePath()
      if fpath then ide:GetProjectTree():SetStartFile(fpath) end
    end)
  notebook:Connect(ID.UNSETSTARTFILE, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide:GetProjectTree():SetStartFile()
    end)
  notebook:Connect(ID.SAVE, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide:GetDocument(selection):Save()
    end)
  notebook:Connect(ID.SAVE, wx.wxEVT_UPDATE_UI, function(event)
      local doc = ide:GetDocument(selection)
      event:Enable(doc:IsModified() or doc:IsNew())
    end)
  notebook:Connect(ID.SAVEAS, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      SaveFileAs(selection)
    end)
  notebook:Connect(ID.SAVEAS, wx.wxEVT_UPDATE_UI, IfAtLeastOneTab)

  -- the following three methods require handling of closing in the idle event,
  -- because of wxwidgets issue that causes crash on OSX when the last page is closed
  -- (http://trac.wxwidgets.org/ticket/15417)
  notebook:Connect(ID.CLOSE, wx.wxEVT_UPDATE_UI, IfAtLeastOneTab)
  notebook:Connect(ID.CLOSE, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide:DoWhenIdle(function() ide:GetDocument(selection):Close() end)
    end)

  notebook:Connect(ID.CLOSEALL, wx.wxEVT_UPDATE_UI, IfAtLeastOneTab)
  notebook:Connect(ID.CLOSEALL, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide:DoWhenIdle(function()
          ide:GetDocument(selection):CloseAll({scope = "section"})
        end)
    end)

  notebook:Connect(ID.CLOSEOTHER, wx.wxEVT_UPDATE_UI, function(event)
      event:Enable(notebook:GetPageCount() > 1)
    end)
  notebook:Connect(ID.CLOSEOTHER, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide:DoWhenIdle(function()
          ide:GetDocument(selection):CloseAll({keep = true, scope = "section"})
        end)
    end)

  notebook:Connect(ID.CLOSESEARCHRESULTS, wx.wxEVT_UPDATE_UI, function(event)
      local ispreview = false
      for p = 0, notebook:GetPageCount()-1 do
        ispreview = ispreview or isPreview(notebook:GetPage(p))
      end
      event:Enable(ispreview)
    end)
  notebook:Connect(ID.CLOSESEARCHRESULTS, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide:DoWhenIdle(function()
          for p = notebook:GetPageCount()-1, 0, -1 do
            local editor = notebook:GetPage(p)
            if isPreview(editor) then ide:GetDocument(editor):Close() end
          end
        end)
    end)

  notebook:Connect(ID.REFRESHSEARCHRESULTS, wx.wxEVT_UPDATE_UI, function(event)
      event:Enable(isPreview(selection))
    end)
  notebook:Connect(ID.REFRESHSEARCHRESULTS, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide.findReplace:RefreshResults(selection)
    end)

  notebook:Connect(ID.SHOWLOCATION, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ShowLocation(ide:GetDocument(selection):GetFilePath())
    end)
  notebook:Connect(ID.SHOWLOCATION, wx.wxEVT_UPDATE_UI, IfAtLeastOneTab)

  notebook:Connect(ID.COPYFULLPATH, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide:CopyToClipboard(ide:GetDocument(selection):GetFilePath())
    end)

  frame.notebook = notebook
  return notebook
end

local function addDND(notebook)
  -- this handler allows dragging tabs into this notebook
  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_ALLOW_DND,
    function (event)
      local notebookfrom = event:GetDragSource()
      if notebookfrom ~= ide.frame.notebook then
        -- disable cross-notebook movement of specific tabs
        local idx = event:GetSelection()
        if idx == wx.wxNOT_FOUND then return end
        local win = notebookfrom:GetPage(idx)
        if not win then return end
        local winid = win:GetId()
        if (ide:IsValidCtrl(ide:GetOutput()) and winid == ide:GetOutput():GetId())
        or (ide:IsValidCtrl(ide:GetConsole()) and winid == ide:GetConsole():GetId())
        or (ide:IsValidCtrl(ide:GetProjectTree()) and winid == ide:GetProjectTree():GetId())
        or isPreview(win) -- search results preview
        then return end

        local mgr = ide.frame.uimgr
        local pane = mgr:GetPane(notebookfrom)
        if not pane:IsOk() then return end -- not a managed window
        if pane:IsFloating() then
          notebookfrom:GetParent():Hide()
        else
          pane:Hide()
          mgr:Update()
        end
        mgr:DetachPane(notebookfrom)

        -- this is a workaround for wxwidgets bug (2.9.5+) that combines
        -- content from two windows when tab is dragged over an active tab.
        local mouse = wx.wxGetMouseState()
        local mouseatpoint = wx.wxPoint(mouse:GetX(), mouse:GetY())
        local ok, tabs = pcall(function() return wx.wxFindWindowAtPoint(mouseatpoint):DynamicCast("wxAuiTabCtrl") end)
        if ok then tabs:SetNoneActive() end

        event:Allow()
      end
    end)

  -- these handlers allow dragging tabs out of this notebook.
  -- I couldn't find a good way to stop dragging event as it's not known
  -- where the event is going to end when it's started, so we manipulate
  -- the flag that allows splits and disable it when needed.
  -- It is then enabled in BEGIN_DRAG event.
  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_BEGIN_DRAG,
    function (event)
      event:Skip()

      -- allow dragging if it was disabled earlier
      local flags = notebook:GetWindowStyleFlag()
      if bit.band(flags, wxaui.wxAUI_NB_TAB_SPLIT) == 0 then
        notebook:SetWindowStyleFlag(flags + wxaui.wxAUI_NB_TAB_SPLIT)
      end
    end)

  -- there is currently no support in wxAuiNotebook for dragging tabs out.
  -- This is implemented as removing a tab that was dragged out and
  -- recreating it with the right control. This is complicated by the fact
  -- that tabs can be split, so if the destination is withing the area where
  -- splits happen, the tab is not removed.
  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_END_DRAG,
    function (event)
      event:Skip()

      local mgr = ide.frame.uimgr
      local win = mgr:GetPane(notebook).window
      local x = win:GetScreenPosition():GetX()
      local y = win:GetScreenPosition():GetY()
      local w, h = win:GetSize():GetWidth(), win:GetSize():GetHeight()

      local selection, tabctrl = getTabWindow(event, notebook)
      if selection == wx.wxNOT_FOUND then return end

      local mouse = wx.wxGetMouseState()
      local mx, my = mouse:GetX(), mouse:GetY()
      if mx < x or mx > x + w or my < y or my > y + h then
        -- disallow split as the target is outside the notebook
        local flags = notebook:GetWindowStyleFlag()
        if bit.band(flags, wxaui.wxAUI_NB_TAB_SPLIT) ~= 0 then
          notebook:SetWindowStyleFlag(flags - wxaui.wxAUI_NB_TAB_SPLIT)
        end

        if ide.wxver < "3.0" then
          -- don't allow dragging out single tabs from tab ctrl
          -- as wxwidgets doesn't like removing pages from split notebooks.
          if tabctrl:GetPageCount() == 1 then return end
        end

        -- don't allow last pages to be dragged out from Project and Output notebooks
        if (notebook == ide:GetProjectNotebook() or notebook == ide:GetOutputNotebook())
        and notebook:GetPageCount() == 1 then
          return
        end

        local label = notebook:GetPageText(selection)
        local pane = ide:RestorePanelByLabel(label)
        if pane then
          pane:FloatingPosition(mx-10, my-10)
          pane:Show()
          notebook:RemovePage(selection)
          mgr:Update()
          return
        end
      end

      -- set the selection on the dragged tab to reset its state
      -- workaround for wxwidgets issue http://trac.wxwidgets.org/ticket/15071
      notebook:SetSelection(selection)
      -- set focus on the content of the selected tab
      notebook:GetPage(selection):SetFocus()
    end)
end

local function createBottomNotebook(frame)
  -- bottomnotebook (errorlog,shellbox)
  local bottomnotebook = ide:CreateNotebook(frame, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize,
    wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE
    - wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB + wx.wxNO_BORDER)

  addDND(bottomnotebook)

  bottomnotebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CHANGED,
    function (event)
      local nb = event:GetEventObject():DynamicCast("wxAuiNotebook")
      -- set focus on the new page
      local idx = event:GetSelection()
      if idx == wx.wxNOT_FOUND then return end
      nb:GetPage(idx):SetFocus()

      local preview = isPreview(nb:GetPage(nb:GetSelection()))
      local flags = nb:GetWindowStyleFlag()
      if preview and bit.band(flags, wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB) == 0 then
        nb:SetWindowStyleFlag(flags + wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB)
      elseif not preview and bit.band(flags, wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB) ~= 0 then
        nb:SetWindowStyleFlag(flags - wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB)
      end
    end)

  -- disallow tabs closing
  bottomnotebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CLOSE,
    function (event)
      local nb = event:GetEventObject():DynamicCast("wxAuiNotebook")
      if isPreview(nb:GetPage(nb:GetSelection())) then
        event:Skip()
      else
        event:Veto()
      end
    end)

  local selection
  bottomnotebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_TAB_RIGHT_UP,
    function (event)
      -- event:GetSelection() returns the index *inside the current tab*;
      -- for split notebooks, this may not be the same as the index
      -- in the notebook we are interested in here
      local idx = event:GetSelection()
      if idx == wx.wxNOT_FOUND then return end
      local tabctrl = event:GetEventObject():DynamicCast("wxAuiTabCtrl")

      -- save tab index the event is for
      selection = bottomnotebook:GetPageIndex(tabctrl:GetPage(idx).window)

      local menu = ide:MakeMenu {
        { ID.CLOSE, TR("&Close Page") },
        { ID.CLOSESEARCHRESULTS, TR("Close Search Results Pages") },
        { },
        { ID.REFRESHSEARCHRESULTS, TR("Refresh Search Results") },
      }

      PackageEventHandle("onMenuOutputTab", menu, bottomnotebook, event, selection)

      -- popup statuses are not refreshed on Linux, so do it manually
      if ide.osname == "Unix" then UpdateMenuUI(menu, bottomnotebook) end
      bottomnotebook:PopupMenu(menu)
    end)

  bottomnotebook:Connect(ID.CLOSE, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide:DoWhenIdle(function() bottomnotebook:DeletePage(selection) end)
    end)
  bottomnotebook:Connect(ID.CLOSE, wx.wxEVT_UPDATE_UI, function(event)
      event:Enable(isPreview(bottomnotebook:GetPage(selection)))
    end)

  bottomnotebook:Connect(ID.CLOSESEARCHRESULTS, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide:DoWhenIdle(function()
          for p = bottomnotebook:GetPageCount()-1, 0, -1 do
            if isPreview(bottomnotebook:GetPage(p)) then bottomnotebook:DeletePage(p) end
          end
        end)
    end)
  bottomnotebook:Connect(ID.CLOSESEARCHRESULTS, wx.wxEVT_UPDATE_UI, function(event)
      local ispreview = false
      for p = 0, bottomnotebook:GetPageCount()-1 do
        ispreview = ispreview or isPreview(bottomnotebook:GetPage(p))
      end
      event:Enable(ispreview)
    end)

  bottomnotebook:Connect(ID.REFRESHSEARCHRESULTS, wx.wxEVT_UPDATE_UI, function(event)
      event:Enable(isPreview(bottomnotebook:GetPage(selection)))
    end)
  bottomnotebook:Connect(ID.REFRESHSEARCHRESULTS, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ide.findReplace:RefreshResults(bottomnotebook:GetPage(selection))
    end)

  local errorlog = ide:CreateStyledTextCtrl(bottomnotebook, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBORDER_NONE)

  errorlog:Connect(wx.wxEVT_CONTEXT_MENU,
    function (event)
      local menu = ide:MakeMenu {
          { ID.UNDO, TR("&Undo")..KSC(ID.UNDO) },
          { ID.REDO, TR("&Redo")..KSC(ID.REDO) },
          { },
          { ID.CUT, TR("Cu&t")..KSC(ID.CUT) },
          { ID.COPY, TR("&Copy")..KSC(ID.COPY) },
          { ID.PASTE, TR("&Paste")..KSC(ID.PASTE) },
          { ID.SELECTALL, TR("Select &All")..KSC(ID.SELECTALL) },
          { },
          { ID.CLEAROUTPUT, TR("C&lear Output Window")..KSC(ID.CLEAROUTPUT) },
        }
      PackageEventHandle("onMenuOutput", menu, errorlog, event)

      -- popup statuses are not refreshed on Linux, so do it manually
      if ide.osname == "Unix" then UpdateMenuUI(menu, errorlog) end
      errorlog:PopupMenu(menu)
    end)

  -- connect to the main frame, so it can be called from anywhere
  frame:Connect(ID.CLEAROUTPUT, wx.wxEVT_COMMAND_MENU_SELECTED,
    function(event) ide:GetOutput():Erase() end)

  local shellbox = ide:CreateStyledTextCtrl(bottomnotebook, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBORDER_NONE)

  local menupos
  shellbox:Connect(wx.wxEVT_CONTEXT_MENU,
    function (event)
      local menu = ide:MakeMenu {
          { ID.UNDO, TR("&Undo")..KSC(ID.UNDO) },
          { ID.REDO, TR("&Redo")..KSC(ID.REDO) },
          { },
          { ID.CUT, TR("Cu&t")..KSC(ID.CUT) },
          { ID.COPY, TR("&Copy")..KSC(ID.COPY) },
          { ID.PASTE, TR("&Paste")..KSC(ID.PASTE) },
          { ID.SELECTALL, TR("Select &All")..KSC(ID.SELECTALL) },
          { },
          { ID.SELECTCONSOLECOMMAND, TR("&Select Command") },
          { ID.CLEARCONSOLE, TR("C&lear Console Window")..KSC(ID.CLEARCONSOLE) },
        }
      menupos = event:GetPosition()
      PackageEventHandle("onMenuConsole", menu, shellbox, event)

      -- popup statuses are not refreshed on Linux, so do it manually
      if ide.osname == "Unix" then UpdateMenuUI(menu, shellbox) end
      shellbox:PopupMenu(menu)
    end)

  shellbox:Connect(ID.SELECTCONSOLECOMMAND, wx.wxEVT_COMMAND_MENU_SELECTED,
    function(event) ConsoleSelectCommand(menupos) end)

  -- connect to the main frame, so it can be called from anywhere
  frame:Connect(ID.CLEARCONSOLE, wx.wxEVT_COMMAND_MENU_SELECTED,
    function(event) ide:GetConsole():Erase() end)

  bottomnotebook:AddPage(errorlog, TR("Output"), true)
  bottomnotebook:AddPage(shellbox, TR("Local console"), false)

  bottomnotebook.errorlog = errorlog
  bottomnotebook.shellbox = shellbox

  frame.bottomnotebook = bottomnotebook
  return bottomnotebook
end

local function createProjNotebook(frame)
  local projnotebook = ide:CreateNotebook(frame, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize,
    wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE
    - wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB + wx.wxNO_BORDER)

  addDND(projnotebook)

  -- disallow tabs closing
  projnotebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CLOSE,
    function (event) event:Veto() end)

  frame.projnotebook = projnotebook
  return projnotebook
end

-- ----------------------------------------------------------------------------
-- Add the child windows to the frame

local frame = createFrame()
createToolBar(frame)
createNotebook(frame)
createProjNotebook(frame)
createBottomNotebook(frame)

do
  local mgr = frame.uimgr

  mgr:AddPane(frame.toolBar, wxaui.wxAuiPaneInfo():
    Name("toolbar"):Caption("Toolbar"):
    ToolbarPane():Top():CloseButton(false):PaneBorder(false):
    LeftDockable(false):RightDockable(false))
  mgr:AddPane(frame.notebook, wxaui.wxAuiPaneInfo():
    Name("notebook"):
    CenterPane():PaneBorder(false))
  mgr:AddPane(frame.projnotebook, wxaui.wxAuiPaneInfo():
    Name("projpanel"):CaptionVisible(false):
    MinSize(200,200):BestSize(300,300):FloatingSize(200,400):
    Left():Layer(1):Position(1):PaneBorder(false):
    CloseButton(true):MaximizeButton(false):PinButton(true))
  mgr:AddPane(frame.bottomnotebook, wxaui.wxAuiPaneInfo():
    Name("bottomnotebook"):CaptionVisible(false):
    MinSize(100,100):BestSize(200,200):FloatingSize(400,200):
    Bottom():Layer(1):Position(1):PaneBorder(false):
    CloseButton(true):MaximizeButton(false):PinButton(true))

  if type(ide.config.bordersize) == 'number' then
    for _, uimgr in pairs {mgr, frame.notebook:GetAuiManager(),
      frame.bottomnotebook:GetAuiManager(), frame.projnotebook:GetAuiManager()} do
      uimgr:GetArtProvider():SetMetric(wxaui.wxAUI_DOCKART_SASH_SIZE,
        ide.config.bordersize)
    end
  end

  for _, nb in pairs {frame.bottomnotebook, frame.projnotebook} do
    nb:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_BG_DCLICK,
      function() PaneFloatToggle(nb) end)
  end

  mgr.defaultPerspective = mgr:SavePerspective()
end
