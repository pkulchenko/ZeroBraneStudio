-- Copyright 2011-14 Paul Kulchenko, ZeroBrane LLC
-- authors: Luxinia Dev (Eike Decker & Christoph Kubisch)
-- Lomtik Software (J. Winwood & John Labenski)
---------------------------------------------------------

local ide = ide

-- Pick some reasonable fixed width fonts to use for the editor
local function setFont(style, config)
  return wx.wxFont(config.fontsize or 10, wx.wxFONTFAMILY_MODERN, style,
    wx.wxFONTWEIGHT_NORMAL, false, config.fontname or "",
    config.fontencoding or wx.wxFONTENCODING_DEFAULT)
end
ide.font.eNormal = setFont(wx.wxFONTSTYLE_NORMAL, ide.config.editor)
ide.font.eItalic = setFont(wx.wxFONTSTYLE_ITALIC, ide.config.editor)

ide.font.oNormal = setFont(wx.wxFONTSTYLE_NORMAL, ide.config.outputshell)
ide.font.oItalic = setFont(wx.wxFONTSTYLE_ITALIC, ide.config.outputshell)

-- treeCtrl font requires slightly different handling
do local gui, config = wx.wxTreeCtrl():GetFont(), ide.config.filetree
  if config.fontsize then gui:SetPointSize(config.fontsize) end
  if config.fontname then gui:SetFaceName(config.fontname) end
  ide.font.fNormal = gui
end

-- funcList font requires similar handling
do local gui, config = wx.wxTreeCtrl():GetFont(), ide.config.funclist
  if config.fontsize then gui:SetPointSize(config.fontsize) end
  if config.fontname then gui:SetFaceName(config.fontname) end
  ide.font.dNormal = gui
end

-- ----------------------------------------------------------------------------
-- Create the wxFrame
-- ----------------------------------------------------------------------------
local function createFrame()
  local frame = wx.wxFrame(wx.NULL, wx.wxID_ANY, GetIDEString("editor"),
    wx.wxDefaultPosition, wx.wxSize(1000, 700))
  -- wrap into protected call as DragAcceptFiles fails on MacOS with
  -- wxwidgets 2.8.12 even though it should work according to change notes
  -- for 2.8.10: "Implemented wxWindow::DragAcceptFiles() on all platforms."
  pcall(function() frame:DragAcceptFiles(true) end)
  frame:Connect(wx.wxEVT_DROP_FILES,function(evt)
      local files = evt:GetFiles()
      if not files or #files == 0 then return end
      for i,f in ipairs(files) do
        LoadFile(f,nil,true)
      end
    end)

  local menuBar = wx.wxMenuBar()
  local statusBar = frame:CreateStatusBar(6)
  local section_width = statusBar:GetTextExtent("OVRW")
  statusBar:SetStatusStyles({wx.wxSB_FLAT, wx.wxSB_FLAT, wx.wxSB_FLAT,
    wx.wxSB_FLAT, wx.wxSB_FLAT, wx.wxSB_FLAT})
  statusBar:SetStatusWidths(
    {-1, section_width*6, section_width, section_width, section_width*5, section_width*4})
  statusBar:SetStatusText(GetIDEString("statuswelcome"))
  
  local mgr = wxaui.wxAuiManager()
  mgr:SetManagedWindow(frame)

  frame.menuBar = menuBar
  frame.statusBar = statusBar
  frame.uimgr = mgr

  return frame
end

local function SCinB(id) -- shortcut in brackets
  local shortcut = KSC(id):gsub("\t","")
  return shortcut and #shortcut > 0 and (" ("..shortcut..")") or ""
end

local function menuDropDownPosition(event)
  local tb = event:GetEventObject():DynamicCast('wxAuiToolBar')
  local rect = tb:GetToolRect(event:GetId())
  return ide.frame:ScreenToClient(tb:ClientToScreen(rect:GetBottomLeft()))
end

