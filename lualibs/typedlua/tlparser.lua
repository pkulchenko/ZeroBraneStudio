--[[
This module implements Typed Lua parser
]]

local tlparser = {}

local lpeg = require "lpeg"
lpeg.locale(lpeg)

local tlast = require "typedlua.tlast"
local tllexer = require "typedlua.tllexer"
local tlst = require "typedlua.tlst"
local tltype = require "typedlua.tltype"

local function chainl1 (pat, sep)
  return lpeg.Cf(pat * lpeg.Cg(sep * pat)^0, tlast.exprBinaryOp)
end

-- for relaxed processing

local function recover (p, msg)
  return p + lpeg.Cmt(lpeg.Carg(1) * lpeg.Carg(3), function (s, i, e, recover)
    if recover then e.warnings[i] = msg end
    return recover
  end)
end

local function unknown (p)
  local level = 0
  local enter = lpeg.Cmt(lpeg.P(true), function() level = level + 1 return true end)
  local leave = lpeg.Cmt(lpeg.P(true), function() level = level - 1 return true end)
    * (lpeg.P(1) - lpeg.P(1))
  return lpeg.Cmt(enter * p
    + lpeg.Cmt(lpeg.Carg(1) * lpeg.Carg(3) * lpeg.C(lpeg.P(1)), function(s,i,t,r,m)
          if not r
          or level ~= 1 and lpeg.match(tllexer.Keywords,s,i-1) then return false end
          table.insert(t.unknown, i)
          return true, tlast.unknown(i, m)
        end)
    + leave, function(s, p, ...) level = level - 1 return p, ... end)
end

