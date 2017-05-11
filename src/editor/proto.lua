-- Copyright 2013-15 Paul Kulchenko, ZeroBrane LLC
---------------------------------------------------------

local q = EscapeMagic
local modpref = ide.MODPREF

ide.proto.Document = {__index = {
  UpdateTitle = function(self)
    if PackageEventHandle("onEditorUpdateTabText", self) == false then 
      self:SetTabText(self.fileName)
    end
  end,
  GetFileName = function(self) return self.fileName end,
  GetFilePath = function(self) return self.filePath end,
  GetFileExt = function(self) return GetFileExt(self.fileName) end,
  GetModTime = function(self) return self.modTime end,
  GetEditor = function(self) return self.editor end,
  GetTabIndex = function(self) return self.index end,
  IsModified = function(self) return self.isModified end,
  IsNew = function(self) return self.filePath == nil end,
  SetFilePath = function(self, path) self.filePath = path end,
  SetModTime = function(self, modtime) self.modTime = modtime end,
  SetModified = function(self, modified)
    self.isModified = modified
    self:SetTabText()
  end,
  SetTabText = function(self, text)
    ide:GetEditorNotebook():SetPageText(self.index,
      (self.isModified and modpref or '')..(text or self:GetTabText()))
  end,
  GetTabText = function(self)
    if self.index == nil then return self.fileName end
    return ide:GetEditorNotebook():GetPageText(self.index):gsub("^"..q(modpref), "")
  end,
  SetActive = function(self) SetEditorSelection(self.index) end,
  Save = function(self) return SaveFile(self.editor, self.filePath) end,
  Close = function(self) return ClosePage(self.index) end,
  CloseAll = function(self) return CloseAllPagesExcept(-1) end,
  CloseAllExcept = function(self) return CloseAllPagesExcept(self.index) end,
}}

ide.proto.Plugin = {__index = {
  GetName = function(self) return self.name end,
  GetFileName = function(self) return self.fname end,
  GetFilePath = function(self) return MergeFullPath(GetPathWithSep(ide.editorFilename), self.fpath) end,
  GetConfig = function(self) return ide.config[self.fname] or {} end,
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
      comment = false, nocode = true, numformat = cfg.numformat,
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