local function createToolBar(frame)
  local toolBar = wxaui.wxAuiToolBar(frame, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize,
    wxaui.wxAUI_TB_PLAIN_BACKGROUND)
  -- wxChoice is a bit too narrow on Linux, so make it a bit larger
  local funclist = wx.wxChoice.new(toolBar, ID "toolBar.funclist",
    wx.wxDefaultPosition, wx.wxSize.new(240, ide.osname == 'Unix' and 28 or 24))
  
  -- there are two sets of icons: use 24 on OSX and 16 on others.
  local toolBmpSize =
    ide.osname == 'Macintosh' and wx.wxSize(24, 24) or wx.wxSize(16, 16)
  local getBitmap = (ide.app.createbitmap or wx.wxArtProvider.GetBitmap)
  toolBar:AddTool(ID_NEW, "New", getBitmap(wx.wxART_NORMAL_FILE, wx.wxART_TOOLBAR, toolBmpSize), TR("Create an empty document")..SCinB(ID_NEW))
  toolBar:AddTool(ID_OPEN, "Open", getBitmap(wx.wxART_FILE_OPEN, wx.wxART_TOOLBAR, toolBmpSize), TR("Open an existing document")..SCinB(ID_OPEN))
  toolBar:AddTool(ID_SAVE, "Save", getBitmap(wx.wxART_FILE_SAVE, wx.wxART_TOOLBAR, toolBmpSize), TR("Save the current document")..SCinB(ID_SAVE))
  toolBar:AddTool(ID_SAVEALL, "Save All", getBitmap(wx.wxART_NEW_DIR, wx.wxART_TOOLBAR, toolBmpSize), TR("Save all open documents")..SCinB(ID_SAVEALL))
  toolBar:AddTool(ID_PROJECTDIRFROMFILE, "Update", getBitmap(wx.wxART_GO_DIR_UP, wx.wxART_TOOLBAR, toolBmpSize), TR("Set project directory from current file")..SCinB(ID_PROJECTDIRFROMFILE))
  toolBar:AddTool(ID_PROJECTDIRCHOOSE, "Choose", getBitmap("wxART_DIR_SETUP", wx.wxART_TOOLBAR, toolBmpSize), TR("Choose a project directory")..SCinB(ID_PROJECTDIRCHOOSE))
  toolBar:AddSeparator()
  toolBar:AddTool(ID_FIND, "Find", getBitmap(wx.wxART_FIND, wx.wxART_TOOLBAR, toolBmpSize), TR("Find text")..SCinB(ID_FIND))
  toolBar:AddTool(ID_REPLACE, "Replace", getBitmap(wx.wxART_FIND_AND_REPLACE, wx.wxART_TOOLBAR, toolBmpSize), TR("Find and replace text")..SCinB(ID_REPLACE))
  if ide.app.createbitmap then -- custom handler should handle all bitmaps
    toolBar:AddSeparator()
    toolBar:AddTool(ID_STARTDEBUG, "Start Debugging", getBitmap("wxART_DEBUG_START", wx.wxART_TOOLBAR, toolBmpSize), TR("Start or Continue debugging")..SCinB(ID_STARTDEBUG))
    toolBar:AddTool(ID_STOPDEBUG, "Stop Debugging", getBitmap("wxART_DEBUG_STOP", wx.wxART_TOOLBAR, toolBmpSize), TR("Stop the currently running process")..SCinB(ID_STOPDEBUG))
    toolBar:AddTool(ID_DETACHDEBUG, "Detach Process", getBitmap("wxART_DEBUG_DETACH", wx.wxART_TOOLBAR, toolBmpSize), TR("Stop debugging and continue running the process")..SCinB(ID_DETACHDEBUG))
    toolBar:AddTool(ID_BREAK, "Break", getBitmap("wxART_DEBUG_BREAK", wx.wxART_TOOLBAR, toolBmpSize), TR("Break execution at the next executed line of code")..SCinB(ID_BREAK))
    toolBar:AddTool(ID_STEP, "Step into", getBitmap("wxART_DEBUG_STEP_INTO", wx.wxART_TOOLBAR, toolBmpSize), TR("Step into")..SCinB(ID_STEP))
    toolBar:AddTool(ID_STEPOVER, "Step over", getBitmap("wxART_DEBUG_STEP_OVER", wx.wxART_TOOLBAR, toolBmpSize), TR("Step over")..SCinB(ID_STEPOVER))
    toolBar:AddTool(ID_STEPOUT, "Step out", getBitmap("wxART_DEBUG_STEP_OUT", wx.wxART_TOOLBAR, toolBmpSize), TR("Step out of the current function")..SCinB(ID_STEPOUT))
    toolBar:AddSeparator()
    toolBar:AddTool(ID_TOGGLEBREAKPOINT, "Toggle breakpoint", getBitmap("wxART_DEBUG_BREAKPOINT_TOGGLE", wx.wxART_TOOLBAR, toolBmpSize), TR("Toggle breakpoint")..SCinB(ID_TOGGLEBREAKPOINT))
    toolBar:AddTool(ID_VIEWCALLSTACK, "Stack window", getBitmap("wxART_DEBUG_CALLSTACK", wx.wxART_TOOLBAR, toolBmpSize), TR("View the stack window")..SCinB(ID_VIEWCALLSTACK))
    toolBar:AddTool(ID_VIEWWATCHWINDOW, "Watch window", getBitmap("wxART_DEBUG_WATCH", wx.wxART_TOOLBAR, toolBmpSize), TR("View the watch window")..SCinB(ID_VIEWWATCHWINDOW))
  end
  toolBar:AddSeparator()
  toolBar:AddControl(funclist)

  toolBar:SetToolDropDown(ID_OPEN, true)
  toolBar:Connect(ID_OPEN, wxaui.wxEVT_COMMAND_AUITOOLBAR_TOOL_DROPDOWN, function(event)
    if event:IsDropDownClicked() then
      local menu = wx.wxMenu()
      FileRecentListUpdate(menu)
      toolBar:PopupMenu(menu, menuDropDownPosition(event))
    else
      event:Skip()
    end
  end)

  toolBar:SetToolDropDown(ID_PROJECTDIRCHOOSE, true)
  toolBar:Connect(ID_PROJECTDIRCHOOSE, wxaui.wxEVT_COMMAND_AUITOOLBAR_TOOL_DROPDOWN, function(event)
    if event:IsDropDownClicked() then
      local menu = wx.wxMenu()
      FileTreeProjectListUpdate(menu, 0)
      toolBar:PopupMenu(menu, menuDropDownPosition(event))
    else
      event:Skip()
    end
  end)

  toolBar:GetArtProvider():SetElementSize(wxaui.wxAUI_TBART_GRIPPER_SIZE, 0)
  toolBar:Realize()

  toolBar.funclist = funclist
  frame.toolBar = toolBar
  return toolBar