local G = lpeg.P { "TypedLua";
  TypedLua = tllexer.Shebang^-1 * tllexer.Skip * lpeg.V("Chunk") * -1 +
             tllexer.report_error();
  -- type language
  Type = lpeg.V("NilableType");
  NilableType = lpeg.V("UnionType") * (tllexer.symb("?") * lpeg.Cc(true))^-1 /
                tltype.UnionNil;
  UnionType = lpeg.V("PrimaryType") * (lpeg.Cg(tllexer.symb("|") * lpeg.V("PrimaryType"))^0) /
              tltype.Union;
  PrimaryType = lpeg.V("LiteralType") +
                lpeg.V("BaseType") +
                lpeg.V("NilType") +
                lpeg.V("ValueType") +
                lpeg.V("AnyType") +
                lpeg.V("SelfType") +
                lpeg.V("FunctionType") +
                lpeg.V("TableType") +
                lpeg.V("VariableType");
  LiteralType = ((tllexer.token("false", "Type") * lpeg.Cc(false)) +
                (tllexer.token("true", "Type") * lpeg.Cc(true)) +
                tllexer.token(tllexer.Number, "Type") +
                tllexer.token(tllexer.String, "Type")) /
                tltype.Literal;
  BaseType = tllexer.token("boolean", "Type") / tltype.Boolean +
             tllexer.token("number", "Type") / tltype.Number +
             tllexer.token("string", "Type") / tltype.String;
  NilType = tllexer.token("nil", "Type") / tltype.Nil;
  ValueType = tllexer.token("value", "Type") / tltype.Value;
  AnyType = tllexer.token("any", "Type") / tltype.Any;
  SelfType = tllexer.token("self", "Type") / tltype.Self;
  FunctionType = lpeg.V("InputType") * tllexer.symb("->") * lpeg.V("NilableTuple") /
                 tltype.Function;
  MethodType = lpeg.V("InputType") * tllexer.symb("=>") * lpeg.V("NilableTuple") *
               lpeg.Cc(true) / tltype.Function;
  InputType = tllexer.symb("(") * (lpeg.V("TupleType") + lpeg.Cc(nil)) * tllexer.symb(")") *
              lpeg.Carg(2) /
              tltype.inputTuple;
  NilableTuple = lpeg.V("UnionlistType") * (tllexer.symb("?") * lpeg.Carg(2))^-1 /
                 tltype.UnionlistNil;
  UnionlistType = lpeg.V("OutputType") * (lpeg.Cg(tllexer.symb("|") * lpeg.V("OutputType"))^0) /
                  tltype.Unionlist;
  OutputType = tllexer.symb("(") * (lpeg.V("TupleType") + lpeg.Cc(nil)) * tllexer.symb(")") *
               lpeg.Carg(2) /
               tltype.outputTuple;
  TupleType = lpeg.Ct(lpeg.V("Type") * (tllexer.symb(",") * lpeg.V("Type"))^0) *
              (tllexer.symb("*") * lpeg.Cc(true))^-1 /
              tltype.Tuple;
  TableType = tllexer.symb("{") * lpeg.V("TableTypeBody") * tllexer.symb("}") /
              tltype.Table;
  TableTypeBody = lpeg.V("RecordType") +
                  lpeg.V("HashType") +
                  lpeg.V("ArrayType") +
                  lpeg.Cc(nil);
  RecordType = lpeg.V("RecordField") * (tllexer.symb(",") * lpeg.V("RecordField"))^0 *
               (tllexer.symb(",") * (lpeg.V("HashType") + lpeg.V("ArrayType")))^-1;
  RecordField = ((tllexer.kw("const") * lpeg.Cc(true)) + lpeg.Cc(false)) *
                lpeg.V("LiteralType") * tllexer.symb(":") * lpeg.V("Type") /
                tltype.Field;
  HashType = lpeg.Cc(false) * lpeg.V("KeyType") * tllexer.symb(":") * lpeg.V("FieldType") /
             tltype.Field;
  ArrayType = lpeg.Cc(false) * lpeg.Cc(tltype.Number()) * lpeg.V("FieldType") /
              tltype.Field;
  KeyType = lpeg.V("BaseType") + lpeg.V("ValueType") + lpeg.V("AnyType");
  FieldType = lpeg.V("Type") * lpeg.Cc(tltype.Nil()) / tltype.Union;
  VariableType = tllexer.token(tllexer.Name, "Type") / tltype.Variable;
  RetType = lpeg.V("NilableTuple") +
            lpeg.V("Type") * lpeg.Carg(2) / tltype.retType;
  Id = lpeg.Cp() * tllexer.token(tllexer.Name, "Name") / tlast.ident;
  TypeDecId = (tllexer.kw("const") * lpeg.V("Id") / tlast.setConst) +
              lpeg.V("Id");
  IdList = lpeg.Cp() * lpeg.V("TypeDecId") * (tllexer.symb(",") * lpeg.V("TypeDecId"))^0 /
           tlast.namelist;
  IdDec = lpeg.V("IdList") * tllexer.symb(":") *
          (lpeg.V("Type") + lpeg.V("MethodType")) / tltype.fieldlist;
  IdDecList = (lpeg.V("IdDec")^1 + lpeg.Cc(nil)) / tltype.Table;
  TypeDec = tllexer.token(tllexer.Name, "Name") * lpeg.V("IdDecList") * tllexer.kw("end");
  Interface = lpeg.Cp() * tllexer.kw("interface") * lpeg.V("TypeDec") /
              tlast.statInterface;
  -- parser
  Chunk = lpeg.V("Block");
  StatList = (tllexer.symb(";") + unknown(lpeg.V("Stat")))^0;
  Var = lpeg.V("Id");
  TypedId = lpeg.Cp() * tllexer.token(tllexer.Name, "Name") * tllexer.lcwrap(tllexer.symb(":", tllexer.leavecomment) *
            lpeg.V("Type"))^-1 / tlast.ident;
  FunctionDef = tllexer.kw("function") * lpeg.V("FuncBody");
  FieldSep = tllexer.symb(",") + tllexer.symb(";");
  Field = lpeg.Cp() *
          ((tllexer.symb("[") * lpeg.V("Expr") * recover(tllexer.symb("]"), "closing ]")) +
          (lpeg.Cp() * tllexer.token(tllexer.Name, "Name") / tlast.exprString)) *
          tllexer.symb("=") * lpeg.V("Expr") / tlast.fieldPair +
          lpeg.V("Expr");
  TField = (tllexer.kw("const") * lpeg.V("Field") / tlast.setConst) +
           lpeg.V("Field");
  FieldList = (lpeg.V("TField") * (lpeg.V("FieldSep") * lpeg.V("TField"))^0 *
              lpeg.V("FieldSep")^-1)^-1;
  Constructor = lpeg.Cp() * tllexer.symb("{") * lpeg.V("FieldList") * recover(tllexer.symb("}"), "closing }") / tlast.exprTable;
  NameList = lpeg.Cp() * lpeg.V("TypedId") * (tllexer.symb(",") * lpeg.V("TypedId"))^0 /
             tlast.namelist;
  ExpList = lpeg.Cp() * lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^0 /
            tlast.explist;
  FuncArgs = tllexer.symb("(") *
             (lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^0)^-1 *
             recover(tllexer.symb(")"), "closing )") +
             lpeg.V("Constructor") +
             lpeg.Cp() * tllexer.token(tllexer.String, "String") / tlast.exprString;
  OrOp = tllexer.kw("or") / "or";
  AndOp = tllexer.kw("and") / "and";
  RelOp = tllexer.symb("~=") / "ne" +
          tllexer.symb("==") / "eq" +
          tllexer.symb("<=") / "le" +
          tllexer.symb(">=") / "ge" +
          tllexer.symb("<") / "lt" +
          tllexer.symb(">") / "gt";
  ConOp = tllexer.symb("..") / "concat";
  AddOp = tllexer.symb("+") / "add" +
          tllexer.symb("-") / "sub";
  MulOp = tllexer.symb("*") / "mul" +
          tllexer.symb("/") / "div" +
          tllexer.symb("%") / "mod";
  UnOp = tllexer.kw("not") / "not" +
         tllexer.symb("-") / "unm" +
         tllexer.symb("#") / "len";
  PowOp = tllexer.symb("^") / "pow";
  Expr = lpeg.V("SubExpr_1");
  SubExpr_1 = chainl1(lpeg.V("SubExpr_2"), lpeg.V("OrOp"));
  SubExpr_2 = chainl1(lpeg.V("SubExpr_3"), lpeg.V("AndOp"));
  SubExpr_3 = chainl1(lpeg.V("SubExpr_4"), lpeg.V("RelOp"));
  SubExpr_4 = lpeg.V("SubExpr_5") * lpeg.V("ConOp") * lpeg.V("SubExpr_4") /
              tlast.exprBinaryOp +
              lpeg.V("SubExpr_5");
  SubExpr_5 = chainl1(lpeg.V("SubExpr_6"), lpeg.V("AddOp"));
  SubExpr_6 = chainl1(lpeg.V("SubExpr_7"), lpeg.V("MulOp"));
  SubExpr_7 = lpeg.V("UnOp") * lpeg.V("SubExpr_7") / tlast.exprUnaryOp +
              lpeg.V("SubExpr_8");
  SubExpr_8 = lpeg.V("SimpleExp") * (lpeg.V("PowOp") * lpeg.V("SubExpr_7"))^-1 /
              tlast.exprBinaryOp;
  SimpleExp = lpeg.Cp() * tllexer.token(tllexer.Number, "Number") / tlast.exprNumber +
              lpeg.Cp() * tllexer.token(tllexer.String, "String") / tlast.exprString +
              lpeg.Cp() * tllexer.kw("nil") / tlast.exprNil +
              lpeg.Cp() * tllexer.kw("false") / tlast.exprFalse +
              lpeg.Cp() * tllexer.kw("true") / tlast.exprTrue +
              lpeg.Cp() * tllexer.symb("...") / tlast.exprDots +
              lpeg.V("FunctionDef") +
              lpeg.V("Constructor") +
              lpeg.V("SuffixedExp");
  SuffixedExp = lpeg.Cf(lpeg.V("PrimaryExp") * (
                (lpeg.Cp() * tllexer.symb(".") *
                  (lpeg.Cp() * tllexer.token(tllexer.Name, "Name") / tlast.exprString)) /
                  tlast.exprIndex +
                (lpeg.Cp() * tllexer.symb("[") * lpeg.V("Expr") * recover(tllexer.symb("]"), "closing ]")) /
                tlast.exprIndex +
                (lpeg.Cp() * lpeg.Cg(tllexer.symb(":") *
                   (lpeg.Cp() * tllexer.token(tllexer.Name, "Name") / tlast.exprString) *
                   lpeg.V("FuncArgs"))) / tlast.invoke +
                (lpeg.Cp() * lpeg.V("FuncArgs")) / tlast.call)^0, tlast.exprSuffixed);
  PrimaryExp = lpeg.V("Var") +
               lpeg.Cp() * tllexer.symb("(") * lpeg.V("Expr") * recover(tllexer.symb(")"), "closing )") / tlast.exprParen;
  Block = lpeg.Cp() * lpeg.V("StatList") * lpeg.V("RetStat")^-1 / tlast.block;
  IfStat = lpeg.Cp() * tllexer.kw("if", tllexer.leavecomment) * lpeg.V("Expr") * tllexer.kw("then") * lpeg.V("Block") *
           (tllexer.kw("elseif") * lpeg.V("Expr") * tllexer.kw("then") * lpeg.V("Block"))^0 *
           (tllexer.kw("else") * lpeg.V("Block"))^-1 *
           recover(tllexer.kw("end"), "if end") / tlast.statIf;
  WhileStat = lpeg.Cp() * tllexer.kw("while", tllexer.leavecomment) * lpeg.V("Expr") *
              tllexer.kw("do") * lpeg.V("Block") * recover(tllexer.kw("end"), "while end") / tlast.statWhile;
  DoStat = tllexer.kw("do", tllexer.leavecomment) * lpeg.V("Block") * recover(tllexer.kw("end"), "do end") / tlast.statDo;
  ForBody = tllexer.kw("do") * lpeg.V("Block");
  ForNum = lpeg.Cp() *
           lpeg.V("Id") * tllexer.symb("=") * lpeg.V("Expr") * tllexer.symb(",") *
           lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^-1 *
           lpeg.V("ForBody") / tlast.statFornum;
  ForGen = lpeg.Cp() * lpeg.V("NameList") * tllexer.kw("in") *
           lpeg.V("ExpList") * lpeg.V("ForBody") / tlast.statForin;
  ForStat = tllexer.kw("for", tllexer.leavecomment) * (lpeg.V("ForNum") + lpeg.V("ForGen")) * tllexer.kw("end");
  RepeatStat = lpeg.Cp() * tllexer.kw("repeat", tllexer.leavecomment) * lpeg.V("Block") *
               tllexer.kw("until") * lpeg.V("Expr") / tlast.statRepeat;
  FuncName = lpeg.Cf(lpeg.V("Id") * (tllexer.symb(".") *
             (lpeg.Cp() * tllexer.token(tllexer.Name, "Name") / tlast.exprString))^0, tlast.funcName) *
             (tllexer.symb(":") * (lpeg.Cp() * tllexer.token(tllexer.Name, "Name") /
             tlast.exprString) *
               lpeg.Cc(true))^-1 /
             tlast.funcName;
  ParList = lpeg.Cp() * lpeg.V("NameList") * (tllexer.symb(",") * lpeg.V("TypedVarArg"))^-1 /
            tlast.parList2 +
            lpeg.Cp() * lpeg.V("TypedVarArg") / tlast.parList1 +
            lpeg.Cp() / tlast.parList0;
  TypedVarArg = lpeg.Cp() * tllexer.symb("...") * (tllexer.symb(":") * lpeg.V("Type"))^-1 /
                tlast.identDots;
  FuncBody = lpeg.Cp() * tllexer.symb("(") * lpeg.V("ParList") * recover(tllexer.symb(")"), "closing )") *
             tllexer.lcwrap(tllexer.symb(":", tllexer.leavecomment) * lpeg.V("RetType"))^-1 *
             lpeg.V("Block") * recover(tllexer.kw("end"), "function end") / tlast.exprFunction;
  FuncStat = lpeg.Cp() * tllexer.lcwrap(tllexer.kw("const", tllexer.leavecomment) * lpeg.Cc(true) + lpeg.Cc(false), tllexer.leavecomment) *
             tllexer.kw("function", tllexer.leavecomment) * lpeg.V("FuncName") * lpeg.V("FuncBody") /
             tlast.statFuncSet;
  LocalFunc = lpeg.Cp() * tllexer.kw("function") *
              lpeg.V("Id") * lpeg.V("FuncBody") / tlast.statLocalrec;
  LocalAssign = lpeg.Cp() * lpeg.V("NameList") *
                ((tllexer.symb("=") * lpeg.V("ExpList")) + lpeg.Ct(lpeg.Cc())) / tlast.statLocal;
  LocalStat = tllexer.lcwrap(tllexer.kw("local", tllexer.leavecomment) * lpeg.V("LocalTypeDec"), tllexer.leavecomment) +
              tllexer.kw("local", tllexer.leavecomment) * (lpeg.V("LocalFunc") + lpeg.V("LocalAssign"));
  LabelStat = lpeg.Cp() * tllexer.symb("::", tllexer.leavecomment) * tllexer.token(tllexer.Name, "Name") * tllexer.symb("::") / tlast.statLabel;
  BreakStat = lpeg.Cp() * tllexer.kw("break", tllexer.leavecomment) / tlast.statBreak;
  GoToStat = lpeg.Cp() * tllexer.kw("goto", tllexer.leavecomment) * tllexer.token(tllexer.Name, "Name") / tlast.statGoto;
  RetStat = lpeg.Cp() * tllexer.kw("return", tllexer.leavecomment) *
            (lpeg.V("Expr") * (tllexer.symb(",") * lpeg.V("Expr"))^0)^-1 *
            tllexer.symb(";")^-1 / tlast.statReturn;
  TypeDecStat = tllexer.lcwrap(lpeg.V("Interface"), tllexer.leavecomment);
  CommentStat = lpeg.Cp() * lpeg.C(tllexer.Comment) / tlast.comment;
  LocalTypeDec = lpeg.V("TypeDecStat") / tlast.statLocalTypeDec;
  LVar = (tllexer.kw("const") * lpeg.V("SuffixedExp") / tlast.setConst) +
         lpeg.V("SuffixedExp");
  ExprStat = lpeg.Cmt(
             (lpeg.V("LVar") * (lpeg.Cc(tlast.statSet) * lpeg.V("Assignment"))) +
             (lpeg.V("SuffixedExp") * (lpeg.Cc(tlast.statApply))),
             function (s, i, s1, f, ...) return f(s1, ...) end);
  Assignment = ((tllexer.symb(",") * lpeg.V("LVar"))^1)^-1 * tllexer.symb("=") * lpeg.V("ExpList");
  Stat = lpeg.V("IfStat") + lpeg.V("WhileStat") + lpeg.V("DoStat") + lpeg.V("ForStat") +
         lpeg.V("RepeatStat") + lpeg.V("FuncStat") + lpeg.V("LocalStat") +
         lpeg.V("LabelStat") + lpeg.V("BreakStat") + lpeg.V("GoToStat") +
         lpeg.V("TypeDecStat") + lpeg.V("ExprStat") + lpeg.V("CommentStat");
}

