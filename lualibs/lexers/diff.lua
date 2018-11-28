-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Diff LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('diff', {lex_by_line = true})

-- Text, separators, and file headers.
lex:add_rule('index', token(lexer.COMMENT, 'Index: ' * lexer.any^0 * -1))
lex:add_rule('separator', token(lexer.COMMENT, ('---' + P('*')^4 + P('=')^1) *
                                               lexer.space^0 * -1))
lex:add_rule('header', token('header', (P('*** ') + '--- ' + '+++ ') *
                                       lexer.any^1))
lex:add_style('header', lexer.STYLE_COMMENT)

-- Location.
lex:add_rule('location', token(lexer.NUMBER, ('@@' + lexer.digit^1 + '****') *
                                             lexer.any^1))

-- Additions, deletions, and changes.
lex:add_rule('addition', token('addition', S('>+') * lexer.any^0))
lex:add_style('addition', 'fore:$(color.green)')
lex:add_rule('deletion', token('deletion', S('<-') * lexer.any^0))
lex:add_style('deletion', 'fore:$(color.red)')
lex:add_rule('change', token('change', '!' * lexer.any^0))
lex:add_style('change', 'fore:$(color.yellow)')

lex:add_rule('any_line', token(lexer.DEFAULT, lexer.any^1))

return lex
