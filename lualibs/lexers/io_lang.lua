-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Io LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('io_lang')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  block method while foreach if else do super self clone proto setSlot hasSlot
  type write print forward
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  Block Buffer CFunction Date Duration File Future LinkedList List Map Message
  Nil Nop Number Object String WeakLink
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
local sq_str = lexer.delimited_range("'")
local dq_str = lexer.delimited_range('"')
local tq_str = '"""' * (lexer.any - '"""')^0 * P('"""')^-1
lex:add_rule('string', token(lexer.STRING, tq_str + sq_str + dq_str))

-- Comments.
local line_comment = (P('#') + '//') * lexer.nonnewline^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR,
                               S('`~@$%^&*-+/=\\<>?.,:;()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '(', ')')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
