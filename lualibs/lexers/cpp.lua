-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- C++ LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('cpp')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  asm auto break case catch class const const_cast continue default delete do
  dynamic_cast else explicit export extern false for friend goto if inline
  mutable namespace new operator private protected public register
  reinterpret_cast return sizeof static static_cast switch template this throw
  true try typedef typeid typename using virtual volatile while
  -- Operators.
  and and_eq bitand bitor compl not not_eq or or_eq xor xor_eq
  -- C++11.
  alignas alignof constexpr decltype final noexcept override static_assert
  thread_local
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  bool char double enum float int long short signed struct union unsigned void
  wchar_t
  -- C++11.
  char16_t char32_t nullptr
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

-- Preprocessor.
local preproc_word = word_match[[
  define elif else endif error if ifdef ifndef import line pragma undef using
  warning
]]
lex:add_rule('preprocessor',
             #lexer.starts_line('#') *
             (token(lexer.PREPROCESSOR, '#' * S('\t ')^0 * preproc_word) +
              token(lexer.PREPROCESSOR, '#' * S('\t ')^0 * 'include') *
              (token(lexer.WHITESPACE, S('\t ')^1) *
               token(lexer.STRING,
                     lexer.delimited_range('<>', true, true)))^-1))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%<>!=^&|?~:;,.()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.PREPROCESSOR, 'if', 'endif')
lex:add_fold_point(lexer.PREPROCESSOR, 'ifdef', 'endif')
lex:add_fold_point(lexer.PREPROCESSOR, 'ifndef', 'endif')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
