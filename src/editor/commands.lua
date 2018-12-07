-- Copyright 2011-17 Paul Kulchenko, ZeroBrane LLC
-- authors: Lomtik Software (J. Winwood & John Labenski)
-- Luxinia Dev (Eike Decker & Christoph Kubisch)
---------------------------------------------------------

local ide = ide
local frame = ide.frame
local notebook = frame.notebook
local uimgr = frame.uimgr
local unpack = table.unpack or unpack

local CURRENT_LINE_MARKER = StylesGetMarker("currentline")

function NewFile(filename)
  filename = filename or ide:GetDefaultFileName()
  local editor = CreateEditor()
  local doc = AddEditor(editor, filename)
  if not doc then
    editor:Destroy()
    return
  end
  doc:SetActive()
  PackageEventHandle("onEditorNew", editor)
  return editor
end

-- Find an editor page that hasn't been used at all, eg. an untouched NewFile()
local function findUnusedEditor()
  for _, document in pairs(ide:GetDocuments()) do
    local editor = document:GetEditor()
    if (editor:GetLength() == 0) and
    (not document:IsModified()) and document:IsNew() and
    not (editor:GetReadOnly() == true) then
      return editor
    end
  end
  return
end

function LoadFile(filePath, editor, file_must_exist, skipselection)
  filePath = filePath:gsub("%s+$","")

  -- if the file name is empty or is a directory or looks like a directory, don't do anything
  if filePath == ''
  or wx.wxDirExists(filePath)
  or filePath:find("[/\\]$") then
    return nil, "Invalid filename"
  end

  filePath = FileNormalizePath(filePath)
  -- on some Windows versions, normalization doesn't return "original" file name,
  -- so detect that and use LongPath instead
  if ide.osname == "Windows" and wx.wxFileExists(filePath)
  and FileNormalizePath(filePath:upper()) ~= FileNormalizePath(filePath:lower()) then
    filePath = FileGetLongPath(filePath)
  end

  -- prevent files from being reopened again
  if not editor then
    local doc = ide:FindDocument(filePath)
    if doc then
      if not skipselection then doc:SetActive() end
      return doc:GetEditor()
    end
  end

  local filesize = FileSize(filePath)
  if filesize == wx.wxInvalidOffset then
    -- invalid offset is also reported on empty files with no read access (at least on Windows)
    ide:ReportError(TR("Can't open file '%s': %s")
      :format(filePath, "symlink is broken or access is denied."))
    return nil
  end
  if not filesize and file_must_exist then return nil end

  local current = editor and editor:GetCurrentPos()
  editor = editor or findUnusedEditor() or CreateEditor()
  editor:Freeze()
  editor:SetupKeywords(GetFileExt(filePath))
  editor:MarkerDeleteAll(-1)
  if filesize then editor:Allocate(filesize) end
  editor:SetReadOnly(false) -- disable read-only status if set on the editor
  editor:BeginUndoAction()
  editor:SetTextDyn("")
  editor.bom = string.char(0xEF,0xBB,0xBF)

  local inputfilter = GetConfigIOFilter("input")
  local file_text
  ide:PushStatus("")
  local ok, err = FileRead(filePath, 1024*1024, function(s) -- callback is only called when the file exists
      if not file_text then
        -- remove BOM from UTF-8 encoded files; store BOM to add back when saving
        if s and editor:GetCodePage() == wxstc.wxSTC_CP_UTF8 and s:find("^"..editor.bom) then
          s = s:gsub("^"..editor.bom, "")
        else
          -- set to 'false' as checks for nil on wxlua objects may fail at run-time
          editor.bom = false
        end
        file_text = s
      end
      if inputfilter then s = inputfilter(filePath, s) end
      local expected = editor:GetLength() + #s
      editor:AppendTextDyn(s)
      -- if the length is not as expected, then either it's a binary file or invalid UTF8
      if editor:GetLength() ~= expected then
        -- skip binary files with unknown extensions as they may have any sequences
        -- when using Raw methods, this can only happen for binary files (that include \0 chars)
        if editor.useraw or editor.spec == ide.specs.none and IsBinary(s) then
          ide:Print(("%s: %s"):format(filePath,
              TR("Binary file is shown as read-only as it is only partially loaded.")))
          file_text = ''
          editor:SetReadOnly(true)
          return false
        end

        -- handle invalid UTF8 characters
        -- fix: doesn't handle characters split by callback buffer
        local replacement, invalid = "\022"
        s, invalid = FixUTF8(s, replacement)
        if #invalid > 0 then
          editor:AppendTextDyn(s)
          local lastline = nil
          for _, n in ipairs(invalid) do
            local line = editor:LineFromPosition(n)
            if line ~= lastline then
              ide:Print(("%s:%d: %s"):format(filePath, line+1,
                  TR("Replaced an invalid UTF8 character with %s."):format(replacement)))
              lastline = line
            end
          end
        end
      end
      if filesize and filesize > 0 then
        ide:PopStatus()
        ide:PushStatus(TR("%s%% loaded..."):format(math.floor(100*editor:GetLength()/filesize)))
      end
    end)
  ide:PopStatus()

  -- empty or non-existing files don't have bom
  if not file_text then editor.bom = false end

  editor:EndUndoAction()
  -- try one more time with shebang if the type is not known yet
  if editor.spec == ide.specs.none then editor:SetupKeywords(GetFileExt(filePath)) end
  editor:Colourise(0, -1)
  editor:ResetTokenList() -- reset list of tokens if this is a reused editor
  editor:Thaw()

  -- only report errors on existing files
  if not ok and filesize then
    -- restore the changes in the editor,
    -- as it may be applied to some other content, for example, in preview
    editor:Undo()
    ide:ReportError(TR("Can't open file '%s': %s"):format(filePath, err))
    return nil
  end

  local edcfg = ide.config.editor
  if current then editor:GotoPos(current) end
  if (file_text and edcfg.autotabs) then
    -- use tabs if they are already used
    -- or if "usetabs" is set and no space indentation is used in a file
    editor:SetUseTabs(string.find(file_text, "\t") ~= nil
      or edcfg.usetabs and (file_text:find("%f[^\r\n] ") or file_text:find("^ ")) == nil)
  end
  
  if (file_text and edcfg.checkeol) then
    -- Auto-detect CRLF/LF line-endings
    local foundcrlf = string.find(file_text,"\r\n") ~= nil
    local foundlf = (string.find(file_text,"[^\r]\n") ~= nil)
      or (string.find(file_text,"^\n") ~= nil) -- edge case: file beginning with LF and having no other LF
    if foundcrlf and foundlf then -- file with mixed line-endings
      ide:Print(("%s: %s")
        :format(filePath, TR("Mixed end-of-line encodings detected.")..' '..
          TR("Use '%s' to show line endings and '%s' to convert them.")
        :format("ide:GetEditor():SetViewEOL(1)", "ide:GetEditor():ConvertEOLs(ide:GetEditor():GetEOLMode())")))
    elseif foundcrlf then
      editor:SetEOLMode(wxstc.wxSTC_EOL_CRLF)
    elseif foundlf then
      editor:SetEOLMode(wxstc.wxSTC_EOL_LF)
    -- else (e.g. file is 1 line long or uses another line-ending): use default EOL mode
    end
  end

  editor:EmptyUndoBuffer()
  local doc = ide:GetDocument(editor)
  if doc then -- existing editor; switch to the tab
    notebook:SetSelection(doc:GetTabIndex())
  else -- the editor has not been added to notebook
    doc = AddEditor(editor, wx.wxFileName(filePath):GetFullName() or ide:GetDefaultFileName())
  end
  doc.filePath = filePath
  doc.fileName = wx.wxFileName(filePath):GetFullName()
  doc.modTime = GetFileModTime(filePath)

  doc:SetModified(false)
  doc:SetTabText(doc:GetFileName())

  -- activate the editor; this is needed for those cases when the editor is
  -- created from some other element, for example, from a project tree.
  if not skipselection then doc:SetActive() end

  PackageEventHandle("onEditorLoad", editor)

  return editor
