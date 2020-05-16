-- Copyright 2015-2018 Alejandro Baez (https://keybase.io/baez). See License.txt.
-- Rust LPeg lexer.

local lexer = require("lexer")
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('rust')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  abstract alignof as become box break const continue crate do else enum extern
  false final fn for if impl in let loop macro match mod move mut offsetof
  override priv proc pub pure ref return Self self sizeof static struct super
  trait true type typeof unsafe unsized use virtual where while yield
]]))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, lexer.word^1 * S("!")))

-- Library types
lex:add_rule('library', token(lexer.LABEL, lexer.upper *
                                           (lexer.lower + lexer.dec_num)^1))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
 () bool isize usize char str u8 u16 u32 u64 i8 i16 i32 i64 f32 f64
]]))

-- Strings.
local sq_str = P('L')^-1 * lexer.delimited_range("'")
local dq_str = P('L')^-1 * lexer.delimited_range('"')
local raw_str = '#"' * (lexer.any - '#')^0 * P('#')^-1
lex:add_rule('string', token(lexer.STRING, dq_str + raw_str))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER,
                             lexer.float +
                             P('0b')^-1 * (lexer.dec_num + "_")^1 +
                             lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR,
                               S('+-/*%<>!=`^~@&|?#~:;,.()[]{}')))

-- Attributes.
lex:add_rule('preprocessor', token(lexer.PREPROCESSOR,
                                   "#[" * (lexer.nonnewline - ']')^0 *
                                   P("]")^-1))

-- Fold points.
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))
lex:add_fold_point(lexer.OPERATOR, '(', ')')
lex:add_fold_point(lexer.OPERATOR, '{', '}')

return lex
