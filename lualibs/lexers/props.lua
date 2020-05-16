-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Props LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('props', {lex_by_line = true})

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Colors.
lex:add_rule('color', token('color', '#' * lexer.xdigit * lexer.xdigit *
                                     lexer.xdigit * lexer.xdigit *
                                     lexer.xdigit * lexer.xdigit))
lex:add_style('color', lexer.STYLE_NUMBER)

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.nonnewline^0))

-- Equals.
lex:add_rule('equals', token(lexer.OPERATOR, '='))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'") +
                                           lexer.delimited_range('"')))

-- Variables.
lex:add_rule('variable', token(lexer.VARIABLE, '$(' * (lexer.any - ')')^1 *
                                               ')'))

return lex
