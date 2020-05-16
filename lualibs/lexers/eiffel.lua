-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Eiffel LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('eiffel')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  alias all and as check class creation debug deferred do else elseif end ensure
  expanded export external feature from frozen if implies indexing infix inherit
  inspect invariant is like local loop not obsolete old once or prefix redefine
  rename require rescue retry select separate then undefine until variant when
  xor
  current false precursor result strip true unique void
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  character string bit boolean integer real none any
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'", true) +
                                           lexer.delimited_range('"', true)))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '--' * lexer.nonnewline^0))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('=!<>+-/*%&|^~.,:;?()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.KEYWORD, 'check', 'end')
lex:add_fold_point(lexer.KEYWORD, 'debug', 'end')
lex:add_fold_point(lexer.KEYWORD, 'deferred', function(text, pos, line, s)
  return line:find('deferred%s+class') and 0 or 1
end)
lex:add_fold_point(lexer.KEYWORD, 'do', 'end')
lex:add_fold_point(lexer.KEYWORD, 'from', 'end')
lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
lex:add_fold_point(lexer.KEYWORD, 'inspect', 'end')
lex:add_fold_point(lexer.KEYWORD, 'once', 'end')
lex:add_fold_point(lexer.KEYWORD, 'class', function(text, pos, line, s)
  return line:find('deferred%s+class') and 0 or 1
end)
lex:add_fold_point(lexer.COMMENT, '--', lexer.fold_line_comments('--'))

return lex
