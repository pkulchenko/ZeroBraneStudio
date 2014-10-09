--[[
This file implements Typed Lua type checker
]]

if not table.unpack then table.unpack = unpack end

local tlchecker = {}

local tlast = require "typedlua.tlast"
local tlst = require "typedlua.tlst"
local tltype = require "typedlua.tltype"
local tlparser = require "typedlua.tlparser"
local tldparser = require "typedlua.tldparser"

local Value = tltype.Value()
local Any = tltype.Any()
local Nil = tltype.Nil()
local Self = tltype.Self()
local False = tltype.False()
local True = tltype.True()
local Boolean = tltype.Boolean()
local Number = tltype.Number()
local String = tltype.String()

local check_block, check_stm, check_exp, check_var

local function lineno (s, i)
  if i == 1 then return 1, 1 end
  local rest, num = s:sub(1,i):gsub("[^\n]*\n", "")
  local r = #rest
  return 1 + num, r ~= 0 and r or 1
end

local function typeerror (env, tag, msg, pos)
  local l, c = lineno(env.subject, pos)
  local error_msg = { tag = tag, msg = msg, l = l, c = c }
  table.insert(env.messages, error_msg)
end

local function set_type (node, t)
  node["type"] = t
end

local function get_type (node)
  return node and node["type"] or Nil
end

local function get_interface (env, name, pos)
  local t = tlst.get_interface(env, name)
  if not t then
    local msg = "type alias '%s' is not defined"
    msg = string.format(msg, name)
    typeerror(env, "alias", msg, pos)
    return Nil
  else
    return t
  end
end

local function replace_names (env, t, pos)
  if tltype.isLiteral(t) or
     tltype.isBase(t) or
     tltype.isNil(t) or
     tltype.isValue(t) or
     tltype.isAny(t) or
     tltype.isSelf(t) or
     tltype.isVoid(t) or
     tltype.isRecursive(t) then
    return t
  elseif tltype.isUnion(t) or
         tltype.isUnionlist(t) or
         tltype.isTuple(t) then
    local r = { tag = t.tag }
    for k, v in ipairs(t) do
      r[k] = replace_names(env, t[k], pos)
    end
    return r
  elseif tltype.isFunction(t) then
    t[1] = replace_names(env, t[1], pos)
    t[2] = replace_names(env, t[2], pos)
    return t
  elseif tltype.isTable(t) then
    for k, v in ipairs(t) do
      t[k][2] = replace_names(env, t[k][2], pos)
    end
    return t
  elseif tltype.isVariable(t) then
    return replace_names(env, get_interface(env, t[1], pos), pos)
  elseif tltype.isVararg(t) then
    t[1] = replace_names(env, t[1], pos)
    return t
  else
    return t
  end
end

local function close_type (t)
  if tltype.isUnion(t) or
     tltype.isUnionlist(t) or
     tltype.isTuple(t) then
    for k, v in ipairs(t) do
      close_type(v)
    end
  else
    if t.open then t.open = nil end
  end
end

local function searchpath (name, path)
  if package.searchpath then
    return package.searchpath(name, path)
  else
    local error_msg = ""
    for tldpath in string.gmatch(path, "([^;]*);") do
      tldpath = string.gsub(tldpath, "?", name)
      local f = io.open(tldpath, "r")
      if f then
        f:close()
        return tldpath
      else
        error_msg = error_msg .. string.format("no file '%s'\n", tldpath)
      end
    end
    return nil, error_msg
  end
end

local function infer_return_type (env)
  local l = tlst.get_return_type(env)
  if #l == 0 then
    if env.strict then
      return tltype.Void()
    else
      return tltype.Tuple({ Nil }, true)
    end
  else
    local r = tltype.Unionlist(table.unpack(l))
    close_type(r)
    return r
  end
end

local function check_tl (env, name, path)
  local file = io.open(path, "r")
  local subject = file:read("*a")
  io.close(file)
  local ast = assert(tlparser.parse(subject, path, env.strict))
  tlst.begin_function(env)
  check_block(env, ast)
  local t1 = tltype.first(infer_return_type(env))
  tlst.end_function(env)
  return t1
end

local function check_interface (env, stm)
  local name, t, is_local = stm[1], stm[2], stm.is_local
  if tlst.get_interface(env, name) then
    local msg = "attempt to redeclare interface '%s'"
    msg = string.format(msg, name)
    typeerror(env, "alias", msg, stm.pos)
  else
    tlst.set_interface(env, name, t, is_local)
  end
end

local function check_userdata (env, stm)
  local name, t, is_local = stm[1], stm[2], stm.is_local
  if tlst.get_userdata(env, name) then
    local msg = "attempt to redeclare userdata '%s'"
    msg = string.format(msg, name)
    typeerror(env, "alias", msg, stm.pos)
  else
    tlst.set_userdata(env, name, t, is_local)
  end
end

local function check_tld (env, name, path)
  local ast = assert(tldparser.parse(path, env.strict))
  local t = tltype.Table()
  for k, v in ipairs(ast) do
    local tag = v.tag
    if tag == "Id" then
      table.insert(t, tltype.Field(v.const, tltype.Literal(v[1]), v[2]))
    elseif tag == "Interface" then
      check_interface(env, v)
    elseif tag == "Userdata" then
      check_userdata(env, v)
    else
      error("trying to check a description item, but got a " .. tag)
    end
  end
  return t
end

local function check_require (env, name, pos)
  if not env["loaded"][name] then
    local path = string.gsub(package.path, "[.]lua", ".tl")
    local filepath, msg1 = searchpath(name, path)
    if filepath then
      env["loaded"][name] = check_tl(env, name, filepath)
    else
      path = string.gsub(package.path, "[.]lua", ".tld")
      local filepath, msg2 = searchpath(name, path)
      if filepath then
        env["loaded"][name] = check_tld(env, name, filepath)
      else
        env["loaded"][name] = Any
        local msg = "could not load '%s'%s%s"
        msg = string.format(msg, name, msg1, msg2)
        typeerror(env, "load", msg, pos)
      end
    end
  end
  return env["loaded"][name]
