-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Gap LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('gap')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  and break continue do elif else end fail false fi for function if in infinity
  local not od or rec repeat return then true until while
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'", true) +
                                           lexer.delimited_range('"', true)))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.nonnewline^0))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.digit^1 * -lexer.alpha))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('*+-,./:;<=>~^#()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.KEYWORD, 'function', 'end')
lex:add_fold_point(lexer.KEYWORD, 'do', 'od')
lex:add_fold_point(lexer.KEYWORD, 'if', 'fi')
lex:add_fold_point(lexer.KEYWORD, 'repeat', 'until')
lex:add_fold_point(lexer.COMMENT, '#', lexer.fold_line_comments('#'))

return lex
