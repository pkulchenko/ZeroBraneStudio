-- Copyright 2017-2018 Michael Forney. See License.txt
-- Myrddin LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local lex = lexer.new('myrddin')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  break const continue elif else extern false for generic goto if impl in match
  pkg pkglocal sizeof struct trait true type union use var while
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  void bool char byte int uint int8 uint8 int16 uint16 int32 uint32 int64 uint64
  flt32 flt64
]] + '@' * lexer.word))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = P{
  V'part' * P'*/'^-1,
  part = '/*' * (V'full' + (lexer.any - '/*' - '*/'))^0,
  full = V'part' * '*/',
}
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'", true) +
                                           lexer.delimited_range('"', true)))

-- Numbers.
local digit = lexer.digit + '_'
local bdigit = R'01' + '_'
local xdigit = lexer.xdigit + '_'
local odigit = R'07' + '_'
local integer = '0x' * xdigit^1 + '0o' * odigit^1 + '0b' * bdigit^1 + digit^1
local float = digit^1 * (('.' * digit^1) * (S'eE' * S'+-'^-1 * digit^1)^-1 +
                         ('.' * digit^1)^-1 * S'eE' * S'+-'^-1 * digit^1)
lex:add_rule('number', token(lexer.NUMBER, float + integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S'`#_+-/*%<>~!=^&|~:;,.()[]{}'))

return lex
