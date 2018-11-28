-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Boo LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('boo')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  and break cast continue elif else ensure except for given goto if in isa is
  not or otherwise pass raise ref try unless when while
  -- Definitions.
  abstract callable class constructor def destructor do enum event final get
  interface internal of override partial private protected public return set
  static struct transient virtual yield
  -- Namespaces.
  as from import namespace
  -- Other.
  self super null true false
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  bool byte char date decimal double duck float int long object operator regex
  sbyte short single string timespan uint ulong ushort
]]))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, word_match[[
  array assert checked enumerate __eval__ filter getter len lock map matrix max
  min normalArrayIndexing print property range rawArrayIndexing required
  __switch__ typeof unchecked using yieldAll zip
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
local sq_str = lexer.delimited_range("'", true)
local dq_str = lexer.delimited_range('"', true)
local triple_dq_str = '"""' * (lexer.any - '"""')^0 * P('"""')^-1
local regex_str = #P('/') * lexer.last_char_includes('!%^&*([{-=+|:;,?<>~') *
                  lexer.delimited_range('/', true)
lex:add_rule('string', token(lexer.STRING, triple_dq_str + sq_str + dq_str) +
                       token(lexer.REGEX, regex_str))

-- Comments.
local line_comment = '#' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, (lexer.float + lexer.integer) *
                                           (S('msdhsfFlL') + 'ms')^-1))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('!%^&*()[]{}-=+/|:;.,?<>~`')))

return lex
