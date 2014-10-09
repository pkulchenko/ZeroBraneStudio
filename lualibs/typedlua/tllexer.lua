--[[
This module implements Typed Lua lexer
]]

local tllexer = {}

local lpeg = require "lpeg"
lpeg.locale(lpeg)

local function getffp (s, i, t)
  return t.ffp or i, t
end

local function setffp (s, i, t, n)
  if not t.ffp or i > t.ffp then
    t.ffp = i
    t.list = {} ; t.list[n] = n
    t.expected = "'" .. n .. "'"
  elseif i == t.ffp then
    if not t.list[n] then
      t.list[n] = n
      t.expected = "'" .. n .. "', " .. t.expected
    end
  end
  return false
end

local function updateffp (name)
  return lpeg.Cmt(lpeg.Carg(1) * lpeg.Cc(name), setffp)
end

local function fix_str (str)
  str = string.gsub(str, "\\a", "\a")
  str = string.gsub(str, "\\b", "\b")
  str = string.gsub(str, "\\f", "\f")
  str = string.gsub(str, "\\n", "\n")
  str = string.gsub(str, "\\r", "\r")
  str = string.gsub(str, "\\t", "\t")
  str = string.gsub(str, "\\v", "\v")
  str = string.gsub(str, "\\\n", "\n")
  str = string.gsub(str, "\\\r", "\n")
  str = string.gsub(str, "\\'", "'")
  str = string.gsub(str, '\\"', '"')
  str = string.gsub(str, '\\\\', '\\')
  return str
end

tllexer.Shebang = lpeg.P("#") * (lpeg.P(1) - lpeg.P("\n"))^0 * lpeg.P("\n")

local Space = lpeg.space^1

local Equals = lpeg.P("=")^0
local Open = "[" * lpeg.Cg(Equals, "init") * "[" * lpeg.P("\n")^-1
local Close = "]" * lpeg.C(Equals) * "]"
local CloseEQ = lpeg.Cmt(Close * lpeg.Cb("init"),
                         function (s, i, a, b) return a == b end)

local LongString = Open * lpeg.C((lpeg.P(1) - CloseEQ)^0) * Close /
                   function (s, o) return s end

local LongComment = lpeg.P("--") * LongString / function () return end
local LineComment = lpeg.P("--") * (lpeg.P(1) - lpeg.P("\n"))^0 - LongComment

tllexer.Comment = (LongComment + LineComment) * Space^0
tllexer.Skip = (Space + LineComment)^0

local idStart = lpeg.alpha + lpeg.P("_")
local idRest = lpeg.alnum + lpeg.P("_")

local Keywords = lpeg.P("and") + "break" + "do" + "elseif" + "else" + "end" +
                 "false" + "for" + "function" + "goto" + "if" + "in" +
                 "local" + "nil" + "not" + "or" + "repeat" + "return" +
                 "then" + "true" + "until" + "while"

tllexer.Keywords = Keywords
tllexer.Reserved = Keywords * -idRest

local Identifier = idStart * idRest^0

tllexer.Name = -tllexer.Reserved * lpeg.C(Identifier) * -idRest

tllexer.leavecomment = true

function tllexer.token (pat, name, leavecomment)
  return (leavecomment and lpeg.P(true) or (Space + LongComment)^0) * pat * tllexer.Skip
    + updateffp(name) * lpeg.P(false)
end

function tllexer.symb (str, leavecomment)
  return tllexer.token(lpeg.P(str), str, leavecomment)
end

function tllexer.kw (str, leavecomment)
  return tllexer.token(lpeg.P(str) * -idRest, str, leavecomment)
end

function tllexer.lcwrap (pat, leavecomment)
  return (lpeg.P("--") * Open * Space^0 * (pat - CloseEQ) * Space^0 * (Close / function() return end)
         + (leavecomment and lpeg.P(true) or LongComment^0) * pat) * tllexer.Skip
end

local Hex = (lpeg.P("0x") + lpeg.P("0X")) * lpeg.xdigit^1
local Expo = lpeg.S("eE") * lpeg.S("+-")^-1 * lpeg.digit^1
local Float = (((lpeg.digit^1 * lpeg.P(".") * lpeg.digit^0) +
              (lpeg.P(".") * lpeg.digit^1)) * Expo^-1) +
              (lpeg.digit^1 * Expo)
local Int = lpeg.digit^1

tllexer.Number = lpeg.C(Hex + Float + Int) / tonumber

local ShortString = lpeg.P('"') *
                    lpeg.C(((lpeg.P('\\') * lpeg.P(1)) + (lpeg.P(1) - lpeg.P('"')))^0) *
                    lpeg.P('"') +
                    lpeg.P("'") *
                    lpeg.C(((lpeg.P("\\") * lpeg.P(1)) + (lpeg.P(1) - lpeg.P("'")))^0) *
                    lpeg.P("'")

tllexer.String = LongString + (ShortString / fix_str)

-- for error reporting
local OneWord = tllexer.Name + tllexer.Number + tllexer.String + tllexer.Reserved + lpeg.P("...") + lpeg.P(1)

local function lineno (s, i)
  if i == 1 then return 1, 1 end
  local rest, num = s:sub(1,i):gsub("[^\n]*\n", "")
  local r = #rest
  return 1 + num, r ~= 0 and r or 1
end

function tllexer.syntaxerror (subject, pos, filename, msg)
  local l, c = lineno(subject, pos)
  local error_msg = "%s:%d:%d: syntax error, %s"
  return string.format(error_msg, filename, l, c, msg)
end

local function geterrorinfo ()
  return lpeg.Cmt(lpeg.Carg(1), getffp) * (lpeg.C(OneWord) + lpeg.Cc("EOF")) /
  function (t, u)
    t.unexpected = u
    return t
  end
end

local function errormsg ()
  return geterrorinfo() /
  function (t)
    local p = t.ffp or 1
    local msg = "unexpected '%s', expecting %s"
    msg = string.format(msg, t.unexpected, t.expected)
    return nil, tllexer.syntaxerror(t.subject, p, t.filename, msg)
  end
end

function tllexer.report_error ()
  return errormsg()
end

return tllexer
