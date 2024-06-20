-- Copyright 2011-18 Paul Kulchenko, ZeroBrane LLC
-- Original authors: Lomtik Software (J. Winwood & John Labenski)
-- Luxinia Dev (Eike Decker & Christoph Kubisch)
-- Integration with MobDebug
---------------------------------------------------------

local copas = require "copas"
local socket = require "socket"
local mobdebug = require "mobdebug"
local unpack = table.unpack or unpack

local ide = ide
local protodeb = setmetatable(ide:GetDebugger(), ide.proto.Debugger)
local debugger = protodeb
debugger.running = false -- true when the debuggee is running
debugger.listening = false -- true when the debugger is listening for a client
debugger.portnumber = ide.config.debugger.port or mobdebug.port -- the port # to use for debugging
debugger.watchCtrl = nil -- the watch ctrl that shows watch information
debugger.stackCtrl = nil -- the stack ctrl that shows stack information
debugger.toggleview = {
  bottomnotebook = true, -- output/console is "on" by default
  stackpanel = false, watchpanel = false, toolbar = false }
debugger.needrefresh = {} -- track components that may need a refresh
debugger.hostname = ide.config.debugger.hostname or (function()
  local hostname = socket.dns.gethostname()
  return hostname and socket.dns.toip(hostname) and hostname or "localhost"
end)()
debugger.imglist = ide:CreateImageList("STACK", "VALUE-CALL", "VALUE-LOCAL", "VALUE-UP")

local image = { STACK = 0, LOCAL = 1, UPVALUE = 2 }

local CURRENT_LINE_MARKER = StylesGetMarker("currentline")
local CURRENT_LINE_MARKER_VALUE = 2^CURRENT_LINE_MARKER
local BREAKPOINT_MARKER = StylesGetMarker("breakpoint")
local BREAKPOINT_MARKER_VALUE = 2^BREAKPOINT_MARKER

local activate = {CHECKONLY = "checkonly", NOREPORT = "noreport", CLEARALL = "clearall"}

local function serialize(value, options) return mobdebug.line(value, options) end

local function displayError(...) return ide:GetOutput():Error(...) end

local function fixUTF8(...)
  local t = {...}
  -- convert to escaped decimal code as these can only appear in strings
  local function fix(s) return '\\'..string.byte(s) end
  for i = 1, #t do t[i] = FixUTF8(t[i], fix) end
  return unpack(t)
end