local traverse_stm, traverse_exp, traverse_var
local traverse_block, traverse_explist, traverse_varlist, traverse_parlist

function traverse_parlist (env, parlist)
  local len = #parlist
  if len > 0 and parlist[len].tag == "Dots" then
    local t = parlist[len][1] or tltype.Any()
    tlst.set_vararg(env, t)
    len = len - 1
  end
  for i = 1, len do
    tlst.set_local(env, parlist[i])
  end
  return true
end

local function traverse_function (env, exp)
  tlst.begin_function(env)
  tlst.begin_scope(env)
  local status, msg = traverse_parlist(env, exp[1])
  if not status then return status, msg end
  if not exp[3] then
    status, msg = traverse_block(env, exp[2])
    if not status then return status, msg end
  else
    status, msg = traverse_block(env, exp[3])
    if not status then return status, msg end
  end
  tlst.end_scope(env)
  tlst.end_function(env)
  return true
end

local function traverse_op (env, exp)
  local status, msg = traverse_exp(env, exp[2])
  if not status then return status, msg end
  if exp[3] then
    status, msg = traverse_exp(env, exp[3])
    if not status then return status, msg end
  end
  return true
end

local function traverse_paren (env, exp)
  local status, msg = traverse_exp(env, exp[1])
  if not status then return status, msg end
  return true