end

function ReLoadFile(filePath, editor, ...)
  if not editor then return LoadFile(filePath, editor, ...) end

  -- save all markers
  local markers = editor:MarkerGetAll()
  -- add the current line content to retrieved markers to compare later if needed
  for _, marker in ipairs(markers) do marker[3] = editor:GetLineDyn(marker[1]) end
  local lines = editor:GetLineCount()

  -- load file into the same editor
  editor = LoadFile(filePath, editor, ...)
  if not editor then return end

  if #markers > 0 then -- restore all markers
    -- delete all markers as they may be restored by a different mechanism,
    -- which may be limited to only restoring some markers
    editor:MarkerDeleteAll(-1)
    local samelinecount = lines == editor:GetLineCount()
    for _, marker in ipairs(markers) do
      local line, mask, text = unpack(marker)
      if samelinecount then
        -- restore marker at the same line number
        editor:MarkerAddSet(line, mask)
      else
        -- find matching line in the surrounding area and restore marker there
        for _, l in ipairs({line, line-1, line-2, line+1, line+2}) do
          if text == editor:GetLineDyn(l) then
            editor:MarkerAddSet(l, mask)
            break
          end
        end
      end
    end
    PackageEventHandle("onEditorMarkerUpdate", editor)
  end

  return editor