end

local function check_masking (env, local_name, pos)
  local masked_local = tlst.masking(env, local_name)
  if masked_local then
    local l, c = lineno(env.subject, masked_local.pos)
    msg = "masking previous declaration of local %s on line %d"
    msg = string.format(msg, local_name, l)
    typeerror(env, "mask", msg, pos)
  end
end

local function check_unused_locals (env)
  local l = tlst.unused(env)
  for k, v in pairs(l) do
    local msg = "unused local " .. k
    typeerror(env, "unused", msg, v.pos)
  end
end

local function check_arith (env, exp)
  local exp1, exp2 = exp[2], exp[3]
  check_exp(env, exp1)
  check_exp(env, exp2)
  local t1, t2 = tltype.first(get_type(exp1)), tltype.first(get_type(exp2))
  local msg = "attempt to perform arithmetic on a '%s'"
  if tltype.subtype(t1, Number) and tltype.subtype(t2, Number) then
    set_type(exp, Number)
  elseif tltype.isAny(t1) then
    set_type(exp, Any)
    msg = string.format(msg, tltype.tostring(t1))
    typeerror(env, "any", msg, exp1.pos)
  elseif tltype.isAny(t2) then
    set_type(exp, Any)
    msg = string.format(msg, tltype.tostring(t2))
    typeerror(env, "any", msg, exp2.pos)
  else
    set_type(exp, Any)
    local wrong_type, wrong_pos = tltype.general(t1), exp1.pos
    if tltype.subtype(t1, Number) or tltype.isAny(t1) then
      wrong_type, wrong_pos = tltype.general(t2), exp2.pos
    end
    msg = string.format(msg, tltype.tostring(wrong_type))
    typeerror(env, "arith", msg, wrong_pos)
  end
end

local function check_concat (env, exp)
  local exp1, exp2 = exp[2], exp[3]
  check_exp(env, exp1)
  check_exp(env, exp2)
  local t1, t2 = tltype.first(get_type(exp1)), tltype.first(get_type(exp2))
  local msg = "attempt to concatenate a '%s'"
  if tltype.subtype(t1, String) and tltype.subtype(t2, String) then
    set_type(exp, String)
  elseif tltype.isAny(t1) then
    set_type(exp, Any)
    msg = string.format(msg, tltype.tostring(t1))
    typeerror(env, "any", msg, exp1.pos)
  elseif tltype.isAny(t2) then
    set_type(exp, Any)
    msg = string.format(msg, tltype.tostring(t2))
    typeerror(env, "any", msg, exp2.pos)
  else
    set_type(exp, Any)
    local wrong_type, wrong_pos = tltype.general(t1), exp1.pos
    if tltype.subtype(t1, String) or tltype.isAny(t1) then
      wrong_type, wrong_pos = tltype.general(t2), exp2.pos
    end
    msg = string.format(msg, tltype.tostring(wrong_type))
    typeerror(env, "concat", msg, wrong_pos)
  end
end

local function check_equal (env, exp)
  local exp1, exp2 = exp[2], exp[3]
  check_exp(env, exp1)
  check_exp(env, exp2)
  set_type(exp, Boolean)
end

local function check_order (env, exp)
  local exp1, exp2 = exp[2], exp[3]
  check_exp(env, exp1)
  check_exp(env, exp2)
  local t1, t2 = tltype.first(get_type(exp1)), tltype.first(get_type(exp2))
  local msg = "attempt to compare '%s' with '%s'"
  if tltype.subtype(t1, Number) and tltype.subtype(t2, Number) then
    set_type(exp, Boolean)
  elseif tltype.subtype(t1, String) and tltype.subtype(t2, String) then
    set_type(exp, Boolean)
  elseif tltype.isAny(t1) then
    set_type(exp, Any)
    msg = string.format(msg, tltype.tostring(t1), tltype.tostring(t2))
    typeerror(env, "any", msg, exp1.pos)
  elseif tltype.isAny(t2) then
    set_type(exp, Any)
    msg = string.format(msg, tltype.tostring(t1), tltype.tostring(t2))
    typeerror(env, "any", msg, exp2.pos)
  else
    set_type(exp, Any)
    t1, t2 = tltype.general(t1), tltype.general(t2)
    msg = string.format(msg, tltype.tostring(t1), tltype.tostring(t2))
    typeerror(env, "order", msg, exp.pos)
  end
end

local function check_and (env, exp)
  local exp1, exp2 = exp[2], exp[3]
  check_exp(env, exp1)
  check_exp(env, exp2)
  local t1, t2 = tltype.first(get_type(exp1)), tltype.first(get_type(exp2))
  if tltype.isNil(t1) or tltype.isFalse(t1) then
    set_type(exp, t1)
  elseif tltype.isUnion(t1, Nil) then
    set_type(exp, tltype.Union(t2, Nil))
  elseif tltype.isUnion(t1, False) then
    set_type(exp, tltype.Union(t2, False))
  else
    set_type(exp, tltype.Union(t1, t2))
  end
end

local function check_or (env, exp)
  local exp1, exp2 = exp[2], exp[3]
  check_exp(env, exp1)
  check_exp(env, exp2)
  local t1, t2 = tltype.first(get_type(exp1)), tltype.first(get_type(exp2))
  if tltype.isNil(t1) or tltype.isFalse(t1) then
    set_type(exp, t2)
  elseif tltype.isUnion(t1, Nil) then
    set_type(exp, tltype.Union(tltype.filterUnion(t1, Nil), t2))
  elseif tltype.isUnion(t1, False) then
    set_type(exp, tltype.Union(tltype.filterUnion(t1, False), t2))
  else
    set_type(exp, tltype.Union(t1, t2))
  end
end

