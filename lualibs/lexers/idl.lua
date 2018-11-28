-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- IDL LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('idl')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  abstract attribute case const context custom default enum exception factory
  FALSE in inout interface local module native oneway out private public raises
  readonly struct support switch TRUE truncatable typedef union valuetype
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  any boolean char double fixed float long Object octet sequence short string
  unsigned ValueBase void wchar wstring
]]))

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
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Preprocessor.
local preproc_word = word_match[[
  define undef ifdef ifndef if elif else endif include warning pragma
]]
lex:add_rule('preproc', token(lexer.PREPROCESSOR, lexer.starts_line('#') *
                                                  preproc_word))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('!<>=+-/*%&|^~.,:;?()[]{}')))

return lex
