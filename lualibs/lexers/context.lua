-- Copyright 2006-2018 Robert Gieseke. See License.txt.
-- ConTeXt LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('context')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '%' * lexer.nonnewline^0))

-- ConTeXt environments.
local environment = token('environment', '\\' * (P('start') + 'stop') *
                                         lexer.word)
lex:add_rule('environment', environment)
lex:add_style('environment', lexer.STYLE_KEYWORD)

-- Sections.
lex:add_rule('section', token('section', '\\' * word_match[[
  chapter part section subject subsection subsubject subsubsection subsubsubject
  title
]]))
lex:add_style('section', lexer.STYLE_CLASS)

-- Commands.
local command = token('command', '\\' * (lexer.alpha^1 *
                                         ('\\' * lexer.alpha^0)^-1 +
                                         S('#$&~_^%{}\\')))
lex:add_rule('command', command)
lex:add_style('command', lexer.STYLE_KEYWORD)

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('$&#{}[]')))

-- Fold points.
lex:add_fold_point('environment', '\\start', '\\stop')
lex:add_fold_point('command', '\\begin', '\\end')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '%', lexer.fold_line_comments('%'))

-- Embedded Lua.
local luatex = lexer.load('lua')
local luatex_start_rule = #P('\\startluacode') * environment
local luatex_end_rule = #P('\\stopluacode') * environment
lex:embed(luatex, luatex_start_rule, luatex_end_rule)

return lex