local function check_binary_op (env, exp)
  local op = exp[1]
  if op == "add" or op == "sub" or
     op == "mul" or op == "div" or op == "mod" or
     op == "pow" then
    check_arith(env, exp)
  elseif op == "concat" then
    check_concat(env, exp)
  elseif op == "eq" then
    check_equal(env, exp)
  elseif op == "lt" or op == "le" then
    check_order(env, exp)
  elseif op == "and" then
    check_and(env, exp)
  elseif op == "or" then
    check_or(env, exp)
  else
    error("cannot type check binary operator " .. op)
  end
end

local function check_not (env, exp)
  local exp1 = exp[2]
  check_exp(env, exp1)
  set_type(exp, Boolean)
end

local function check_minus (env, exp)
  local exp1 = exp[2]
  check_exp(env, exp1)
  local t1 = tltype.first(get_type(exp1))
  local msg = "attempt to perform arithmetic on a '%s'"
  if tltype.subtype(t1, Number) then
    set_type(exp, Number)
  elseif tltype.isAny(t1) then
    set_type(exp, Any)
    msg = string.format(msg, tltype.tostring(t1))
    typeerror(env, "any", msg, exp1.pos)
  else
    set_type(exp, Any)
    t1 = tltype.general(t1)
    msg = string.format(msg, tltype.tostring(t1))
    typeerror(env, "arith", msg, exp1.pos)
  end
end

local function check_len (env, exp)
  local exp1 = exp[2]
  check_exp(env, exp1)
  local t1 = tltype.first(get_type(exp1))
  local msg = "attempt to get length of a '%s'"
  if tltype.subtype(t1, String) or
     tltype.subtype(t1, tltype.Table()) then
    set_type(exp, Number)
  elseif tltype.isAny(t1) then
    set_type(exp, Any)
    msg = string.format(msg, tltype.tostring(t1))
    typeerror(env, "any", msg, exp1.pos)
  else
    set_type(exp, Any)
    t1 = tltype.general(t1)
    msg = string.format(msg, tltype.tostring(t1))
    typeerror(env, "len", msg, exp1.pos)
  end
end

local function check_unary_op (env, exp)
  local op = exp[1]
  if op == "not" then
    check_not(env, exp)
  elseif op == "unm" then
    check_minus(env, exp)
  elseif op == "len" then
    check_len(env, exp)
  else
    error("cannot type check unary operator " .. op)
  end
end

local function check_op (env, exp)
  if exp[3] then
    check_binary_op(env, exp)
  else
    check_unary_op(env, exp)
  end
end

local function check_paren (env, exp)
  local exp1 = exp[1]
  check_exp(env, exp1)
  local t1 = get_type(exp1)
  set_type(exp, tltype.first(t1))
end

local function check_parameters (env, parlist)
  local len = #parlist
  if len == 0 then
    if env.strict then
      return tltype.Void()
    else
      return tltype.Tuple({ Value }, true)
    end
  else
    local l = {}
    if parlist[1][1] == "self" and not parlist[1][2] then
      parlist[1][2] = Self
    end
    for i = 1, len do
      if not parlist[i][2] then parlist[i][2] = Any end
      l[i] = parlist[i][2]
    end
    if parlist[len].tag == "Dots" then
      tlst.set_vararg(env, parlist[len][2])
      return tltype.Tuple(l, true)
    else
      if env.strict then
        return tltype.Tuple(l)
      else
        l[len + 1] = Value
        return tltype.Tuple(l, true)
      end
    end
  end
end

local function check_explist (env, explist)
  for k, v in ipairs(explist) do
    check_exp(env, v)
  end
end

local function check_return_type (env, inf_type, dec_type, pos)
  local msg = "return type '%s' does not match '%s'"
  inf_type = replace_names(env, inf_type, pos)
  dec_type = replace_names(env, dec_type, pos)
  if tltype.subtype(inf_type, dec_type) then
  elseif tltype.consistent_subtype(inf_type, dec_type) then
    msg = string.format(msg, tltype.tostring(inf_type), tltype.tostring(dec_type))
    typeerror(env, "any", msg, pos)
  else
    msg = string.format(msg, tltype.tostring(inf_type), tltype.tostring(dec_type))
    typeerror(env, "ret", msg, pos)
  end
end

local function check_function (env, exp)
  local idlist, ret_type, block = exp[1], exp[2], exp[3]
  local infer_return = false
  if not block then
    block = ret_type
    ret_type = tltype.Tuple({ Any }, true)
    infer_return = true
  end
  tlst.begin_function(env)
  tlst.begin_scope(env)
  local input_type = check_parameters(env, idlist)
  local t = tltype.Function(input_type, ret_type)
  local len = #idlist
  if len > 0 and idlist[len].tag == "Dots" then len = len - 1 end
  for k = 1, len do
    local v = idlist[k]
    set_type(v, v[2])
    check_masking(env, v[1], v.pos)
    tlst.set_local(env, v)
  end
  check_block(env, block)
  check_unused_locals(env)
  tlst.end_scope(env)
  local inferred_type = infer_return_type(env)
  if infer_return then
    ret_type = inferred_type
    t = tltype.Function(input_type, ret_type)
    set_type(exp, t)
  end
  t = replace_names(env, t, exp.pos)
  check_return_type(env, inferred_type, ret_type, exp.pos)
  tlst.end_function(env)
  set_type(exp, t)
end

local function check_table (env, exp)
  local l = {}
  local i = 1
  local len = #exp
  for k, v in ipairs(exp) do
    local tag = v.tag
    local t1, t2
    if tag == "Pair" then
      local exp1, exp2 = v[1], v[2]
      check_exp(env, exp1)
      check_exp(env, exp2)
      t1, t2 = get_type(exp1), tltype.general(get_type(exp2))
      if tltype.subtype(t1, Nil) then
        t1 = Any
        local msg = "table index can be nil"
        typeerror(env, "table", msg, exp1.pos)
      elseif not (tltype.subtype(t1, Boolean) or
                  tltype.subtype(t1, Number) or
                  tltype.subtype(t1, String)) then
        t1 = Any
        local msg = "table index is dynamic"
        typeerror(env, "any", msg, exp1.pos)
      end
    else
      local exp1 = v
      check_exp(env, exp1)
      t1, t2 = tltype.Literal(i), tltype.general(get_type(exp1))
      if k == len and tltype.isVararg(t2) then
        t1 = Number
      end
      i = i + 1
    end
    if t2.open then t2.open = nil end
    t2 = tltype.first(t2)
    l[k] = tltype.Field(v.const, t1, t2)
  end
  local t = tltype.Table(table.unpack(l))
  t.unique = true
  set_type(exp, t)
