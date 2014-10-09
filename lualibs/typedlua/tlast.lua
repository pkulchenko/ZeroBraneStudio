--[[
This module implements Typed Lua AST.
This AST extends the AST format implemented by Metalua.
For more information about Metalua, please, visit:
https://github.com/fab13n/metalua-parser

block: { stat* }

stat:
  `Do{ stat* }
  | `Set{ {lhs+} {expr+} }                    -- lhs1, lhs2... = e1, e2...
  | `While{ expr block }                      -- while e do b end
  | `Repeat{ block expr }                     -- repeat b until e
  | `If{ (expr block)+ block? }               -- if e1 then b1 [elseif e2 then b2] ... [else bn] end
  | `Fornum{ ident expr expr expr? block }    -- for ident = e, e[, e] do b end
  | `Forin{ {ident+} {expr+} block }          -- for i1, i2... in e1, e2... do b end
  | `Local{ {ident+} {expr+}? }               -- local i1, i2... = e1, e2...
  | `Localrec{ ident expr }                   -- only used for 'local function'
  | `Goto{ <string> }                         -- goto str
  | `Label{ <string> }                        -- ::str::
  | `Return{ <expr*> }                        -- return e1, e2...
  | `Break                                    -- break
  | apply
  | `Interface{ <string> type }

expr:
  `Nil
  | `Dots
  | `True
  | `False
  | `Number{ <number> }
  | `String{ <string> }
  | `Function{ { ident* { `Dots type? }? } typelist? block }
  | `Table{ ( `Pair{ expr expr } | expr )* }
  | `Op{ opid expr expr? }
  | `Paren{ expr }       -- significant to cut multiple values returns
  | apply
  | lhs

