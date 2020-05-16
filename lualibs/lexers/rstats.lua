-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- R LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('rstats')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  break else for if in next repeat return switch try while
  Inf NA NaN NULL FALSE TRUE
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  array character complex data.frame double factor function integer list logical
  matrix numeric vector
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'", true) +
                                           lexer.delimited_range('"', true)))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.nonnewline^0))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, (lexer.float + lexer.integer) *
                                           P('i')^-1))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('<->+*/^=.,:;|$()[]{}')))

return lex