end

local function var2name (var)
  local tag = var.tag
  if tag == "Id" then
    return string.format("local '%s'", var[1])
  elseif tag == "Index" then
    if var[1].tag == "Id" and var[1][1] == "_ENV" and var[2].tag == "String" then
      return string.format("global '%s'", var[2][1])
    else
      return string.format("field '%s'", var[2][1])
    end
  else
    return "value"
  end
end

local function explist2typegen (explist)
  local len = #explist
  return function (i)
    if i <= len then
      local t = get_type(explist[i])
      return tltype.first(t)
    else
      local t
      if len == 0 then t = Nil else t = get_type(explist[len]) end
      if tltype.isVararg(t) then
        return tltype.first(t)
      else
        return Nil
      end
    end
  end
end

local function explist2type (explist)
  local len = #explist
  if len == 0 then
    return tltype.Tuple({ Nil }, true)
  else
    local l = {}
    for i = 1, len do
      l[i] = tltype.first(get_type(explist[i]))
    end
    if not tltype.isVararg(explist[len]) then
      l[len + 1] = Nil
    end
    return tltype.Tuple(l, true)
  end
end

local function arglist2type (explist, strict)
  local len = #explist
  if len == 0 then
    if strict then
      return tltype.Void()
    else
      return tltype.Tuple({ Nil }, true)
    end
  else
    local l = {}
    for i = 1, len do
      l[i] = tltype.first(get_type(explist[i]))
    end
    if strict then
      return tltype.Tuple(l)
    else
      if not tltype.isVararg(explist[len]) then
        l[len + 1] = Nil
      end
      return tltype.Tuple(l, true)
    end
  end
end

local function check_arguments (env, func_name, dec_type, infer_type, pos)
  local msg = "attempt to pass '%s' to %s of input type '%s'"
  dec_type = replace_names(env, dec_type, pos)
  infer_type = replace_names(env, infer_type, pos)
  if tltype.subtype(infer_type, dec_type) then
  elseif tltype.consistent_subtype(infer_type, dec_type) then
    msg = string.format(msg, tltype.tostring(infer_type), func_name, tltype.tostring(dec_type))
    typeerror(env, "any", msg, pos)
  else
    msg = string.format(msg, tltype.tostring(infer_type), func_name, tltype.tostring(dec_type))
    typeerror(env, "args", msg, pos)
  end
end

local function replace_self (env, t)
  local s = env.self or Nil
  if tltype.isTuple(t) then
    local l = {}
    for k, v in ipairs(t) do
      if tltype.isSelf(v) then
        table.insert(l, s)
      else
        table.insert(l, v)
      end
    end
    return tltype.Tuple(l)
  else
    return t
  end
end

local function check_call (env, exp)
  local exp1 = exp[1]
  local explist = {}
  for i = 2, #exp do
    explist[i - 1] = exp[i]
  end
  check_exp(env, exp1)
  check_explist(env, explist)
  if exp1.tag == "Index" and
     exp1[1].tag == "Id" and exp1[1][1] == "_ENV" and
     exp1[2].tag == "String" and exp1[2][1] == "setmetatable" then
    if explist[1] and explist[2] then
      local t1, t2 = get_type(explist[1]), get_type(explist[2])
      local t3 = tltype.getField(tltype.Literal("__index"), t2)
      if not tltype.isNil(t3) then
        if tltype.isTable(t3) then t3.open = true end
        set_type(exp, t3)
      else
        local msg = "second argument of setmetatable must be { __index = e }"
        typeerror(env, "call", msg, exp.pos)
        set_type(exp, Any)
      end
    else
      local msg = "setmetatable must have two arguments"
      typeerror(env, "call", msg, exp.pos)
      set_type(exp, Any)
    end
  elseif exp1.tag == "Index" and
         exp1[1].tag == "Id" and exp1[1][1] == "_ENV" and
         exp1[2].tag == "String" and exp1[2][1] == "require" then
    if explist[1] then
      local t1 = get_type(explist[1])
      if tltype.isStr(t1) then
        set_type(exp, check_require(env, explist[1][1], exp.pos))
      else
        local msg = "the argument of require must be a literal string"
        typeerror(env, "call", msg, exp.pos)
        set_type(exp, Any)
      end
    else
      local msg = "require must have one argument"
      typeerror(env, "call", msg, exp.pos)
      set_type(exp, Any)
    end
  else
    local t = tltype.first(get_type(exp1))
    local inferred_type = arglist2type(explist, env.strict)
    local msg = "attempt to call %s of type '%s'"
    if tltype.isFunction(t) then
      check_arguments(env, var2name(exp1), replace_self(env, t[1]), inferred_type, exp.pos)
      set_type(exp, replace_self(env, t[2]))
    elseif tltype.isAny(t) then
      set_type(exp, Any)
      msg = string.format(msg, var2name(exp1), tltype.tostring(t))
      typeerror(env, "any", msg, exp.pos)
    else
      set_type(exp, Nil)
      msg = string.format(msg, var2name(exp1), tltype.tostring(t))
      typeerror(env, "call", msg, exp.pos)
    end
  end
end

