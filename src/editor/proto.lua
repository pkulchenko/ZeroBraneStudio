-- Copyright 2013-17 Paul Kulchenko, ZeroBrane LLC
---------------------------------------------------------

local q = EscapeMagic
local modpref = ide.MODPREF

ide.proto.Document = {__index = {
  GetFileName = function(self) return self.fileName end,
  GetFilePath = function(self) return self.filePath end,
  GetFileExt = function(self) return GetFileExt(self.fileName) end,
  GetFileModifiedTime = function(self) return self.modTime end,
  GetEditor = function(self) return self.editor end,
  GetTabIndex = function(self)
    local notebook = self.editor:GetParent():DynamicCast("wxAuiNotebook")
    local index = notebook:GetPageIndex(self.editor)
    -- index may be -1 when `GetPageIndex` is called when the editor is already
    -- removed from the notebook; return non-existing index to continue
    return index >= 0 and index or notebook:GetPageCount(), notebook
  end,
  IsModified = function(self) return self.editor:GetModify() end,
  IsNew = function(self) return self.filePath == nil end,
  IsActive = function(self)
    if not self.editor then return false end
    local index, notebook = self:GetTabIndex()
    return notebook:GetSelection() == index
  end,
  SetFilePath = function(self, path) self.filePath = path end,
  SetFileName = function(self, name)
    local newext = not self.fileName or not name or GetFileExt(name) ~= GetFileExt(self.fileName)
    self.fileName = name
    -- reset the editor based on the set name
    local editor = self.editor
    if editor and newext then
      editor:SetupKeywords(GetFileExt(name))
      editor:Colourise(0, -1)
      editor:ResetTokenList() -- reset list of tokens if this is a reused editor
    end
  end,
  SetFileModifiedTime = function(self, modtime) self.modTime = modtime end,
  SetModified = function(self, modified)
    if modified == false then self.editor:SetSavePoint() end
  end,
  SetTabText = function(self, text)
    local modpref = ide.config.editor.modifiedprefix or modpref
    local index, notebook = self:GetTabIndex()
    notebook:SetPageText(index,
      (self:IsModified() and modpref or '')..(text or self:GetTabText()))
    if ide.config.editor.showtabtooltip and ide:IsValidProperty(notebook, "SetPageToolTip") then
      notebook:SetPageToolTip(index, self:GetFilePath() or text or self:GetTabText())
    end
    if ide.config.editor.showtabicon then
      if not notebook:GetImageList() then
        notebook:SetImageList(ide:GetProjectTree():GetImageList())
      end
      notebook:SetPageImage(index,
        ide:GetProjectTree():GetFileImage(self:GetFilePath() or text or self:GetTabText()))
    end
  end,
  GetTabText = function(self)
    local modpref = ide.config.editor.modifiedprefix or modpref
    local index, notebook = self:GetTabIndex()
    if index == nil then return self.fileName end
    return (notebook:GetPageText(index):gsub("^"..q(modpref), ""))
  end,
  SetActive = function(self)
    if not self.editor then return false end

    local index, notebook = self:GetTabIndex()
    if index and notebook:GetSelection() ~= index then notebook:SetSelection(index) end

    AddToFileHistory(self:GetFilePath())

    self.editor:SetFocus()
    self.editor:SetSTCFocus(true)
    -- when the active editor is changed while the focus is away from the application
    -- (as happens on OSX when the editor is selected from the command bar)
    -- the focus stays on wxAuiToolBar component, so need to explicitly switch it.
    -- this is needed because SetFocus doesn't reset the focus if it's already on the target.
    if ide.osname == "Macintosh" and ide.infocus then ide.infocus = self.editor end
  end,
  Save = function(self) return SaveFile(self.editor, self.filePath) end,
  Close = function(self) return ClosePage(self:GetTabIndex()) end,
  CloseAll = function(self, opts)
    -- opts.keep=true/false -- keep the current document (false)
    -- opts.scope="section"/"notebook"/"project"/"all" -- ("all")
    -- opts.dryrun=true/false -- return the list of documents and not close (false)
    if not opts then opts = {} end
    local index, nb = self:GetTabIndex()
    local tabctrl = opts.scope == "section" and nb:GetTabCtrl(self.editor) or nil
    -- if the tab control is not available and `section` is requested as the scope,
    -- change the scope to the `notebook`. This shouldn't normally happen,
    -- but may if the tab control is checked before the frame is fully set up.
    if not tabctrl and opts.scope == "section" then opts.scope = "notebook" end
    local toclose = {}
    for _, document in ipairs(ide:GetDocumentList()) do
      local dindex, dnb = document:GetTabIndex()
      local path = document:GetFilePath()
      if (not opts.keep or dnb ~= nb or dindex ~= index)
      and (not opts.scope or opts.scope == "all" -- close all if the scope is not set
        or (opts.scope == "notebook" and nb:GetPageIndex(document:GetEditor()) >= 0)
        or (opts.scope == "project" and path and ide:IsProjectSubDirectory(path))
        -- if the document is in the same tab control (for split notebooks)
        or (opts.scope == "section" and tabctrl and tabctrl:GetIdxFromWindow(document:GetEditor()) >= 0)
      ) then
        table.insert(toclose, document)
      end
    end
    if opts.dryrun then return toclose end
    -- close pages in the reverse order (as ids shift when pages are closed)
    for i = #toclose, 1, -1 do
      if not toclose[i]:Close() then return false end
    end
    return true
  end,
}}

