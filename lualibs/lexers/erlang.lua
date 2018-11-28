-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Erlang LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('erlang')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  after begin case catch cond end fun if let of query receive try when
  -- Operators.
  div rem or xor bor bxor bsl bsr and band not bnot badarg nocookie orelse
  andalso false true
]]))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, word_match[[
  abs alive apply atom_to_list binary_to_list binary_to_term concat_binary date
  disconnect_node element erase exit float float_to_list get get_keys
  group_leader halt hd integer_to_list is_alive is_record length link
  list_to_atom list_to_binary list_to_float list_to_integer list_to_pid
  list_to_tuple load_module make_ref monitor_node node nodes now open_port
  pid_to_list process_flag process_info process put register registered round
  self setelement size spawn spawn_link split_binary statistics term_to_binary
  throw time tl trunc tuple_to_list unlink unregister whereis
  -- Others.
  any atom binary bitstring byte constant function integer list map mfa
  non_neg_integer number pid ports port_close port_info pos_integer reference
  record
  -- Erlang.
  check_process_code delete_module get_cookie hash math module_loaded preloaded
  processes purge_module set_cookie set_node
  -- Math.
  acos asin atan atan2 cos cosh exp log log10 min max pi pow power sin sinh sqrt
  tan tanh
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.lower *
                                                   ('_' + lexer.alnum)^0))

-- Variables.
lex:add_rule('variable', token(lexer.VARIABLE, P('_')^0 * lexer.upper *
                                               ('_' + lexer.alnum)^0))

-- Directives.
lex:add_rule('directive', token('directive', '-' * word_match[[
  author behaviour behavior compile copyright define doc else endif export file
  ifdef ifndef import include include_lib module record spec type undef
]]))
lex:add_style('directive', lexer.STYLE_PREPROCESSOR)

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'", true) +
                                           lexer.delimited_range('"') +
                                           '$' * lexer.any * lexer.alnum^0))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '%' * lexer.nonnewline^0))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('-<>.;=/|+*:,!()[]{}')))

-- Preprocessor.
lex:add_rule('preprocessor', token(lexer.TYPE, '?' * lexer.word))

-- Records.
lex:add_rule('type', token(lexer.TYPE, '#' * lexer.word))

-- Fold points.
lex:add_fold_point(lexer.KEYWORD, 'case', 'end')
lex:add_fold_point(lexer.KEYWORD, 'fun', 'end')
lex:add_fold_point(lexer.KEYWORD, 'if', 'end')
lex:add_fold_point(lexer.KEYWORD, 'query', 'end')
lex:add_fold_point(lexer.KEYWORD, 'receive', 'end')
lex:add_fold_point(lexer.OPERATOR, '(', ')')
lex:add_fold_point(lexer.OPERATOR, '[', ']')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '%', lexer.fold_line_comments('%'))

return lex