local function check_invoke (env, exp)
  local exp1, exp2 = exp[1], exp[2]
  local explist = {}
  for i = 3, #exp do
    explist[i - 2] = exp[i]
  end
  check_exp(env, exp1)
  check_exp(env, exp2)
  check_explist(env, explist)
  local t1, t2 = get_type(exp1), get_type(exp2)
  if tltype.isTable(t1) or
     tltype.isString(t1) or
     tltype.isStr(t1) then
    local inferred_type = arglist2type(explist, env.strict)
    local t3
    if tltype.isTable(t1) then
      t3 = tltype.getField(t2, t1)
      table.insert(inferred_type, 1, Self)
    else
      local string_userdata = env["loaded"]["string"] or tltype.Table()
      t3 = tltype.getField(t2, string_userdata)
      table.insert(inferred_type, 1, String)
    end
    local msg = "attempt to call method '%s' of type '%s'"
    if tltype.isFunction(t3) then
      check_arguments(env, "field", t3[1], inferred_type, exp.pos)
      set_type(exp, replace_self(env, t3[2]))
    elseif tltype.isAny(t3) then
      set_type(exp, Any)
      msg = string.format(msg, exp2[1], tltype.tostring(t3))
      typeerror(env, "any", msg, exp.pos)
    else
      set_type(exp, Nil)
      msg = string.format(msg, exp2[1], tltype.tostring(t3))
      typeerror(env, "invoke", msg, exp.pos)
    end
  elseif tltype.isAny(t1) then
    set_type(exp, Any)
    local msg = "attempt to index '%s' with '%s'"
    msg = string.format(msg, tltype.tostring(t1), tltype.tostring(t2))
    typeerror(env, "any", msg, exp.pos)
  else
    set_type(exp, Nil)
    local msg = "attempt to index '%s' with '%s'"
    msg = string.format(msg, tltype.tostring(t1), tltype.tostring(t2))
    typeerror(env, "index", msg, exp.pos)
  end
end

local function check_local_var (env, id, inferred_type, close_local)
  local local_name, local_type, pos = id[1], id[2], id.pos
  inferred_type = replace_names(env, inferred_type, pos)
  if tltype.isMethod(inferred_type) then
    local msg = "attempt to create a method reference"
    typeerror(env, "local", msg, pos)
    inferred_type = Nil
  end
  if not local_type then
    if tltype.isNil(inferred_type) then
      local_type = Any
    else
      local_type = tltype.general(inferred_type)
      if inferred_type.unique then
        local_type.unique = nil
        local_type.open = true
      end
      if close_local then local_type.open = nil end
    end
  else
    local_type = replace_names(env, local_type, pos)
    local msg = "attempt to assign '%s' to '%s'"
    msg = string.format(msg, tltype.tostring(inferred_type), tltype.tostring(local_type))
    if tltype.subtype(inferred_type, local_type) then
    elseif tltype.consistent_subtype(inferred_type, local_type) then
      typeerror(env, "any", msg, pos)
    else
      typeerror(env, "local", msg, pos)
    end
  end
  set_type(id, local_type)
  check_masking(env, id[1], id.pos)
  tlst.set_local(env, id)
end

local function unannotated_idlist (idlist)
  for k, v in ipairs(idlist) do
    if v[2] then return false end
  end
  return true
end

local function sized_unionlist (t)
  for i = 1, #t - 1 do
    if #t[i] ~= #t[i + 1] then return false end
  end
  return true
end

local function check_local (env, idlist, explist)
  check_explist(env, explist)
  if unannotated_idlist(idlist) and
     #explist == 1 and
     tltype.isUnionlist(get_type(explist[1])) and
     sized_unionlist(get_type(explist[1])) and
     #idlist == #get_type(explist[1])[1] - 1 then
    local t = get_type(explist[1])
    for k, v in ipairs(idlist) do
      set_type(v, t)
      v.i = k
      check_masking(env, v[1], v.pos)
      tlst.set_local(env, v)
    end
  else
    local tuple = explist2typegen(explist)
    for k, v in ipairs(idlist) do
      local t = tuple(k)
      local close_local = explist[k] and explist[k].tag == "Id" and tltype.isTable(t)
      check_local_var(env, v, t, close_local)
    end
  end
end

local function check_localrec (env, id, exp)
  local idlist, ret_type, block = exp[1], exp[2], exp[3]
  local infer_return = false
  if not block then
    block = ret_type
    ret_type = tltype.Tuple({ Any }, true)
    infer_return = true
  end
  tlst.begin_function(env)
  local input_type = check_parameters(env, idlist)
  local t = tltype.Function(input_type, ret_type)
  t = replace_names(env, t, exp.pos)
  id[2] = t
  set_type(id, t)
  check_masking(env, id[1], id.pos)
  tlst.set_local(env, id)
  tlst.begin_scope(env)
  local len = #idlist
  if len > 0 and idlist[len].tag == "Dots" then len = len - 1 end
  for k = 1, len do
    local v = idlist[k]
    v[2] = replace_names(env, v[2], exp.pos)
    set_type(v, v[2])
    check_masking(env, v[1], v.pos)
    tlst.set_local(env, v)
  end
  check_block(env, block)
  check_unused_locals(env)
  tlst.end_scope(env)
  local inferred_type = infer_return_type(env)
  if infer_return then
    ret_type = inferred_type
    t = tltype.Function(input_type, ret_type)
    id[2] = t
    set_type(id, t)
    tlst.set_local(env, id)
    set_type(exp, t)
  end
  t = replace_names(env, t, exp.pos)
  check_return_type(env, inferred_type, ret_type, exp.pos)
  tlst.end_function(env)
end

local function explist2typelist (explist)
  local len = #explist
  if len == 0 then
    return tltype.Tuple({ Nil }, true)
  else
    local l = {}
    for i = 1, len - 1 do
      table.insert(l, tltype.first(get_type(explist[i])))
    end
    local last_type = get_type(explist[len])
    if tltype.isUnionlist(last_type) then
      last_type = tltype.unionlist2tuple(last_type)
    end
    if tltype.isTuple(last_type) then
      for k, v in ipairs(last_type) do
        table.insert(l, v)
      end
    else
      table.insert(l, last_type)
    end
    if not tltype.isVararg(last_type) then
      table.insert(l, tltype.Vararg(Nil))
    end
    return tltype.Tuple(l)
  end
