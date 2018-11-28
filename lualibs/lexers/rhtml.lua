-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- RHTML LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('rhtml', {inherit = lexer.load('html')})

-- Embedded Ruby.
local ruby = lexer.load('rails')
local ruby_start_rule = token('rhtml_tag', '<%' * P('=')^-1)
local ruby_end_rule = token('rhtml_tag', '%>')
lex:embed(ruby, ruby_start_rule, ruby_end_rule)
lex:add_style('rhtml_tag', lexer.STYLE_EMBEDDED)

-- Fold points.
lex:add_fold_point('rhtml_tag', '<%', '%>')

return lex
