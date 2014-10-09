--[[
This module implements Typed Lua tltype.
]]

if not table.unpack then table.unpack = unpack end

local tltype = {}

-- literal types

-- Literal : (boolean|number|string) -> (type) 
function tltype.Literal (l)
  return { tag = "TLiteral", [1] = l }
end

-- False : () -> (type)
function tltype.False ()
  return tltype.Literal(false)
end

-- True : () -> (type)
function tltype.True ()
  return tltype.Literal(true)
end

-- Num : (number) -> (type)
function tltype.Num (n)
  return tltype.Literal(n)
end

-- Str : (string) -> (type)
function tltype.Str (s)
  return tltype.Literal(s)
end

-- isLiteral : (type) -> (boolean)
function tltype.isLiteral (t)
  return t.tag == "TLiteral"
end

-- isFalse : (type) -> (boolean)
function tltype.isFalse (t)
  return tltype.isLiteral(t) and t[1] == false
end

-- isTrue : (type) -> (boolean)
function tltype.isTrue (t)
  return tltype.isLiteral(t) and t[1] == true
end

-- isNum : (type) -> (boolean)
function tltype.isNum (t)
  return tltype.isLiteral(t) and type(t[1]) == "number"
end

-- isStr : (type) -> (boolean)
function tltype.isStr (t)
  return tltype.isLiteral(t) and type(t[1]) == "string"
end

-- base types

-- Base : ("boolean"|"number"|"string") -> (type)
function tltype.Base (s)
  return { tag = "TBase", [1] = s }
end

-- Boolean : () -> (type)
function tltype.Boolean ()
  return tltype.Base("boolean")
end

-- Number : () -> (type)
function tltype.Number ()
  return tltype.Base("number")
end

-- String : () -> (type)
function tltype.String ()
  return tltype.Base("string")
end

-- isBase : (type) -> (boolean)
function tltype.isBase (t)
  return t.tag == "TBase"
end

-- isBoolean : (type) -> (boolean)
function tltype.isBoolean (t)
  return tltype.isBase(t) and t[1] == "boolean"
end

-- isNumber : (type) -> (boolean)
function tltype.isNumber (t)
  return tltype.isBase(t) and t[1] == "number"
end

-- isString : (type) -> (boolean)
function tltype.isString (t)
  return tltype.isBase(t) and t[1] == "string"
end

-- nil type

-- Nil : () -> (type)
function tltype.Nil ()
  return { tag = "TNil" }
end

-- isNil : (type) -> (boolean)
function tltype.isNil (t)
  return t.tag == "TNil"
end

-- value type

-- Value : () -> (type)
function tltype.Value (t)
  return { tag = "TValue" }
end

-- isValue : (type) -> (boolean)
function tltype.isValue (t)
  return t.tag == "TValue"
end

-- dynamic type

-- Any : () -> (type)
function tltype.Any ()
  return { tag = "TAny" }
end

-- isAny : (type) -> (boolean)
function tltype.isAny (t)
  return t.tag == "TAny"
end

-- self type

-- Self : () -> (type)
function tltype.Self ()
  return { tag = "TSelf" }
end

-- isSelf : (type) -> (boolean)
function tltype.isSelf (t)
  return t.tag == "TSelf"
end

-- void type

-- Void : () -> (type)
function tltype.Void ()
  return { tag = "TVoid" }
end

-- isVoid : (type) -> (boolean)
function tltype.isVoid (t)
  return t.tag == "TVoid"
end

-- union types

-- Union : (type*) -> (type)
function tltype.Union (...)
  local l1 = {...}
  -- remove unions of unions
  local l2 = {}
  for i = 1, #l1 do
    if tltype.isUnion(l1[i]) then
      for j = 1, #l1[i] do
        table.insert(l2, l1[i][j])
      end
    else
      table.insert(l2, l1[i])
    end
  end
  -- remove duplicated types
  local l3 = {}
  for i = 1, #l2 do
    local enter = true
    for j = i + 1, #l2 do
      if tltype.subtype(l2[i], l2[j]) and tltype.subtype(l2[j], l2[i]) then
        enter = false
        break
      end
    end
    if enter then table.insert(l3, l2[i]) end
  end
  -- simplify union
  local t = { tag = "TUnion" }
  for i = 1, #l3 do
    local enter = true
    for j = 1, #l3 do
      if i ~= j and tltype.subtype(l3[i], l3[j]) then
        enter = false
        break
      end
    end
    if enter then table.insert(t, l3[i]) end
  end
  if #t == 1 then
    return t[1]
  else
    return t
  end
