-- Copyright 2015-2018 David B. Lamkins <david@lamkins.net>. See License.txt.
-- Faust LPeg lexer, see http://faust.grame.fr/

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('faust')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  declare import mdoctags dependencies distributed inputs outputs par seq sum
  prod xor with environment library component ffunction fvariable fconstant int
  float case waveform h: v: t:
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range('"', true)))

-- Comments.
local line_comment = '//' * lexer.nonnewline^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
local int = R('09')^1
local rad = P('.')
local exp = (P('e') * S('+-')^-1 * int)^-1
local flt = int * (rad * int)^-1 * exp + int^-1 * rad * int * exp
lex:add_rule('number', token(lexer.NUMBER, flt + int))

-- Pragmas.
lex:add_rule('pragma', token(lexer.PREPROCESSOR, P('<mdoc>') *
                                                 (lexer.any - P('</mdoc>'))^0 *
                                                 P('</mdoc>')^-1))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR,
                               S('+-/*%<>~!=^&|?~:;,.()[]{}@#$`\\\'')))

return lex
