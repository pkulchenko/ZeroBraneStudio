-- Copyright 2015-2018 Alejandro Baez (https://keybase.io/baez). See License.txt.
-- TOML LPeg lexer.

local lexer = require("lexer")
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('toml', {fold_by_indentation = true})

-- Whitespace
lex:add_rule('indent', #lexer.starts_line(S(' \t')) *
                       (token(lexer.WHITESPACE, ' ') +
                        token('indent_error', '\t'))^1)
lex:add_rule('whitespace', token(lexer.WHITESPACE, S(' \t')^1 +
                                                   lexer.newline^1))
lex:add_style('indent_error', 'back:%(color.red)')

-- kewwords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[true false]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'") +
                                           lexer.delimited_range('"')))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.nonnewline^0))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('#=+-,.{}[]()')))

-- Datetime.
lex:add_rule('datetime',
             token('timestamp',
                   lexer.digit * lexer.digit * lexer.digit * lexer.digit * -- yr
                   '-' * lexer.digit * lexer.digit^-1 * -- month
                   '-' * lexer.digit * lexer.digit^-1 * -- day
                   ((S(' \t')^1 + S('tT'))^-1 * -- separator
                    lexer.digit * lexer.digit^-1 * -- hour
                    ':' * lexer.digit * lexer.digit * -- minute
                    ':' * lexer.digit * lexer.digit * -- second
                    ('.' * lexer.digit^0)^-1 * -- fraction
                    ('Z' + -- timezone
                     S(' \t')^0 * S('-+') * lexer.digit * lexer.digit^-1 *
                     (':' * lexer.digit * lexer.digit)^-1)^-1)^-1))
lex:add_style('timestamp', lexer.STYLE_NUMBER)

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

return lex
