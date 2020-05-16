-- Copyright 2016-2018 David B. Lamkins <david@lamkins.net>. See License.txt.
-- Protocol Buffer IDL LPeg lexer.
-- <https://developers.google.com/protocol-buffers/>

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('protobuf')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  contained syntax import option package message group oneof optional required
  repeated default extend extensions to max reserved service rpc returns
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  int32 int64 uint32 uint64 sint32 sint64 fixed32 fixed64 sfixed32 sfixed64
  float double bool string bytes enum true false
]]))

-- Strings.
local sq_str = P('L')^-1 * lexer.delimited_range("'", true)
local dq_str = P('L')^-1 * lexer.delimited_range('"', true)
lex:add_rule('string', token(lexer.STRING, sq_str + dq_str))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('<>=|;,.()[]{}')))

return lex
