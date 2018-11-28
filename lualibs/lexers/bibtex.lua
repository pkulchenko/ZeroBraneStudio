-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Bibtex LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('bibtex')

-- Whitespace.
local ws = token(lexer.WHITESPACE, lexer.space^1)

-- Fields.
lex:add_rule('field', token('field', word_match[[
  author title journal year volume number pages month note key publisher editor
  series address edition howpublished booktitle organization chapter school
  institution type isbn issn affiliation issue keyword url
]]))
lex:add_style('field', lexer.STYLE_CONSTANT)

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING,
                             lexer.delimited_range('"') +
                             lexer.delimited_range('{}', false, true, true)))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S(',=')))

-- Embedded in Latex.
local latex = lexer.load('latex')

-- Embedded Bibtex.
local entry = token('entry', P('@') * word_match([[
  book article booklet conference inbook incollection inproceedings manual
  mastersthesis lambda misc phdthesis proceedings techreport unpublished
]], true))
lex:add_style('entry', lexer.STYLE_PREPROCESSOR)
local bibtex_start_rule = entry * ws^0 * token(lexer.OPERATOR, P('{'))
local bibtex_end_rule = token(lexer.OPERATOR, P('}'))
latex:embed(lex, bibtex_start_rule, bibtex_end_rule)

return lex
