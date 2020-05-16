ok(not ide:LoadFile(''), "Don't load file with an empty name.")
ok(not ide:LoadFile("\r\n "), "Don't load file with name that only has whitespaces.")
ok(not ide:LoadFile('t'), "Don't load file with directory as the name (1/2).")
ok(not ide:LoadFile('./'), "Don't load file with directory as the name (2/2).")

ok(ide:LoadFile('some-nonexisting-name', nil, true) == nil,
  "Do not load non-existing files unless allowed.")
ok(ide:LoadFile('some-nonexisting-name'), "Load non-existing files.")
ClosePage()

is(#ide:GetDocumentList(), 0, "No open editor tab corresponds to empty document list.")
local ed1 = ide:LoadFile('t/test.lua')
local ed2 = ide:LoadFile('t/test.sh')
local ed3 = ide:LoadFile('t/test.bat')
is(#ide:GetDocumentList(), 3, "Three open editor tabs correspond to three documents.")
is(ide:GetDocument(ed3):IsActive(), true, "Last open document is set active.")
ide:GetDocument(ed2):Close()
is(ide:GetDocument(ed3):IsActive(), true, "Closing other document preserves active status.")
is(ide:GetDocument(ed3):GetTabIndex(), 1, "Closing other document updates tab index.")
is(#ide:GetDocumentList(), 2, "Closing a document maintains document list.")
ide:GetDocument(ed3):Close()
is(ide:GetDocument(ed1):IsActive(), true, "Closing active document moves active status.")
like(ide:GetMainFrame():GetTitle(), "test%.lua", "Activating document after closing sets the application title.")
ide:GetDocument(ed1):Close()
is(#ide:GetDocumentList(), 0, "Closing all documents results in empty document list.")
like(ide:GetMainFrame():GetTitle(), " %- $", "Closing all documents sets the application title without file name.")

local ed1 = ide:LoadFile('t/test.lua')
local ed2 = ide:LoadFile('t/test.sh')
local nb = ide:GetEditorNotebook()
-- requesting "section" here may switch to "notebook" scope in some cases (wx3.1.1 on Windows)
ide:GetDocument(ed2):CloseAll({keep = true, scope = "section"})
is(#ide:GetDocumentList(), 1, "Closing 'other' documents keeps the current open.")
ide:GetDocument(ed2):CloseAll()
is(#ide:GetDocumentList(), 0, "Closing 'all' documents leaves no document open.")

local fullpath = MergeFullPath(wx.wxFileName.GetCwd(), 't/test.lua')
ok(ide:ActivateFile('t/test.lua:10'), "Load file:line.")
ok(not ide:ActivateFile('t/foo.bar:10'), "Doesn't load non-existent file:line.")
ok(ide:ActivateFile(fullpath..':10'), "Load fullpath/file:line.")
ok(not ide:ActivateFile(fullpath..'/foo.bar:10'), "Doesn't load non-existent fullpath/file:line.")
ClosePage() -- close activated file

local sep = GetPathSeparator()
like(ide:GetFileList('t', true, 'test.lua', {path = true})[1], "^t"..sep.."test.lua$",
  "Traversing `t`, including path in the results (1/6)")
like(ide:GetFileList('t/', true, 'test.lua', {path = true})[1], "^t"..sep.."test.lua$",
  "Traversing `t/`, including path in the results (2/6)")
like(ide:GetFileList('t\\', true, 'test.lua', {path = true})[1], "^t"..sep.."test.lua$",
  "Traversing `t\\`, including path in the results (3/6)")
is(ide:GetFileList('t', true, 'test.lua', {path = false})[1], "test.lua",
  "Traversing `t`, not including path in the results (4/6)")
is(ide:GetFileList('t/', true, 'test.lua', {path = false})[1], "test.lua",
  "Traversing `t/`, not including path in the results (5/6)")
is(ide:GetFileList('t\\', true, 'test.lua', {path = false})[1], "test.lua",
  "Traversing `t\\`, not including path in the results (6/6)")

is(#ide:GetFileList('t', true, '*.lua', {maxnum = 2}), 2, "List of files returned can be limited with `maxnum`.")

local luas = ide:GetFileList('t', true, '*.lua')
local more = ide:GetFileList('t', true, '*.lua; *.more')
cmp_ok(#luas, '>', 0, "List of files is returned for '.lua' extension.")
is(#luas, #more, "Lists of files returned for '.lua' and '.lua; .more' are the same.")

local luasnodir = ide:GetFileList('t', true, '*.lua', {folder = false})
is(#luas, #luasnodir, "List of files returned for '.lua' does not include folders.")

local fcopy = "t/copy.lua!"
ok(FileCopy("t/test.lua", fcopy), "File copied successfully.")
local copy = FileRead(fcopy)
ok(copy ~= nil, "Copied file exists.")
ok(copy == FileRead("t/test.lua"), "Copy matches the original.")

local luasmore = ide:GetFileList('t', true, '*.lua')
is(#luasmore, #luas, ("Mask '.lua' doesn't match '%s'"):format(fcopy))
ok(FileRemove(fcopy) and not FileRead(fcopy), "File deleted successfully.")

local exlist = ide.config.excludelist
local path = 'zbstudio/res/16'
local bins0 = ide:GetFileList(path, true, '*')
local bins1 = ide:GetFileList(path, true, '*.png')
ok(#bins0 > 1, "'*.*' mask retrieves binary files.")

ide.config.excludelist = ".png/"
local bins = ide:GetFileList(path, true, '*')
is(#bins, #bins0, "Excluding '.png/' still returns 'png' files.")

ide.config.excludelist = ".png"
bins = ide:GetFileList(path, true, '*')
is(#bins, 1, "Excluding '.png' skips 'png' files.")

ide.config.excludelist = "*.png"
bins = ide:GetFileList(path, true, '*')
is(#bins, 1, "Excluding '*.png' skips 'png' files.")

ide.config.excludelist = {"*.png"}
bins = ide:GetFileList(path, true, '*')
is(#bins, 1, "Excluding {'*.png'} skips 'png' files.")

ide.config.excludelist = {["*.png"] = true}
bins = ide:GetFileList(path, true, '*')
is(#bins, 1, "Excluding {['*.png'] = true} skips 'png' files.")

ide.config.excludelist = {["*.png"] = false}
bins = ide:GetFileList(path, true, '*')
is(#bins, #bins0, "Excluding {['*.png'] = false} doesn't skip 'png' files.")

ide.config.excludelist = "FIND*.png"
bins = ide:GetFileList(path, true, '*.png')
ok(#bins < #bins1, "Excluding `FIND*.png` filters out files with that mask.")

ide.config.excludelist = "*.png"
bins = ide:GetFileList(path, true, 'FIND*.png')
ok(#bins < #bins1, "Requesting `FIND*.png` filters specific files.")

ide.config.excludelist = ""
local bina = ide:GetFileList('src', true, '*.lua')

ide.config.excludelist = "editor"
bins = ide:GetFileList('src', true, '*.lua')
is(#bins, #bina, "Excluding `editor` still returns the content of `editor` folder.")

ide.config.excludelist = "editor/"
bins = ide:GetFileList('src', true, '*.lua')
ok(#bins < #bina, "Excluding `editor/` skips the content of `editor` folder.")

ide.config.excludelist = "editor\\"
local nosrc = #bins
bins = ide:GetFileList('src', true, '*.lua')
ok(#bins < #bina, "Excluding `editor\\` skips the content of `editor` folder.")
is(#bins, nosrc, "Excluding `editor\\` and `editor/` produce the same result.")

nosrc = #ide:GetFileList('src', true, '*.lua', {folder = false})
ide.config.excludelist = "editor/**.lua"
bins = ide:GetFileList('src', true, '*.lua', {folder = false})
is(#bins, nosrc, "Excluding `editor/**.lua` skips lua files in subfolders.")

ide.config.excludelist = ""
local editor = #ide:GetFileList('src/editor', true, '*.lua', {folder = false})

ide.config.excludelist = "src/*.lua"
bins = ide:GetFileList('src', true, '*.lua', {folder = false})
is(#bins, editor, "Excluding `src/*.lua` skips lua files only in `src` folder.")

ide.config.excludelist = exlist
bins = ide:GetFileList(path, true, '*', {skipbinary = true})
is(#bins, 1, "Default mask excludes `png` files with `skipbinary`.")

bins = ide:GetFileList("bin", true, '*.exe', {folder = false})
is(bins, {}, "Default mask excludes `*.exe` files.")