apply:
  `Call{ expr expr* }
  | `Invoke{ expr `String{ <string> } expr* }

lhs: ident | `Index{ expr expr }

ident: `Id{ <string> type? }

opid: 'add' | 'sub' | 'mul' | 'div' | 'mod' | 'pow' | 'concat'
  | 'eq' | 'lt' | 'le' | 'and' | 'or' | 'not' | 'unm' | 'len'

type:
  `TLiteral{ literal }
  | `TBase{ base }
  | `TNil
  | `TValue
  | `TAny
  | `TSelf
  | `TUnion{ type type type* }
  | `TFunction{ type type }
  | `TTable{ type type* }
  | `TVariable{ <string> }
  | `TRecursive{ <string> type }
  | `TVoid
  | `TUnionlist{ type type type* }
  | `TTuple{ type type* }
  | `TVararg{ type }

literal: false | true | <number> | <string>

base: 'boolean' | 'number' | 'string'

field: `TField{ <string> type }
]]

local tlast = {}

-- namelist : (number, ident, ident*) -> (namelist)
function tlast.namelist (pos, id, ...)
  local t = { tag = "NameList", pos = pos, ... }
  table.insert(t, 1, id)
  return t
end

-- explist : (number, expr, expr*) -> (explist)
function tlast.explist (pos, expr, ...)
  local t = { tag = "ExpList", pos = pos, ... }
  table.insert(t, 1, expr)
  return t
end

-- stat

-- unknown : (pos, string)
function tlast.unknown (pos, s)
  return { tag = "Unknown", pos = pos, s }
end

-- comment : (pos, string)
function tlast.comment (pos, s)
  return { tag = "Comment", pos = pos, s }
end

-- block : (number, stat*) -> (block)
function tlast.block (pos, ...)
  return { tag = "Block", pos = pos, ... }
end

-- statDo : (block) -> (stat)
function tlast.statDo (block)
  block.tag = "Do"
  return block
end

-- statWhile : (number, expr, block) -> (stat)
function tlast.statWhile (pos, expr, block)
  return { tag = "While", pos = pos, [1] = expr, [2] = block }
end

-- statRepeat : (number, block, expr) -> (stat)
function tlast.statRepeat (pos, block, expr)
  return { tag = "Repeat", pos = pos, [1] = block, [2] = expr }
end

-- statIf : (number, any*) -> (stat)
function tlast.statIf (pos, ...)
  return { tag = "If", pos = pos, ... }
end

-- statFornum : (number, ident, expr, expr, expr|block, block?) -> (stat)
function tlast.statFornum (pos, ident, e1, e2, e3, block)
  local s = { tag = "Fornum", pos = pos }
  s[1] = ident
  s[2] = e1
  s[3] = e2
  s[4] = e3
  s[5] = block
  return s
end

-- statForin : (number, namelist, explist, block) -> (stat)
function tlast.statForin (pos, namelist, explist, block)
  local s = { tag = "Forin", pos = pos }
  s[1] = namelist
  s[2] = explist
  s[3] = block
  return s
end

-- statLocal : (number, namelist, explist) -> (stat)
function tlast.statLocal (pos, namelist, explist)
  return { tag = "Local", pos = pos, [1] = namelist, [2] = explist }
end

-- statLocalrec : (number, ident, expr) -> (stat)
function tlast.statLocalrec (pos, ident, expr)
  return { tag = "Localrec", pos = pos, [1] = { ident }, [2] = { expr } }
end

-- statGoto : (number, string) -> (stat)
function tlast.statGoto (pos, str)
  return { tag = "Goto", pos = pos, [1] = str }
end

-- statLabel : (number, string) -> (stat)
function tlast.statLabel (pos, str)
  return { tag = "Label", pos = pos, [1] = str }
end

-- statReturn : (number, expr*) -> (stat)
function tlast.statReturn (pos, ...)
  return { tag = "Return", pos = pos, ... }
end

-- statBreak : (number) -> (stat)
function tlast.statBreak (pos)
  return { tag = "Break", pos = pos }
end

-- statFuncSet : (number, lhs, expr) -> (stat)
function tlast.statFuncSet (pos, is_const, lhs, expr)
  lhs.const = is_const
  if lhs.is_method then
    table.insert(expr[1], 1, { tag = "Id", [1] = "self" })
  end
  return { tag = "Set", pos = pos, [1] = { lhs }, [2] = { expr } }
end

-- statSet : (expr*) -> (boolean, stat?)
function tlast.statSet (...)
  local vl = { ... }
  local el = vl[#vl]
  table.remove(vl)
  for k, v in ipairs(vl) do
    if v.tag == "Id" or v.tag == "Index" then
      vl[k] = v
    else
      -- invalid assignment
      return false
    end
  end
  vl.tag = "Varlist"
  vl.pos = vl[1].pos
  return true, { tag = "Set", pos = vl.pos, [1] = vl, [2] = el }
end

-- statApply : (expr) -> (boolean, stat?)
function tlast.statApply (expr)
  if expr.tag == "Call" or expr.tag == "Invoke" then
    return true, expr
  else
    -- invalid statement
    return false
  end
end

-- statInterface : (number, string, type) -> (stat)
function tlast.statInterface (pos, name, t)
  t.interface = name
  return { tag = "Interface", pos = pos, [1] = name, [2] = t }
end

-- statUserdata : (number, string, type) -> (stat)
function tlast.statUserdata (pos, name, t)
  t.userdata = name
  return { tag = "Userdata", pos = pos, [1] = name, [2] = t }
end

-- statLocalTypeDec : (stat) -> (stat)
function tlast.statLocalTypeDec (stat)
  stat.is_local = true
  return stat
end

-- parlist

-- parList0 : (number) -> (parlist)
function tlast.parList0 (pos)
  return { tag = "Parlist", pos = pos }
end

-- parList1 : (number, ident) -> (parlist)
function tlast.parList1 (pos, vararg)
  return { tag = "Parlist", pos = pos, [1] = vararg }
end

-- parList2 : (number, namelist, ident?) -> (parlist)
function tlast.parList2 (pos, namelist, vararg)
  if vararg then table.insert(namelist, vararg) end
  return namelist
end

-- fieldlist

-- fieldPair : (number, expr, expr) -> (field)
function tlast.fieldPair (pos, e1, e2)
  return { tag = "Pair", pos = pos, [1] = e1, [2] = e2 }
end

-- expr

-- exprNil : (number) -> (expr)
function tlast.exprNil (pos)
  return { tag = "Nil", pos = pos }
end

-- exprDots : (number) -> (expr)
function tlast.exprDots (pos)
  return { tag = "Dots", pos = pos }
end

-- exprTrue : (number) -> (expr)
function tlast.exprTrue (pos)
  return { tag = "True", pos = pos }
end

-- exprFalse : (number) -> (expr)
function tlast.exprFalse (pos)
  return { tag = "False", pos = pos }
end

-- exprNumber : (number, number) -> (expr)
function tlast.exprNumber (pos, num)
  return { tag = "Number", pos = pos, [1] = num }
end

-- exprString : (number, string) -> (expr)
function tlast.exprString (pos, str)
  return { tag = "String", pos = pos, [1] = str }
end

-- exprFunction : (number, parlist, type|stat, stat?) -> (expr)
function tlast.exprFunction (pos, parlist, rettype, stat)
  return { tag = "Function", pos = pos, [1] = parlist, [2] = rettype, [3] = stat }
end

-- exprTable : (number, field*) -> (expr)
function tlast.exprTable (pos, ...)
  return { tag = "Table", pos = pos, ... }
end

-- exprUnaryOp : (string, expr) -> (expr)
function tlast.exprUnaryOp (op, e)
  return { tag = "Op", pos = e.pos, [1] = op, [2] = e }
end

-- exprBinaryOp : (expr, string?, expr?) -> (expr)
function tlast.exprBinaryOp (e1, op, e2)
  if not op then
    return e1
  elseif op == "add" or
         op == "sub" or
         op == "mul" or
         op == "div" or
         op == "mod" or
         op == "pow" or
         op == "concat" or
         op == "eq" or
         op == "lt" or
         op == "le" or
         op == "and" or
         op == "or" then
    return { tag = "Op", pos = e1.pos, [1] = op, [2] = e1, [3] = e2 }
  elseif op == "ne" then
    return tlast.exprUnaryOp ("not", tlast.exprBinaryOp(e1, "eq", e2))
  elseif op == "gt" then
    return { tag = "Op", pos = e1.pos, [1] = "lt", [2] = e2, [3] = e1 }
  elseif op == "ge" then
    return { tag = "Op", pos = e1.pos, [1] = "le", [2] = e2, [3] = e1 }
  end
end

-- exprParen : (number, expr) -> (expr)
function tlast.exprParen (pos, e)
  return { tag = "Paren", pos = pos, [1] = e }
end

-- exprSuffixed : (expr, expr?) -> (expr)
function tlast.exprSuffixed (e1, e2)
  if e2 then
    if e2.tag == "Call" or e2.tag == "Invoke" then
      local e = { tag = e2.tag, pos = e1.pos, [1] = e1 }
      for k, v in ipairs(e2) do
        table.insert(e, v)
      end
      return e
    else
      return { tag = "Index", pos = e1.pos, [1] = e1, [2] = e2[1] }
    end
  else
    return e1
  end
end

-- exprIndex : (number, expr) -> (lhs)
function tlast.exprIndex (pos, e)
  return { tag = "Index", pos = pos, [1] = e }
end

-- ident : (number, string, type?) -> (ident)
function tlast.ident (pos, str, t)
  return { tag = "Id", pos = pos, [1] = str, [2] = t }
end

-- index : (number, expr, expr) -> (lhs)
function tlast.index (pos, e1, e2)
  return { tag = "Index", pos = pos, [1] = e1, [2] = e2 }
end

-- identDots : (number, type?) -> (expr)
function tlast.identDots (pos, t)
  return { tag = "Dots", pos = pos, [1] = t }
end

-- funcName : (ident, ident, true?) -> (lhs)
function tlast.funcName (ident1, ident2, is_method)
  if ident2 then
    local t = { tag = "Index", pos = ident1.pos }
    t[1] = ident1
    t[2] = ident2
    if is_method then t.is_method = is_method end
    return t
  else
    return ident1
  end
end

-- apply

-- call : (number, expr, expr*) -> (apply)
function tlast.call (pos, e1, ...)
  local a = { tag = "Call", pos = pos, [1] = e1 }
  local list = { ... }
  for i = 1, #list do
    a[i + 1] = list[i]
  end
  return a
end

-- invoke : (number, expr, expr, expr*) -> (apply)
function tlast.invoke (pos, e1, e2, ...)
  local a = { tag = "Invoke", pos = pos, [1] = e1, [2] = e2 }
  local list = { ... }
  for i = 1, #list do
    a[i + 2] = list[i]
  end
  return a
end

-- setConst : (expr|field|id) -> (expr|field|id)
function tlast.setConst (t)
  t.const = true
  return t
end

-- tostring

local block2str, stm2str, exp2str, var2str, type2str
local explist2str, varlist2str, parlist2str, fieldlist2str

local function iscntrl (x)
  if (x >= 0 and x <= 31) or (x == 127) then return true end
  return false
end

local function isprint (x)
  return not iscntrl(x)
end

local function fixed_string (str)
  local new_str = ""
  for i=1,string.len(str) do
    char = string.byte(str, i)
    if char == 34 then new_str = new_str .. string.format("\\\"")
    elseif char == 92 then new_str = new_str .. string.format("\\\\")
    elseif char == 7 then new_str = new_str .. string.format("\\a")
    elseif char == 8 then new_str = new_str .. string.format("\\b")
    elseif char == 12 then new_str = new_str .. string.format("\\f")
    elseif char == 10 then new_str = new_str .. string.format("\\n")
    elseif char == 13 then new_str = new_str .. string.format("\\r")
    elseif char == 9 then new_str = new_str .. string.format("\\t")
    elseif char == 11 then new_str = new_str .. string.format("\\v")
    else
      if isprint(char) then
        new_str = new_str .. string.format("%c", char)
      else
        new_str = new_str .. string.format("\\%03d", char)
      end
    end
  end
  return new_str
end

local function name2str (name)
  return string.format('"%s"', name)
end

local function number2str (n)
  return string.format('"%s"', tostring(n))
end

local function string2str (s)
  return string.format('"%s"', fixed_string(s))
end

function type2str (t)
  local tag = t.tag
  local str = "`" .. tag
  if tag == "TLiteral" then
    str = str .. " " .. tostring(t[1])
  elseif tag == "TBase" then
    str = str .. " " .. t[1]
  elseif tag == "TNil" or
         tag == "TValue" or
         tag == "TAny" or
         tag == "TSelf" or
         tag == "TVoid" then
  elseif tag == "TUnion" or
         tag == "TUnionlist" then
    local l = {}
    for k, v in ipairs(t) do
      l[k] = type2str(v)
    end
    str = str .. "{ " .. table.concat(l, ", ") .. " }"
  elseif tag == "TFunction" then
    str = str .. "{ "
    str = str .. type2str(t[1]) .. ", "
    str = str .. type2str(t[2])
    str = str .. " }"
  elseif tag == "TTable" then
    local l = {}
    for k, v in ipairs(t) do
      l[k] = type2str(v[1]) .. ":" .. type2str(v[2])
    end
    str = str .. "{ " .. table.concat(l, ", ") .. " }"
  elseif tag == "TVariable" then
    str = str .. " " .. t[1]
  elseif tag == "TRecursive" then
    str = str .. "{ "
    str = str .. t[1] .. ", "
    str = str .. type2str(t[2])
    str = str .. " }"
  elseif tag == "TTuple" then
    local l = {}
    for k, v in ipairs(t) do
      l[k] = type2str(v)
    end
    return str .. "{ " .. table.concat(l, ", ") .. " }"
  elseif tag == "TVararg" then
    return str .. "{ " .. type2str(t[1]) .. " }"
  else
    error("expecting a type, but got a " .. tag)
  end
  return str
end

function var2str (var)
  local tag = var.tag
  local str = "`" .. tag
  if tag == "Id" then
    str = str .. " " .. name2str(var[1])
    if var[2] then
      str = str .. ":" .. type2str(var[2])
    end
  elseif tag == "Index" then
    str = str .. "{ "
    str = str .. exp2str(var[1]) .. ", "
    str = str .. exp2str(var[2])
    str = str .. " }"
  else
    error("expecting a variable, but got a " .. tag)
  end
  return str
end

function varlist2str (varlist)
  local l = {}
  for k, v in ipairs(varlist) do
    l[k] = var2str(v)
  end
  return "{ " .. table.concat(l, ", ") .. " }"
end

function parlist2str (parlist)
  local l = {}
  local len = #parlist
  local is_vararg = false
  if len > 0 and parlist[len].tag == "Dots" then
    is_vararg = true
    len = len - 1
  end
  local i = 1
  while i <= len do
    l[i] = var2str(parlist[i])
    i = i + 1
  end
  if is_vararg then
    l[i] = "`" .. parlist[i].tag
    if parlist[i][1] then
      l[i] = l[i] .. ":" .. type2str(parlist[i][1])
    end
  end
  return "{ " .. table.concat(l, ", ") .. " }"
end

function fieldlist2str (fieldlist)
  local l = {}
  for k, v in ipairs(fieldlist) do
    local tag = v.tag
    if tag == "Pair" then
      l[k] = "`" .. tag .. "{ "
      l[k] = l[k] .. exp2str(v[1]) .. ", " .. exp2str(v[2])
      l[k] = l[k] .. " }"
    else -- expr
      l[k] = exp2str(v)
    end
  end
  if #l > 0 then
    return "{ " .. table.concat(l, ", ") .. " }"
  else
    return ""
  end
end

function exp2str (exp)
  local tag = exp.tag
  local str = "`" .. tag
  if tag == "Nil" or
     tag == "Dots" or
     tag == "True" or
     tag == "False" then
  elseif tag == "Number" then
    str = str .. " " .. number2str(exp[1])
  elseif tag == "String" then
    str = str .. " " .. string2str(exp[1])
  elseif tag == "Function" then
    str = str .. "{ "
    str = str .. parlist2str(exp[1])
    if exp[3] then
      str = str .. ":" .. type2str(exp[2])
      str = str .. ", " .. block2str(exp[3])
    else
      str = str .. ", " .. block2str(exp[2])
    end
    str = str .. " }"
  elseif tag == "Table" then
    str = str .. fieldlist2str(exp)
  elseif tag == "Op" then
    str = str .. "{ "
    str = str .. name2str(exp[1]) .. ", "
    str = str .. exp2str(exp[2])
    if exp[3] then
      str = str .. ", " .. exp2str(exp[3])
    end
    str = str .. " }"
  elseif tag == "Paren" then
    str = str .. "{ " .. exp2str(exp[1]) .. " }"
  elseif tag == "Call" then
    str = str .. "{ "
    str = str .. exp2str(exp[1])
    if exp[2] then
      for i=2, #exp do
        str = str .. ", " .. exp2str(exp[i])
      end
    end
    str = str .. " }"
  elseif tag == "Invoke" then
    str = str .. "{ "
    str = str .. exp2str(exp[1]) .. ", "
    str = str .. exp2str(exp[2])
    if exp[3] then
      for i=3, #exp do
        str = str .. ", " .. exp2str(exp[i])
      end
    end
    str = str .. " }"
  elseif tag == "Id" or
         tag == "Index" then
    str = var2str(exp)
  else
    error("expecting an expression, but got a " .. tag)
  end
  return str
end

function explist2str (explist)
  local l = {}
  for k, v in ipairs(explist) do
    l[k] = exp2str(v)
  end
  if #l > 0 then
    return "{ " .. table.concat(l, ", ") .. " }"
  else
    return ""
  end
end

function stm2str (stm)
  local tag = stm.tag
  local str = "`" .. tag
  if tag == "Do" then -- `Do{ stat* }
    local l = {}
    for k, v in ipairs(stm) do
      l[k] = stm2str(v)
    end
    str = str .. "{ " .. table.concat(l, ", ") .. " }"
  elseif tag == "Set" then
    str = str .. "{ "
    str = str .. varlist2str(stm[1]) .. ", "
    str = str .. explist2str(stm[2])
    str = str .. " }"
  elseif tag == "While" then
    str = str .. "{ "
    str = str .. exp2str(stm[1]) .. ", "
    str = str .. block2str(stm[2])
    str = str .. " }"
  elseif tag == "Repeat" then
    str = str .. "{ "
    str = str .. block2str(stm[1]) .. ", "
    str = str .. exp2str(stm[2])
    str = str .. " }"
  elseif tag == "If" then
    str = str .. "{ "
    local len = #stm
    if len % 2 == 0 then
      local l = {}
      for i=1,len-2,2 do
        str = str .. exp2str(stm[i]) .. ", " .. block2str(stm[i+1]) .. ", "
      end
      str = str .. exp2str(stm[len-1]) .. ", " .. block2str(stm[len])
    else
      local l = {}
      for i=1,len-3,2 do
        str = str .. exp2str(stm[i]) .. ", " .. block2str(stm[i+1]) .. ", "
      end
      str = str .. exp2str(stm[len-2]) .. ", " .. block2str(stm[len-1]) .. ", "
      str = str .. block2str(stm[len])
    end
    str = str .. " }"
  elseif tag == "Fornum" then
    str = str .. "{ "
    str = str .. var2str(stm[1]) .. ", "
    str = str .. exp2str(stm[2]) .. ", "
    str = str .. exp2str(stm[3]) .. ", "
    if stm[5] then
      str = str .. exp2str(stm[4]) .. ", "
      str = str .. block2str(stm[5])
    else
      str = str .. block2str(stm[4])
    end
    str = str .. " }"
  elseif tag == "Forin" then
    str = str .. "{ "
    str = str .. varlist2str(stm[1]) .. ", "
    str = str .. explist2str(stm[2]) .. ", "
    str = str .. block2str(stm[3])
    str = str .. " }"
  elseif tag == "Local" then
    str = str .. "{ "
    str = str .. varlist2str(stm[1])
    if #stm[2] > 0 then
      str = str .. ", " .. explist2str(stm[2])
    else
      str = str .. ", " .. "{  }"
    end
    str = str .. " }"
  elseif tag == "Localrec" then
    str = str .. "{ "
    str = str .. "{ " .. var2str(stm[1][1]) .. " }, "
    str = str .. "{ " .. exp2str(stm[2][1]) .. " }"
    str = str .. " }"
  elseif tag == "Goto" or
         tag == "Label" then
    str = str .. "{ " .. name2str(stm[1]) .. " }"
  elseif tag == "Return" then
    str = str .. explist2str(stm)
  elseif tag == "Break" then
  elseif tag == "Call" then
    str = str .. "{ "
    str = str .. exp2str(stm[1])
    if stm[2] then
      for i=2, #stm do
        str = str .. ", " .. exp2str(stm[i])
      end
    end
    str = str .. " }"
  elseif tag == "Invoke" then
    str = str .. "{ "
    str = str .. exp2str(stm[1]) .. ", "
    str = str .. exp2str(stm[2])
    if stm[3] then
      for i=3, #stm do
        str = str .. ", " .. exp2str(stm[i])
      end
    end
    str = str .. " }"
  elseif tag == "Interface" then
    str = str .. "{ "
    str = str .. stm[1] .. ", "
    str = str .. type2str(stm[2])
    str = str .. " }"
  elseif tag == "Unknown" then
    str = str .. "{ "
    str = str .. '"' .. tostring(stm[1]) .. '"'
    str = str .. " }"
  elseif tag == "Comment" then
    str = nil
  else
    error("expecting a statement, but got a " .. tag)
  end
  return str
end

function block2str (block)
  local l = {}
  for k, v in ipairs(block) do
    local val = stm2str(v)
    if val then table.insert(l, val) end
  end
  return "{ " .. table.concat(l, ", ") .. " }"
end

-- tostring : (block) -> (string)
function tlast.tostring (block)
  return block2str(block)
end

-- dump : (block, number?) -> ()
function tlast.dump (t, i)
  if i == nil then i = 0 end
  io.write(string.format("{\n"))
  for k, v in pairs(t) do
    if type(k) == "string" then
      io.write(string.format("%s[%s] = %s\n", string.rep(" ", i + 2), k, tostring(v)))
    end
  end
  for k, v in ipairs(t) do
    io.write(string.format("%s[%s] = ", string.rep(" ", i + 2), tostring(k)))
    if type(v) == "table" then
      tlast.dump(v, i + 2)
    else
      io.write(string.format("%s\n", tostring(v)))
    end
  end
  io.write(string.format("%s}\n", string.rep(" ", i)))
end

return tlast