end

local function traverse_table (env, fieldlist)
  for k, v in ipairs(fieldlist) do
    local tag = v.tag
    if tag == "Pair" or tag == "Const" then
      local status, msg = traverse_exp(env, v[1])
      if not status then return status, msg end
      status, msg = traverse_exp(env, v[2])
      if not status then return status, msg end
    else
      local status, msg = traverse_exp(env, v)
      if not status then return status, msg end
    end
  end
  return true
end

local function traverse_vararg (env, exp)
  if not tlst.is_vararg(env) then
    local msg = "cannot use '...' outside a vararg function"
    return nil, tllexer.syntaxerror(env.subject, exp.pos, env.filename, msg)
  end
  return true
end

local function traverse_call (env, call)
  local status, msg = traverse_exp(env, call[1])
  if not status then return status, msg end
  for i=2, #call do
    status, msg = traverse_exp(env, call[i])
    if not status then return status, msg end
  end
  return true
end

local function traverse_invoke (env, invoke)
  local status, msg = traverse_exp(env, invoke[1])
  if not status then return status, msg end
  for i=3, #invoke do
    status, msg = traverse_exp(env, invoke[i])
    if not status then return status, msg end
  end
  return true
end

local function traverse_assignment (env, stm)
  local status, msg = traverse_varlist(env, stm[1])
  if not status then return status, msg end
  status, msg = traverse_explist(env, stm[2])
  if not status then return status, msg end
  return true