end

local function check_return (env, stm)
  check_explist(env, stm)
  local t = explist2typelist(stm)
  tlst.set_return_type(env, tltype.general(t))
end

local function check_assignment (env, varlist, explist)
  for k, v in ipairs(varlist) do
    if v.tag == "Index" and v[1].tag == "Id" and v[2].tag == "String" then
      local l = tlst.get_local(env, v[1][1])
      local t = get_type(l)
      if not env.self then
        env.self = t
      else
        if tltype.subtype(t, env.self) then env.self = t end
      end
    end
  end
  check_explist(env, explist)
  for k, v in ipairs(varlist) do
    check_var(env, v, explist[k])
  end
  local var_type, exp_type = explist2typelist(varlist), explist2typelist(explist)
  local msg = "attempt to assign '%s' to '%s'"
  if tltype.subtype(exp_type, var_type) then
  elseif tltype.consistent_subtype(exp_type, var_type) then
    msg = string.format(msg, tltype.tostring(exp_type), tltype.tostring(var_type))
    typeerror(env, "any", msg, varlist[1].pos)
  else
    msg = string.format(msg, tltype.tostring(exp_type), tltype.tostring(var_type))
    typeerror(env, "set", msg, varlist[1].pos)
  end
  for k, v in ipairs(varlist) do
    local tag = v.tag
    if tag == "Id" then
      local name = v[1]
      local l = tlst.get_local(env, name)
      local exp = explist[k]
      if exp and exp.tag == "Op" and exp[1] == "or" and
         exp[2].tag == "Id" and exp[2][1] == name and not l.assigned then
        local t1, t2 = get_type(exp), get_type(l)
        if tltype.subtype(t1, t2) then
          l.bkp = t2
          set_type(l, t1)
        end
      end
      l.assigned = true
    elseif tag == "Index" then
      local t1, t2 = get_type(v[1]), get_type(v[2])
    end
  end
end

local function check_while (env, stm)
  local exp1, stm1 = stm[1], stm[2]
  check_exp(env, exp1)
  check_block(env, stm1)
end

local function check_repeat (env, stm)
  local stm1, exp1 = stm[1], stm[2]
  check_block(env, stm1)
  check_exp(env, exp1)
end

local function tag2type (t)
  if tltype.isLiteral(t) then
    local tag = t[1]
    if tag == "nil" then
      return Nil
    elseif tag == "boolean" then
      return Boolean
    elseif tag == "number" then
      return Number
    elseif tag == "string" then
      return String
    else
      return t
    end
  else
    return t
  end
end

local function get_index (u, t, i)
  if tltype.isUnionlist(u) then
    for k, v in ipairs(u) do
      if tltype.subtype(v[i], t) and tltype.subtype(t, v[i]) then
        return k
      end
    end
  end
end

local function check_if (env, stm)
  local l = {}
  for i = 1, #stm, 2 do
    local exp, block = stm[i], stm[i + 1]
    if block then
      check_exp(env, exp)
      if exp.tag == "Id" then
        local name = exp[1]
        l[name] = tlst.get_local(env, name)
        if not tltype.isUnionlist(get_type(l[name])) then
          if not l[name].bkp then l[name].bkp = get_type(l[name]) end
          l[name].filter = Nil
          set_type(l[name], tltype.filterUnion(get_type(l[name]), Nil))
        else
          local i = get_index(get_type(l[name]), Nil, l[name].i)
          l[name].filter = table.remove(get_type(l[name]), i)
        end
      elseif exp.tag == "Op" and exp[1] == "not" and exp[2].tag == "Id" then
        local name = exp[2][1]
        l[name] = tlst.get_local(env, name)
        if not tltype.isUnionlist(get_type(l[name])) then
          if not l[name].bkp then l[name].bkp = get_type(l[name]) end
          if not l[name].filter then
            l[name].filter = tltype.filterUnion(get_type(l[name]), Nil)
          else
            l[name].filter = tltype.filterUnion(l[name].filter, Nil)
          end
          set_type(l[name], Nil)
        else
          local i = get_index(get_type(l[name]), Nil, l[name].i)
          l[name].filter = table.remove(get_type(l[name]), i)
          local bkp = table.remove(get_type(l[name]))
          table.insert(get_type(l[name]), l[name].filter)
          l[name].filter = bkp
        end
      elseif exp.tag == "Op" and exp[1] == "eq" and
             exp[2].tag == "Call" and exp[2][1].tag == "Index" and
             exp[2][1][1].tag == "Id" and exp[2][1][1][1] == "_ENV" and
             exp[2][1][2].tag == "String" and exp[2][1][2][1] == "type" and
             exp[2][2].tag == "Id" then
        local name = exp[2][2][1]
        l[name] = tlst.get_local(env, name)
        local t = tag2type(get_type(exp[3]))
        if not tltype.isUnionlist(get_type(l[name])) then
          if not l[name].bkp then l[name].bkp = get_type(l[name]) end
          if not l[name].filter then
            l[name].filter = tltype.filterUnion(get_type(l[name]), t)
          else
            l[name].filter = tltype.filterUnion(l[name].filter, t)
          end
          set_type(l[name], t)
        else
          local i = get_index(get_type(l[name]), t, l[name].i)
          l[name].filter = table.remove(get_type(l[name]), i)
          local bkp = table.remove(get_type(l[name]))
          table.insert(get_type(l[name]), l[name].filter)
          l[name].filter = bkp
        end
      elseif exp.tag == "Op" and exp[1] == "not" and
             exp[2].tag == "Op" and exp[2][1] == "eq" and
             exp[2][2].tag == "Call" and exp[2][2][1].tag == "Index" and
             exp[2][2][1][1].tag == "Id" and exp[2][2][1][1][1] == "_ENV" and
             exp[2][2][1][2].tag == "String" and exp[2][2][1][2][1] == "type" and
             exp[2][2][2].tag == "Id" then
        local name = exp[2][2][2][1]
        l[name] = tlst.get_local(env, name)
        local t = tag2type(get_type(exp[2][3]))
        if not tltype.isUnionlist(get_type(l[name])) then
          if not l[name].bkp then l[name].bkp = get_type(l[name]) end
          l[name].filter = t
          set_type(l[name], tltype.filterUnion(get_type(l[name]), t))
        else
          local i = get_index(get_type(l[name]), t, l[name].i)
          l[name].filter = table.remove(get_type(l[name]), i)
        end
      end
    else
      block = exp
    end
    check_block(env, block)
    for k, v in pairs(l) do
      if not tltype.isTuple(v.filter) then
        set_type(v, v.filter)
      else
        local t = get_type(v)
        local bkp = table.remove(t)
        table.insert(t, v.filter)
        v.filter = bkp
      end
    end
  end
  for k, v in pairs(l) do
    if not tltype.isUnionlist(get_type(v)) then
      set_type(v, v.bkp)
    else
      table.insert(get_type(v), v.filter)
    end
  end
