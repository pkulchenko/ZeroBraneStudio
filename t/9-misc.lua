local i18n = ide:GetFileList('cfg/i18n/', true, '*.lua')
is(#i18n, 11, "Language files are present in i18n directory.")
for _, ln in ipairs(i18n) do
  local func = loadfile(ln)
  ok(type(func) == 'function' and func() ~= nil, ("Loaded '%s' language file."):format(ln))
end

local ints = ide:GetFileList('interpreters/', true)
for _, i in ipairs(ints) do
  ok(type(loadfile(i)) == 'function', ("Loaded '%s' interpreter file."):format(i))
end

local fixed, invalid = FixUTF8("+\128\129\130+\194\127+", "+")
is(fixed, "++++++\127+", "Invalid UTF8 is fixed (1/2).")
is(#invalid, 4, "Invalid UTF8 is fixed (2/2).")

local UTF8s = {
  "ABCDE", -- 1 byte codes
  "\194\160\194\161\194\162\194\163\194\164", -- 2 byte codes
  "\225\160\160\225\161\161\225\162\162\225\163\163\225\164\164", -- 3 byte codes
}

for n, code in ipairs(UTF8s) do
  is(FixUTF8(code), code, ("Valid UTF8 code is left unmodified (%d/%d)."):format(n, #UTF8s))
end

local function copyToClipboard(text, format)
  local tdo = wx.wxTextDataObject()
  if format == wx.wxDF_TEXT then
    tdo:SetData(wx.wxDataFormat(format), text)
  else
    tdo:SetText(text)
  end

  local clip = wx.wxClipboard.Get()
  clip:Open()
  clip:SetData(tdo)
  clip:Close()
end

local editor = NewFile()

-- copying valid UTF8
local valid = "ás grande"
copyToClipboard(valid)
editor:PasteDyn()
is(editor:GetTextDyn(), valid, "Valid UTF-8 string is pasted from the clipboard.")

if ide.wxver >= "3.1" then
  -- copying invalid UTF8
  local invalid = "-- \193"
  copyToClipboard(invalid, wx.wxDF_TEXT)
  editor:SetTextDyn(invalid)
  ok(#editor:GetTextDyn() == #invalid, "Length of stored string is the same as the invalid UTF-8 string.")

  local valid = "ásg"
  ok(#editor:GetTextDyn() == #valid, "Length of copied content is the same as the valid UTF-8 string.")
  editor:SetSelectionStart(0)
  editor:SetSelectionEnd(#invalid)
  editor:CopyDyn() -- populate the buffer with the "invalid" copy
  editor:SetSelectionEnd(0)
  editor:PasteDyn()
  is(editor:GetTextDyn(), invalid..invalid, "Invalid UTF-8 string is copied and pasted.")
end

-- copying valid when the buffer is for invalid of the same length
copyToClipboard(valid)
editor:SetText("")
editor:PasteDyn()
is(editor:GetTextDyn(), valid, "Valid UTF-8 string is pasted from the clipboard after coping invalid UTF-8 string.")

for _, tst in ipairs({
  "_ = .1 + 1. + 1.1 + 0xa",
  "_ = 1e1 + 0xa.ap1",
  "_ = 0xabcULL + 0x1LL + 1LL + 1ULL",
  "_ = .1e1i + 0x1.1p1i + 0xa.ap1i",
}) do
  ok(AnalyzeString(tst) ~= nil,
    ("Numeric expression '%s' can be checked with static analysis."):format(tst))

  editor:SetText(tst)
  editor:ResetTokenList()
  while editor:IndicateSymbols() do end
  local defonly = true
  for _, token in ipairs(ide:GetEditor():GetTokenList()) do
    if token.name ~= '_' then defonly = false end
  end
  ok(defonly == true, ("Numeric expression '%s' can be checked with inline parser."):format(tst))
end

ide:GetDocument(editor):SetModified(false)
ClosePage()

local at = ide:GetAccelerators()
ok(next(at) ~= nil, "One or more accelerator is set in the accelerator table.")
for id in pairs(at) do ide:SetAccelerator(id, nil) end
at = ide:GetAccelerators()
ok(next(at) == nil, "No accelerators are present after removing all of them.")

ide:SetHotKey(ID.STARTDEBUG, "F1")
is(ide:FindMenuItem(ID.STARTDEBUG):GetText():match("\t(.*)"), "F1", "`SetHotKey` sets the requested hotkey.")
ok(ide:FindMenuItem(ID.ABOUT):GetText():match("\t(.*)") == nil, "`SetHotKey` removes conflicted hotkey (1/2).")

local keyid, keysc = ide:GetHotKey(ID.STARTDEBUG)
is(keysc, "F1", "`GetHotKey` returns hotkey assigned with SetHotKey using id lookup.")
is(ide:GetHotKey("F1"), ID.STARTDEBUG, "`GetHotKey` returns hotkey assigned with SetHotKey using shortcut lookup.")

ide:SetHotKey(ID.STARTDEBUG)
ok(ide:GetHotKey("F1") == nil, "Setting hotkey to `nil` properly removes it (1/2).")
ok(ide:GetHotKey(ID.STARTDEBUG) == nil, "Setting hotkey to `nil` properly removes it (1/2).")

ok(ide:GetHotKey("F13") == nil, "`GetHotKey` returns nothing for nonexisting shortcut.")
ok(ide:GetHotKey(1) == nil, "`GetHotKey` returns nothing for nonexisting id.")
ok(ide:GetHotKey() == nil, "`GetHotKey` returns nothing when no parameters are passed.")

ide:SetHotKey(ID.STARTDEBUG, "Ctrl+N") -- this should resolve conflict with `Ctrl-N`
ok(ide:FindMenuItem(ID.NEW):GetText():match("\t(.*)") == nil, "`SetHotKey` removes conflicted hotkey (2/2).")

local capname, cwd = [[T\TesT.LUA]], wx.wxGetCwd()
if ide.osname == "Windows" then
  -- relative path
  is(FileGetLongPath(capname), capname:lower(), "`GetLongFilePath` returns properly formatted path on Windows (1/3).")
  -- absolute path with volume
  is(FileGetLongPath(MergeFullPath(cwd,capname)), MergeFullPath(cwd,capname:lower()), "`GetLongFilePath` returns properly formatted path on Windows (2/3).")
  -- absolute path with no volume
  is(FileGetLongPath(MergeFullPath(cwd,capname):gsub("^.:","")), MergeFullPath(cwd,capname:lower()):gsub("^.:",""), "`GetLongFilePath` returns properly formatted path on Windows (3/3).")
end

local tree = ide:GetProjectTree()
ok(pcall(function() tree:SetStartFile() end) == true, "Unsetting start file without project doesn't fail.")

ide:SetProject("t")
is(ide:GetProject("t"):gsub("[/\\]$",""), MergeFullPath(cwd,"t"), "Project is set to the expected path.")
local itemid = tree:FindItem("test.lua")
ok(itemid and itemid:IsOk() and tree:IsFileKnown(itemid), ".lua files have 'known' type.")


local spec = ide:FindSpec("py", "#!/bin/env ruby")
is(spec.lexer, "lexlpeg.python", "Shebang detection is not triggered for known extensions.")

spec = ide:FindSpec("", "#!/bin/env ruby")
is(spec.lexer, "lexlpeg.ruby", "Shebang detection sets correct lexer.")
is(#spec.exts, 0, "Shebang detection doesn't add extensions.")

local p = ide:GetProject()
ide.filetree.settings.mapped[p] = {}
local res = tree:MapDirectory("foo")
is(#ide.filetree.settings.mapped[p], 0, "MapDirectory doesn't add non-existing directory.")
ok(res == nil, "MapDirectory reports failure to add directory.")
local sep = GetPathSeparator()
local dir = "../src"
res = tree:MapDirectory(dir)
is(#ide.filetree.settings.mapped[p], 1, "MapDirectory adds a new directory to the list.")
ok(res == true, "MapDirectory reports success to add directory.")
tree:MapDirectory(dir..sep)
is(#ide.filetree.settings.mapped[p], 1, "MapDirectory skips adding the same directory.")
tree:UnmapDirectory(dir..sep)
ok(not ide.filetree.settings.mapped[p], "UnmapDirectory removes directory from the list.")

ok(tree:SetStartFile("test.lua") ~= nil, "SetStartFile sets start file.")
is(tree:GetStartFile(), "test.lua", "GetStartFile returns expected value.")
tree:SetStartFile()
ok(tree:GetStartFile() == nil, "GetStartFile returns `nil` after unsetting start file.")

is(ide:IsValidProperty({}, "nonexisting"), false, "`IsValidProperty` returns `false ` for non-existing properties.")
