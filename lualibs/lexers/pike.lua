-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Pike LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('pike')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  break case catch continue default do else for foreach gauge if lambda return
  sscanf switch while import inherit
  -- Type modifiers.
  constant extern final inline local nomask optional private protected public
  static variant
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  array class float function int mapping mixed multiset object program string
  void
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'", true) +
                                           lexer.delimited_range('"', true) +
                                           '#' * lexer.delimited_range('"')))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '//' * lexer.nonnewline_esc^0 +
                                             lexer.nested_pair('/*', '*/')))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, (lexer.float + lexer.integer) *
                                           S('lLdDfF')^-1))

-- Preprocessors.
lex:add_rule('preprocessor', token(lexer.PREPROCESSOR, lexer.starts_line('#') *
                                                       lexer.nonnewline^0))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('<>=!+-/*%&|^~@`.,:;()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