end

local function getExtsString(ed)
  local exts = ed and ed.spec and ed.spec.exts or {}
  local knownexts = #exts > 0 and "*."..table.concat(exts, ";*.") or nil
  return (knownexts and TR("Known Files").." ("..knownexts..")|"..knownexts.."|" or "")
  .. TR("All files").." (*)|*"
end

function OpenFile(event)
  local editor = ide:GetEditor()
  local path = editor and ide:GetDocument(editor):GetFilePath() or nil
  local fileDialog = wx.wxFileDialog(ide.frame, TR("Open file"),
    (path and GetPathWithSep(path) or ide:GetProject() or ""),
    "",
    getExtsString(editor),
    wx.wxFD_OPEN + wx.wxFD_FILE_MUST_EXIST + wx.wxFD_MULTIPLE)
  if fileDialog:ShowModal() == wx.wxID_OK then
    for _, path in ipairs(fileDialog:GetPaths()) do
      if not LoadFile(path, nil, true) then
        ide:ReportError(TR("Unable to load file '%s'."):format(path))
      end
    end
  end
  fileDialog:Destroy()
end

-- save the file to filePath or if filePath is nil then call SaveFileAs
function SaveFile(editor, filePath)
  -- this event can be aborted
  -- as SaveFileAs calls SaveFile, this event may be called two times:
  -- first without filePath and then with filePath
  if PackageEventHandle("onEditorPreSave", editor, filePath) == false then
    return false
  end

  if not filePath then
    return SaveFileAs(editor)
  else
    if ide.config.savebak then
      local ok, err = FileRename(filePath, filePath..".bak")
      if not ok then
        ide:ReportError(TR("Unable to save file '%s': %s"):format(filePath..".bak", err))
        return
      end
    end

    local st = ((editor:GetCodePage() == wxstc.wxSTC_CP_UTF8 and editor.bom or "")
      .. editor:GetTextDyn())
    if GetConfigIOFilter("output") then
      st = GetConfigIOFilter("output")(filePath,st)
    end

    local ok, err = FileWrite(filePath, st)
    if ok then
      editor:SetSavePoint()
      local doc = ide:GetDocument(editor)
      doc:SetFilePath(filePath)
      doc:SetFileName(wx.wxFileName(filePath):GetFullName())
      doc:SetFileModifiedTime(GetFileModTime(filePath))
      doc:SetTabText(doc:GetFileName())
      ide:SetTitle() -- update title of the main window
      SetAutoRecoveryMark()
      FileTreeMarkSelected(filePath)

      PackageEventHandle("onEditorSave", editor)

      return true
    else
      ide:ReportError(TR("Unable to save file '%s': %s"):format(filePath, err))
    end
  end

  return false
end

function ApproveFileOverwrite()
  return wx.wxMessageBox(
    TR("File already exists.").."\n"..TR("Do you want to overwrite it?"),
    ide:GetProperty("editormessage"),
    wx.wxYES_NO + wx.wxCENTRE, ide.frame) == wx.wxYES
end

