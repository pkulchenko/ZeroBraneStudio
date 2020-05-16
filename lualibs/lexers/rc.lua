-- Copyright 2017-2018 Michael Forney. See License.txt.
-- rc LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('rc')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  for in while if not switch fn builtin cd eval exec exit flag rfork shift
  ulimit umask wait whatis . ~
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
local str = lexer.delimited_range("'", false, true)
local heredoc = '<<' * P(function(input, index)
  local s, e, _, delimiter = input:find('[ \t]*(["\']?)([%w!"%%+,-./:?@_~]+)%1',
                                        index)
  if s == index and delimiter then
    delimiter = delimiter:gsub('[%%+-.?]', '%%%1')
    local _, e = input:find('[\n\r]'..delimiter..'[\n\r]', e)
    return e and e + 1 or #input + 1
  end
end)
lex:add_rule('string', token(lexer.STRING, str + heredoc))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.nonnewline^0))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.integer + lexer.float))

-- Variables.
lex:add_rule('variable', token(lexer.VARIABLE, '$' * S('"#')^-1 *
                                               ('*' + lexer.digit^1 +
                                                lexer.word)))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('@`=!<>*&^|;?()[]{}') +
                                               '\\\n'))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '#', lexer.fold_line_comments('#'))

return lex