end

local function check_fornum (env, stm)
  local id, exp1, exp2, exp3, block = stm[1], stm[2], stm[3], stm[4], stm[5]
  id[2] = Number
  set_type(id, Number)
  tlst.begin_scope(env)
  tlst.set_local(env, id)
  check_exp(env, exp1)
  local t = get_type(exp1)
  local msg = "'for' initial value must be a number"
  if tltype.subtype(t, Number) then
  elseif tltype.consistent_subtype(t, Number) then
    typeerror(env, "any", msg, exp1.pos)
  else
    typeerror(env, "fornum", msg, exp1.pos)
  end
  check_exp(env, exp2)
  t = get_type(exp2)
  msg = "'for' limit must be a number"
  if tltype.subtype(t, Number) then
  elseif tltype.consistent_subtype(t, Number) then
    typeerror(env, "any", msg, exp2.pos)
  else
    typeerror(env, "fornum", msg, exp2.pos)
  end
  if block then
    check_exp(env, exp3)
    t = get_type(exp3)
    msg = "'for' step must be a number"
    if tltype.subtype(t, Number) then
    elseif tltype.consistent_subtype(t, Number) then
      typeerror(env, "any", msg, exp3.pos)
    else
      typeerror(env, "fornum", msg, exp3.pos)
    end
  else
    block = exp3
  end
  check_block(env, block)
  check_unused_locals(env)
  tlst.end_scope(env)
end

local function check_forin (env, idlist, explist, block)
  tlst.begin_scope(env)
  check_explist(env, explist)
  local t = tltype.first(get_type(explist[1]))
  local tuple = explist2typegen({})
  local msg = "attempt to iterate over %s"
  if tltype.isFunction(t) then
    local l = {}
    for k, v in ipairs(t[2]) do
      l[k] = {}
      set_type(l[k], v)
    end
    tuple = explist2typegen(l)
  elseif tltype.isAny(t) then
    msg = string.format(msg, tltype.tostring(t))
    typeerror(env, "any", msg, idlist.pos)
  else
    msg = string.format(msg, tltype.tostring(t))
    typeerror(env, "forin", msg, idlist.pos)
  end
  for k, v in ipairs(idlist) do
    local t = tltype.filterUnion(tuple(k), Nil)
    check_local_var(env, v, t, false)
  end
  check_block(env, block)
  check_unused_locals(env)
  tlst.end_scope(env)
end

local function check_id (env, exp)
  local name = exp[1]
  local l = tlst.get_local(env, name)
  local t = get_type(l)
  if tltype.isUnionlist(t) and l.i then
    set_type(exp, tltype.unionlist2union(t, l.i))
  else
    set_type(exp, t)
  end
end

local function check_index (env, exp)
  local exp1, exp2 = exp[1], exp[2]
  check_exp(env, exp1)
  check_exp(env, exp2)
  local t1, t2 = tltype.first(get_type(exp1)), tltype.first(get_type(exp2))
  local msg = "attempt to index '%s' with '%s'"
  if tltype.isRecursive(t1) then t1 = t1[2] end
  if tltype.isSelf(t1) and env.self then t1 = env.self end
  if tltype.isTable(t1) then
    local field_type = tltype.getField(t2, t1)
    if not tltype.isNil(field_type) then
      set_type(exp, field_type)
    else
      if exp1.tag == "Id" and exp1[1] == "_ENV" and exp2.tag == "String" then
        msg = "attempt to access undeclared global '%s'"
        msg = string.format(msg, exp2[1])
      else
        msg = string.format(msg, tltype.tostring(t1), tltype.tostring(t2))
      end
      typeerror(env, "index", msg, exp.pos)
      set_type(exp, Nil)
    end
  elseif tltype.isAny(t1) then
    set_type(exp, Any)
    msg = string.format(msg, tltype.tostring(t1), tltype.tostring(t2))
    typeerror(env, "any", msg, exp.pos)
  else
    set_type(exp, Nil)
    msg = string.format(msg, tltype.tostring(t1), tltype.tostring(t2))
    typeerror(env, "index", msg, exp.pos)
  end
end