function SaveFileAs(editor)
  local saved = false
  local document = ide:GetDocument(editor)
  local filePath = (document and document:GetFilePath()
    or ((ide:GetProject() or "")..(document and document:GetFileName() or ide.config.default.name)))
  if document then document:SetActive() end

  local fn = wx.wxFileName(filePath)
  fn:Normalize() -- want absolute path for dialog

  local ext = fn:GetExt()
  if (not ext or #ext == 0) and editor.spec and editor.spec.exts then
    ext = editor.spec.exts[1]
    -- set the extension on the file if assigned as this is used by OSX/Linux
    -- to present the correct default "save as type" choice.
    if ext then fn:SetExt(ext) end
  end
  local fileDialog = wx.wxFileDialog(ide.frame, TR("Save file as"),
    fn:GetPath(wx.wxPATH_GET_VOLUME),
    fn:GetFullName(),
    -- specify the current extension plus all other extensions based on specs
    (ext and #ext > 0 and "*."..ext.."|*."..ext.."|" or "")..getExtsString(editor),
    wx.wxFD_SAVE)

  if fileDialog:ShowModal() == wx.wxID_OK then
    local filePath = fileDialog:GetPath()

    -- check if there is another tab with the same name and prepare to close it
    local doc = ide:FindDocument(filePath)
    local cansave = fn:GetFullName() == filePath -- saving into the same file
       or not wx.wxFileName(filePath):FileExists() -- or a new file
       or ApproveFileOverwrite()

    if cansave and SaveFile(editor, filePath) then
      saved = true
      if doc then doc:Close() end
    end
  end

  fileDialog:Destroy()
  return saved
end

function SaveAll(quiet)
  for _, document in pairs(ide:GetDocuments()) do
    local filePath = document:GetFilePath()
    if (document:IsModified() or document:IsNew()) -- need to save
    and (filePath or not quiet) then -- have path or can ask user
      SaveFile(document:GetEditor(), filePath) -- will call SaveFileAs if necessary
    end
  end
end

-- Show a dialog to save a file before closing editor.
-- returns wxID_YES, wxID_NO, or wxID_CANCEL if allow_cancel
function SaveModifiedDialog(editor, allow_cancel)
  local result = wx.wxID_NO
  local document = ide:GetDocument(editor)
  if document and document:IsModified() then
    document:SetActive()
    local message = TR("Do you want to save the changes to '%s'?")
      :format(document:GetFileName() or ide.config.default.name)
    local dlg_styles = wx.wxYES_NO + wx.wxCENTRE + wx.wxICON_QUESTION
    if allow_cancel then dlg_styles = dlg_styles + wx.wxCANCEL end
    local dialog = wx.wxMessageDialog(ide.frame, message,
      TR("Save Changes?"),
      dlg_styles)
    result = dialog:ShowModal()
    dialog:Destroy()
    if result == wx.wxID_YES then
      if not document:Save() then
        return wx.wxID_CANCEL -- cancel if canceled save dialog
      end
    end
  end

  return result
end

function SaveOnExit(allow_cancel)
  for _, document in pairs(ide:GetDocuments()) do
    if (SaveModifiedDialog(document:GetEditor(), allow_cancel) == wx.wxID_CANCEL) then
      return false
    end
  end

  -- if all documents have been saved or refused to save, then mark those that
  -- are still modified as not modified (they don't need to be saved)
  -- to keep their tab names correct
  for _, document in pairs(ide:GetDocuments()) do
    if document:IsModified() then document:SetModified(false) end
  end

  return true
end

function SetAllEditorsReadOnly(enable)
  for _, document in pairs(ide:GetDocuments()) do
    document:GetEditor():SetReadOnly(enable)
  end
end

-----------------
-- Debug related

function ClearAllCurrentLineMarkers()
  for _, document in pairs(ide:GetDocuments()) do
    document:GetEditor():MarkerDeleteAll(CURRENT_LINE_MARKER)
    document:GetEditor():Refresh() -- needed for background markers that don't get refreshed (wx2.9.5)
  end
end

-- remove shebang line (#!) as it throws a compilation error as
-- loadstring() doesn't allow it even though lua/loadfile accepts it.
-- replace with a new line to keep the number of lines the same.
function StripShebang(code) return (code:gsub("^#!.-\n", "\n")) end

local compileOk, compileTotal = 0, 0
function CompileProgram(editor, params)
  local params = {
    jumponerror = (params or {}).jumponerror ~= false,
    reportstats = (params or {}).reportstats ~= false,
    keepoutput = (params or {}).keepoutput,
  }
  local doc = ide:GetDocument(editor)
  local filePath = doc:GetFilePath() or doc:GetFileName()
  local func, err = loadstring(StripShebang(editor:GetTextDyn()), '@'..filePath)
  local line = not func and tonumber(err:match(":(%d+)%s*:")) or nil

  if not params.keepoutput then ClearOutput() end

  compileTotal = compileTotal + 1
  if func then
    compileOk = compileOk + 1
    if params.reportstats then
      ide:Print(TR("Compilation successful; %.0f%% success rate (%d/%d).")
        :format(compileOk/compileTotal*100, compileOk, compileTotal))
    end
  else
    ide:GetOutput():Activate()
    ide:Print(TR("Compilation error").." "..TR("on line %d"):format(line)..":")
    ide:Print((err:gsub("\n$", "")))
    -- check for escapes invalid in LuaJIT/Lua 5.2 that are allowed in Lua 5.1
    if err:find('invalid escape sequence') then
      local s = editor:GetLineDyn(line-1)
      local cleaned = s
        :gsub('\\[abfnrtv\\"\']', '  ')
        :gsub('(\\x[0-9a-fA-F][0-9a-fA-F])', function(s) return string.rep(' ', #s) end)
        :gsub('(\\%d%d?%d?)', function(s) return string.rep(' ', #s) end)
        :gsub('(\\z%s*)', function(s) return string.rep(' ', #s) end)
      local invalid = cleaned:find("\\")
      if invalid then
        ide:Print(TR("Consider removing backslash from escape sequence '%s'.")
          :format(s:sub(invalid,invalid+1)))
      end
    end
    if line and params.jumponerror and line-1 ~= editor:GetCurrentLine() then
      editor:GotoLine(line-1)
    end
  end

  return func ~= nil -- return true if it compiled ok
end

------------------
-- Save & Close

function SaveIfModified(editor)
  local doc = ide:GetDocument(editor)
  if doc and doc:IsModified() or doc:IsNew() then
    local saved = false
    if doc:IsNew() then
      local ret = wx.wxMessageBox(
        TR("You must save the program first.").."\n"..TR("Press cancel to abort."),
        TR("Save file?"), wx.wxOK + wx.wxCANCEL + wx.wxCENTRE, ide.frame)
      if ret == wx.wxOK then
        saved = SaveFileAs(editor)
      end
    else
      saved = doc:Save()
    end
    return saved
  end

  return true -- saved
end

function GetOpenFiles()
  local opendocs = {}
  for _, document in ipairs(ide:GetDocumentList()) do
    if document:GetFilePath() then
      local wxfname = wx.wxFileName(document:GetFilePath())
      wxfname:Normalize()

      table.insert(opendocs, {filename=wxfname:GetFullPath(),
        id=document:GetTabIndex(), cursorpos = document:GetEditor():GetCurrentPos()})
    end
  end

  local ed = ide:GetEditor()
  local doc = ed and ide:GetDocument(ed)
  return opendocs, {index = (doc and doc:GetTabIndex() or 0)}
end

function SetOpenFiles(nametab,params)
  for _, doc in ipairs(nametab) do
    local editor = LoadFile(doc.filename,nil,true,true) -- skip selection
    if editor then editor:GotoPosDelayed(doc.cursorpos or 0) end
  end
  local doc = ide:GetDocument(notebook:GetPage(params and params.index or 0))
  if doc then doc:SetActive() end
end

function ProjectConfig(dir, config)
  if config then ide.session.projects[dir] = config
  else return unpack(ide.session.projects[dir] or {}) end
end

function SetOpenTabs(params)
  local recovery, nametab = LoadSafe("return "..params.recovery)
  if not recovery or not nametab then
    ide:Print(TR("Can't process auto-recovery record; invalid format: %s."):format(nametab or "unknown"))
    return
  end
  if not params.quiet then
    ide:Print(TR("Found auto-recovery record and restored saved session."))
  end
  for _,doc in ipairs(nametab) do
    -- check for missing file if no content is stored
    if doc.filepath and not doc.content and not wx.wxFileExists(doc.filepath) then
      ide:Print(TR("File '%s' is missing and can't be recovered."):format(doc.filepath))
    else
      local editor = (doc.filepath and LoadFile(doc.filepath,nil,true,true)
        or findUnusedEditor() or NewFile(doc.filename))
      local opendoc = ide:GetDocument(editor)
      if doc.content then
        editor:SetTextDyn(doc.content)
        if doc.filepath and opendoc.modTime and doc.modified < opendoc.modTime:GetTicks() then
          ide:Print(TR("File '%s' has more recent timestamp than restored '%s'; please review before saving.")
            :format(doc.filepath, opendoc:GetTabText()))
        end
      end
      editor:GotoPosDelayed(doc.cursorpos or 0)
    end
  end
  notebook:SetSelection(params and params.index or 0)
end

local function getOpenTabs()
  local opendocs = {}
  for _, document in pairs(ide:GetDocumentList()) do
    local editor = document:GetEditor()
    table.insert(opendocs, {
      filename = document:GetFileName(),
      filepath = document:GetFilePath(),
      tabname = document:GetTabText(),
      -- get number of seconds
      modified = document:GetFileModifiedTime() and document:GetFileModifiedTime():GetTicks(),
      content = document:IsModified() and editor:GetTextDyn() or nil,
      id = document:GetTabIndex(),
      cursorpos = editor:GetCurrentPos()})
  end

  local ed = ide:GetEditor()
  local doc = ed and ide:GetDocument(ed)
  return opendocs, {index = (doc and doc:GetTabIndex() or 0)}
end

function SetAutoRecoveryMark()
  ide.session.lastupdated = os.time()
end

local function saveHotExit()
  local opentabs, params = getOpenTabs()
  if #opentabs > 0 then
    params.recovery = DumpPlain(opentabs)
    params.quiet = true
    SettingsSaveFileSession({}, params)
  end
end

local function saveAutoRecovery(force)
  if not ide.config.autorecoverinactivity then return end

  local lastupdated = ide.session.lastupdated
  if not force then
    if not lastupdated or lastupdated < (ide.session.lastsaved or 0) then return end
  end

  local now = os.time()
  if not force and lastupdated + ide.config.autorecoverinactivity > now then return end

  -- find all open modified files and save them
  local opentabs, params = getOpenTabs()
  if #opentabs > 0 then
    params.recovery = DumpPlain(opentabs)
    SettingsSaveAll()
    SettingsSaveFileSession({}, params)
    ide.settings:Flush()
  end
  ide.session.lastsaved = now
  ide:SetStatus(TR("Saved auto-recover at %s."):format(os.date("%H:%M:%S")))
end

function StoreRestoreProjectTabs(curdir, newdir, intfname)
  local win = ide.osname == 'Windows'
  local interpreter = intfname or ide.interpreter.fname
  local current, closing, restore = notebook:GetSelection(), 0, false

  if ide.osname ~= 'Macintosh' then notebook:Freeze() end

  if curdir and #curdir > 0 then
    local lowcurdir = win and string.lower(curdir) or curdir
    local lownewdir = win and string.lower(newdir) or newdir
    local projdocs = {}
    for _, document in ipairs(GetOpenFiles()) do
      local dpath = win and string.lower(document.filename) or document.filename
      -- check if the filename is in the same folder
      if dpath:find(lowcurdir, 1, true) == 1
      and dpath:find("^[\\/]", #lowcurdir+1) then
        table.insert(projdocs, document)
        closing = closing + (document.id < current and 1 or 0)
      elseif document.id == current then restore = true end
    end

    -- adjust for the number of closing tabs on the left from the current one
    current = current - closing

    -- save opened files from this project
    ProjectConfig(curdir, {projdocs,
      {index = notebook:GetSelection() - current, interpreter = interpreter}})

    local editor = ide:GetEditor()
    local doc = editor and ide:GetDocument(editor)
    if doc then doc:CloseAll({scope = "project"}) end
  end

  local files, params = ProjectConfig(newdir)
  if files then
    -- provide fake index so that it doesn't activate it as the index may be not
    -- quite correct if some of the existing files are already open in the IDE.
    SetOpenFiles(files, {index = #files + notebook:GetPageCount()})
  end

  -- either interpreter is chosen for the project or the default value is set
  if (params and params.interpreter) or (not params and ide.config.interpreter) then
    ProjectSetInterpreter(params and params.interpreter or ide.config.interpreter)
  end

  if ide.osname ~= 'Macintosh' then notebook:Thaw() end

  local index = params and params.index
  if notebook:GetPageCount() == 0 then NewFile()
  elseif restore and current >= 0 then notebook:SetSelection(current)
  elseif index and index >= 0 and files[index+1] then
    -- move the editor tab to the front with the file from the config
    LoadFile(files[index+1].filename, nil, true)
  end

  -- remove current config as it may change; the current configuration is
  -- stored with the general config.
  -- The project configuration will be updated when the project is changed.
  ProjectConfig(newdir, {})
end

local function closeWindow(event)
  -- if the app is already exiting, then help it exit; wxwidgets on Windows
  -- is supposed to report Shutdown/logoff events by setting CanVeto() to
  -- false, but it doesn't happen. We simply leverage the fact that
  -- CloseWindow is called several times in this case and exit. Similar
  -- behavior has been also seen on Linux, so this logic applies everywhere.
  if ide.exitingProgram then os.exit() end

  ide.exitingProgram = true -- don't handle focus events

  if not ide.config.hotexit and not SaveOnExit(event:CanVeto()) then
    event:Veto()
    ide.exitingProgram = false
    return
  end

  ide:ShowFullScreen(false)

  if ide:GetProject() then PackageEventHandle("onProjectClose", ide:GetProject()) end
  PackageEventHandle("onAppClose")

  -- first need to detach all processes IDE has launched as the current
  -- process is likely to terminate before child processes are terminated,
  -- which may lead to a crash when EVT_END_PROCESS event is called.
  DetachChildProcess()
  ide:GetDebugger():Shutdown()

  SettingsSaveAll()
  if ide.config.hotexit then saveHotExit() end
  ide.settings:Flush()

  do -- hide all floating panes first
    local panes = frame.uimgr:GetAllPanes()
    for index = 0, panes:GetCount()-1 do
      local pane = frame.uimgr:GetPane(panes:Item(index).name)
      if pane:IsFloating() then pane:Hide() end
    end
  end
  frame.uimgr:Update() -- hide floating panes
  frame.uimgr:UnInit()
  frame:Hide() -- hide the main frame while the IDE exits

  wx.wxClipboard:Get():Flush() -- keep the clipboard content after exit

  -- stop all the timers
  for _, timer in pairs(ide.timers) do timer:Stop() end
  wx.wxGetApp():Disconnect(wx.wxEVT_TIMER)

  event:Skip()

  PackageEventHandle("onAppShutdown")
end
frame:Connect(wx.wxEVT_CLOSE_WINDOW, closeWindow)

local function restoreFocus()
  -- check if the window is shown before returning focus to it,
  -- as it may lead to a recursion in event handlers on OSX (wxwidgets 2.9.5).
  if ide:IsWindowShown(ide.infocus) then
    ide.infocus:SetFocus()
    -- if switching to the editor, then also call SetSTCFocus,
    -- otherwise the cursor is not shown in the editor on OSX.
    if ide.infocus:GetClassInfo():GetClassName() == "wxStyledTextCtrl" then
      ide.infocus:DynamicCast("wxStyledTextCtrl"):SetSTCFocus(true)
    end
  end
end

-- in the presence of wxAuiToolbar, when (1) the app gets focus,
-- (2) a floating panel is closed or (3) a toolbar dropdown is closed,
-- the focus is always on the toolbar when the app gets focus,
-- so to restore the focus correctly, need to track where the control is
-- and to set the focus to the last element that had focus.
-- it would be easier to track KILL_FOCUS events, but controls on OSX
-- don't always generate KILL_FOCUS events (see relevant wxwidgets
-- tickets: http://trac.wxwidgets.org/ticket/14142
-- and http://trac.wxwidgets.org/ticket/14269)

ide.editorApp:Connect(wx.wxEVT_SET_FOCUS, function(event)
  if ide.exitingProgram then return end

  local win = ide.frame:FindFocus()
  if win then
    local class = win:GetClassInfo():GetClassName()
    -- don't set focus on the main frame or toolbar
    if ide.infocus and (class == "wxAuiToolBar" or class == "wxFrame") then
      pcall(restoreFocus)
      return
    end

    -- keep track of the current control in focus, but only on the main frame
    -- don't try to "remember" any of the focus changes on various dialog
    -- windows as those will disappear along with their controls
    local grandparent = win:GetGrandParent()
    local frameid = ide.frame:GetId()
    local mainwin = grandparent and grandparent:GetId() == frameid
    local parent = win:GetParent()
    while parent do
      local class = parent:GetClassInfo():GetClassName()
      if (class == "wxFrame" or class:find("^wx.*Dialog$"))
      and parent:GetId() ~= frameid then
        mainwin = false; break
      end
      parent = parent:GetParent()
    end
    if mainwin then
      if ide.osname == "Macintosh"
      and ide:IsValidCtrl(ide.infocus) and ide.infocus:DynamicCast("wxWindow") ~= win then
        -- kill focus on the control that had the focus as wxwidgets on OSX
        -- doesn't do it: http://trac.wxwidgets.org/ticket/14142;
        -- wrap into pcall in case the window is already deleted
        local ev = wx.wxFocusEvent(wx.wxEVT_KILL_FOCUS)
        pcall(function() ide.infocus:GetEventHandler():ProcessEvent(ev) end)
      end
      ide.infocus = win
    end
  end

  event:Skip()
end)

local updateInterval = 250 -- time in ms
wx.wxUpdateUIEvent.SetUpdateInterval(updateInterval)

ide.editorApp:Connect(wx.wxEVT_ACTIVATE_APP,
  function(event)
    if not ide.exitingProgram then
      local active = event:GetActive()
      -- restore focus to the last element that received it;
      -- wrap into pcall in case the element has disappeared
      -- while the application was out of focus
      if ide.osname == "Macintosh" and active and ide.infocus then pcall(restoreFocus) end

      -- save auto-recovery record when making the app inactive
      if not active then saveAutoRecovery(true) end

      -- disable UI refresh when app is inactive, but only when not running
      wx.wxUpdateUIEvent.SetUpdateInterval(
        (active or ide:GetLaunchedProcess()) and updateInterval or -1)

      PackageEventHandle(active and "onAppFocusSet" or "onAppFocusLost", ide.editorApp)
    end
    event:Skip()
  end)

if ide.config.autorecoverinactivity then
  ide.timers.session = ide:AddTimer(frame, function() saveAutoRecovery() end)
  -- check at least 5s to be never more than 5s off
  ide.timers.session:Start(math.min(5, ide.config.autorecoverinactivity)*1000)
end

function PaneFloatToggle(window)
  local pane = uimgr:GetPane(window)
  if pane:IsFloating() then
    pane:Dock()
  else
    pane:Float()
    pane:FloatingPosition(pane.window:GetScreenPosition())
    pane:FloatingSize(pane.window:GetSize())
  end
  uimgr:Update()
end

local cma, cman = 0, 1
frame:Connect(wx.wxEVT_IDLE,
  function(event)
    if ide:GetDebugger():Update() then event:RequestMore(true) end
    -- there is a chance that the current debugger can change after `Update` call
    -- (as the debugger may be suspended during initial socket connection),
    -- so retrieve the current debugger again to make sure it's properly set up.
    local debugger = ide:GetDebugger()
    if (debugger.scratchpad) then debugger:ScratchpadRefresh() end
    if IndicateIfNeeded() then event:RequestMore(true) end
    PackageEventHandleOnce("onIdleOnce", event)
    PackageEventHandle("onIdle", event)

    -- process onidle events if any
    if #ide.onidle > 0 then table.remove(ide.onidle, 1)() end
    if #ide.onidle > 0 then event:RequestMore(true) end -- request more if anything left

    if ide.config.showmemoryusage then
      local mem = collectgarbage("count")
      local alpha = math.max(tonumber(ide.config.showmemoryusage) or 0, 1/cman)
      cman = cman + 1
      cma = alpha * mem + (1-alpha) * cma
      ide:SetStatus(("cur: %sKb; avg: %sKb"):format(math.floor(mem), math.floor(cma)))
    end

    event:Skip() -- let other EVT_IDLE handlers to work on the event
  end)
