-- Copyright 2006-2018 Robert Gieseke. See License.txt.
-- Lilypond LPeg lexer.
-- TODO Embed Scheme; Notes?, Numbers?

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('lilypond')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords, commands.
lex:add_rule('keyword', token(lexer.KEYWORD, '\\' * lexer.word))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING,
                             lexer.delimited_range('"', false, true)))

-- Comments.
-- TODO: block comment.
lex:add_rule('comment', token(lexer.COMMENT, '%' * lexer.nonnewline^0))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S("{}'~<>|")))

return lex