function check_var (env, var, exp)
  local tag = var.tag
  if tag == "Id" then
    local name = var[1]
    local l = tlst.get_local(env, name)
    local t = get_type(l)
    if exp and exp.tag == "Id" and tltype.isTable(t) then t.open = nil end
    set_type(var, t)
  elseif tag == "Index" then
    local exp1, exp2 = var[1], var[2]
    check_exp(env, exp1)
    check_exp(env, exp2)
    local t1, t2 = tltype.first(get_type(exp1)), tltype.first(get_type(exp2))
    local msg = "attempt to index '%s' with '%s'"
    if tltype.isRecursive(t1) then t1 = t1[2] end
    if tltype.isSelf(t1) and env.self then t1 = env.self end
    if tltype.isTable(t1) then
      local field_type = tltype.getField(t2, t1)
      if not tltype.isNil(field_type) then
        set_type(var, field_type)
      else
        if t1.open then
          if exp then
            local t3 = tltype.general(get_type(exp))
            local t = tltype.general(t1)
            table.insert(t, tltype.Field(var.const, t2, t3))
            t = replace_names(env, t, var.pos)
            t1 = replace_names(env, t1, var.pos)
            if tltype.subtype(t, t1) then
              table.insert(t1, tltype.Field(var.const, t2, t3))
            else
              msg = "could not include field '%s'"
              msg = string.format(msg, tltype.tostring(t2))
              typeerror(env, "open", msg, var.pos)
            end
            if t3.open then t3.open = nil end
            set_type(var, t3)
          else
            set_type(var, Nil)
          end
        else
          if exp1.tag == "Id" and exp1[1] == "_ENV" and exp2.tag == "String" then
            msg = "attempt to access undeclared global '%s'"
            msg = string.format(msg, exp2[1])
          else
            msg = "attempt to use '%s' to index closed table"
            msg = string.format(msg, tltype.tostring(t2))
          end
          typeerror(env, "open", msg, var.pos)
          set_type(var, Nil)
        end
      end
    elseif tltype.isAny(t1) then
      set_type(var, Any)
      msg = string.format(msg, tltype.tostring(t1), tltype.tostring(t2))
      typeerror(env, "any", msg, var.pos)
    else
      set_type(var, Nil)
      msg = string.format(msg, tltype.tostring(t1), tltype.tostring(t2))
      typeerror(env, "index", msg, var.pos)
    end
  else
    error("cannot type check variable " .. tag)
  end
end

function check_exp (env, exp)
  local tag = exp.tag
  if tag == "Nil" then
    set_type(exp, Nil)
  elseif tag == "Dots" then
    set_type(exp, tltype.Vararg(tlst.get_vararg(env)))
  elseif tag == "True" then
    set_type(exp, True)
  elseif tag == "False" then
    set_type(exp, False)
  elseif tag == "Number" then
    set_type(exp, tltype.Literal(exp[1]))
  elseif tag == "String" then
    set_type(exp, tltype.Literal(exp[1]))
  elseif tag == "Function" then
    check_function(env, exp)
  elseif tag == "Table" then
    check_table(env, exp)
  elseif tag == "Op" then
    check_op(env, exp)
  elseif tag == "Paren" then
    check_paren(env, exp)
  elseif tag == "Call" then
    check_call(env, exp)
  elseif tag == "Invoke" then
    check_invoke(env, exp)
  elseif tag == "Id" then
    check_id(env, exp)
  elseif tag == "Index" then
    check_index(env, exp)
  else
    error("cannot type check expression " .. tag)
  end
end

function check_stm (env, stm)
  local tag = stm.tag
  if tag == "Do" then
    check_block(env, stm)
  elseif tag == "Set" then
    check_assignment(env, stm[1], stm[2])
  elseif tag == "While" then
    check_while(env, stm)
  elseif tag == "Repeat" then
    check_repeat(env, stm)
  elseif tag == "If" then
    check_if(env, stm)
  elseif tag == "Fornum" then
    check_fornum(env, stm)
  elseif tag == "Forin" then
    check_forin(env, stm[1], stm[2], stm[3])
  elseif tag == "Local" then
    check_local(env, stm[1], stm[2])
  elseif tag == "Localrec" then
    check_localrec(env, stm[1][1], stm[2][1])
  elseif tag == "Goto" then
  elseif tag == "Label" then
  elseif tag == "Return" then
    check_return(env, stm)
  elseif tag == "Break" then
  elseif tag == "Call" then
    check_call(env, stm)
  elseif tag == "Invoke" then
    check_invoke(env, stm)
  elseif tag == "Interface" then
    check_interface(env, stm)
  elseif tag == "Unknown" then
    return true
  elseif tag == "Comment" then
    return true
  else
    error("cannot type check statement " .. tag)
  end
end

function check_block (env, block)
  tlst.begin_scope(env)
  for k, v in ipairs(block) do
    check_stm(env, v)
  end
  check_unused_locals(env)
  tlst.end_scope(env)
end

local function load_lua_env (env)
  local t = check_require(env, "base", 0)
  local l = { "coroutine", "package", "string", "table", "math", "bit32", "io", "os", "debug" }
  for k, v in ipairs(l) do
    local t1 = tltype.Literal(v)
    local t2 = check_require(env, v, 0)
    local f = tltype.Field(false, t1, t2)
    table.insert(t, f)
  end
  t.open = true
  local lua_env = tlast.ident(0, "_ENV", t)
  set_type(lua_env, t)
  tlst.set_local(env, lua_env)
  tlst.get_local(env, "_ENV")
end

function tlchecker.typecheck (ast, subject, strict)
  assert(type(ast) == "table")
  assert(type(subject) == "string")
  assert(type(strict) == "boolean")
  local env = tlst.new_env(subject, strict)
  tlst.begin_function(env)
  tlst.begin_scope(env)
  tlst.set_vararg(env, String)
  load_lua_env(env)
  for k, v in ipairs(ast) do
    check_stm(env, v)
  end
  check_unused_locals(env)
  tlst.end_scope(env)
  tlst.end_function(env)
  return env.messages
end

function tlchecker.error_msgs (messages, filename, warnings)
  local l = {}
  local error_msg = filename .. ":%d:%d: type error, %s"
  local skip_error = { any = true,
    mask = true,
    unused = true,
  }
  for k, v in ipairs(messages) do
    local tag = v.tag
    if skip_error[tag] then
      if warnings then
        table.insert(l, string.format(error_msg, v.l, v.c, v.msg))
      end
    else
      table.insert(l, string.format(error_msg, v.l, v.c, v.msg))
    end
  end
  if #l == 0 then
    return nil
  else
    return table.concat(l, "\n")
  end
end

return tlchecker
