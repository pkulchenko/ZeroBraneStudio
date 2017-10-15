-- Copyright 2011-17 Paul Kulchenko, ZeroBrane LLC
-- authors: Lomtik Software (J. Winwood & John Labenski)
-- Luxinia Dev (Eike Decker & Christoph Kubisch)
---------------------------------------------------------

local ide = ide
local frame = ide.frame
local menuBar = frame.menuBar
local findReplace = ide.findReplace

local findMenu = ide:MakeMenu {
  { ID_FIND, TR("&Find")..KSC(ID_FIND), TR("Find text") },
  { ID_FINDNEXT, TR("Find &Next")..KSC(ID_FINDNEXT), TR("Find the next text occurrence") },
  { ID_FINDPREV, TR("Find &Previous")..KSC(ID_FINDPREV), TR("Find the earlier text occurence") },
  { ID_FINDSELECTNEXT, TR("Select And Find Next")..KSC(ID_FINDSELECTNEXT), TR("Select the word under cursor and find its next occurrence") },
  { ID_FINDSELECTPREV, TR("Select And Find Previous")..KSC(ID_FINDSELECTPREV), TR("Select the word under cursor and find its previous occurrence") },
  { ID_REPLACE, TR("&Replace")..KSC(ID_REPLACE), TR("Find and replace text") },
  { },
  { ID_FINDINFILES, TR("Find &In Files")..KSC(ID_FINDINFILES), TR("Find text in files") },
  { ID_REPLACEINFILES, TR("Re&place In Files")..KSC(ID_REPLACEINFILES), TR("Find and replace text in files") },
  { },
  { ID_NAVIGATE, TR("Navigate"), "", {
    { ID_NAVIGATETOFILE, TR("Go To File...")..KSC(ID_NAVIGATETOFILE), TR("Go to file") },
    { ID_NAVIGATETOLINE, TR("Go To Line...")..KSC(ID_NAVIGATETOLINE), TR("Go to line") },
    { ID_NAVIGATETOSYMBOL, TR("Go To Symbol...")..KSC(ID_NAVIGATETOSYMBOL), TR("Go to symbol") },
    { ID_NAVIGATETOMETHOD, TR("Insert Library Function...")..KSC(ID_NAVIGATETOMETHOD), TR("Find and insert library function") },
  } },
}
menuBar:Append(findMenu, TR("&Search"))

-- allow search functions for either Editor with focus (which includes editor-like panels)
-- or editor tabs (even when the current editor is not in focus)
local function onUpdateUISearchMenu(event) event:Enable((ide:GetEditorWithFocus() or ide:GetEditor()) ~= nil) end

frame:Connect(ID_FIND, wx.wxEVT_COMMAND_MENU_SELECTED,
  function (event)
    findReplace:Show(false)
  end)
frame:Connect(ID_FIND, wx.wxEVT_UPDATE_UI, onUpdateUISearchMenu)

frame:Connect(ID_REPLACE, wx.wxEVT_COMMAND_MENU_SELECTED,
  function (event)
    findReplace:Show(true)
  end)
frame:Connect(ID_REPLACE, wx.wxEVT_UPDATE_UI, onUpdateUISearchMenu)

frame:Connect(ID_FINDINFILES, wx.wxEVT_COMMAND_MENU_SELECTED,
  function (event)
    findReplace:Show(false,true)
  end)
frame:Connect(ID_REPLACEINFILES, wx.wxEVT_COMMAND_MENU_SELECTED,
  function (event)
    findReplace:Show(true,true)
  end)

frame:Connect(ID_FINDNEXT, wx.wxEVT_COMMAND_MENU_SELECTED,
  function (event)
    local editor = ide:GetEditor()
    if editor and ide.wxver >= "2.9.5" and editor:GetSelections() > 1 then
      local selection = editor:GetMainSelection() + 1
      if selection >= editor:GetSelections() then selection = 0 end
      editor:SetMainSelection(selection)
      editor:ShowPosEnforcePolicy(editor:GetCurrentPos())
    else
      if findReplace:SetFind(findReplace:GetFind() or findReplace:GetSelection()) then
        findReplace:Find()
      else
        findReplace:Show(false)
      end
    end
  end)
frame:Connect(ID_FINDNEXT, wx.wxEVT_UPDATE_UI, onUpdateUISearchMenu)

frame:Connect(ID_FINDPREV, wx.wxEVT_COMMAND_MENU_SELECTED,
  function (event)
    local editor = ide:GetEditor()
    if editor and ide.wxver >= "2.9.5" and editor:GetSelections() > 1 then
      local selection = editor:GetMainSelection() - 1
      if selection < 0 then selection = editor:GetSelections() - 1 end
      editor:SetMainSelection(selection)
      editor:ShowPosEnforcePolicy(editor:GetCurrentPos())
    else
      if findReplace:SetFind(findReplace:GetFind() or findReplace:GetSelection()) then
        findReplace:Find(true) -- search up
      else
        findReplace:Show(false)
      end
    end
  end)
frame:Connect(ID_FINDPREV, wx.wxEVT_UPDATE_UI, onUpdateUISearchMenu)

-- Select and Find behaves like Find if there is a current selection;
-- if not, it selects a word under cursor (if any) and does find.

frame:Connect(ID_FINDSELECTNEXT, wx.wxEVT_COMMAND_MENU_SELECTED,
  function (event)
    if findReplace:SetFind(findReplace:GetSelection() or findReplace:GetWordAtCaret()) then
      findReplace:Find()
    end
  end)
frame:Connect(ID_FINDSELECTNEXT, wx.wxEVT_UPDATE_UI, onUpdateUISearchMenu)

frame:Connect(ID_FINDSELECTPREV, wx.wxEVT_COMMAND_MENU_SELECTED,
  function (event)
    if findReplace:SetFind(findReplace:GetSelection() or findReplace:GetWordAtCaret()) then
      findReplace:Find(true)
    end
  end)
frame:Connect(ID_FINDSELECTPREV, wx.wxEVT_UPDATE_UI, onUpdateUISearchMenu)

local special = {SYMBOL = '@', LINE = ':', METHOD = ';'}
frame:Connect(ID_NAVIGATETOFILE, wx.wxEVT_COMMAND_MENU_SELECTED,
  function() ide:ShowCommandBar("") end)
frame:Connect(ID_NAVIGATETOLINE, wx.wxEVT_COMMAND_MENU_SELECTED,
  function() ide:ShowCommandBar(special.LINE) end)
frame:Connect(ID_NAVIGATETOMETHOD, wx.wxEVT_COMMAND_MENU_SELECTED,
  function() ide:ShowCommandBar(special.METHOD) end)
frame:Connect(ID_NAVIGATETOSYMBOL, wx.wxEVT_COMMAND_MENU_SELECTED,
  function()
    local ed = ide:GetEditor()
    ide:ShowCommandBar(special.SYMBOL, ed and ed:ValueFromPosition(ed:GetCurrentPos()))
  end)
