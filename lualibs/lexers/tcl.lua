-- Copyright 2014-2018 Joshua Krämer. See License.txt.
-- Tcl LPeg lexer.
-- This lexer follows the TCL dodekalogue (http://wiki.tcl.tk/10259).
-- It is based on the previous lexer by Mitchell.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('tcl')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Comment.
lex:add_rule('comment', token(lexer.COMMENT, '#' * P(function(input, index)
  local i = index - 2
  while i > 0 and input:find('^[ \t]', i) do i = i - 1 end
  if i < 1 or input:find('^[\r\n;]', i) then return index end
end) * lexer.nonnewline^0))

-- Separator (semicolon).
lex:add_rule('separator', token(lexer.CLASS, P(';')))

-- Argument expander.
lex:add_rule('expander', token(lexer.LABEL, P('{*}')))

-- Delimiters.
lex:add_rule('braces', token(lexer.KEYWORD, S('{}')))
lex:add_rule('quotes', token(lexer.FUNCTION, '"'))
lex:add_rule('brackets', token(lexer.VARIABLE, S('[]')))

-- Variable substitution.
lex:add_rule('variable', token(lexer.STRING, '$' *
                                             (lexer.alnum + '_' + P(':')^2)^0))

-- Backslash substitution.
lex:add_rule('backslash', token(lexer.TYPE,
                                '\\' * (lexer.digit * lexer.digit^-2 +
                                        'x' * lexer.xdigit^1 +
                                        'u' * lexer.xdigit * lexer.xdigit^-3 +
                                        'U' * lexer.xdigit * lexer.xdigit^-7 +
                                        1)))

-- Fold points.
lex:add_fold_point(lexer.KEYWORD, '{', '}')
lex:add_fold_point(lexer.COMMENT, '#', lexer.fold_line_comments('#'))

return lex