ide.proto.Plugin = {__index = {
  GetName = function(self) return self.name end,
  GetFileName = function(self) return self.fname end,
  GetFilePath = function(self) return MergeFullPath(GetPathWithSep(ide.editorFilename), self.fpath) end,
  GetConfig = function(self) return rawget(ide.config,self.fname) or {} end,
  GetSettings = function(self) return SettingsRestorePackage(self.fname) end,
  SetSettings = function(self, settings, opts) SettingsSavePackage(self.fname, settings, opts) end,
}}

ide.proto.Interpreter = {__index = {
  GetName = function(self) return self.name end,
  GetFileName = function(self) return self.fname end,
  GetExePath = function(self, ...) return self:fexepath(...) end,
  GetAPI = function(self) return self.api end,
  GetCommandLineArg = function(self, name)
    return ide.config.arg and (ide.config.arg.any or ide.config.arg[name or self.fname])
  end,
  UpdateStatus = function(self)
    local cla = self.takeparameters and self:GetCommandLineArg()
    ide:SetStatus(self.name..(cla and #cla > 0 and ": "..cla or ""), 4)
  end,
  fprojdir = function(self,wfilename)
    return wfilename:GetPath(wx.wxPATH_GET_VOLUME)
  end,
  fworkdir = function(self,wfilename)
    local proj = ide:GetProject()
    return proj and proj:gsub("[\\/]$","") or wfilename:GetPath(wx.wxPATH_GET_VOLUME)
  end,
  fattachdebug = function(self) ide:GetDebugger():SetOptions() end,
}}

ide.proto.Debugger = {__index = {
  IsRunning = function(self) return self.running end,
  IsConnected = function(self) return self.server end,
  IsListening = function(self) return self.listening end,
  GetHostName = function(self) return self.hostname end,
  GetPortNumber = function(self) return self.portnumber end,
  GetConsole = function(self)
    local debugger = self
    return function(...) return debugger:shell(...) end
  end,
  GetDataOptions = function(self, options)
    local cfg = ide.config.debugger
    local params = {
      comment = false, nocode = true, numformat = cfg.numformat, metatostring = cfg.showtostring,
      maxlevel = cfg.maxdatalevel, maxnum = cfg.maxdatanum, maxlength = cfg.maxdatalength,
    }
    for k, v in pairs(options or {}) do params[k] = v end
    return params
  end,
}}

ide.proto.ID = {
  __index = function(_, id) return _G['ID_'..id] end,
  __call = function(_, id) return IDgen(id) end,
}