end

local function traverse_const_assignment (env, stm)
  local status, msg = traverse_var(env, stm[1])
  if not status then return status, msg end
  status, msg = traverse_exp(env, stm[2])
  if not status then return status, msg end
  return true
end

local function traverse_break (env, stm)
  if not tlst.insideloop(env) then
    local msg = "<break> not inside a loop"
    return nil, tllexer.syntaxerror(env.subject, stm.pos, env.filename, msg)
  end
  return true
end

local function traverse_forin (env, stm)
  tlst.begin_loop(env)
  tlst.begin_scope(env)
  for k, v in ipairs(stm[1]) do
    tlst.set_local(env, v)
  end
  local status, msg = traverse_explist(env, stm[2])
  if not status then return status, msg end
  status, msg = traverse_block(env, stm[3])
  if not status then return status, msg end
  tlst.end_scope(env)
  tlst.end_loop(env)
  return true
end

local function traverse_fornum (env, stm)
  local status, msg
  tlst.begin_loop(env)
  tlst.begin_scope(env)
  tlst.set_local(env, stm[1])
  status, msg = traverse_exp(env, stm[2])
  if not status then return status, msg end
  status, msg = traverse_exp(env, stm[3])
  if not status then return status, msg end
  if stm[5] then
    status, msg = traverse_exp(env, stm[4])
    if not status then return status, msg end
    status, msg = traverse_block(env, stm[5])
    if not status then return status, msg end
  else
    status, msg = traverse_block(env, stm[4])
    if not status then return status, msg end
  end
  tlst.end_scope(env)
  tlst.end_loop(env)
  return true
