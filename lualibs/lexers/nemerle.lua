-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Nemerle LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('nemerle')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  _ abstract and array as base catch class def do else extends extern finally
  foreach for fun if implements in interface internal lock macro match module
  mutable namespace new out override params private protected public ref repeat
  sealed static struct syntax this throw try type typeof unless until using
  variant virtual when where while
  -- Values.
  null true false
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  bool byte char decimal double float int list long object sbyte short string
  uint ulong ushort void
]]))

-- Strings.
local sq_str = P('L')^-1 * lexer.delimited_range("'", true)
local dq_str = P('L')^-1 * lexer.delimited_range('"', true)
lex:add_rule('string', token(lexer.STRING, sq_str + dq_str))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Preprocessor.
local preproc_word = word_match[[
  define elif else endif endregion error if ifdef ifndef line pragma region
  undef using warning
]]
lex:add_rule('preproc', token(lexer.PREPROCESSOR, lexer.starts_line('#') *
                                                  S('\t ')^0 * preproc_word))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%<>!=^&|?~:;.()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.PREPROCESSOR, 'region', 'endregion')
lex:add_fold_point(lexer.PREPROCESSOR, 'if', 'endif')
lex:add_fold_point(lexer.PREPROCESSOR, 'ifdef', 'endif')
lex:add_fold_point(lexer.PREPROCESSOR, 'ifndef', 'endif')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
