-- Copyright 2010-2018 Martin Morawetz. See License.txt.
-- ChucK LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('chuck')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  -- Control structures.
  break continue else for if repeat return switch until while
  -- Other chuck keywords.
  function fun spork const new
]]))

-- Constants.
lex:add_rule('constant', token(lexer.CONSTANT, word_match[[
  -- Special values.
  false maybe me null NULL pi true
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  float int time dur void same
]]))

-- Classes.
lex:add_rule('class', token(lexer.CLASS, word_match[[
  -- Class keywords.
  class extends implements interface private protected public pure static super
  this
]]))

-- Global ugens.
lex:add_rule('ugen', token('ugen', word_match[[dac adc blackhole]]))
lex:add_style('ugen', lexer.STYLE_CONSTANT)

-- Times.
lex:add_rule('time', token('time', word_match[[
  samp ms second minute hour day week
]]))
lex:add_style('time', lexer.STYLE_NUMBER)

-- Special special value.
lex:add_rule('now', token('now', P('now')))
lex:add_style('now', lexer.STYLE_CONSTANT..',bold')

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
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%<>!=^&|?~:;.()[]{}@')))

return lex
