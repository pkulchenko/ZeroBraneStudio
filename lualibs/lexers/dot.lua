-- Copyright 2006-2018 Brian "Sir Alaran" Schott. See License.txt.
-- Dot LPeg lexer.
-- Based off of lexer code by Mitchell.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('dot')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  graph node edge digraph fontsize rankdir fontname shape label arrowhead
  arrowtail arrowsize color comment constraint decorate dir headlabel headport
  headURL labelangle labeldistance labelfloat labelfontcolor labelfontname
  labelfontsize layer lhead ltail minlen samehead sametail style taillabel
  tailport tailURL weight subgraph
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
	box polygon ellipse circle point egg triangle plaintext diamond trapezium
  parallelogram house pentagon hexagon septagon octagon doublecircle
  doubleoctagon tripleoctagon invtriangle invtrapezium invhouse Mdiamond Msquare
  Mcircle rect rectangle none note tab folder box3d record
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'") +
                                           lexer.delimited_range('"')))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.digit^1 + lexer.float))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('->()[]{};')))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
