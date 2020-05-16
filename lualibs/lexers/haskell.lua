-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Haskell LPeg lexer.
-- Modified by Alex Suraci.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('haskell', {fold_by_indentation = true})

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  case class data default deriving do else if import in infix infixl infixr
  instance let module newtype of then type where _ as qualified hiding
]]))

local word = (lexer.alnum + S("._'#"))^0
local op = lexer.punct - S('()[]{}')

-- Types & type constructors.
lex:add_rule('type', token(lexer.TYPE, (lexer.upper * word) +
                                       (":" * (op^1 - ":"))))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, (lexer.alpha + '_') * word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'", true) +
                                           lexer.delimited_range('"')))

-- Comments.
local line_comment = '--' * lexer.nonnewline_esc^0
local block_comment = '{-' * (lexer.any - '-}')^0 * P('-}')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, op))

return lex
