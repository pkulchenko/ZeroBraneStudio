-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Ini LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('ini')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  true false on off yes no
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, (lexer.alpha + '_') *
                                                   (lexer.alnum + S('_.'))^0))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'") +
                                           lexer.delimited_range('"')))

-- Labels.
lex:add_rule('label', token(lexer.LABEL,
                            lexer.delimited_range('[]', true, true)))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, lexer.starts_line(S(';#')) *
                                             lexer.nonnewline^0))

-- Numbers.
local dec = lexer.digit^1 * ('_' * lexer.digit^1)^0
local oct_num = '0' * S('01234567_')^1
local integer = S('+-')^-1 * (lexer.hex_num + oct_num + dec)
lex:add_rule('number', token(lexer.NUMBER, lexer.float + integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, '='))

return lex