end

local function traverse_goto (env, stm)
  tlst.set_pending_goto(env, stm)
  return true
end

local function traverse_if (env, stm)
  local len = #stm
  if len % 2 == 0 then
    for i=1, len, 2 do
      local status, msg = traverse_exp(env, stm[i])
      if not status then return status, msg end
      status, msg = traverse_block(env, stm[i+1])
      if not status then return status, msg end
    end
  else
    for i=1, len-1, 2 do
      local status, msg = traverse_exp(env, stm[i])
      if not status then return status, msg end
      status, msg = traverse_block(env, stm[i+1])
      if not status then return status, msg end
    end
    local status, msg = traverse_block(env, stm[len])
    if not status then return status, msg end
  end
  return true
end

local function traverse_label (env, stm)
  if not tlst.set_label(env, stm[1]) then
    local msg = string.format("label '%s' already defined", stm[1])
    return nil, tllexer.syntaxerror(env.subject, stm.pos, env.filename, msg)
  else
    return true
  end
end

local function traverse_local (env, stm)
  local status, msg = traverse_explist(env, stm[2])
  if not status then return status, msg end
  for k, v in ipairs(stm[1]) do
    tlst.set_local(env, v)
  end
  return true
end

local function traverse_localrec (env, stm)
  tlst.set_local(env, stm[1][1])
  local status, msg = traverse_exp(env, stm[2][1])
  if not status then return status, msg end
  return true
