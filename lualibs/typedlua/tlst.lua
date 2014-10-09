--[[
This module implements Typed Lua symbol table.
]]

local tlst = {}

-- new_env : (string, boolean) -> (env)
function tlst.new_env (subject, strict)
  local env = {}
  env.subject = subject
  env.strict = strict
  env.messages = {}
  env.maxscope = 0
  env.scope = 0
  env.fscope = 0
  env.loop = 0
  env["function"] = {}
  env["interface"] = {}
  env["userdata"] = {}
  env["loaded"] = {}
  return env
end

-- new_scope : () -> (senv)
local function new_scope ()
  local senv = {}
  senv["goto"] = {}
  senv["label"] = {}
  senv["local"] = {}
  senv["unused"] = {}
  senv["interface"] = {}
  senv["userdata"] = {}
  return senv
end

-- begin_scope : (env) -> ()
function tlst.begin_scope (env)
  local scope = env.scope
  if scope > 0 then
    for k, v in pairs(env[scope]["local"]) do
      if v["type"] and v["type"].open then
        v["type"].open = nil
        v["type"].reopen = true
      end
    end
  end
  env.scope = scope + 1
  env.maxscope = env.scope
  env[env.scope] = new_scope()
end

-- end_scope : (env) -> ()
function tlst.end_scope (env)
  env.scope = env.scope - 1
  local scope = env.scope
  if scope > 0 then
    for k, v in pairs(env[scope]["local"]) do
      if v.bkp then
        v["type"] = v.bkp
      end
      if v["type"] and v["type"].reopen then
        v["type"].reopen = nil
        v["type"].open = true
      end
    end
  end
end

-- set_pending_goto : (env, stm) -> ()
function tlst.set_pending_goto (env, stm)
  table.insert(env[env.scope]["goto"], stm)
end

-- get_pending_gotos : (env, number) -> ({number:stm})
function tlst.get_pending_gotos (env, scope)
  return env[scope]["goto"]
end

-- get_maxscope : (env) -> (number)
function tlst.get_maxscope (env)
  return env.maxscope
end

-- set_label : (env, string) -> (boolean)
function tlst.set_label (env, name)
  local scope = env.scope
  local label = env[scope]["label"][name]
  if not label then
    env[scope]["label"][name] = true
    return true
  else
    return false
  end
end

-- exist_label : (env, number, string) -> (boolean)
function tlst.exist_label (env, scope, name)
  for s = scope, 1, -1 do
    if env[s]["label"][name] then return true end
  end
  return false
end

-- set_local : (env, id) -> ()
function tlst.set_local (env, id)
  local scope = env.scope
  local local_name = id[1]
  env[scope]["local"][local_name] = id
  env[scope]["unused"][local_name] = id
end

-- get_local : (env, string) -> (id)
function tlst.get_local (env, local_name)
  local scope = env.scope
  for s = scope, 1, -1 do
    local l = env[s]["local"][local_name]
    if l then
      env[s]["unused"][local_name] = nil
      return l
    end
  end
  return nil
end

-- masking : (env, string) -> (id|nil)
function tlst.masking (env, local_name)
  local scope = env.scope
  return env[scope]["local"][local_name]
end

-- unused : (env) -> ({string:id})
function tlst.unused (env)
  local scope = env.scope
  return env[scope]["unused"]
end

-- set_interface : (env, string, type, boolean?) -> ()
function tlst.set_interface (env, name, t, is_local)
  if is_local then
    local scope = env.scope
    env[scope]["interface"][name] = t
  else
    env["interface"][name] = t
  end
end

-- get_interface : (env) -> (type?)
function tlst.get_interface (env, name)
  local scope = env.scope
  for s = scope, 1, -1 do
    local t = env[s]["interface"][name]
    if t then return t end
  end
  if env["interface"][name] then
    return env["interface"][name]
  end
  for s = scope, 1, -1 do
    local t = env[s]["userdata"][name]
    if t then return t end
  end
  return env["userdata"][name]
end

-- set_userdata : (env, string, type, boolean?) -> ()
function tlst.set_userdata (env, name, t, is_local)
  if is_local then
    local scope = env.scope
    env[scope]["userdata"][name] = t
  else
    env["userdata"][name] = t
  end
end

-- get_userdata : (env) -> (type?)
function tlst.get_userdata (env, name)
  local scope = env.scope
  for s = scope, 1, -1 do
    local t = env[s]["userdata"][name]
    if t then return t end
  end
  return env["userdata"][name]
end

-- new_fenv : () -> (fenv)
local function new_fenv ()
  local fenv = {}
  fenv["return_type"] = {}
  return fenv
end

-- begin_function : (env) -> ()
function tlst.begin_function (env)
  env.fscope = env.fscope + 1
  env["function"][env.fscope] = new_fenv()
end

-- end_function : (env) -> ()
function tlst.end_function (env)
  env.fscope = env.fscope - 1
end

-- set_vararg : (env, type) -> ()
function tlst.set_vararg (env, t)
  env["function"][env.fscope]["vararg"] = t
end

-- get_vararg : (env) -> (type?)
function tlst.get_vararg (env, t)
  return env["function"][env.fscope]["vararg"]
end

-- is_vararg : (env) -> (boolean)
function tlst.is_vararg (env)
  local t = tlst.get_vararg(env)
  if t then return true else return false end
end

-- set_return_type : (env, type) -> ()
function tlst.set_return_type (env, t)
  table.insert(env["function"][env.fscope]["return_type"], t)
end

-- get_return_type : (env) -> ({type})
function tlst.get_return_type (env)
  return env["function"][env.fscope]["return_type"]
end

-- begin_loop : (env) -> ()
function tlst.begin_loop (env)
  env.loop = env.loop + 1
end

-- end_loop : (env) -> ()
function tlst.end_loop (env)
  env.loop = env.loop - 1
end

-- insideloop : (env) -> (boolean)
function tlst.insideloop (env)
  return env.loop > 0
end

return tlst
