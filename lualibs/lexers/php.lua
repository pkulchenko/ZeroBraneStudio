-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- PHP LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local lex = lexer.new('php')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  and array as bool boolean break case cfunction class const continue declare
  default die directory do double echo else elseif empty enddeclare endfor
  endforeach endif endswitch endwhile eval exit extends false float for foreach
  function global if include include_once int integer isset list new null object
  old_function or parent print real require require_once resource return static
  stdclass string switch true unset use var while xor
  __class__ __file__ __function__ __line__ __sleep __wakeup
]]))

local word = (lexer.alpha + '_' + R('\127\255')) *
             (lexer.alnum + '_' + R('\127\255'))^0

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, word))

-- Variables.
lex:add_rule('variable', token(lexer.VARIABLE, '$' * word))

-- Strings.
local sq_str = lexer.delimited_range("'")
local dq_str = lexer.delimited_range('"')
local bt_str = lexer.delimited_range('`')
local heredoc = '<<<' * P(function(input, index)
  local _, e, delimiter = input:find('([%a_][%w_]*)[\n\r\f]+', index)
  if delimiter then
    local _, e = input:find('[\n\r\f]+'..delimiter, e)
    return e and e + 1
  end
end)
lex:add_rule('string', token(lexer.STRING, sq_str + dq_str + bt_str + heredoc))
-- TODO: interpolated code.

-- Comments.
local line_comment = (P('//') + '#') * lexer.nonnewline^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, block_comment + line_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('!@%^*&()-+=|/?.,;:<>[]{}')))

-- Embedded in HTML.
local html = lexer.load('html')

-- Embedded PHP.
local php_start_rule = token('php_tag', '<?' * ('php' * lexer.space)^-1)
local php_end_rule = token('php_tag', '?>')
html:embed(lex, php_start_rule, php_end_rule)
lex:add_style('php_tag', lexer.STYLE_EMBEDDED)

-- Fold points.
lex:add_fold_point('php_tag', '<?', '?>')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))
lex:add_fold_point(lexer.COMMENT, '#', lexer.fold_line_comments('#'))
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.OPERATOR, '(', ')')

return lex
