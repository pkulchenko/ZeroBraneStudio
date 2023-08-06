if ide.wxver >= "3.1" then
  ok(wx.wxFileName().ShouldFollowLink ~= nil, "wxlua/wxwidgets 3.1+ includes wxFileName().ShouldFollowLink.")
end

if ide.wxver >= "3.1.4" then
  ok(ide:GetEditorNotebook():GetActiveTabCtrl() ~= nil, "wxlua/wxwidgets 3.1.4+ includes wxAuiNotebook().GetActiveTabCtrl.")
end

local function waitToComplete(bid)
  while wx.wxProcess.Exists(bid) do
    wx.wxSafeYield()
    wx.wxWakeUpIdle()
    wx.wxMilliSleep(100)
  end
  wx.wxSafeYield()
  wx.wxWakeUpIdle() -- wake up one more time to process messages (if any)
end

local modules = {
  ["require([[lfs]])._VERSION"] = "LuaFileSystem 1.8.0",
  ["require([[lpeg]]).version()"] = "1.0.0",
  ["require([[ssl]])._VERSION"] = "0.9",
  ["require([[socket]])._VERSION"] = "LuaSocket 3.0.0",
}
local envall = {'LUA_CPATH', 'LUA_CPATH_5_2', 'LUA_CPATH_5_3', 'LUA_CPATH_5_4'}
local envs = {}
-- save and unset all LUA_CPATH* environmental variables, as we'll only be setting LUA_CPATH
-- for simplicity, so LUA_CPATH_5_2 and _5_3 need to be cleared as they take precedence
for _, env in ipairs(envall) do envs[env] = os.getenv(env); wx.wxUnsetEnv(env) end
for _, luaver in ipairs({"", "5.2", "5.3", "5.4"}) do
  local clibs = ide.osclibs:gsub("clibs", "clibs"..luaver:gsub("%.",""))
  wx.wxSetEnv('LUA_CPATH', clibs)

  for mod, modver in pairs(modules) do
    local res = ""
    local cmd = ('"%s" -e "print(%s)"'):format(ide.interpreters.luadeb:fexepath(luaver), mod)
    local pid, err = ide:ExecuteCommand(cmd, "", function(s) res = res..s end)
    if pid then waitToComplete(pid) end
    -- when there is an error, show the error instead of the expected value
    is((pid and res or err):gsub("%s+$",""), modver,
      ("Checking module version (%s) with Lua %s."):format(mod:match("%[%[(%w+)%]%]"), luaver))
  end
end
for env, val in pairs(envs) do
  if val then wx.wxSetEnv(env, val) else wx.wxUnsetEnv(env) end
end

is(jit and jit.version, "LuaJIT 2.0.4", "Using LuaJIT with the expected version.")

if ide.osname == "Windows" then
  ok(jit and pcall(require, 'fs'), "fs module is loaded.")
end

require "lpeg"
local lexpath = package.searchpath("lexlpeg", ide.osclibs)
ok(package.loadlib(lexpath, "GetLexerCount") ~= nil, "LexLPeg lexer is loaded.")

-- get the list of lexers and check that the match specs in editor.specmap
local lexers = {}
for _, lexer in ipairs(ide:GetFileList('lualibs/lexers/', true, '*.lua', {path = false})) do
  lexers[lexer:gsub("%.lua","")] = 0
end
for ext, lexer in pairs(ide.config.editor.specmap) do
  local msg = "Lexer '"..lexer.."' is present."
  if not lexers[lexer] then
    ok(false, msg)
  else
    if lexers[lexer] == 0 then
      ok(true, msg)
    end
    lexers[lexer] = lexers[lexer] + 1
  end
end
local exceptions = {lexer = true, null = true, rc = true, context = true, tex = true,
  text = true, rails = true, container = true, mediawiki = true, django = true,
  vbscript = true, -- vbscript is only used as an embedded lexer
}
for lexer, num in pairs(lexers) do
  if num == 0 and not exceptions[lexer] then
    ok(false, "Lexer '"..lexer.."' is listed in editor.specmap.")
  end
end