end

local function createNotebook(frame)
  -- notebook for editors
  local notebook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY,
  wx.wxDefaultPosition, wx.wxDefaultSize,
  wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE
  + wxaui.wxAUI_NB_WINDOWLIST_BUTTON + wx.wxNO_BORDER)

  -- wxEVT_SET_FOCUS could be used, but it only works on Windows with wx2.9.5+
  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CHANGED,
    function (event)
      local ed = GetEditor(notebook:GetSelection())
      local doc = ed and ed:GetId() and ide.openDocuments[ed:GetId()]

      -- skip activation when any of the following is true:
      -- (1) there is no document yet, the editor tab was just added,
      -- so no changes needed as there will be a proper later call;
      -- (2) the page change event was triggered after a tab is closed;
      -- (3) on OSX from AddPage event when changing from the last tab
      -- (this is to work around a duplicate event generated in this case
      -- that first activates the added tab and then some other tab (2.9.5)).

      local double = (ide.osname == 'Macintosh'
        and event:GetOldSelection() == notebook:GetPageCount()
        and debug:traceback():find("'AddPage'"))

      if doc and event:GetOldSelection() ~= -1 and not double then
        -- switching between editor tabs doesn't trigger KILL_FOCUS events
        -- on OSX (http://trac.wxwidgets.org/ticket/14142); trigger manually
        if ide.osname == 'Macintosh' then
          local win = notebook:GetPage(event:GetOldSelection())
          local ev = wx.wxFocusEvent(wx.wxEVT_KILL_FOCUS)
          win:GetEventHandler():ProcessEvent(ev)
        end
        SetEditorSelection(notebook:GetSelection())
      end
    end)

  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CLOSE,
    function (event)
      ClosePage(event:GetSelection())
      event:Veto() -- don't propagate the event as the page is already closed
    end)

  notebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_BG_DCLICK,
    function (event)
      -- as this event can be on different tab controls,
      -- need to find the control to add the page to
      local tabctrl = event:GetEventObject():DynamicCast("wxAuiTabCtrl")
      -- check if the active page is in the current control
      local active = tabctrl:GetActivePage()
      if active >= 0 and tabctrl:GetPage(active).window
        ~= notebook:GetPage(notebook:GetSelection()) then
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
        for page = 0, notebook:GetPageCount()-1 do
          local editor = GetEditor(page)
          if editor then ide.openDocuments[editor:GetId()].index = page end
        end
        -- select the content of the tab after drag is done
        SetEditorSelection(event:GetSelection())
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
      local tabctrl = event:GetEventObject():DynamicCast("wxAuiTabCtrl")

      -- save tab index the event is for
      selection = notebook:GetPageIndex(tabctrl:GetPage(idx).window)

      local menu = wx.wxMenu {
        { ID_CLOSE, TR("&Close Page") },
        { ID_CLOSEALL, TR("Close A&ll Pages") },
        { ID_CLOSEOTHER, TR("Close &Other Pages") },
        { },
        { ID_SAVE, TR("&Save") },
        { ID_SAVEAS, TR("Save &As...") },
        { },
        { ID_COPYFULLPATH, TR("Copy Full Path") },
        { ID_SHOWLOCATION, TR("Show Location") },
      }

      PackageEventHandle("onMenuEditorTab", menu, notebook, event, selection)

      notebook:PopupMenu(menu)
    end)

  local function IfAtLeastOneTab(event)
    event:Enable(notebook:GetPageCount() > 0)
    if ide.osname == 'Macintosh' and (event:GetId() == ID_CLOSEALL
    or event:GetId() == ID_CLOSE and notebook:GetPageCount() <= 1)
    then event:Enable(false) end
  end
  local function IfModified(event) event:Enable(EditorIsModified(GetEditor(selection))) end

  notebook:Connect(ID_SAVE, wx.wxEVT_COMMAND_MENU_SELECTED, function ()
      local editor = GetEditor(selection)
      SaveFile(editor, ide.openDocuments[editor:GetId()].filePath)
    end)
  notebook:Connect(ID_SAVE, wx.wxEVT_UPDATE_UI, IfModified)
  notebook:Connect(ID_SAVEAS, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      SaveFileAs(GetEditor(selection))
    end)
  notebook:Connect(ID_SAVEAS, wx.wxEVT_UPDATE_UI, IfAtLeastOneTab)
  notebook:Connect(ID_CLOSE, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ClosePage(selection)
    end)
  notebook:Connect(ID_CLOSE, wx.wxEVT_UPDATE_UI, IfAtLeastOneTab)
  notebook:Connect(ID_CLOSEALL, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      CloseAllPagesExcept(nil)
    end)
  notebook:Connect(ID_CLOSEALL, wx.wxEVT_UPDATE_UI, IfAtLeastOneTab)
  notebook:Connect(ID_CLOSEOTHER, wx.wxEVT_COMMAND_MENU_SELECTED, function ()
      CloseAllPagesExcept(selection)
    end)
  notebook:Connect(ID_CLOSEOTHER, wx.wxEVT_UPDATE_UI, function (event)
      event:Enable(notebook:GetPageCount() > 1)
    end)
  notebook:Connect(ID_SHOWLOCATION, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      ShowLocation(ide:GetDocument(GetEditor(selection)):GetFilePath())
    end)
  notebook:Connect(ID_SHOWLOCATION, wx.wxEVT_UPDATE_UI, IfAtLeastOneTab)
  
  notebook:Connect(ID_COPYFULLPATH, wx.wxEVT_COMMAND_MENU_SELECTED, function()
		local tdo = wx.wxTextDataObject(ide:GetDocument(GetEditor(selection)):GetFilePath())
		if wx.wxClipboard:Get():Open() then
			wx.wxClipboard:Get():SetData(tdo)
			wx.wxClipboard:Get():Close()
		end
    end)

  frame.notebook = notebook
  return notebook
