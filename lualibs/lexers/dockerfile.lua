-- Copyright 2016-2018 Alejandro Baez (https://keybase.io/baez). See License.txt.
-- Dockerfile LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('dockerfile', {fold_by_indentation = true})

-- Whitespace
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  ADD ARG CMD COPY ENTRYPOINT ENV EXPOSE FROM LABEL MAINTAINER ONBUILD RUN
  STOPSIGNAL USER VOLUME WORKDIR
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Variable.
lex:add_rule('variable', token(lexer.VARIABLE,
                               S('$')^1 * (S('{')^1 * lexer.word * S('}')^1 +
                                           lexer.word)))

-- Strings.
local sq_str = lexer.delimited_range("'", false, true)
local dq_str = lexer.delimited_range('"')
lex:add_rule('string', token(lexer.STRING, sq_str + dq_str))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.nonnewline^0))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('\\[],=:{}')))

return lex
