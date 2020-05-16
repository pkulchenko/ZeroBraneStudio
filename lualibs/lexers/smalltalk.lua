-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Smalltalk LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('smalltalk')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  true false nil self super isNil not Smalltalk Transcript
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  Date Time Boolean True False Character String Array Symbol Integer Object
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'") +
                                           '$' * lexer.word))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT,
                              lexer.delimited_range('"', false, true)))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S(':=_<>+-/*!()[]')))

-- Labels.
lex:add_rule('label', token(lexer.LABEL, '#' * lexer.word))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '[', ']')

return lex