end

local function traverse_repeat (env, stm)
  tlst.begin_loop(env)
  local status, msg = traverse_block(env, stm[1])
  if not status then return status, msg end
  status, msg = traverse_exp(env, stm[2])
  if not status then return status, msg end
  tlst.end_loop(env)
  return true
end

local function traverse_return (env, stm)
  local status, msg = traverse_explist(env, stm)
  if not status then return status, msg end
  return true
end

local function traverse_while (env, stm)
  tlst.begin_loop(env)
  local status, msg = traverse_exp(env, stm[1])
  if not status then return status, msg end
  status, msg = traverse_block(env, stm[2])
  if not status then return status, msg end
  tlst.end_loop(env)
  return true
end

local function traverse_interface (env, stm)
  local name, t = stm[1], stm[2]
  local status, msg = tltype.checkTypeDec(name, t)
  if not status then
    return nil, tllexer.syntaxerror(env.subject, stm.pos, env.filename, msg)
  end
  if tltype.checkRecursive(t, name) then
    stm[2] = tltype.Recursive(name, t)
  end
  return true
end

function traverse_var (env, var)
  local tag = var.tag
  if tag == "Id" then
    if not tlst.get_local(env, var[1]) then
      local e1 = tlast.ident(var.pos, "_ENV")
      local e2 = tlast.exprString(var.pos, var[1])
      var.tag = "Index"
      var[1] = e1
      var[2] = e2
    end
    return true
  elseif tag == "Index" then
    local status, msg = traverse_exp(env, var[1])
    if not status then return status, msg end
    status, msg = traverse_exp(env, var[2])
    if not status then return status, msg end
    return true
  else
    error("trying to traverse a variable, but got a " .. tag)
  end
end

function traverse_varlist (env, varlist)
  for k, v in ipairs(varlist) do
    local status, msg = traverse_var(env, v)
    if not status then return status, msg end
  end
  return true
end

