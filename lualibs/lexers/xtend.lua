-- Copyright (c) 2014-2018 Piotr Orzechowski [drzewo.org]. See License.txt.
-- Xtend LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('xtend')

-- Whitespace.
local ws = token(lexer.WHITESPACE, lexer.space^1)
lex:add_rule('whitespace', ws)

-- Classes.
lex:add_rule('class', token(lexer.KEYWORD, P('class')) * ws^1 *
                      token(lexer.CLASS, lexer.word))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  -- General.
  abstract annotation as case catch class create def default dispatch do else
  enum extends extension final finally for if implements import interface
  instanceof it new override package private protected public return self static
  super switch synchronized this throw throws try typeof val var while
  -- Templates.
  -- AFTER BEFORE ENDFOR ENDIF FOR IF SEPARATOR
  -- Literals.
  true false null
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  boolean byte char double float int long short void
  Boolean Byte Character Double Float Integer Long Short String
]]))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, lexer.word) * #P('('))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Templates.
lex:add_rule('template', token('template', "'''" * (lexer.any - P("'''"))^0 *
                                           P("'''")^-1))
lex:add_style('template', lexer.STYLE_EMBEDDED)

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'", true) +
                                           lexer.delimited_range('"', true)))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
local small_suff = S('lL')
local med_suff = S('bB') * S('iI')
local large_suff = S('dD') + S('fF') + S('bB') * S('dD')
local exp = S('eE') * lexer.digit^1

local dec_inf = ('_' * lexer.digit^1)^0
local hex_inf = ('_' * lexer.xdigit^1)^0
local float_pref = lexer.digit^1 * '.' * lexer.digit^1
local float_suff = exp^-1 * med_suff^-1 * large_suff^-1

local dec = lexer.digit * dec_inf * (small_suff^-1 + float_suff)
local hex = lexer.hex_num * hex_inf * P('#' * (small_suff + med_suff))^-1
local float = float_pref * dec_inf * float_suff

lex:add_rule('number', token(lexer.NUMBER, float + hex + dec))

-- Annotations.
lex:add_rule('annotation', token('annotation', '@' * lexer.word))
lex:add_style('annotation', lexer.STYLE_PREPROCESSOR)

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%<>!=^&|?~:;.()[]{}#')))

-- Error.
lex:add_rule('error', token(lexer.ERROR, lexer.any))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))
lex:add_fold_point(lexer.KEYWORD, 'import', lexer.fold_line_comments('import'))

return lex
