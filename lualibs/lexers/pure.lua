-- Copyright 2015-2018 David B. Lamkins <david@lamkins.net>. See License.txt.
-- pure LPeg lexer, see http://purelang.bitbucket.org/

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('pure')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Comments.
local line_comment = '//' * lexer.nonnewline^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Pragmas.
local hashbang = lexer.starts_line('#!') * (lexer.nonnewline - '//')^0
lex:add_rule('pragma', token(lexer.PREPROCESSOR, hashbang))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  namespace with end using interface extern let const def type public private
  nonfix outfix infix infixl infixr prefix postfix if otherwise when case of
  then else
]]))

-- Numbers.
local bin = '0' * S('Bb') * S('01')^1
local hex = '0' * S('Xx') * (R('09') + R('af') + R('AF'))^1
local dec = R('09')^1
local int = (bin + hex + dec) * P('L')^-1
local rad = P('.') - '..'
local exp = (S('Ee') * S('+-')^-1 * int)^-1
local flt = int * (rad * dec)^-1 * exp + int^-1 * rad * dec * exp
lex:add_rule('number', token(lexer.NUMBER, flt + int))

-- Operators.
local punct = S('+-/*%<>~!=^&|?~:;,.()[]{}@#$`\\\'')
local dots = P('..')
lex:add_rule('operator', token(lexer.OPERATOR, dots + punct))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range('"', true)))

return lex