end

local function createBottomNotebook(frame)
  -- bottomnotebook (errorlog,shellbox)
  local bottomnotebook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize,
    wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE
    - wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB + wx.wxNO_BORDER)

  -- this handler allows dragging tabs into this bottom notebook
  bottomnotebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_ALLOW_DND,
    function (event)
      local notebookfrom = event:GetDragSource()
      if notebookfrom ~= ide.frame.notebook then
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
        tabs:SetNoneActive()

        event:Allow()
      end
    end)

  -- these handlers allow dragging tabs out of this bottom notebook.
  -- I couldn't find a good way to stop dragging event as it's not known
  -- where the event is going to end when it's started, so we manipulate
  -- the flag that allows splits and disable it when needed.
  -- It is then enabled in BEGIN_DRAG event.
  bottomnotebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_BEGIN_DRAG,
    function (event)
      event:Skip()

      -- allow dragging if it was disabled earlier
      local flags = bottomnotebook:GetWindowStyleFlag()
      if bit.band(flags, wxaui.wxAUI_NB_TAB_SPLIT) == 0 then
        bottomnotebook:SetWindowStyleFlag(flags + wxaui.wxAUI_NB_TAB_SPLIT)
      end
    end)

  -- there is currently no support in wxAuiNotebook for dragging tabs out.
  -- This is implemented as removing a tab that was dragged out and
  -- recreating it with the right control. This is complicated by the fact
  -- that tabs can be split, so if the destination is withing the area where
  -- splits happen, the tab is not removed.
  bottomnotebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_END_DRAG,
    function (event)
      event:Skip()

      local mgr = ide.frame.uimgr
      local win = mgr:GetPane(bottomnotebook).window
      local x = win:GetScreenPosition():GetX()
      local y = win:GetScreenPosition():GetY()
      local w, h = win:GetSize():GetWidth(), win:GetSize():GetHeight()

      local mouse = wx.wxGetMouseState()
      local mx, my = mouse:GetX(), mouse:GetY()

      if mx >= x and mx <= x + w and my >= y and my <= y + h then return end

      -- disallow split as the target is outside the notebook
      local flags = bottomnotebook:GetWindowStyleFlag()
      if bit.band(flags, wxaui.wxAUI_NB_TAB_SPLIT) ~= 0 then
        bottomnotebook:SetWindowStyleFlag(flags - wxaui.wxAUI_NB_TAB_SPLIT)
      end

      -- don't allow any dragging to the are of the pane header as it
      -- splits already split notebooks incorrectly (wxwidgets bug).
      if my >= y - 30 then return end

      -- don't allow dragging out single tabs from tab ctrl
      -- as wxwidgets doesn't like removing pages from split notebooks.
      local tabctrl = event:GetEventObject():DynamicCast("wxAuiTabCtrl")
      if tabctrl:GetPageCount() == 1 then return end

      local idx = event:GetSelection() -- index within the current tab ctrl
      local selection = bottomnotebook:GetPageIndex(tabctrl:GetPage(idx).window)
      local label = bottomnotebook:GetPageText(selection)

      -- names are translated on labels, so need to translate here as well
      local dragout = ({[TR("Watch")] = DebuggerAddWatchWindow,
                        [TR("Stack")] = DebuggerAddStackWindow})[label]
      if not dragout then return end

      bottomnotebook:RemovePage(selection)

      local pane = mgr:GetPane(dragout())
      pane:FloatingPosition(mx-10, my-10)
      pane:Show()
      mgr:Update()
    end)

  -- disallow tabs closing
  bottomnotebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CLOSE,
    function (event) event:Veto() end)

  local errorlog = wxstc.wxStyledTextCtrl(bottomnotebook, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBORDER_NONE)
	
	errorlog:Connect(wx.wxEVT_CONTEXT_MENU,
		function (event)
			errorlog:PopupMenu(
				wx.wxMenu {
					{ ID_UNDO, TR("&Undo") },
					{ ID_REDO, TR("&Redo") },
					{ },
					{ ID_CUT, TR("Cu&t") },
					{ ID_COPY, TR("&Copy") },
					{ ID_PASTE, TR("&Paste") },
					{ ID_SELECTALL, TR("Select &All") },
					{ },
					{ ID_CLEAROUTPUT, TR("C&lear Output Window") },
				}
			)
		end)
	
	errorlog:Connect(ID_CLEAROUTPUT, wx.wxEVT_COMMAND_MENU_SELECTED,
		function(event)
			ClearOutput()
		end)

  local shellbox = wxstc.wxStyledTextCtrl(bottomnotebook, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxBORDER_NONE)

  bottomnotebook:AddPage(errorlog, TR("Output"), true)
  bottomnotebook:AddPage(shellbox, TR("Local console"), false)
  
  bottomnotebook.errorlog = errorlog
  bottomnotebook.shellbox = shellbox
  
  frame.bottomnotebook = bottomnotebook
  return bottomnotebook
