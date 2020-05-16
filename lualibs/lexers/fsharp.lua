-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- F# LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('fsharp', {fold_by_indentation = true})

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  abstract and as assert asr begin class default delegate do done downcast
  downto else end enum exception false finaly for fun function if in iherit
  interface land lazy let lor lsl lsr lxor match member mod module mutable
  namespace new null of open or override sig static struct then to true try type
  val when inline upcast while with async atomic break checked component const
  constructor continue eager event external fixed functor include method mixin
  process property protected public pure readonly return sealed switch virtual
  void volatile where
  -- Booleans.
  true false
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  bool byte sbyte int16 uint16 int uint32 int64 uint64 nativeint unativeint char
  string decimal unit void float32 single float double
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'", true) +
                                           lexer.delimited_range('"', true)))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '//' * lexer.nonnewline^0 +
                                             lexer.nested_pair('(*', '*)')))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, (lexer.float +
                                            lexer.integer * S('uUlL')^-1)))

-- Preprocessor.
local preproc_word = word_match[[
  else endif endregion if ifdef ifndef light region
]]
lex:add_rule('preproc', token(lexer.PREPROCESSOR, lexer.starts_line('#') *
                                                  S('\t ')^0 * preproc_word))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR,
                               S('=<>+-*/^.,:;~!@#%^&|?[](){}')))

return lex
