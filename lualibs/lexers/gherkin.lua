-- Copyright 2015-2018 Jason Schindler. See License.txt.
-- Gherkin (https://github.com/cucumber/cucumber/wiki/Gherkin) LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('gherkin', {fold_by_indentation = true})

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  And Background But Examples Feature Given Outline Scenario Scenarios Then When
]]))

-- Strings.
local doc_str = '"""' * (lexer.any - '"""')^0 * P('"""')^-1
local dq_str = lexer.delimited_range('"')
lex:add_rule('string', token(lexer.STRING, doc_str + dq_str))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.nonnewline^0))

-- Numbers.
local number = token(lexer.NUMBER, lexer.float + lexer.integer)

-- Tags.
lex:add_rule('tag', token('tag', '@' * lexer.word^0))
lex:add_style('tag', lexer.STYLE_LABEL)

-- Placeholders.
lex:add_rule('placeholder', token('placeholder', lexer.nested_pair('<', '>')))
lex:add_style('placeholder', lexer.STYLE_VARIABLE)

-- Examples.
lex:add_rule('example', token('example', '|' * lexer.nonnewline^0))
lex:add_style('example', lexer.STYLE_NUMBER)

return lex
