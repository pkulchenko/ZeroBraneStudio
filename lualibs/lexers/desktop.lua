-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Desktop Entry LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('desktop')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keys.
lex:add_rule('key', token('key', word_match[[
  Type Version Name GenericName NoDisplay Comment Icon Hidden OnlyShowIn
  NotShowIn TryExec Exec Exec Path Terminal MimeType Categories StartupNotify
  StartupWMClass URL
]]))
lex:add_style('key', lexer.STYLE_KEYWORD)

-- Values.
lex:add_rule('value', token('value', word_match[[true false]]))
lex:add_style('value', lexer.STYLE_CONSTANT)

-- Identifiers.
lex:add_rule('identifier', lexer.token(lexer.IDENTIFIER,
                                       lexer.alpha * (lexer.alnum + S('_-'))^0))

-- Group headers.
lex:add_rule('header',
             lexer.starts_line(token('header',
                                     lexer.delimited_range('[]', false, true))))
lex:add_style('header', lexer.STYLE_LABEL)

-- Locales.
lex:add_rule('locale', token('locale',
                             lexer.delimited_range('[]', false, true)))
lex:add_style('locale', lexer.STYLE_CLASS)

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range('"')))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.nonnewline^0))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, (lexer.float + lexer.integer)))

-- Field codes.
lex:add_rule('code', lexer.token('code', P('%') * S('fFuUdDnNickvm')))
lex:add_style('code', lexer.STYLE_VARIABLE)

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('=')))

return lex
