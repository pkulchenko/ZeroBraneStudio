-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Django LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('django')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  as block blocktrans by endblock endblocktrans comment endcomment cycle date
  debug else extends filter endfilter firstof for endfor if endif ifchanged
  endifchanged ifnotequal endifnotequal in load not now or parsed regroup ssi
  trans with widthratio
]]))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, word_match[[
  add addslashes capfirst center cut date default dictsort dictsortreversed
  divisibleby escape filesizeformat first fix_ampersands floatformat get_digit
  join length length_is linebreaks linebreaksbr linenumbers ljust lower
  make_list phone2numeric pluralize pprint random removetags rjust slice slugify
  stringformat striptags time timesince title truncatewords unordered_list upper
  urlencode urlize urlizetrunc wordcount wordwrap yesno
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING,
                             lexer.delimited_range('"', false, true)))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S(':,.|')))

-- Embed Django in HTML.
local html = lexer.load('html')
local html_comment = '<!--' * (lexer.any - '-->')^0 * P('-->')^-1
local django_comment = '{#' * (lexer.any - lexer.newline - '#}')^0 * P('#}')^-1
html:modify_rule('comment', token(lexer.COMMENT, html_comment + django_comment))
local django_start_rule = token('django_tag', '{' * S('{%'))
local django_end_rule = token('django_tag', S('%}') * '}')
html:embed(lex, django_start_rule, django_end_rule)
lex:add_style('django_tag', lexer.STYLE_EMBEDDED)

-- Fold points.
lex:add_fold_point('django_tag', '{{', '}}')
lex:add_fold_point('django_tag', '{%', '%}')

return lex
