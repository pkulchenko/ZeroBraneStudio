-- Copyright 2006-2018 Robert Gieseke. See License.txt.
-- Sass CSS preprocessor LPeg lexer.
-- http://sass-lang.com

local lexer = require('lexer')
local token = lexer.token
local P, S = lpeg.P, lpeg.S

local lex = lexer.new('sass', {inherit = lexer.load('css')})

-- Line comments.
lex:add_rule('line_comment', token(lexer.COMMENT, '//' * lexer.nonnewline^0))

-- Variables.
lex:add_rule('variable', token(lexer.VARIABLE, '$' * (lexer.alnum + S('_-'))^1))

-- Mixins.
lex:add_rule('mixin', token('mixin', P('@') * lexer.word))
lex:add_style('mixin', lexer.STYLE_FUNCTION)

-- Fold points.
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