end

-- isUnion : (type, type?) -> (boolean)
function tltype.isUnion (t1, t2)
  if not t2 then
    return t1.tag == "TUnion"
  else
    if t1.tag == "TUnion" then
      for k, v in ipairs(t1) do
        if tltype.subtype(t2, v) and tltype.subtype(v, t2) then
          return true
        end
      end
      return false
    else
      return false
    end
  end
end

-- filterUnion : (type, type) -> (type)
function tltype.filterUnion (u, t)
  if tltype.isUnion(u) then
    local l = {}
    for k, v in ipairs(u) do
      if not (tltype.subtype(t, v) and tltype.subtype(v, t)) then
        table.insert(l, v)
      end
    end
    return tltype.Union(table.unpack(l))
  else
    return u
  end
end

-- UnionNil : (type, true?) -> (type)
function tltype.UnionNil (t, is_union_nil)
  if is_union_nil then
    return tltype.Union(t, tltype.Nil())
  else
    return t
  end
end

-- vararg types

-- Vararg : (type) -> (type)
function tltype.Vararg (t)
  return { tag = "TVararg", [1] = t }
end

-- isVararg : (type) -> (boolean)
function tltype.isVararg (t)
  return t.tag == "TVararg"
end

-- tuple types

-- Tuple : ({number:type}, true?) -> (type)
function tltype.Tuple (l, is_vararg)
  if is_vararg then
    l[#l] = tltype.Vararg(l[#l])
  end
  return { tag = "TTuple", table.unpack(l) }
end

-- inputTuple : (type?, boolean) -> (type)
function tltype.inputTuple (t, strict)
  if not strict then
    if not t then
      return tltype.Tuple({ tltype.Value() }, true)
    else
      if not tltype.isVararg(t[#t]) then
        table.insert(t, tltype.Vararg(tltype.Value()))
      end
      return t
    end
  else
    if not t then
      return tltype.Void()
    else
      return t
    end
  end
end

-- outputTuple : (type?, boolean) -> (type)
function tltype.outputTuple (t, strict)
  if not strict then
    if not t then
      return tltype.Tuple({ tltype.Nil() }, true)
    else
      if not tltype.isVararg(t[#t]) then
        table.insert(t, tltype.Vararg(tltype.Nil()))
      end
      return t
    end
  else
    if not t then
      return tltype.Void()
    else
      return t
    end
  end
end

-- retType : (type, boolean) -> (type)
function tltype.retType (t, strict)
  return tltype.outputTuple(tltype.Tuple({ t }), strict)
end

-- isTuple : (type) -> (boolean)
function tltype.isTuple (t)
  return t.tag == "TTuple"
end

-- union of tuple types

-- Unionlist : (type*) -> (type)
function tltype.Unionlist (...)
  local t = tltype.Union(...)
  if tltype.isUnion(t) then t.tag = "TUnionlist" end
  return t
end

-- isUnionlist : (type) -> (boolean)
function tltype.isUnionlist (t)
  return t.tag == "TUnionlist"
end

-- UnionlistNil : (type, boolean?) -> (type)
function tltype.UnionlistNil (t, is_union_nil)
  if type(is_union_nil) == "boolean" then
    local u = tltype.Tuple({ tltype.Nil(), tltype.String() })
    return tltype.Unionlist(t, tltype.outputTuple(u, is_union_nil))
  else
    return t
  end
end

-- function types

-- Function : (type, type, true?) -> (type)
function tltype.Function (t1, t2, is_method)
  if is_method then
    if tltype.isVoid(t1) then
      t1 = tltype.Tuple({ tltype.Self() })
    else
      table.insert(t1, 1, tltype.Self())
    end
  end
  return { tag = "TFunction", [1] = t1, [2] = t2 }
end

function tltype.isFunction (t)
  return t.tag == "TFunction"
end

function tltype.isMethod (t)
  if tltype.isFunction(t) then
    for k, v in ipairs(t[1]) do
      if tltype.isSelf(v) then return true end
    end
    return false
  else
    return false
  end
end

-- table types

-- Field : (boolean, type, type) -> (field)
function tltype.Field (is_const, t1, t2)
  return { tag = "TField", const = is_const, [1] = t1, [2] = t2 }
end

-- isField : (field) -> (boolean)
function tltype.isField (f)
  return f.tag == "TField" and not f.const
end

-- isConstField : (field) -> (boolean)
function tltype.isConstField (f)
  return f.tag == "TField" and f.const
end

-- Table : (field*) -> (type)
function tltype.Table (...)
  return { tag = "TTable", ... }
end

-- isTable : (type) -> (boolean)
function tltype.isTable (t)
  return t.tag == "TTable"
end

-- getField : (type, type) -> (type)
function tltype.getField (f, t)
  if tltype.isTable(t) then
    for k, v in ipairs(t) do
      if tltype.consistent_subtype(f, v[1]) then
        return v[2]
      end
    end
    return tltype.Nil()
  else
    return tltype.Nil()
  end
end

-- fieldlist : ({ident}, type) -> (field*)
function tltype.fieldlist (idlist, t)
  local l = {}
  for k, v in ipairs(idlist) do
    table.insert(l, tltype.Field(v.const, tltype.Literal(v[1]), t))
  end
  return table.unpack(l)
end

-- checkTypeDec : (string, type) -> (true)?
function tltype.checkTypeDec (n, t)
  local predef_type = {
    ["boolean"] = true,
    ["number"] = true,
    ["string"] = true,
    ["value"] = true,
    ["any"] = true,
    ["self"] = true,
    ["const"] = true,
  }
  if not predef_type[n] then
    if tltype.isTable(t) then
      local namelist = {}
      for k, v in ipairs(t) do
        local f1, f2 = v[1], v[2]
        if tltype.isStr(f1) then
          local name = f1[1]
          if not namelist[name] then
            namelist[name] = true
          else
            local msg = "attempt to redeclare field '%s'"
            return nil, string.format(msg, name)
          end
        end
      end
      return true
    else
      return nil, "attempt to name a type that is not a table"
    end
  else
    local msg = "attempt to redeclare type '%s'"
    return nil, string.format(msg, n)
  end
end

-- type variables

-- Variable : (string) -> (type)
function tltype.Variable (name)
  return { tag = "TVariable", [1] = name }
end

-- isVariable : (type) -> (boolean)
function tltype.isVariable (t)
  return t.tag == "TVariable"
end

-- recursive types

-- Recursive : (string, type) -> (type)
function tltype.Recursive (x, t)
  return { tag = "TRecursive", [1] = x, [2] = t }
end

-- isRecursive : (type) -> (boolean)
function tltype.isRecursive (t)
  return t.tag == "TRecursive"
end

local function check_recursive (t, name)
  if tltype.isLiteral(t) or
     tltype.isBase(t) or
     tltype.isNil(t) or
     tltype.isValue(t) or
     tltype.isAny(t) or
     tltype.isSelf(t) or
     tltype.isVoid(t) then
    return false
  elseif tltype.isUnion(t) or
         tltype.isUnionlist(t) or
         tltype.isTuple(t) then
    for k, v in ipairs(t) do
      if check_recursive(v, name) then
        return true
      end
    end
    return false
  elseif tltype.isFunction(t) then
    return check_recursive(t[1], name) or check_recursive(t[2], name)
  elseif tltype.isTable(t) then
    for k, v in ipairs(t) do
      if check_recursive(v[2], name) then
        return true
      end
    end
    return false
  elseif tltype.isVariable(t) then
    return t[1] == name
  elseif tltype.isRecursive(t) then
    return check_recursive(t[2], name)
  elseif tltype.isVararg(t) then
    return check_recursive(t[1], name)
  else
    return false
  end
end

-- checkRecursive : (type, string) -> (boolean)
function tltype.checkRecursive (t, name)
  if tltype.isTable(t) then
    for k, v in ipairs(t) do
      if check_recursive(v[2], name) then return true end
    end
    return false
  else
    return false
  end
end

-- subtyping and consistent-subtyping

local subtype

local function subtype_literal (env, t1, t2)
  if tltype.isLiteral(t1) and tltype.isLiteral(t2) then
    return t1[1] == t2[1]
  elseif tltype.isLiteral(t1) and tltype.isBase(t2) then
    if tltype.isBoolean(t2) then
      return tltype.isFalse(t1) or tltype.isTrue(t1)
    elseif tltype.isNumber(t2) then
      return tltype.isNum(t1)
    elseif tltype.isString(t2) then
      return tltype.isStr(t1)
    else
      return false
    end
  else
    return false
  end
end

local function subtype_base (env, t1, t2)
  if tltype.isBase(t1) and tltype.isBase(t2) then
    return t1[1] == t2[1]
  else
    return false
  end
end

local function subtype_nil (env, t1, t2)
  return tltype.isNil(t1) and tltype.isNil(t2)
end

local function subtype_top (env, t1, t2)
  return tltype.isValue(t2)
end

local function subtype_any (env, t1, t2, relation)
  if relation == "<:" then
    return tltype.isAny(t1) and tltype.isAny(t2)
  else
    return tltype.isAny(t1) or tltype.isAny(t2)
  end
end

local function subtype_self (env, t1, t2)
  return tltype.isSelf(t1) and tltype.isSelf(t2)
end

local function subtype_union (env, t1, t2, relation)
  if tltype.isUnion(t1) then
    for k, v in ipairs(t1) do
      if not subtype(env, v, t2, relation) then
        return false
      end
    end
    return true
  elseif tltype.isUnion(t2) then
    for k, v in ipairs(t2) do
      if subtype(env, t1, v, relation) then
        return true
      end
    end
    return false
  else
    return false
  end
end

local function subtype_function (env, t1, t2, relation)
  if tltype.isFunction(t1) and tltype.isFunction(t2) then
    return subtype(env, t2[1], t1[1], relation) and subtype(env, t1[2], t2[2], relation)
  else
    return false
  end
end

local function subtype_field (env, f1, f2, relation)
  if tltype.isField(f1) and tltype.isField(f2) then
    return subtype(env, f2[1], f1[1], relation) and
           subtype(env, f1[2], f2[2], relation) and
           subtype(env, f2[2], f1[2], relation)
  elseif tltype.isField(f1) and tltype.isConstField(f2) then
    return subtype(env, f2[1], f1[1], relation) and
           subtype(env, f1[2], f2[2], relation)
  elseif tltype.isConstField(f1) and tltype.isConstField(f2) then
    return subtype(env, f2[1], f1[1], relation) and
           subtype(env, f1[2], f2[2], relation)
  else
    return false
  end
end

local function subtype_table (env, t1, t2, relation)
  if tltype.isTable(t1) and tltype.isTable(t2) then
    if t1.unique then
      local m, n = #t2, #t1
      for i = 1, m do
        local subtype_key, subtype_value = false, false
        for j = 1, n do
          if subtype(env, t1[j][1], t2[i][1], relation) then
            subtype_key = true
            if subtype(env, t1[j][2], t2[i][2], relation) then
              subtype_value = true
              break
            end
          end
        end
        if subtype_key then
          if not subtype_value then return false end
        else
          if not subtype(env, tltype.Nil(), t2[i][2], relation) then return false end
        end
      end
      return true
    elseif t1.open then
      local m, n = #t2, #t1
      for i = 1, m do
        local subtype_key, subtype_value = false, false
        for j = 1, n do
          if subtype(env, t1[j][1], t2[i][1], relation) then
            subtype_key = true
            if subtype_field(env, t2[i], t1[j], relation) then
              subtype_value = true
              break
            end
          end
        end
        if subtype_key then
          if not subtype_value then return false end
        else
          if not subtype(env, tltype.Nil(), t2[i][2], relation) then return false end
        end
      end
      return true
    else
      local m, n = #t1, #t2
      for i = 1, n do
        local subtype = false
        for j = 1, m do
          if subtype_field(env, t1[j], t2[i], relation) then
            subtype = true
            break
          end
        end
        if not subtype then return false end
      end
      return true
    end
  else
    return false
  end
end

local function subtype_variable (env, t1, t2)
  if tltype.isVariable(t1) and tltype.isVariable(t2) then
    return env[t1[1] .. t2[1]]
  else
    return false
  end
end

local function subtype_recursive (env, t1, t2, relation)
  if tltype.isRecursive(t1) and tltype.isRecursive(t2) then
    env[t1[1] .. t2[1]] = true
    return subtype(env, t1[2], t2[2], relation)
  elseif tltype.isRecursive(t1) and not tltype.isRecursive(t2) then
    if not env[t1[1] .. t1[1]] then
      env[t1[1] .. t1[1]] = true
      return subtype(env, t1[2], t2, relation)
    else
      return subtype(env, tltype.Variable(t1[1]), t2, relation)
    end
  elseif not tltype.isRecursive(t1) and tltype.isRecursive(t2) then
    if not env[t2[1] .. t2[1]] then
      env[t2[1] .. t2[1]] = true
      return subtype(env, t1, t2[2], relation)
    else
      return subtype(env, t1, tltype.Variable(t2[1]), relation)
    end
  else
    return false
  end
end

local function subtype_tuple (env, t1, t2, relation)
  if tltype.isTuple(t1) and tltype.isTuple(t2) then
    local len1, len2 = #t1, #t2
    if len1 < len2 then
      if not tltype.isVararg(t1[len1]) then return false end
      local i = 1
      while i < len1 do
        if not subtype(env, t1[i], t2[i], relation) then
          return false
        end
        i = i + 1
      end
      local j = i
      while j <= len2 do
        if not subtype(env, t1[i], t2[j], relation) then
          return false
        end
        j = j + 1
      end
      return true
    elseif len1 > len2 then
      if not tltype.isVararg(t2[len2]) then return false end
      local i = 1
      while i < len2 do
        if not subtype(env, t1[i], t2[i], relation) then
          return false
        end
        i = i + 1
      end
      local j = i
      while j <= len1 do
        if not subtype(env, t1[j], t2[i], relation) then
          return false
        end
        j = j + 1
      end
      return true
    else
      for k, v in ipairs(t1) do
        if not subtype(env, t1[k], t2[k], relation) then
          return false
        end
      end
      return true
    end
  else
    return false
  end
end

function subtype (env, t1, t2, relation)
  if tltype.isVoid(t1) and tltype.isVoid(t2) then
    return true
  elseif tltype.isUnionlist(t1) then
    for k, v in ipairs(t1) do
      if not subtype(env, v, t2, relation) then
        return false
      end
    end
    return true
  elseif tltype.isUnionlist(t2) then
    for k, v in ipairs(t2) do
      if subtype(env, t1, v, relation) then
        return true
      end
    end
    return false
  elseif tltype.isTuple(t1) and tltype.isTuple(t2) then
    return subtype_tuple(env, t1, t2, relation)
  elseif tltype.isTuple(t1) and not tltype.isTuple(t2) then
    return false
  elseif not tltype.isTuple(t1) and tltype.isTuple(t2) then
    return false
  elseif tltype.isVararg(t1) and tltype.isVararg(t2) then
    local t1_nil = tltype.Union(t1[1], tltype.Nil())
    local t2_nil = tltype.Union(t2[1], tltype.Nil())
    return subtype(env, t1_nil, t2_nil, relation)
  elseif tltype.isVararg(t1) and not tltype.isVararg(t2) then
    local t1_nil = tltype.Union(t1[1], tltype.Nil())
    return subtype(env, t1_nil, t2, relation)
  elseif not tltype.isVararg(t1) and tltype.isVararg(t2) then
    local t2_nil = tltype.Union(t2[1], tltype.Nil())
    return subtype(env, t1, t2_nil, relation)
  else
    return subtype_literal(env, t1, t2) or
           subtype_base(env, t1, t2) or
           subtype_nil(env, t1, t2) or
           subtype_top(env, t1, t2) or
           subtype_any(env, t1, t2, relation) or
           subtype_self(env, t1, t2) or
           subtype_union(env, t1, t2, relation) or
           subtype_function(env, t1, t2, relation) or
           subtype_table(env, t1, t2, relation) or
           subtype_variable(env, t1, t2) or
           subtype_recursive(env, t1, t2, relation)
  end
end

function tltype.subtype (t1, t2)
  return subtype({}, t1, t2, "<:")
end

function tltype.consistent_subtype (t1, t2)
  return subtype({}, t1, t2, "<~")
end

-- most general type

function tltype.general (t)
  if tltype.isFalse(t) or tltype.isTrue(t) then
    return tltype.Boolean()
  elseif tltype.isNum(t) then
    return tltype.Number()
  elseif tltype.isStr(t) then
    return tltype.String()
  elseif tltype.isUnion(t) then
    local l = {}
    for k, v in ipairs(t) do
      table.insert(l, tltype.general(v))
    end
    return tltype.Union(table.unpack(l))
  elseif tltype.isFunction(t) then
    return tltype.Function(tltype.general(t[1]), tltype.general(t[2]))
  elseif tltype.isTable(t) then
    local l = {}
    for k, v in ipairs(t) do
      table.insert(l, tltype.Field(v.const, v[1], tltype.general(v[2])))
    end
    local n = tltype.Table(table.unpack(l))
    n.unique = t.unique
    n.open = t.open
    return n
  elseif tltype.isTuple(t) then
    local l = {}
    for k, v in ipairs(t) do
      table.insert(l, tltype.general(v))
    end
    return tltype.Tuple(l)
  elseif tltype.isUnionlist(t) then
    local l = {}
    for k, v in ipairs(t) do
      table.insert(l, tltype.general(v))
    end
    return tltype.Unionlist(table.unpack(l))
  elseif tltype.isVararg(t) then
    return tltype.Vararg(tltype.general(t[1]))
  else
    return t
  end
end

-- first level type

local function resize_tuple (t, n)
  local tuple = { tag = "TTuple" }
  local vararg = t[#t][1]
  for i = 1, #t - 1 do
    tuple[i] = t[i]
  end
  for i = #t, n - 1 do
    if tltype.isNil(vararg) then
      tuple[i] = vararg
    else
      tuple[i] = tltype.Union(vararg, Nil)
    end
  end
  tuple[n] = tltype.Vararg(vararg)
  return tuple
end

function tltype.unionlist2tuple (t)
  local max = 1
  for i = 1, #t do
    if #t[i] > max then max = #t[i] end
  end
  local u = {}
  for i = 1, #t do
    if #t[i] < max then
      u[i] = resize_tuple(t[i], max)
    else
      u[i] = t[i]
    end
  end
  local l = {}
  for i = 1, #u do
    for j = 1, #u[i] do
      if not l[j] then l[j] = {} end
      table.insert(l[j], u[i][j])
    end
  end
  local n = { tag = "TTuple" }
  for i = 1, #l - 1 do
    n[i] = tltype.Union(table.unpack(l[i]))
  end
  local vs = {}
  for k, v in ipairs(l[#l]) do
    table.insert(vs, v[1])
  end
  n[#l] = tltype.Vararg(tltype.Union(table.unpack(vs)))
  return n
end

function tltype.unionlist2union (t, i)
  local l = {}
  for k, v in ipairs(t) do
    l[#l + 1] = v[i]
  end
  return tltype.Union(table.unpack(l))
end

function tltype.first (t)
  if tltype.isTuple(t) then
    return tltype.first(t[1])
  elseif tltype.isUnionlist(t) then
    local l = {}
    for k, v in ipairs(t) do
      table.insert(l, tltype.first(v))
    end
    return tltype.Union(table.unpack(l))
  elseif tltype.isVararg(t) then
    return tltype.Union(t[1], tltype.Nil())
  else
    return t
  end
end

-- tostring

-- type2str (type) -> (string)
local function type2str (t)
  if tltype.isLiteral(t) then
    return tostring(t[1])
  elseif tltype.isBase(t) then
    return t[1]
  elseif tltype.isNil(t) then
    return "nil"
  elseif tltype.isValue(t) then
    return "value"
  elseif tltype.isAny(t) then
    return "any"
  elseif tltype.isSelf(t) then
    return "self"
  elseif tltype.isUnion(t) or
         tltype.isUnionlist(t) then
    local l = {}
    for k, v in ipairs(t) do
      l[k] = type2str(v)
    end
    return "(" .. table.concat(l, " | ") .. ")"
  elseif tltype.isFunction(t) then
    return type2str(t[1]) .. " -> " .. type2str(t[2])
  elseif tltype.isTable(t) then
    --if t.interface then return t.interface end
    local l = {}
    for k, v in ipairs(t) do
      l[k] = type2str(v[1]) .. ":" .. type2str(v[2])
      if tltype.isConstField(v) then
        l[k] = "const " .. l[k]
      end
    end
    return "{" .. table.concat(l, ", ") .. "}"
  elseif tltype.isVariable(t) then
    return t[1]
  elseif tltype.isRecursive(t) then
    return t[1] .. "." .. type2str(t[2])
  elseif tltype.isVoid(t) then
    return "(void)"
  elseif tltype.isTuple(t) then
    local l = {}
    for k, v in ipairs(t) do
      l[k] = type2str(v)
    end
    return "(" .. table.concat(l, ", ") .. ")"
  elseif tltype.isVararg(t) then
    return type2str(t[1]) .. "*"
  else
    error("trying to convert type to string but got " .. t.tag)
  end
end

-- tostring : (type) -> (string)
function tltype.tostring (t)
  return type2str(t)
end

return tltype
