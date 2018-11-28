-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- JavaScript LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('javascript')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  abstract boolean break byte case catch char class const continue debugger
  default delete do double else enum export extends false final finally float
  for function get goto if implements import in instanceof int interface let
  long native new null of package private protected public return set short
  static super switch synchronized this throw throws transient true try typeof
  var void volatile while with yield
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Strings.
local regex_str = #P('/') * lexer.last_char_includes('+-*%^!=&|?:;,([{<>') *
                  lexer.delimited_range('/', true) * S('igm')^0
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'") +
                                           lexer.delimited_range('"') +
                                           lexer.delimited_range('`')) +
                       token(lexer.REGEX, regex_str))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%^!=&|?:;,.()[]{}<>')))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