function traverse_exp (env, exp)
  local tag = exp.tag
  if tag == "Nil" or
     tag == "True" or
     tag == "False" or
     tag == "Number" or
     tag == "String" then
    return true
  elseif tag == "Dots" then
    return traverse_vararg(env, exp)
  elseif tag == "Function" then
    return traverse_function(env, exp)
  elseif tag == "Table" then
    return traverse_table(env, exp)
  elseif tag == "Op" then
    return traverse_op(env, exp)
  elseif tag == "Paren" then
    return traverse_paren(env, exp)
  elseif tag == "Call" then
    return traverse_call(env, exp)
  elseif tag == "Invoke" then
    return traverse_invoke(env, exp)
  elseif tag == "Id" or
         tag == "Index" then
    return traverse_var(env, exp)
  else
    error("trying to traverse an expression, but got a " .. tag)
  end
end

function traverse_explist (env, explist)
  for k, v in ipairs(explist) do
    local status, msg = traverse_exp(env, v)
    if not status then return status, msg end
  end
  return true
end

function traverse_stm (env, stm)
  local tag = stm.tag
  if tag == "Do" then
    return traverse_block(env, stm)
  elseif tag == "Set" then
    return traverse_assignment(env, stm)
  elseif tag == "ConstSet" then
    return traverse_const_assignment(env, stm)
  elseif tag == "While" then
    return traverse_while(env, stm)
  elseif tag == "Repeat" then
    return traverse_repeat(env, stm)
  elseif tag == "If" then
    return traverse_if(env, stm)
  elseif tag == "Fornum" then
    return traverse_fornum(env, stm)
  elseif tag == "Forin" then
    return traverse_forin(env, stm)
  elseif tag == "Local" then
    return traverse_local(env, stm)
  elseif tag == "Localrec" then
    return traverse_localrec(env, stm)
  elseif tag == "Goto" then
    return traverse_goto(env, stm)
  elseif tag == "Label" then
    return traverse_label(env, stm)
  elseif tag == "Return" then
    return traverse_return(env, stm)
  elseif tag == "Break" then
    return traverse_break(env, stm)
  elseif tag == "Call" then
    return traverse_call(env, stm)
  elseif tag == "Invoke" then
    return traverse_invoke(env, stm)
  elseif tag == "Interface" then
    return traverse_interface(env, stm)
  elseif tag == "Unknown" then
    return true
  elseif tag == "Comment" then
    return true
  else
    error("trying to traverse a statement, but got a " .. tag)
  end
end

function traverse_block (env, block)
  local l = {}
  tlst.begin_scope(env)
  for k, v in ipairs(block) do
    local status, msg = traverse_stm(env, v)
    if not status then return status, msg end
  end
  tlst.end_scope(env)
  return true
end

local function verify_pending_gotos (env)
  for s = tlst.get_maxscope(env), 1, -1 do
    for k, v in ipairs(tlst.get_pending_gotos(env, s)) do
      local l = v[1]
      if not tlst.exist_label(env, s, l) then
        local msg = string.format("no visible label '%s' for <goto>", l)
        return nil, tllexer.syntaxerror(env.subject, v.pos, env.filename, msg)
      end
    end
  end
  return true
end

local function traverse (ast, errorinfo, strict)
  assert(type(ast) == "table")
  assert(type(errorinfo) == "table")
  assert(type(strict) == "boolean")
  local env = tlst.new_env(errorinfo.subject, strict)
  env.filename = errorinfo.filename
  local _env = tlast.ident(0, "_ENV")
  tlst.begin_function(env)
  tlst.set_vararg(env, tltype.String())
  tlst.begin_scope(env)
  tlst.set_local(env, _env)
  for k, v in ipairs(ast) do
    local status, msg = traverse_stm(env, v)
    if not status then return status, msg end
  end
  tlst.end_scope(env)
  tlst.end_function(env)
  status, msg = verify_pending_gotos(env)
  if not status then return status, msg end
  return ast, errorinfo
end

function tlparser.parse (subject, filename, strict, relaxed)
  local errorinfo = { subject = subject, filename = filename, warnings = {}, unknown = {} }
  lpeg.setmaxstack(1000)
  local ast, error_msg = lpeg.match(G, subject, nil, errorinfo, strict, relaxed or false)
  if not ast then return ast, error_msg end
  return traverse(ast, errorinfo, strict)
end

return tlparser
