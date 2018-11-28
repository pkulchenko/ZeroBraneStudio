-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Java LPeg lexer.
-- Modified by Brian Schott.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('java')

-- Whitespace.
local ws = token(lexer.WHITESPACE, lexer.space^1)
lex:add_rule('whitespace', ws)

-- Classes.
lex:add_rule('classdef', token(lexer.KEYWORD, P('class')) * ws *
                         token(lexer.CLASS, lexer.word))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  abstract assert break case catch class const continue default do else enum
  extends final finally for goto if implements import instanceof interface
  native new package private protected public return static strictfp super
  switch synchronized this throw throws transient try while volatile
  -- Literals.
  true false null
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  boolean byte char double float int long short void
  Boolean Byte Character Double Float Integer Long Short String
]]))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, lexer.word) * #P('('))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'", true) +
                                           lexer.delimited_range('"', true)))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, (lexer.float + lexer.integer) *
                                           S('LlFfDd')^-1))

-- Annotations.
lex:add_rule('annotation', token('annotation', '@' * lexer.word))
lex:add_style('annotation', lexer.STYLE_PREPROCESSOR)

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%<>!=^&|?~:;.()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
