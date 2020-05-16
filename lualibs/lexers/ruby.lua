-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Ruby LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('ruby')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  BEGIN END alias and begin break case class def defined? do else elsif end
  ensure false for if in module next nil not or redo rescue retry return self
  super then true undef unless until when while yield __FILE__ __LINE__
]]))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, word_match[[
  at_exit autoload binding caller catch chop chop! chomp chomp! eval exec exit
  exit! fail fork format gets global_variables gsub gsub! iterator? lambda load
  local_variables loop open p print printf proc putc puts raise rand readline
  readlines require select sleep split sprintf srand sub sub! syscall system
  test trace_var trap untrace_var
]]) * -S('.:|'))

local word_char = lexer.alnum + S('_!?')

-- Identifiers.
local word = (lexer.alpha + '_') * word_char^0
lex:add_rule('identifier', token(lexer.IDENTIFIER, word))

-- Comments.
local line_comment = '#' * lexer.nonnewline_esc^0
local block_comment = lexer.starts_line('=begin') *
                      (lexer.any - lexer.newline * '=end')^0 *
                      (lexer.newline * '=end')^-1
lex:add_rule('comment', token(lexer.COMMENT, block_comment + line_comment))

local delimiter_matches = {['('] = ')', ['['] = ']', ['{'] = '}'}
local literal_delimitted = P(function(input, index)
  local delimiter = input:sub(index, index)
  if not delimiter:find('[%w\r\n\f\t ]') then -- only non alpha-numerics
    local match_pos, patt
    if delimiter_matches[delimiter] then
      -- Handle nested delimiter/matches in strings.
      local s, e = delimiter, delimiter_matches[delimiter]
      patt = lexer.delimited_range(s..e, false, false, true)
    else
      patt = lexer.delimited_range(delimiter)
    end
    match_pos = lpeg.match(patt, input, index)
    return match_pos or #input + 1
  end
end)

-- Strings.
local cmd_str = lexer.delimited_range('`')
local lit_cmd = '%x' * literal_delimitted
local lit_array = '%w' * literal_delimitted
local sq_str = lexer.delimited_range("'")
local dq_str = lexer.delimited_range('"')
local lit_str = '%' * S('qQ')^-1 * literal_delimitted
local heredoc = '<<' * P(function(input, index)
  local s, e, indented, _, delimiter =
    input:find('(%-?)(["`]?)([%a_][%w_]*)%2[\n\r\f;]+', index)
  if s == index and delimiter then
    local end_heredoc = (#indented > 0 and '[\n\r\f]+ *' or '[\n\r\f]+')
    local _, e = input:find(end_heredoc..delimiter, e)
    return e and e + 1 or #input + 1
  end
end)
-- TODO: regex_str fails with `obj.method /patt/` syntax.
local regex_str = #P('/') * lexer.last_char_includes('!%^&*([{-=+|:;,?<>~') *
                  lexer.delimited_range('/', true, false) * S('iomx')^0
local lit_regex = '%r' * literal_delimitted * S('iomx')^0
lex:add_rule('string', token(lexer.STRING, (sq_str + dq_str + lit_str +
                                            heredoc + cmd_str + lit_cmd +
                                            lit_array) * S('f')^-1) +
                       token(lexer.REGEX, regex_str + lit_regex))

-- Numbers.
local dec = lexer.digit^1 * ('_' * lexer.digit^1)^0 * S('ri')^-1
local bin = '0b' * S('01')^1 * ('_' * S('01')^1)^0
local integer = S('+-')^-1 * (bin + lexer.hex_num + lexer.oct_num + dec)
-- TODO: meta, control, etc. for numeric_literal.
local numeric_literal = '?' * (lexer.any - lexer.space) * -word_char
lex:add_rule('number', token(lexer.NUMBER, lexer.float * S('ri')^-1 + integer +
                                           numeric_literal))

-- Variables.
local global_var = '$' * (word + S('!@L+`\'=~/\\,.;<>_*"$?:') + lexer.digit +
                          '-' * S('0FadiIKlpvw'))
local class_var = '@@' * word
local inst_var = '@' * word
lex:add_rule('variable', token(lexer.VARIABLE, global_var + class_var +
                                               inst_var))

-- Symbols.
lex:add_rule('symbol', token('symbol', ':' * P(function(input, index)
  if input:sub(index - 2, index - 2) ~= ':' then return index end
end) * (word_char^1 + sq_str + dq_str)))
lex:add_style('symbol', lexer.STYLE_CONSTANT)

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('!%^&*()[]{}-=+/|:;.,?<>~')))

-- Fold points.
local function disambiguate(text, pos, line, s)
  return line:sub(1, s - 1):match('^%s*$') and
         not text:sub(1, pos - 1):match('\\[ \t]*\r?\n$') and 1 or 0
end
lex:add_fold_point(lexer.KEYWORD, 'begin', 'end')
lex:add_fold_point(lexer.KEYWORD, 'class', 'end')
lex:add_fold_point(lexer.KEYWORD, 'def', 'end')
lex:add_fold_point(lexer.KEYWORD, 'do', 'end')
lex:add_fold_point(lexer.KEYWORD, 'for', 'end')
lex:add_fold_point(lexer.KEYWORD, 'module', 'end')
lex:add_fold_point(lexer.KEYWORD, 'case', 'end')
lex:add_fold_point(lexer.KEYWORD, 'if', disambiguate)
lex:add_fold_point(lexer.KEYWORD, 'while', disambiguate)
lex:add_fold_point(lexer.KEYWORD, 'unless', disambiguate)
lex:add_fold_point(lexer.KEYWORD, 'until', disambiguate)
lex:add_fold_point(lexer.OPERATOR, '(', ')')
lex:add_fold_point(lexer.OPERATOR, '[', ']')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '=begin', '=end')
lex:add_fold_point(lexer.COMMENT, '#', lexer.fold_line_comments('#'))

return lex
