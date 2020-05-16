-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Vala LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('vala')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  class delegate enum errordomain interface namespace signal struct using
  -- Modifiers.
  abstract const dynamic extern inline out override private protected public ref
  static virtual volatile weak
  -- Other.
  as base break case catch construct continue default delete do else ensures
  finally for foreach get if in is lock new requires return set sizeof switch
  this throw throws try typeof value var void while
  -- Etc.
  null true false
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  bool char double float int int8 int16 int32 int64 long short size_t ssize_t
  string uchar uint uint8 uint16 uint32 uint64 ulong unichar ushort
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
local sq_str = lexer.delimited_range("'", true)
local dq_str = lexer.delimited_range('"', true)
local tq_str = '"""' * (lexer.any - '"""')^0 * P('"""')^-1
local ml_str = '@' * lexer.delimited_range('"', false, true)
lex:add_rule('string', token(lexer.STRING, tq_str + sq_str + dq_str + ml_str))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, (lexer.float + lexer.integer) *
                                           S('uUlLfFdDmM')^-1))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%<>!=^&|?~:;.()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