end

local function createProjNotebook(frame)
  local projnotebook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxDefaultSize,
    wxaui.wxAUI_NB_DEFAULT_STYLE
    - wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB + wx.wxNO_BORDER)

  -- disallow tabs closing
  projnotebook:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CLOSE,
    function (event) event:Veto() end)

  frame.projnotebook = projnotebook
  return projnotebook
end

-- ----------------------------------------------------------------------------
-- Add the child windows to the frame

local frame = createFrame()
ide.frame = frame
createToolBar(frame)
createNotebook(frame)
createProjNotebook(frame)
createBottomNotebook(frame)

do
  local frame = ide.frame
  local mgr = frame.uimgr

  mgr:AddPane(frame.toolBar, wxaui.wxAuiPaneInfo():
              Name("toolbar"):Caption("Toolbar"):
              MinSize(300,16):FloatingSize(800,48):
              ToolbarPane():Top():CloseButton(false):PaneBorder(false):
              LeftDockable(false):RightDockable(false))
  mgr:AddPane(frame.notebook, wxaui.wxAuiPaneInfo():
              Name("notebook"):
              CenterPane():PaneBorder(false))
  mgr:AddPane(frame.projnotebook, wxaui.wxAuiPaneInfo():
              Name("projpanel"):CaptionVisible(false):Caption(TR("Project")):
              MinSize(200,200):FloatingSize(200,400):
              Left():Layer(1):Position(1):PaneBorder(false):
              CloseButton(true):MaximizeButton(false):PinButton(true))
  mgr:AddPane(frame.bottomnotebook, wxaui.wxAuiPaneInfo():
              Name("bottomnotebook"):CaptionVisible(false):
              MinSize(100,100):BestSize(200,200):FloatingSize(400,200):
              Bottom():Layer(1):Position(1):PaneBorder(false):
              CloseButton(true):MaximizeButton(false):PinButton(true))

  for _, uimgr in pairs {mgr, frame.notebook:GetAuiManager(),
    frame.bottomnotebook:GetAuiManager(), frame.projnotebook:GetAuiManager()} do
    uimgr:GetArtProvider():SetMetric(wxaui.wxAUI_DOCKART_SASH_SIZE, 2)
  end

  for _, nb in pairs {frame.bottomnotebook, frame.projnotebook} do
    nb:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_BG_DCLICK,
      function() PaneFloatToggle(nb) end)
  end

  mgr.defaultPerspective = mgr:SavePerspective()
end