local debug_file_name, bp_file_name do
  local iscaseinsensitive = wx.wxFileName("A"):SameAs(wx.wxFileName("a"))

  local function isSameAs(f1, f2)
    return f1 == f2 or iscaseinsensitive and f1:lower() == f2:lower()
  end

  local function filePathMatch(file, pattern)
    return (#file >= #pattern) and isSameAs(file:sub(1, #pattern), pattern)
  end

  local function fix_file_name(reverse, file)
    local pathmap = ide.config.debugger and ide.config.debugger.pathmap

    if pathmap then
      local projectDir = ide:GetProject() or ide.cwd or wx.wxGetCwd()
      for _, map in ipairs(pathmap) do
        local remote_path, local_path = map[1], MergeFullPath(projectDir, map[2]) or map[2]

        local pattern, substitution = remote_path, local_path
        if reverse then
            pattern, substitution = substitution, pattern
        end

        if filePathMatch(file, pattern) then
          file = substitution .. file:sub(#pattern + 1)
          break
        end
      end
    end

    return file
  end

  debug_file_name = function (file)
      return fix_file_name(false, file)
  end

  bp_file_name = function (file)
    return fix_file_name(true, file)
  end
end

local q = EscapeMagic
local MORE = "{...}"

function debugger:init(init)
  local o = {}
  -- merge known self and init values
  for k, v in pairs(self) do o[k] = v end
  for k, v in pairs(init or {}) do o[k] = v end
  return setmetatable(o, {__index = protodeb})
end

function debugger:updateWatchesSync(onlyitem)
  local debugger = self
  local watchCtrl = debugger.watchCtrl
  local pane = ide.frame.uimgr:GetPane("watchpanel")
  local shown = watchCtrl and (pane:IsOk() and pane:IsShown() or not pane:IsOk() and watchCtrl:IsShown())
  local canupdate = (debugger.server and not debugger.running and not debugger.scratchpad
    and not (debugger.options or {}).noeval)
  if shown and canupdate then
    local bgcl = watchCtrl:GetBackgroundColour()
    local hicl = wx.wxColour(math.floor(bgcl:Red()*.9),
      math.floor(bgcl:Green()*.9), math.floor(bgcl:Blue()*.9))

    local root = watchCtrl:GetRootItem()
    if not root or not root:IsOk() then return end

    local params = debugger:GetDataOptions({maxlength=false})
    local item = onlyitem or watchCtrl:GetFirstChild(root)
    while true do
      if not item:IsOk() then break end

      local expression = watchCtrl:GetItemExpression(item)
      if expression then
        local _, values, error = debugger:evaluate(expression, params)
        local curchildren = watchCtrl:GetItemChildren(item)
        if error then
          error = error:gsub("%[.-%]:%d+:%s+","")
          watchCtrl:SetItemValueIfExpandable(item, nil)
        else
          if #values == 0 then values = {'nil'} end
          local _, res = LoadSafe("return "..values[1])
          watchCtrl:SetItemValueIfExpandable(item, res)
        end

        local newval = fixUTF8(expression .. ' = '
          .. (error and ('error: '..error) or table.concat(values, ", ")))
        local val = watchCtrl:GetItemText(item)

        watchCtrl:SetItemBackgroundColour(item, val ~= newval and hicl or bgcl)
        watchCtrl:SetItemText(item, newval)

        if onlyitem or val ~= newval then
          local newchildren = watchCtrl:GetItemChildren(item)
          if next(curchildren) ~= nil and next(newchildren) == nil then
            watchCtrl:SetItemHasChildren(item, true)
            watchCtrl:CollapseAndReset(item)
            watchCtrl:SetItemHasChildren(item, false)
          elseif next(curchildren) ~= nil and next(newchildren) ~= nil then
            watchCtrl:CollapseAndReset(item)
            watchCtrl:Expand(item)
          end
        end
      end

      if onlyitem then break end
      item = watchCtrl:GetNextSibling(item)
    end
    debugger.needrefresh.watches = false
  elseif not shown and canupdate then
    debugger.needrefresh.watches = true
  end
end

local callData = {}

function debugger:updateStackSync()
  local debugger = self
  local stackCtrl = debugger.stackCtrl
  local pane = ide.frame.uimgr:GetPane("stackpanel")
  local shown = stackCtrl and (pane:IsOk() and pane:IsShown() or not pane:IsOk() and stackCtrl:IsShown())
  local canupdate = debugger.server and not debugger.running and not debugger.scratchpad
  if shown and canupdate then
    local stack, _, err = debugger:stack(debugger:GetDataOptions({maxlength=false}))
    if not stack or #stack == 0 then
      stackCtrl:DeleteAll()
      if err then -- report an error if any
        stackCtrl:AppendItem(stackCtrl:AddRoot("Stack"), "Error: " .. err, image.STACK)
      end
      return
    end
    stackCtrl:Freeze()
    stackCtrl:DeleteAll()

    local forceexpand = ide.config.debugger.maxdatalevel == 1
    local params = debugger:GetDataOptions({maxlevel=false})
    local maxlen = tonumber(ide.config.debugger.maxdatalength)

    local root = stackCtrl:AddRoot("Stack")
    callData = {} -- reset call cache
    for _,frame in ipairs(stack) do
      -- check if the stack includes expected structures
      if type(frame) ~= "table" or type(frame[1]) ~= "table" or #frame[1] < 7 then break end

      -- "main chunk at line 24"
      -- "foo() at line 13 (defined at foobar.lua:11)"
      -- call = { source.name, source.source, source.linedefined,
      --   source.currentline, source.what, source.namewhat, source.short_src }
      local call = frame[1]

      -- format the function name to a readable user string
      local func = call[5] == "main" and "main chunk"
        or call[5] == "C" and (call[1] or "C function")
        or call[5] == "tail" and "tail call"
        or (call[1] or "anonymous function")

      -- format the function treeitem text string, including the function name
      local text = func ..
        (call[4] == -1 and '' or " at line "..call[4]) ..
        (call[5] ~= "main" and call[5] ~= "Lua" and ''
         or (call[3] > 0 and " (defined at "..call[7]..":"..call[3]..")"
                          or " (defined in "..call[7]..")"))

      -- create the new tree item for this level of the call stack
      local callitem = stackCtrl:AppendItem(root, text, image.STACK)

      -- register call data to provide stack navigation
      callData[callitem:GetValue()] = { call[2], call[4] }

      -- add the local variables to the call stack item
      for name,val in pairs(type(frame[2]) == "table" and frame[2] or {}) do
        -- format the variable name, value as a single line and,
        -- if not a simple type, the string value.
        local value = val[1]
        if type(value) == "string" and maxlen and #value > maxlen then value = value:sub(1,maxlen) end
        local text = ("%s = %s"):format(name, fixUTF8(serialize(value, params)))
        local item = stackCtrl:AppendItem(callitem, text, image.LOCAL)
        stackCtrl:SetItemValueIfExpandable(item, value, forceexpand)
        stackCtrl:SetItemName(item, name)
      end

      -- add the upvalues for this call stack level to the tree item
      for name,val in pairs(type(frame[3]) == "table" and frame[3] or {}) do
        local value = val[1]
        if type(value) == "string" and maxlen and #value > maxlen then value = value:sub(1,maxlen) end
        local text = ("%s = %s"):format(name, fixUTF8(serialize(value, params)))
        local item = stackCtrl:AppendItem(callitem, text, image.UPVALUE)
        stackCtrl:SetItemValueIfExpandable(item, value, forceexpand)
        stackCtrl:SetItemName(item, name)
      end

      stackCtrl:SortChildren(callitem)
      stackCtrl:Expand(callitem)
    end
    stackCtrl:EnsureVisible(stackCtrl:GetFirstChild(root))
    stackCtrl:Thaw()
    stackCtrl:SetScrollPos(wx.wxHORIZONTAL, 0, true)
    debugger.needrefresh.stack = false
  elseif not shown and canupdate then
    debugger.needrefresh.stack = true
  end
end

function debugger:updateStackAndWatches()
  local debugger = self
  -- check if the debugger is running and may be waiting for a response.
  -- allow that request to finish, otherwise this function does nothing.
  if debugger.running then debugger:Update() end
  if debugger.server and not debugger.running then
    copas.addthread(function()
        local debugger = debugger
        debugger:updateStackSync()
        debugger:updateWatchesSync()
      end)
  end
end

function debugger:updateWatches(item)
  local debugger = self
  -- check if the debugger is running and may be waiting for a response.
  -- allow that request to finish, otherwise this function does nothing.
  if debugger.running then debugger:Update() end
  if debugger.server and not debugger.running then
    copas.addthread(function()
        local debugger = debugger
        debugger:updateWatchesSync(item)
      end)
  end
end

function debugger:updateStack()
  local debugger = self
  -- check if the debugger is running and may be waiting for a response.
  -- allow that request to finish, otherwise this function does nothing.
  if debugger.running then debugger:Update() end
  if debugger.server and not debugger.running then
    copas.addthread(function()
        local debugger = debugger
        debugger:updateStackSync()
      end)
  end
end

function debugger:toggleViews(show)
  local debugger = self
  -- don't toggle if the current state is the same as the new one
  local shown = debugger.toggleview.shown
  if (show and shown) or (not show and not shown) then return end

  debugger.toggleview.shown = nil

  local mgr = ide.frame.uimgr
  local refresh = false
  for view, needed in pairs(debugger.toggleview) do
    local bar = view == 'toolbar'
    local pane = mgr:GetPane(view)
    if show then -- starting debugging and pane is not shown
      -- show toolbar during debugging if hidden and not fullscreen
      debugger.toggleview[view] = (not pane:IsShown()
        and (not bar or not ide.frame:IsFullScreen()))
      if debugger.toggleview[view] and (needed or bar) then
        pane:Show()
        refresh = true
      end
    else -- completing debugging and pane is shown
      debugger.toggleview[view] = pane:IsShown() and needed
      if debugger.toggleview[view] then
        pane:Hide()
        refresh = true
      end
    end
  end
  if refresh then mgr:Update() end
  if show then debugger.toggleview.shown = true end
end

local function killProcess(pid)
  if not pid then return false end
  if wx.wxProcess.Exists(pid) then
    local _ = wx.wxLogNull() -- disable error popup; will report as needed
    -- using SIGTERM for some reason kills not only the debugee process,
    -- but also some system processes, which leads to a blue screen crash
    -- (at least on Windows Vista SP2)
    local ret = wx.wxProcess.Kill(pid, wx.wxSIGKILL, wx.wxKILL_CHILDREN)
    if ret == wx.wxKILL_OK then
      ide:Print(TR("Program stopped (pid: %d)."):format(pid))
    elseif ret ~= wx.wxKILL_NO_PROCESS then
      wx.wxMilliSleep(250)
      if wx.wxProcess.Exists(pid) then
        displayError(TR("Unable to stop program (pid: %d), code %d."):format(pid, ret))
        return false
      end
    end
  end
  return true
end

function debugger:ActivateDocument(file, line, activatehow)
  if activatehow == activate.CLEARALL then ClearAllCurrentLineMarkers() end

  local debugger = self
  if not file then return end
  line = tonumber(line)
  file = debug_file_name(file)

  -- file can be a filename or serialized file content; deserialize first.
  -- check if the filename starts with '"' and is deserializable
  -- to avoid showing filenames that may look like valid lua code
  -- (for example: 'mobdebug.lua').
  local content
  if not wx.wxFileName(file):FileExists() and file:find('^"') then
    local ok, res = LoadSafe("return "..file)
    if ok then content = res end
  end

  -- in some cases filename can be returned quoted if the chunk is loaded with
  -- loadstring(chunk, "filename") instead of loadstring(chunk, "@filename")
  if content then
    -- if the returned content can be matched with a file, it's a file name
    local fname = GetFullPathIfExists(debugger.basedir, content) or content
    if wx.wxFileName(fname):FileExists() then file, content = fname, nil end
  elseif not wx.wxIsAbsolutePath(file) and debugger.basedir then
    file = debugger.basedir .. file
  end

  if PackageEventHandle("onDebuggerPreActivate", debugger, file, line) == false then return end

  local activated = false
  local indebugger = file:find('mobdebug%.lua$')
  local fileName = wx.wxFileName(file)
  local fileNameLower = wx.wxFileName(file:lower())

  for _, document in pairs(ide:GetDocuments()) do
    local editor = document:GetEditor()
    -- either the file name matches, or the content;
    -- when checking for the content remove all newlines as they may be
    -- reported differently from the original by the Lua engine.
    local ignorecase = ide.config.debugger.ignorecase or (debugger.options or {}).ignorecase
    local filePath = document:GetFilePath()
    if filePath and (fileName:SameAs(wx.wxFileName(filePath))
      or ignorecase and fileNameLower:SameAs(wx.wxFileName(filePath:lower())))
    or content and content:gsub("[\n\r]","") == editor:GetTextDyn():gsub("[\n\r]","") then
      ClearAllCurrentLineMarkers()
      if line then
        if line == 0 then -- special case; find the first executable line
          line = math.huge
          local loadstring = loadstring or load
          local func = loadstring(editor:GetTextDyn())
          if func then -- .activelines == {[3] = true, [4] = true, ...}
            for l in pairs(debug.getinfo(func, "L").activelines) do
              if l < line then line = l end
            end
          end
          if line == math.huge then line = 1 end
        end
        if debugger.runtocursor then
          local ed, ln = unpack(debugger.runtocursor)
          if ed:GetId() == editor:GetId() and ln == line then
            -- remove run-to breakpoint at this location
            debugger:breakpointToggle(ed, ln, false)
            debugger.runtocursor = nil
          end
        end
        local line = line - 1 -- editor line operations are zero-based
        editor:MarkerAdd(line, CURRENT_LINE_MARKER)
        editor:Refresh() -- needed for background markers that don't get refreshed (wx2.9.5)

        -- expand fold if the activated line is in a folded fragment
        if not editor:GetLineVisible(line) then editor:ToggleFold(editor:GetFoldParent(line)) end

        -- found and marked what we are looking for;
        -- don't need to activate with CHECKONLY (this assumes line is given)
        if activatehow == activate.CHECKONLY then return editor end

        local firstline = editor:DocLineFromVisible(editor:GetFirstVisibleLine())
        local lastline = math.min(editor:GetLineCount(),
          editor:DocLineFromVisible(editor:GetFirstVisibleLine() + editor:LinesOnScreen()))
        -- if the line is already on the screen, then don't enforce policy
        if line <= firstline or line >= lastline then
          editor:EnsureVisibleEnforcePolicy(line)
        end
      end

      document:SetActive()
      ide:RequestAttention()

      if content then
        -- it's possible that the current editor tab already has
        -- breakpoints that have been set based on its filepath;
        -- if the content has been matched, then existing breakpoints
        -- need to be removed and new ones set, based on the content.
        if not debugger.editormap[editor] and filePath then
          local line = editor:MarkerNext(0, BREAKPOINT_MARKER_VALUE)
          while filePath and line ~= -1 do
            debugger:handle("delb " .. bp_file_name(filePath) .. " " .. (line+1))
            debugger:handle("setb " .. bp_file_name(file) .. " " .. (line+1))
            line = editor:MarkerNext(line + 1, BREAKPOINT_MARKER_VALUE)
          end
        end

        -- keep track of those editors that have been activated based on
        -- content rather than file names as their breakpoints have to be
        -- specified in a different way
        debugger.editormap[editor] = file
      end

      activated = editor
      break
    end
  end

  if not (activated or indebugger or debugger.loop or activatehow == activate.CHECKONLY)
  and (ide.config.editor.autoactivate or content and activatehow == activate.NOREPORT) then
    -- found file, but can't activate yet (because this part may be executed
    -- in a different coroutine), so schedule pending activation.
    if content or wx.wxFileName(file):FileExists() then
      debugger.activate = {file, line, content}
      return true -- report successful activation, even though it's pending
    end

    -- only report files once per session and if not asked to skip
    if not debugger.missing[file] and activatehow ~= activate.NOREPORT then
      debugger.missing[file] = true
      displayError(TR("Couldn't activate file '%s' for debugging; continuing without it.")
        :format(file))
    end
  end

  PackageEventHandle("onDebuggerActivate", debugger, file, line, activated)

  return activated
end

function debugger:reSetBreakpoints()
  local debugger = self
  -- remove all breakpoints that may still be present from the last session
  -- this only matters for those remote clients that reload scripts
  -- without resetting their breakpoints
  debugger:handle("delallb")

  -- go over all windows and find all breakpoints
  if (not debugger.scratchpad) then
    for _, document in pairs(ide:GetDocuments()) do
      local editor = document:GetEditor()
      local filePath = document:GetFilePath()
      local line = editor:MarkerNext(0, BREAKPOINT_MARKER_VALUE)
      while filePath and line ~= -1 do
        debugger:handle("setb " .. bp_file_name(filePath) .. " " .. (line+1))
        line = editor:MarkerNext(line + 1, BREAKPOINT_MARKER_VALUE)
      end
    end
  end
end

function debugger:shell(expression, isstatement)
  local debugger = self
  local loadstring = loadstring or load
  -- check if the debugger is running and may be waiting for a response.
  -- allow that request to finish, otherwise this function does nothing.
  if debugger.running then debugger:Update() end
  if debugger.server and not debugger.running
  and (not debugger.scratchpad or debugger.scratchpad.paused) then
    -- default options for shell commands
    local params = debugger:GetDataOptions({
        comment=true, maxlength=false, maxlevel=false, numformat=false})
    -- any explicit options for this command
    for k, v in pairs(loadstring("return"..(expression:match("--%s*(%b{})%s*$") or "{}"))()) do
      params[k] = v
    end
    copas.addthread(function()
        local debugger = debugger
        -- exec command is not expected to return anything.
        -- eval command returns 0 or more results.
        -- 'values' has a list of serialized results returned.
        -- as it is not possible to distinguish between 0 results and one
        -- 'nil' value returned, 'nil' is always returned in this case.
        -- the first value returned by eval command is not used;
        -- this may need to be taken into account by other debuggers.
        local addedret, forceexpression = true, expression:match("^%s*=%s*")
        expression = expression:gsub("^%s*=%s*","")
        local _, values, err = debugger:evaluate(expression, params)
        if not forceexpression and err then
          local _, values2, err2 = debugger:execute(expression, params)
          -- since the remote execution may fail during compilation- and run-time,
          -- and some expressions may fail in both cases, try to report the "best" error.
          -- for example, `x[1]` fails as statement, and may also fail if `x` is `nil`.
          -- in this case, the first (expression) error is returned if it's not a
          -- statement and compiles as an expression without errors.
          -- the order of statement and expression checks can't be reversed as errors from
          -- code fragments that fail with both, will be always reported as expressions.
          if not (err2 and not isstatement and loadstring("return "..expression)) then
            addedret, values, err = false, values2, err2
          end
        end

        if err then
          if addedret then err = err:gsub('^%[string "return ', '[string "') end
          ide:GetConsole():Error(err)
        elseif addedret or #values > 0 then
          if forceexpression then -- display elements as multi-line
            for i,v in pairs(values) do -- stringify each of the returned values
              local func = loadstring('return '..v) -- deserialize the value first
              if func then -- if it's deserialized correctly
                values[i] = (forceexpression and i > 1 and '\n' or '') ..
                  serialize(func(), {nocode = true, comment = 0,
                    -- if '=' is used, then use multi-line serialized output
                    indent = forceexpression and '  ' or nil})
              end
            end
          end

          -- if empty table is returned, then show nil if this was an expression
          if #values == 0 and (forceexpression or not isstatement) then
            values = {'nil'}
          end
          ide:GetConsole():Print(unpack(values))
        end

        -- refresh Stack and Watch windows if executed a statement (and no err)
        if isstatement and not err and not addedret and #values == 0 then
          debugger:updateStackSync()
          debugger:updateWatchesSync()
        end
      end)
  elseif debugger.server then
    ide:GetConsole():Error(TR("Can't evaluate the expression while the application is running."))
  end
end

function debugger:stoppedAtBreakpoint(file, line)
  -- if this document can be activated and the current line has a breakpoint
  local editor = self:ActivateDocument(file, line, activate.CHECKONLY)
  if not editor then return false end

  local current = editor:MarkerNext(0, CURRENT_LINE_MARKER_VALUE)
  local breakpoint = editor:MarkerNext(current, BREAKPOINT_MARKER_VALUE)
  return breakpoint ~= wx.wxNOT_FOUND and breakpoint == current
end

function debugger:mapRemotePath(basedir, file, line, method)
  local debugger = self
  if not file then return end

  -- file is /foo/bar/my.lua; basedir is d:\local\path\
  -- check for d:\local\path\my.lua, d:\local\path\bar\my.lua, ...
  -- wxwidgets on Windows handles \\ and / as separators, but on OSX
  -- and Linux it only handles 'native' separator;
  -- need to translate for GetDirs to work.
  local file = file:gsub("\\", "/")
  local parts = wx.wxFileName(file):GetDirs()
  local name = wx.wxFileName(file):GetFullName()

  -- find the longest remote path that can be mapped locally
  local longestpath, remotedir
  while true do
    local mapped = GetFullPathIfExists(basedir, name)
    if mapped then
      longestpath = mapped
      remotedir = file:gsub(q(name):gsub("/", ".").."$", "")
    end
    if #parts == 0 then break end
    name = table.remove(parts, #parts) .. "/" .. name
  end
  -- if the mapped directory empty or the same as the basedir, nothing to do
  if not remotedir or remotedir == "" or wx.wxFileName(remotedir):SameAs(wx.wxFileName(debugger.basedir)) then return end

  -- if found a local mapping under basedir
  local activated = longestpath and (debugger:ActivateDocument(longestpath, line, method or activate.NOREPORT)
    -- local file may exist, but not activated when not (auto-)opened, still need to remap
    or wx.wxFileName(longestpath):FileExists())
  if activated then
    -- find remote basedir by removing the tail from remote file
    debugger:handle("basedir " .. debugger.basedir .. "\t" .. remotedir)
    -- reset breakpoints again as remote basedir has changed
    debugger:reSetBreakpoints()
    ide:Print(TR("Mapped remote request for '%s' to '%s'."):format(remotedir, debugger.basedir))

    return longestpath
  end

  return nil
end

function debugger:Listen(start)
  local debugger = ide:GetDebugger()
  if start == false then
    if debugger.listening then
      debugger:terminate() -- terminate if running
      copas.removeserver(debugger.listening)
      ide:Print(TR("Debugger server stopped at %s:%d.")
        :format(debugger.hostname, debugger.portnumber))
      debugger.listening = false
    else
      displayError(TR("Can't stop debugger server as it is not started."))
    end
    return
  end

  if debugger.listening then return end

  local server, err = socket.bind("*", debugger.portnumber)
  if not server then
    displayError(TR("Can't start debugger server at %s:%d: %s.")
      :format(debugger.hostname, debugger.portnumber, err or TR("unknown error")))
    return
  end
  ide:Print(TR("Debugger server started at %s:%d."):format(debugger.hostname, debugger.portnumber))

  copas.autoclose = false
  copas.addserver(server, function (skt)
      local debugger = ide:GetDebugger()
      local options = debugger.options or {}
      if options.refuseonconflict == nil then options.refuseonconflict = ide.config.debugger.refuseonconflict end

      -- pull any pending data not processed yet
      if debugger.running then debugger:Update() end
      if debugger.server and options.refuseonconflict then
        displayError(TR("Refused a request to start a new debugging session as there is one in progress already."))
        return
      end

      -- error handler is set per-copas-thread
      copas.setErrorHandler(function(error)
        -- ignore errors that happen because debugging session is
        -- terminated during handshake (server == nil in this case).
        if debugger.server then
          displayError(TR("Can't start debugging session due to internal error '%s'."):format(error))
        end
        debugger:terminate()
      end)

      -- this may be a remote call without using an interpreter and as such
      -- debugger.options may not be set, but runonstart is still configured.
      local runstart = options.runstart
      if runstart == nil then runstart = ide.config.debugger.runonstart end

      -- support allowediting as set in the interpreter or config
      if options.allowediting == nil then options.allowediting = ide.config.debugger.allowediting end

      if not debugger.scratchpad and not options.allowediting then
        SetAllEditorsReadOnly(true)
      end

      debugger = ide:SetDebugger(debugger:init({
          server = copas.wrap(skt),
          socket = skt,
          loop = false,
          scratchable = false,
          stats = {line = 0},
          missing = {},
          editormap = {},
          runtocursor = nil,
      }))

      if PackageEventHandle("onDebuggerPreLoad", debugger, options) == false then return end

      local editor = ide:GetEditor()
      local startfile = ide:GetProjectStartFile() or options.startwith
        or (editor and SaveIfModified(editor) and ide:GetDocument(editor):GetFilePath())

      if not startfile then
        displayError(TR("Can't start debugging without an opened file or with the current file not being saved."))
        return debugger:terminate()
      end

      local startpath = wx.wxFileName(startfile):GetPath(wx.wxPATH_GET_VOLUME + wx.wxPATH_GET_SEPARATOR)
      local basedir = options.basedir or ide:GetProject() or startpath
      -- guarantee that the path has a trailing separator
      debugger.basedir = wx.wxFileName.DirName(basedir):GetFullPath()

      -- load the remote file into the debugger
      -- set basedir first, before loading to make sure that the path is correct
      debugger:handle("basedir " .. debugger.basedir)

      local init = options.init or ide.config.debugger.init
      if init then
        local _, _, err = debugger:execute(init)
        if err then displayError(TR("Ignored error in debugger initialization code: %s."):format(err)) end
      end

      debugger:reSetBreakpoints()

      local redirect = ide.config.debugger.redirect or options.redirect
      if redirect then
        debugger:handle("output stdout " .. redirect, nil,
          { handler = function(m)
              -- if it's an error returned, then handle the error
              if m and m:find("stack traceback:", 1, true) then
                -- this is an error message sent remotely
                local ok, res = LoadSafe("return "..m)
                if ok then
                  ide:Print(res)
                  return
                end
              end

              if ide.config.debugger.outputfilter then
                local ok, res = pcall(ide.config.debugger.outputfilter, m)
                if ok then
                  m = res
                else
                  displayError("Output filter failed: "..res)
                  return
                end
              end
              if m then ide:GetOutput():Write(m) end
            end})
      end

      if (options.startwith) then
        local file, line, err = debugger:loadfile(options.startwith)
        if err then
          displayError(TR("Can't run the entry point script ('%s').")
            :format(options.startwith)
            .." "..TR("Compilation error")
            ..":\n"..err)
          return debugger:terminate()
        elseif runstart and not debugger.scratchpad then
          if debugger:stoppedAtBreakpoint(file, line) then
            debugger:ActivateDocument(file, line)
            runstart = false
          end
        elseif file and line and not debugger:ActivateDocument(file, line) then
          displayError(TR("Debugging suspended at '%s:%s' (couldn't activate the file).")
            :format(file, line))
        end
      elseif not debugger.scratchpad then
        local file, line, err = debugger:loadfile(startfile)
        -- "load" can work in two ways: (1) it can load the requested file
        -- OR (2) it can "refuse" to load it if the client was started
        -- with start() method, which can't load new files
        -- if file and line are set, this indicates option #2
        if err then
          displayError(TR("Can't start debugging for '%s'."):format(startfile)
            .." "..TR("Compilation error")
            ..":\n"..err)
          return debugger:terminate()
        elseif runstart then
          local file = (debugger:mapRemotePath(basedir, file, line or 0, activate.CHECKONLY)
            or file or startfile)

          if debugger:stoppedAtBreakpoint(file, line or 0) then
            debugger:ActivateDocument(file, line or 0)
            runstart = false
          end
        elseif file and line then
          local activated = debugger:ActivateDocument(file, line, activate.NOREPORT)

          -- if not found, check using full file path and reset basedir
          if not activated and not wx.wxIsAbsolutePath(file) then
            activated = debugger:ActivateDocument(startpath..file, line, activate.NOREPORT)
            if activated then
              debugger.basedir = startpath
              debugger:handle("basedir " .. debugger.basedir)
              -- reset breakpoints again as basedir has changed
              debugger:reSetBreakpoints()
            end
          end

          -- if not found and the files doesn't exist, it may be
          -- a remote call; try to map it to the project folder.
          -- also check for absolute path as it may need to be remapped
          -- when autoactivation is disabled.
          if not activated and (not wx.wxFileName(file):FileExists()
                                or wx.wxIsAbsolutePath(file)) then
            if debugger:mapRemotePath(basedir, file, line, activate.NOREPORT) then
              activated = true
            end
          end

          if not activated then
            displayError(TR("Debugging suspended at '%s:%s' (couldn't activate the file).")
              :format(file, line))
          end

          -- debugger may still be available for scratchpad,
          -- if the interpreter signals scratchpad support, so enable it.
          debugger.scratchable = ide.interpreter.scratchextloop ~= nil
        else
          debugger.scratchable = true
          local activated = debugger:ActivateDocument(startfile, 0) -- find the appropriate line
          if not activated then
            displayError(TR("Debugging suspended at '%s:%s' (couldn't activate the file).")
              :format(startfile, '?'))
          end
        end
      end

      if (not options.noshell and not debugger.scratchpad) then
        ide:GetConsole():SetRemote(debugger:GetConsole())
      end

      debugger:toggleViews(true)
      debugger:updateStackSync()
      debugger:updateWatchesSync()

      ide:Print(TR("Debugging session started in '%s'."):format(debugger.basedir))

      if debugger.scratchpad then
        debugger.scratchpad.updated = true
      elseif runstart then
        ClearAllCurrentLineMarkers()
        debugger:Run()
      end

      -- request attention if the debugging is stopped
      if not debugger.running then ide:RequestAttention() end
      -- refresh toolbar and menus in case the main app is not active
      ide:GetMainFrame():UpdateWindowUI(wx.wxUPDATE_UI_FROMIDLE)
      ide:GetToolBar():UpdateWindowUI(wx.wxUPDATE_UI_FROMIDLE)

      PackageEventHandle("onDebuggerLoad", debugger, options)
    end)
  debugger.listening = server
end

local function nameOutputTab(name)
  local nbk = ide.frame.bottomnotebook
  local index = nbk:GetPageIndex(ide:GetOutput())
  if index ~= wx.wxNOT_FOUND then nbk:SetPageText(index, name) end
end

local ok, winapi = pcall(require, 'winapi')
if not ok then winapi = nil end

function debugger:handle(command, server, options)
  local debugger = self
  local verbose = ide.config.debugger.verbose
  options = options or {}
  options.verbose = verbose and (function(...) ide:Print(...) end) or false

  local ip, port = debugger.socket:getpeername()
  PackageEventHandle("onDebuggerCommand", debugger, command, server or debugger.server, options)
  debugger.running = true
  debugger:UpdateStatus("running")
  if verbose then ide:Print(("[%s:%s] Debugger sent (command):"):format(ip, port), command) end
  local file, line, err = mobdebug.handle(command, server or debugger.server, options)
  if verbose then ide:Print(("[%s:%s] Debugger received (file, line, err):"):format(ip, port), file, line, err) end
  debugger.running = false
  -- only set suspended if the debugging hasn't been terminated
  debugger:UpdateStatus(debugger.server and "suspended" or "stopped")

  -- some filenames may be represented in a different code page; check and re-encode as UTF8
  local codepage = ide:GetCodePage()
  if codepage and type(file) == "string" and FixUTF8(file) == nil and winapi then
    file = winapi.encode(codepage, winapi.CP_UTF8, file)
  end

  return file, line, err
end

function debugger:exec(command, func)
  local debugger = self
  if debugger.server and not debugger.running then
    copas.addthread(function()
        local debugger = debugger
        -- execute a custom function (if any) in the context of this thread
        if type(func) == 'function' then func() end
        local out
        local attempts = 0
        while true do
          -- clear markers before running the command
          -- don't clear if running trace as the marker is then invisible,
          -- and it needs to be visible during tracing
          if not debugger.loop then ClearAllCurrentLineMarkers() end
          debugger.breaking = false
          local file, line, err = debugger:handle(out or command)
          if out then out = nil end
          if line == nil then
            if err then displayError(err) end
            debugger:teardown()
            return
          elseif not debugger.server then
            -- it is possible that while debugger.handle call was executing
            -- the debugging was terminated; simply return in this case.
            return
          else
            local activated = debugger:ActivateDocument(file, line)
            -- activation has been canceled; nothing else needs to be done
            if activated == nil then return end
            if activated then
              -- move cursor to the activated line if it's a breakpoint
              if ide.config.debugger.linetobreakpoint
              and command ~= "step" and debugger:stoppedAtBreakpoint(file, line)
              and not debugger.breaking and ide:IsValidCtrl(activated) then
                activated:GotoLine(line-1)
              end
              debugger.stats.line = debugger.stats.line + 1
              if debugger.loop then
                debugger:updateStackSync()
                debugger:updateWatchesSync()
              else
                debugger:updateStackAndWatches()
                return
              end
            else
              -- clear the marker as it wasn't cleared earlier
              if debugger.loop then ClearAllCurrentLineMarkers() end
              -- we may be in some unknown location at this point;
              -- If this happens, stop and report allowing users to set
              -- breakpoints and step through.
              if debugger.breaking then
                displayError(TR("Debugging suspended at '%s:%s' (couldn't activate the file).")
                  :format(file, line))
                debugger:updateStackAndWatches()
                return
              end
              -- redo now; if the call is from the debugger, then repeat
              -- the same command, except when it was "run" (switch to 'step');
              -- this is needed to "break" execution that happens in on() call.
              -- in all other cases get out of this file.
              -- don't get out of "mobdebug", because it may happen with
              -- start() or on() call, which will get us out of the current
              -- file, which is not what we want.
              -- Some engines (Corona SDK) report =?:0 as the current location.
              -- repeat the same command, but check if this has been tried
              -- too many times already; if so, get "out"
              out = ((tonumber(line) == 0 and attempts < 10) and command
                or (file:find('mobdebug%.lua$')
                  and (command == 'run' and 'step' or command) or "out"))
              attempts = attempts + 1
            end
          end
        end
      end)
  end
end

function debugger:handleAsync(command)
  local debugger = self
  if debugger.server and not debugger.running then
    copas.addthread(function()
        local debugger = debugger
        debugger:handle(command)
      end)
  end
end
function debugger:handleDirect(command)
  local debugger = self
  local sock = debugger.socket
  if debugger.server and sock then
    local running = debugger.running
    -- this needs to be short as it will block the UI
    sock:settimeout(0.25)
    debugger:handle(command, sock)
    sock:settimeout(0)
    -- restore running status
    debugger.running = running
  end
end

function debugger:loadfile(file)
  local debugger = self
  local f, l, err = debugger:handle("load " .. file)
  if not f and wx.wxFileExists(file) and err and err:find("Cannot open file") then
    local content = FileRead(file)
    if content then return debugger:loadstring(file, content) end
  end
  return f, l, err
end
function debugger:loadstring(file, string)
  local debugger = self
  return debugger:handle("loadstring '" .. file .. "' " .. string)
end

do
  local nextupdatedelta = 0.250
  local nextupdate = ide:GetTime() + nextupdatedelta
  local function forceUpdateOnWrap(editor)
    -- http://www.scintilla.org/ScintillaDoc.html#LineWrapping
    -- Scintilla doesn't perform wrapping immediately after a content change
    -- for performance reasons, so the activation calculations can be wrong
    -- if there is wrapping that pushes the current line out of the screen.
    -- force editor update that performs wrapping recalculation.
    if ide.config.editor.usewrap then editor:Update(); editor:Refresh() end
  end
  function debugger:Update()
    local debugger = self
    local smth = false
    if debugger.server or debugger.listening and ide:GetTime() > nextupdate then
      smth = copas.step(0)
      nextupdate = ide:GetTime() + nextupdatedelta
    end

    -- if there is any pending activation
    if debugger.activate then
      local file, line, content = unpack(debugger.activate)
      debugger.activate = nil
      if content then
        local editor = NewFile()
        editor:SetTextDyn(content)
        if not ide.config.debugger.allowediting
        and not (debugger.options or {}).allowediting then
          editor:SetReadOnly(true)
        end
        forceUpdateOnWrap(editor)
        debugger:ActivateDocument(file, line)
      else
        local editor = LoadFile(file)
        if editor then
          forceUpdateOnWrap(editor)
          debugger:ActivateDocument(file, line)
        end
      end
    end
    return smth
  end
end

function debugger:terminate()
  local debugger = self
  if debugger.server then
    if killProcess(ide:GetLaunchedProcess()) then -- if there is PID, try local kill
      ide:SetLaunchedProcess(nil)
    else -- otherwise, try graceful exit for the remote process
      debugger:detach("exit")
    end
    debugger:teardown()
  end
end
function debugger:Step() return self:exec("step") end
function debugger:trace()
  local debugger = self
  debugger.loop = true
  debugger:exec("step")
end
function debugger:RunTo(editor, line)
  local debugger = self

  -- check if the location is valid for a breakpoint
  if editor:IsLineEmpty(line-1) then return end

  local ed, ln = unpack(debugger.runtocursor or {})
  local same = ed and ln and ed:GetId() == editor:GetId() and ln == line

  -- check if there is already a breakpoint in the "run to" location;
  -- if so, don't mark the location as "run to" as it will stop there anyway
  if bit.band(editor:MarkerGet(line-1), BREAKPOINT_MARKER_VALUE) > 0
  and not same then
    debugger.runtocursor = nil
    debugger:Run()
    return
  end

  -- save the location of the breakpoint
  debugger.runtocursor = {editor, line}
  -- set breakpoint and execute run
  debugger:exec("run", function()
      -- if run-to-cursor location is already set, then remove the breakpoint,
      -- but only if this location is different
      if ed and ln and not same then
        debugger:breakpointToggle(ed, ln, false) -- remove earlier run-to breakpoint
        debugger:Wait()
      end
      if not same then
        debugger:breakpointToggle(editor, line, true) -- set new run-to breakpoint
        debugger:Wait()
      end
    end)
end
function debugger:Wait()
  local debugger = self
  -- wait for all results to come back
  while debugger.running do debugger:Update() end
end
function debugger:Over() return self:exec("over") end
function debugger:Out() return self:exec("out") end
function debugger:Run() return self:exec("run") end
function debugger:detach(cmd)
  local debugger = self
  if not debugger.server then return end
  if debugger.running then
    debugger:handleDirect(cmd or "done")
    debugger:teardown()
  else
    debugger:exec(cmd or "done")
  end
end
local function todeb(params) return params and " -- "..mobdebug.line(params, {comment = false}) or "" end
function debugger:evaluate(exp, params) return self:handle('eval ' .. exp .. todeb(params)) end
function debugger:execute(exp, params) return self:handle('exec '.. exp .. todeb(params)) end
function debugger:stack(params) return self:handle('stack' .. todeb(params)) end
function debugger:Break(command)
  local debugger = self
  -- stop if we're running a "trace" command
  debugger.loop = false

  -- force suspend command; don't use copas interface as it checks
  -- for the other side "reading" and the other side is not reading anything.
  -- use the "original" socket to send "suspend" command.
  -- this will only break on the next Lua command.
  if debugger.socket then
    local running = debugger.running
    -- this needs to be short as it will block the UI
    debugger.socket:settimeout(0.25)
    local file, line, err = debugger:handle(command or "suspend", debugger.socket)
    debugger.socket:settimeout(0)
    -- restore running status
    debugger.running = running
    debugger.breaking = true
    -- don't need to do anything else as the earlier call (run, step, etc.)
    -- will get the results (file, line) back and will update the UI
    return file, line, err
  end
end
function debugger:breakpoint(file, line, state)
  local debugger = self
  if debugger.running then
    return debugger:handleDirect((state and "asetb " or "adelb ") .. bp_file_name(file) .. " " .. line)
  end
  return debugger:handleAsync((state and "setb " or "delb ") .. bp_file_name(file) .. " " .. line)
end
function debugger:EvalAsync(var, callback, params)
  local debugger = self
  if debugger.server and not debugger.running and callback
  and not debugger.scratchpad and not (debugger.options or {}).noeval then
    copas.addthread(function()
      local debugger = debugger
      local _, values, err = debugger:evaluate(var, params)
      if err then
        callback(nil, (err:gsub("%[.-%]:%d+:%s*","error: ")))
      else
        callback(#values > 0 and values[1] or 'nil')
      end
    end)
  end
end

local width, height = 360, 200

local keyword = {}
for _,k in ipairs({'and', 'break', 'do', 'else', 'elseif', 'end', 'false',
  'for', 'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
  'return', 'then', 'true', 'until', 'while'}) do keyword[k] = true end

local function stringifyKeyIntoPrefix(name, num)
  return (type(name) == "number"
    and (num and num == name and '' or ("[%s] = "):format(name))
    or type(name) == "string" and (name:match("^[%l%u_][%w_]*$") and not keyword[name]
      and ("%s = "):format(name)
      or ("[%q] = "):format(name))
    or ("[%s] = "):format(tostring(name)))
end

local function debuggerCreateStackWindow()
  local stackCtrl = ide:CreateTreeCtrl(ide.frame, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxSize(width, height),
    wx.wxTR_LINES_AT_ROOT + wx.wxTR_HAS_BUTTONS + wx.wxTR_SINGLE
    + wx.wxTR_HIDE_ROOT + wx.wxNO_BORDER)

  local debugger = ide:GetDebugger()
  debugger.stackCtrl = stackCtrl

  stackCtrl:SetImageList(debugger.imglist)

  local names = {}
  function stackCtrl:SetItemName(item, name)
    local nametype = type(name)
    names[item:GetValue()] = (
      (nametype == 'string' or nametype == 'number' or nametype == 'boolean')
      and name or nil
    )
  end

  function stackCtrl:GetItemName(item)
    return names[item:GetValue()]
  end

  local expandable = {} -- special value
  local valuecache = {}
  function stackCtrl:SetItemValueIfExpandable(item, value, delayed)
    local maxlvl = tonumber(ide.config.debugger.maxdatalevel)
    -- don't make empty tables expandable if expansion is disabled (`maxdatalevel` is false)
    local isexpandable = type(value) == 'table' and (next(value) ~= nil or delayed and maxlvl ~= nil)
    if isexpandable then -- cache table value to expand when requested
      valuecache[item:GetValue()] = next(value) == nil and expandable or value
    elseif type(value) ~= 'table' then
      valuecache[item:GetValue()] = nil
    end
    self:SetItemHasChildren(item, isexpandable)
  end

  function stackCtrl:IsExpandable(item) return valuecache[item:GetValue()] == expandable end

  function stackCtrl:DeleteAll()
    self:DeleteAllItems()
    valuecache = {}
    names = {}
  end

  function stackCtrl:GetItemChildren(item)
    return valuecache[item:GetValue()] or {}
  end

  function stackCtrl:IsFrame(item)
    return (item and item:IsOk() and self:GetItemParent(item):IsOk()
      and self:GetItemParent(item):GetValue() == self:GetRootItem():GetValue())
  end

  function stackCtrl:GetItemFullExpression(item)
    local expr = ''
    while item:IsOk() and not self:IsFrame(item) do
      local name = self:GetItemName(item)
      -- check if it's a top item, as it needs to be used as is;
      -- convert `(*vararg num)` to `select(num, ...)`
      expr = (self:IsFrame(self:GetItemParent(item))
        and name:gsub("^%(%*vararg (%d+)%)$", "select(%1, ...)")
        or (type(name) == 'string' and '[%q]' or '[%s]'):format(tostring(name)))
      ..expr
      item = self:GetItemParent(item)
    end
    return expr, item:IsOk() and item or nil
  end

  function stackCtrl:GetItemPos(item)
    if not item:IsOk() then return end
    local pos = 0
    repeat
      pos = pos + 1
      item = self:GetPrevSibling(item)
    until not item:IsOk()
    return pos
  end

  function stackCtrl:ExpandItemValue(item)
    local expr, itemframe = self:GetItemFullExpression(item)
    local stack = self:GetItemPos(itemframe)

    local debugger = ide:GetDebugger()
    if debugger.running then debugger:Update() end
    if debugger.server and not debugger.running
    and (not debugger.scratchpad or debugger.scratchpad.paused) then
      copas.addthread(function()
        local debugger = debugger
        local value, _, err = debugger:evaluate(expr, {maxlevel = 1, stack = stack})
        if err then
          err = err:gsub("%[.-%]:%d+:%s+","")
          -- this may happen when attempting to expand a sub-element referenced by a key
          -- that can't be evaluated, like a table, function, or userdata
          if err ~= "attempt to index a nil value" then
            self:SetItemText(item, 'error: '..err)
          else
            local name = self:GetItemName(item)
            local text = stringifyKeyIntoPrefix(name, self:GetItemPos(item)).."{}"
            self:SetItemText(item, text)
            self:SetItemValueIfExpandable(item, {})
            self:Expand(item)
          end
        else
          local ok, res = LoadSafe("return "..tostring(value))
          if ok then
            self:SetItemValueIfExpandable(item, res)
            self:Expand(item)

            local name = self:GetItemName(item)
            if not name then
              -- this is an empty table, so replace MORE indicator with the empty table
              self:SetItemText(item, (self:GetItemText(item):gsub(q(MORE), "{}")))
              return
            end

            -- update cache in the parent
            local parent = self:GetItemParent(item)
            valuecache[parent:GetValue()][name] = res

            local params = debugger:GetDataOptions({maxlevel=false})

            -- now update all serialized values in the tree starting from the expanded item
            while item:IsOk() and not self:IsFrame(item) do
              local value = valuecache[item:GetValue()]
              local strval = fixUTF8(serialize(value, params))
              local name = self:GetItemName(item)
              local text = (self:IsFrame(self:GetItemParent(item))
                and name.." = "
                or stringifyKeyIntoPrefix(name, self:GetItemPos(item)))
              ..strval
              self:SetItemText(item, text)
              item = self:GetItemParent(item)
            end
          end
        end
      end)
    end
  end

  stackCtrl:Connect(wx.wxEVT_COMMAND_TREE_ITEM_EXPANDING,
    function (event)
      local item_id = event:GetItem()
      local count = stackCtrl:GetChildrenCount(item_id, false)
      if count > 0 then return true end

      if stackCtrl:IsExpandable(item_id) then return stackCtrl:ExpandItemValue(item_id) end

      local image = stackCtrl:GetItemImage(item_id)
      local num, maxnum = 1, ide.config.debugger.maxdatanum
      local params = debugger:GetDataOptions({maxlevel = false})

      stackCtrl:Freeze()
      for name,value in pairs(stackCtrl:GetItemChildren(item_id)) do
        local item = stackCtrl:AppendItem(item_id, "", image)
        stackCtrl:SetItemValueIfExpandable(item, value, true)

        local strval = stackCtrl:IsExpandable(item) and MORE or fixUTF8(serialize(value, params))
        stackCtrl:SetItemText(item, stringifyKeyIntoPrefix(name, num)..strval)
        stackCtrl:SetItemName(item, name)

        num = num + 1
        if num > maxnum then break end
      end
      stackCtrl:Thaw()
      return true
    end)

  stackCtrl:Connect(wx.wxEVT_SET_FOCUS, function(event)
      local debugger = ide:GetDebugger()
      if debugger.needrefresh.stack then
        debugger:updateStack()
        debugger.needrefresh.stack = false
      end
    end)

  -- register navigation callback
  stackCtrl:Connect(wx.wxEVT_LEFT_DCLICK, function (event)
    local item_id = stackCtrl:HitTest(event:GetPosition())
    if not item_id or not item_id:IsOk() then event:Skip() return end

    local coords = callData[item_id:GetValue()]
    if not coords then event:Skip() return end

    local file, line = coords[1], coords[2]
    if file:match("@") then file = string.sub(file, 2) end
    file = GetFullPathIfExists(ide:GetDebugger().basedir, file)
    if file then
      local editor = LoadFile(file,nil,true)
      editor:SetFocus()
      if line then
        editor:GotoLine(line-1)
        editor:EnsureVisibleEnforcePolicy(line-1) -- make sure the line is visible (unfolded)
      end
    end
  end)

  local layout = ide:GetSetting("/view", "uimgrlayout")
  if layout and not layout:find("stackpanel") then
    ide:AddPanelDocked(ide.frame.bottomnotebook, stackCtrl, "stackpanel", TR("Stack"))
  else
    ide:AddPanel(stackCtrl, "stackpanel", TR("Stack"))
  end
end

local function debuggerCreateWatchWindow()
  local watchCtrl = ide:CreateTreeCtrl(ide.frame, wx.wxID_ANY,
    wx.wxDefaultPosition, wx.wxSize(width, height),
    wx.wxTR_LINES_AT_ROOT + wx.wxTR_HAS_BUTTONS + wx.wxTR_SINGLE
    + wx.wxTR_HIDE_ROOT + wx.wxTR_EDIT_LABELS + wx.wxNO_BORDER)

  local debugger = ide:GetDebugger()
  debugger.watchCtrl = watchCtrl

  local root = watchCtrl:AddRoot("Watch")
  watchCtrl:SetImageList(debugger.imglist)

  local defaultExpr = "watch expression"
  local expressions = {} -- table to keep track of expressions

  function watchCtrl:SetItemExpression(item, expr, value)
    expressions[item:GetValue()] = expr
    self:SetItemText(item, expr .. ' = ' .. (value or '?'))
    self:SelectItem(item, true)
    local debugger = ide:GetDebugger()
    if not value then debugger:updateWatches(item) end
  end

  function watchCtrl:GetItemExpression(item)
    return expressions[item:GetValue()]
  end

  local names = {}
  function watchCtrl:SetItemName(item, name)
    local nametype = type(name)
    names[item:GetValue()] = (
      (nametype == 'string' or nametype == 'number' or nametype == 'boolean')
      and name or nil
    )
  end

  function watchCtrl:GetItemName(item)
    return names[item:GetValue()]
  end

  local expandable = {} -- special value
  local valuecache = {}
  function watchCtrl:SetItemValueIfExpandable(item, value, delayed)
    local maxlvl = tonumber(ide.config.debugger.maxdatalevel)
    -- don't make empty tables expandable if expansion is disabled (`maxdatalevel` is false)
    local isexpandable = type(value) == 'table' and (next(value) ~= nil or delayed and maxlvl ~= nil)
    if isexpandable then -- cache table value to expand when requested
      valuecache[item:GetValue()] = next(value) == nil and expandable or value
    elseif type(value) ~= 'table' then
      valuecache[item:GetValue()] = nil
    end
    self:SetItemHasChildren(item, isexpandable)
  end

  function watchCtrl:IsExpandable(item) return valuecache[item:GetValue()] == expandable end

  function watchCtrl:GetItemChildren(item)
    return valuecache[item:GetValue()] or {}
  end

  function watchCtrl:IsWatch(item)
    return (item and item:IsOk() and self:GetItemParent(item):IsOk()
      and self:GetItemParent(item):GetValue() == root:GetValue())
  end

  function watchCtrl:IsEditable(item)
    return (item and item:IsOk()
      and (self:IsWatch(item) or self:GetItemName(item) ~= nil))
  end

  function watchCtrl:GetItemFullExpression(item)
    local expr = ''
    while true do
      local name = self:GetItemName(item)
      expr = (self:IsWatch(item)
        and ('({%s})[1]'):format(self:GetItemExpression(item))
        or (type(name) == 'string' and '[%q]' or '[%s]'):format(tostring(name))
      )..expr
      if self:IsWatch(item) then break end
      item = self:GetItemParent(item)
      if not item:IsOk() then break end
    end
    return expr, item:IsOk() and item or nil
  end

  function watchCtrl:CopyItemValue(item)
    local expr = self:GetItemFullExpression(item)

    local debugger = ide:GetDebugger()
    if debugger.running then debugger:Update() end
    if debugger.server and not debugger.running
    and (not debugger.scratchpad or debugger.scratchpad.paused) then
      copas.addthread(function()
        local debugger = debugger
        local _, values, error = debugger:evaluate(expr)
        ide:CopyToClipboard(error and error:gsub("%[.-%]:%d+:%s+","")
          or (#values == 0 and 'nil' or fixUTF8(values[1])))
      end)
    end
  end

  function watchCtrl:UpdateItemValue(item, value)
    local expr, itemupd = self:GetItemFullExpression(item)

    local debugger = ide:GetDebugger()
    if debugger.running then debugger:Update() end
    if debugger.server and not debugger.running
    and (not debugger.scratchpad or debugger.scratchpad.paused) then
      copas.addthread(function()
        local debugger = debugger
        local _, _, err = debugger:execute(expr..'='..value)
        if err then
          watchCtrl:SetItemText(item, 'error: '..err:gsub("%[.-%]:%d+:%s+",""))
        elseif itemupd then
          debugger:updateWatchesSync(itemupd)
        end
        debugger:updateStackSync()
      end)
    end
  end

  function watchCtrl:GetItemPos(item)
    if not item:IsOk() then return end
    local pos = 0
    repeat
      pos = pos + 1
      item = self:GetPrevSibling(item)
    until not item:IsOk()
    return pos
  end

  function watchCtrl:ExpandItemValue(item)
    local expr = self:GetItemFullExpression(item)

    local debugger = ide:GetDebugger()
    if debugger.running then debugger:Update() end
    if debugger.server and not debugger.running
    and (not debugger.scratchpad or debugger.scratchpad.paused) then
      copas.addthread(function()
        local debugger = debugger
        local value, _, err = debugger:evaluate(expr, {maxlevel = 1})
        if err then
          self:SetItemText(item, 'error: '..err:gsub("%[.-%]:%d+:%s+",""))
        else
          local ok, res = LoadSafe("return "..tostring(value))
          if ok then
            self:SetItemValueIfExpandable(item, res)
            self:Expand(item)
            local name = self:GetItemName(item)
            if not name then
              self:SetItemText(item, (self:GetItemText(item):gsub(q(MORE), "{}")))
              return
            end

            -- update cache in the parent
            local parent = self:GetItemParent(item)
            valuecache[parent:GetValue()][name] = res

            local params = debugger:GetDataOptions({maxlevel=false})

            -- now update all serialized values in the tree starting from the expanded item
            while item:IsOk() do
              local value = valuecache[item:GetValue()]
              local strval = fixUTF8(serialize(value, params))
              local name = self:GetItemName(item)
              local text = (self:IsWatch(item)
                and self:GetItemExpression(item).." = "
                or stringifyKeyIntoPrefix(name, self:GetItemPos(item)))
              ..strval
              self:SetItemText(item, text)
              if self:IsWatch(item) then break end
              item = self:GetItemParent(item)
            end
          end
        end
      end)
    end
  end

  watchCtrl:Connect(wx.wxEVT_COMMAND_TREE_ITEM_EXPANDING,
    function (event)
      local item_id = event:GetItem()
      local count = watchCtrl:GetChildrenCount(item_id, false)
      if count > 0 then return true end

      if watchCtrl:IsExpandable(item_id) then return watchCtrl:ExpandItemValue(item_id) end

      local image = watchCtrl:GetItemImage(item_id)
      local num, maxnum = 1, ide.config.debugger.maxdatanum
      local params = debugger:GetDataOptions({maxlevel = false})

      watchCtrl:Freeze()
      for name,value in pairs(watchCtrl:GetItemChildren(item_id)) do
        local item = watchCtrl:AppendItem(item_id, "", image)
        watchCtrl:SetItemValueIfExpandable(item, value, true)

        local strval = watchCtrl:IsExpandable(item) and MORE or fixUTF8(serialize(value, params))
        watchCtrl:SetItemText(item, stringifyKeyIntoPrefix(name, num)..strval)
        watchCtrl:SetItemName(item, name)

        num = num + 1
        if num > maxnum then break end
      end
      watchCtrl:Thaw()
      return true
    end)

  watchCtrl:Connect(wx.wxEVT_COMMAND_TREE_DELETE_ITEM,
    function (event)
      local value = event:GetItem():GetValue()
      expressions[value] = nil
      valuecache[value] = nil
      names[value] = nil
    end)

  watchCtrl:Connect(wx.wxEVT_SET_FOCUS, function(event)
      local debugger = ide:GetDebugger()
      if debugger.needrefresh.watches then
        debugger:updateWatches()
        debugger.needrefresh.watches = false
      end
    end)

  local item
  -- wx.wxEVT_CONTEXT_MENU is only triggered over tree items on OSX,
  -- but it needs to be also triggered below any item to add a watch,
  -- so use RIGHT_DOWN instead
  watchCtrl:Connect(wx.wxEVT_RIGHT_DOWN,
    function (event)
      -- store the item to be used in edit/delete actions
      item = watchCtrl:HitTest(watchCtrl:ScreenToClient(wx.wxGetMousePosition()))
      local editlabel = watchCtrl:IsWatch(item) and TR("&Edit Watch") or TR("&Edit Value")
      local menu = ide:MakeMenu {
        { ID.ADDWATCH, TR("&Add Watch")..KSC(ID.ADDWATCH) },
        { ID.EDITWATCH, editlabel..KSC(ID.EDITWATCH) },
        { ID.DELETEWATCH, TR("&Delete Watch")..KSC(ID.DELETEWATCH) },
        { ID.COPYWATCHVALUE, TR("&Copy Value")..KSC(ID.COPYWATCHVALUE) },
      }
      PackageEventHandle("onMenuWatch", menu, watchCtrl, event)
      watchCtrl:PopupMenu(menu)
      item = nil
    end)

  watchCtrl:Connect(ID.ADDWATCH, wx.wxEVT_COMMAND_MENU_SELECTED, function (event)
      watchCtrl:SetFocus()
      watchCtrl:EditLabel(watchCtrl:AppendItem(root, defaultExpr, image.LOCAL))
    end)

  watchCtrl:Connect(ID.EDITWATCH, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event) watchCtrl:EditLabel(item or watchCtrl:GetSelection()) end)
  watchCtrl:Connect(ID.EDITWATCH, wx.wxEVT_UPDATE_UI,
    function (event) event:Enable(watchCtrl:IsEditable(item or watchCtrl:GetSelection())) end)

  watchCtrl:Connect(ID.DELETEWATCH, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event) watchCtrl:Delete(item or watchCtrl:GetSelection()) end)
  watchCtrl:Connect(ID.DELETEWATCH, wx.wxEVT_UPDATE_UI,
    function (event) event:Enable(watchCtrl:IsWatch(item or watchCtrl:GetSelection())) end)

  watchCtrl:Connect(ID.COPYWATCHVALUE, wx.wxEVT_COMMAND_MENU_SELECTED,
    function (event) watchCtrl:CopyItemValue(item or watchCtrl:GetSelection()) end)
  watchCtrl:Connect(ID.COPYWATCHVALUE, wx.wxEVT_UPDATE_UI, function (event)
      -- allow copying only when the debugger is available
      local debugger = ide:GetDebugger()
      event:Enable(item:IsOk() and debugger.server and not debugger.running
        and (not debugger.scratchpad or debugger.scratchpad.paused))
    end)

  local label
  watchCtrl:Connect(wx.wxEVT_COMMAND_TREE_BEGIN_LABEL_EDIT,
    function (event)
      local item = event:GetItem()
      if not (item:IsOk() and watchCtrl:IsEditable(item)) then
        event:Veto()
        return
      end

      label = watchCtrl:GetItemText(item)

      if watchCtrl:IsWatch(item) then
        local expr = watchCtrl:GetItemExpression(item)
        if expr then watchCtrl:SetItemText(item, expr) end
      else
        local prefix = stringifyKeyIntoPrefix(watchCtrl:GetItemName(item))
        local val = watchCtrl:GetItemText(item):gsub(q(prefix),'')
        watchCtrl:SetItemText(item, val)
      end
    end)
  watchCtrl:Connect(wx.wxEVT_COMMAND_TREE_END_LABEL_EDIT,
    function (event)
      event:Veto()

      local item = event:GetItem()
      if event:IsEditCancelled() then
        if watchCtrl:GetItemText(item) == defaultExpr then
          -- when Delete is called from END_EDIT, it causes infinite loop
          -- on OSX (wxwidgets 2.9.5) as Delete calls END_EDIT again.
          -- disable handlers during Delete and then enable back.
          watchCtrl:SetEvtHandlerEnabled(false)
          watchCtrl:Delete(item)
          watchCtrl:SetEvtHandlerEnabled(true)
        else
          watchCtrl:SetItemText(item, label)
        end
      else
        if watchCtrl:IsWatch(item) then
          watchCtrl:SetItemExpression(item, event:GetLabel())
        else
          watchCtrl:UpdateItemValue(item, event:GetLabel())
        end
      end
      event:Skip()
    end)

  local layout = ide:GetSetting("/view", "uimgrlayout")
  if layout and not layout:find("watchpanel") then
    ide:AddPanelDocked(ide.frame.bottomnotebook, watchCtrl, "watchpanel", TR("Watch"))
  else
    ide:AddPanel(watchCtrl, "watchpanel", TR("Watch"))
  end
end

debuggerCreateStackWindow()
debuggerCreateWatchWindow()

----------------------------------------------
-- public api

function debugger:RefreshPanels() return self:updateStackAndWatches() end

function debugger:BreakpointSet(...) return self:breakpoint(...) end

local statuses = {
  running = TR("Output (running)"),
  suspended = TR("Output (suspended)"),
  stopped = TR("Output"),
}
function debugger:UpdateStatus(status)
  local debugger = self
  if not status then
    status = debugger.running and "running" or debugger.server and "suspended" or "stopped"
  end
  if PackageEventHandle("onDebuggerStatusUpdate", debugger, status) == false then return end
  nameOutputTab(statuses[status] or statuses.stopped)
end

function debugger:OutputSet(stream, mode, options)
  return self:handle(("output %s %s"):format(stream, mode), nil, options)
end

function DebuggerAttachDefault(options) ide:GetDebugger():SetOptions(options) end
function debugger:SetOptions(options) self.options = options end

function debugger:Stop()
  local debugger = self
  -- terminate the local session (if still active)
  if killProcess(ide:GetLaunchedProcess()) then ide:SetLaunchedProcess(nil) end
  debugger:terminate()
end

function debugger:Shutdown()
  self:Stop()
  PackageEventHandle("onDebuggerShutdown", self)
end

function debugger:teardown()
  local debugger = self
  if debugger.server then
    local lines = TR("traced %d instruction", debugger.stats.line):format(debugger.stats.line)
    ide:Print(TR("Debugging session completed (%s)."):format(lines))
    debugger:UpdateStatus(ide:GetLaunchedProcess() and "running" or "stopped")
    if debugger.runtocursor then
      local ed, ln = unpack(debugger.runtocursor)
      debugger:breakpointToggle(ed, ln, false) -- remove current run-to breakpoint
    end
    if PackageEventHandle("onDebuggerPreClose", debugger) ~= false then
      SetAllEditorsReadOnly(false)
      ide:GetConsole():SetRemote(nil)
      ClearAllCurrentLineMarkers()
      debugger:toggleViews(false)
      PackageEventHandle("onDebuggerClose", debugger)
    end
    debugger.server = nil
    debugger:ScratchpadOff()
  else
    -- it's possible that the application couldn't start, or that the
    -- debugger in the application didn't start, which means there is
    -- no debugger.server, but scratchpad may still be on. Turn it off.
    debugger:ScratchpadOff()
  end
end

local function debuggerMakeFileName(editor)
  return ide:GetDocument(editor):GetFilePath()
  or ide:GetDocument(editor):GetFileName()
  or ide:GetDefaultFileName()
end

function debugger:breakpointToggle(editor, line, value)
  local debugger = self
  local file = debugger.editormap and debugger.editormap[editor] or debuggerMakeFileName(editor)
  debugger:BreakpointSet(file, line, value)
end

-- scratchpad functions

function debugger:ScratchpadRefresh()
  local debugger = self
  if debugger.scratchpad and debugger.scratchpad.updated and not debugger.scratchpad.paused then
    local scratchpadEditor = debugger.scratchpad.editor
    if scratchpadEditor.spec.apitype
    and scratchpadEditor.spec.apitype == "lua"
    and not ide.interpreter.skipcompile
    and not CompileProgram(scratchpadEditor, { jumponerror = false, reportstats = false })
    then
      debugger.scratchpad.updated = false
      return
    end

    local code = StripShebang(scratchpadEditor:GetTextDyn())
    if debugger.scratchpad.running then
      -- break the current execution first
      -- don't try too frequently to avoid overwhelming the debugger
      local now = ide:GetTime()
      if now - debugger.scratchpad.running > 0.250 then
        debugger:Break()
        debugger.scratchpad.running = now
      end
    else
      local filePath = debuggerMakeFileName(scratchpadEditor)

      -- wrap into a function call to make "return" to work with scratchpad
      code = "(function(...)"..code.."\nend)(...)"

      -- this is a special error message that is generated at the very end
      -- of each script to avoid exiting the (debugee) scratchpad process.
      -- these errors are handled and not reported to the user
      local errormsg = 'execution suspended at ' .. ide:GetTime()
      local stopper = "error('" .. errormsg .. "')"
      -- store if interpreter requires a special handling for external loop
      local extloop = ide.interpreter.scratchextloop

      local function reloadScratchpadCode()
        local debugger = debugger
        debugger.scratchpad.running = ide:GetTime()
        debugger.scratchpad.updated = false
        debugger.scratchpad.runs = (debugger.scratchpad.runs or 0) + 1

        ide:GetOutput():Erase()

        -- the code can be running in two ways under scratchpad:
        -- 1. controlled by the application, requires stopper (most apps)
        -- 2. controlled by some external loop (for example, love2d).
        -- in the first case we need to reload the app after each change
        -- in the second case, we need to load the app once and then
        -- "execute" new code to reflect the changes (with some limitations).
        local _, _, err
        if extloop then -- if the execution is controlled by an external loop
          if debugger.scratchpad.runs == 1
          then _, _, err = debugger:loadstring(filePath, code)
          else _, _, err = debugger:execute(code) end
        else   _, _, err = debugger:loadstring(filePath, code .. stopper) end

        -- when execute() is used, it's not possible to distinguish between
        -- compilation and run-time error, so just report as "Scratchpad error"
        local prefix = extloop and TR("Scratchpad error") or TR("Compilation error")

        if not err then
          _, _, err = debugger:handle("run")
          prefix = TR("Execution error")
        end
        if err and not err:find(errormsg) then
          local fragment, line = err:match('.-%[string "([^\010\013]+)"%]:(%d+)%s*:')
          -- make the code shorter to better see the error message
          if prefix == TR("Scratchpad error") and fragment and #fragment > 30 then
            err = err:gsub(q(fragment), function(s) return s:sub(1,30)..'...' end)
          end
          displayError(prefix
            ..(line and (" "..TR("on line %d"):format(line)) or "")
            ..":\n"..err:gsub('stack traceback:.+', ''):gsub('\n+$', ''))
        end
        debugger.scratchpad.running = false
      end

      copas.addthread(reloadScratchpadCode)
    end
  end
end

function debugger:ScratchpadOn(editor)
  local debugger = self

  -- first check if there is already scratchpad editor.
  -- this may happen when more than one editor is being added...
  if debugger.scratchpad and debugger.scratchpad.editors then
    debugger.scratchpad.editors[editor] = true
  else
    debugger.scratchpad = {editor = editor, editors = {[editor] = true}}

    -- check if the debugger is already running; this happens when
    -- scratchpad is turned on after external script has connected
    if debugger.server then
      debugger.scratchpad.updated = true
      ClearAllCurrentLineMarkers()
      SetAllEditorsReadOnly(false)
      ide:GetConsole():SetRemote(nil) -- disable remote shell
      debugger:ScratchpadRefresh()
    elseif not ProjectDebug(true, "scratchpad") then
      debugger.scratchpad = nil
      return
    end
  end

  local scratchpadEditor = editor
  for _, numberStyle in ipairs(scratchpadEditor.spec.isnumber) do
    scratchpadEditor:StyleSetUnderline(numberStyle, true)
  end
  debugger.scratchpad.margin = scratchpadEditor:GetAllMarginWidth()

  scratchpadEditor:Connect(wxstc.wxEVT_STC_MODIFIED, function(event)
    local evtype = event:GetModificationType()
    if (bit.band(evtype,wxstc.wxSTC_MOD_INSERTTEXT) ~= 0 or
        bit.band(evtype,wxstc.wxSTC_MOD_DELETETEXT) ~= 0 or
        bit.band(evtype,wxstc.wxSTC_PERFORMED_UNDO) ~= 0 or
        bit.band(evtype,wxstc.wxSTC_PERFORMED_REDO) ~= 0) then
      debugger.scratchpad.updated = true
      debugger.scratchpad.editor = scratchpadEditor
    end
    event:Skip()
  end)

  scratchpadEditor:Connect(wx.wxEVT_LEFT_DOWN, function(event)
    local scratchpad = debugger.scratchpad

    local point = event:GetPosition()
    local pos = scratchpadEditor:PositionFromPoint(point)
    local isnumber = scratchpadEditor.spec.isnumber

    -- are we over a number in the scratchpad? if not, it's not our event
    if not (scratchpad and isnumber[bit.band(scratchpadEditor:GetStyleAt(pos),ide.STYLEMASK)]) then
      event:Skip()
      return
    end

    -- find start position and length of the number
    local text = scratchpadEditor:GetTextDyn()

    local nstart = pos
    while nstart >= 0 and isnumber[bit.band(scratchpadEditor:GetStyleAt(nstart),ide.STYLEMASK)] do
      nstart = nstart - 1
    end

    local nend = pos
    while nend < string.len(text) and isnumber[bit.band(scratchpadEditor:GetStyleAt(nend),ide.STYLEMASK)] do
      nend = nend + 1
    end

    -- check if there is minus sign right before the number and include it
    if nstart >= 0 and scratchpadEditor:GetTextRangeDyn(nstart,nstart+1) == '-' then 
      nstart = nstart - 1
    end
    scratchpad.start = nstart + 1
    scratchpad.length = nend - nstart - 1
    scratchpad.origin = scratchpadEditor:GetTextRangeDyn(nstart+1,nend)
    if tonumber(scratchpad.origin) then
      scratchpad.point = point
      scratchpadEditor:BeginUndoAction()
      scratchpadEditor:CaptureMouse()
    end
  end)

  scratchpadEditor:Connect(wx.wxEVT_LEFT_UP, function(event)
    if debugger.scratchpad and debugger.scratchpad.point then
      debugger.scratchpad.point = nil
      scratchpadEditor:EndUndoAction()
      scratchpadEditor:ReleaseMouse()
      wx.wxSetCursor(wx.wxNullCursor) -- restore cursor
    else event:Skip() end
  end)

  scratchpadEditor:Connect(wx.wxEVT_MOTION, function(event)
    local point = event:GetPosition()
    local pos = scratchpadEditor:PositionFromPoint(point)
    local scratchpad = debugger.scratchpad
    local ipoint = scratchpad and scratchpad.point

    -- record the fact that we are over a number or dragging slider
    scratchpad.over = scratchpad and
      (ipoint ~= nil or scratchpadEditor.spec.isnumber[bit.band(scratchpadEditor:GetStyleAt(pos),ide.STYLEMASK)])

    if ipoint then
      local startpos = scratchpad.start
      local endpos = scratchpad.start+scratchpad.length

      -- calculate difference in point position
      local dx = point.x - ipoint.x

      -- calculate the number of decimal digits after the decimal point
      local origin = scratchpad.origin
      local decdigits = #(origin:match('%.(%d+)') or '')

      -- calculate new value
      local value = tonumber(origin) + dx * 10^-decdigits

      -- convert new value back to string to check the number of decimal points
      -- this is needed because the rate of change is determined by the
      -- current value. For example, for number 1, the next value is 2,
      -- but for number 1.1, the next is 1.2 and for 1.01 it is 1.02.
      -- But if 1.01 becomes 1.00, the both zeros after the decimal point
      -- need to be preserved to keep the increment ratio the same when
      -- the user wants to release the slider and start again.
      origin = tostring(value)
      local newdigits = #(origin:match('%.(%d+)') or '')
      if decdigits ~= newdigits then
        origin = origin .. (origin:find('%.') and '' or '.') .. ("0"):rep(decdigits-newdigits)
      end

      -- update length
      scratchpad.length = #origin

      -- update the value in the document
      scratchpadEditor:SetTargetStart(startpos)
      scratchpadEditor:SetTargetEnd(endpos)
      scratchpadEditor:ReplaceTarget(origin)
    else event:Skip() end
  end)

  scratchpadEditor:Connect(wx.wxEVT_SET_CURSOR, function(event)
    if (debugger.scratchpad and debugger.scratchpad.over) then
      event:SetCursor(wx.wxCursor(wx.wxCURSOR_SIZEWE))
    elseif debugger.scratchpad and ide.osname == 'Unix' then
      -- restore the cursor manually on Linux since event:Skip() doesn't reset it
      local ibeam = event:GetX() > debugger.scratchpad.margin
      event:SetCursor(wx.wxCursor(ibeam and wx.wxCURSOR_IBEAM or wx.wxCURSOR_RIGHT_ARROW))
    else event:Skip() end
  end)

  return true
end

function debugger:ScratchpadOff()
  local debugger = self
  if not debugger.scratchpad then return end

  for scratchpadEditor in pairs(debugger.scratchpad.editors) do
    for _, numberStyle in ipairs(scratchpadEditor.spec.isnumber) do
      scratchpadEditor:StyleSetUnderline(numberStyle, false)
    end
    scratchpadEditor:Disconnect(wx.wxID_ANY, wx.wxID_ANY, wxstc.wxEVT_STC_MODIFIED)
    scratchpadEditor:Disconnect(wx.wxID_ANY, wx.wxID_ANY, wx.wxEVT_MOTION)
    scratchpadEditor:Disconnect(wx.wxID_ANY, wx.wxID_ANY, wx.wxEVT_LEFT_DOWN)
    scratchpadEditor:Disconnect(wx.wxID_ANY, wx.wxID_ANY, wx.wxEVT_LEFT_UP)
    scratchpadEditor:Disconnect(wx.wxID_ANY, wx.wxID_ANY, wx.wxEVT_SET_CURSOR)
  end

  wx.wxSetCursor(wx.wxNullCursor) -- restore cursor

  debugger.scratchpad = nil
  debugger:terminate()

  -- disable menu if it is still enabled
  -- (as this may be called when the debugger is being shut down)
  local menuBar = ide.frame.menuBar
  if menuBar:IsChecked(ID.RUNNOW) then menuBar:Check(ID.RUNNOW, false) end

  return true
end

debugger = ide:SetDebugger(setmetatable({}, {__index = protodeb}))

ide:AddPackage('core.debugger', {
    onEditorMarkerUpdate = function(self, editor, marker, line, value)
      if marker ~= BREAKPOINT_MARKER then return end

      local debugger = ide:GetDebugger()
      if value == false then
        -- if there is pending "run-to-cursor" call at this location, remove it
        local ed, ln = unpack(debugger.runtocursor or {})
        local same = ed and ln and ed:GetId() == editor:GetId() and ln == line
        if same then debugger.runtocursor = nil end
      elseif editor:IsLineEmpty(line-1) then
        return false -- don't set marker here
      end

      return debugger:breakpointToggle(editor, line, value)
    end,
  })
