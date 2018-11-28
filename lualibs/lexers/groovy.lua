-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Groovy LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('groovy')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  abstract break case catch continue default do else extends final finally for
  if implements instanceof native new private protected public return static
  switch synchronized throw throws transient try volatile while strictfp package
  import as assert def mixin property test using in
  false null super this true it
]]))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, word_match[[
  abs any append asList asWritable call collect compareTo count div dump each
  eachByte eachFile eachLine every find findAll flatten getAt getErr getIn
  getOut getText grep immutable inject inspect intersect invokeMethods isCase
  join leftShift minus multiply newInputStream newOutputStream newPrintWriter
  newReader newWriter next plus pop power previous print println push putAt read
  readBytes readLines reverse reverseEach round size sort splitEachLine step
  subMap times toInteger toList tokenize upto waitForOrKill withPrintWriter
  withReader withStream withWriter withWriterAppend write writeLine
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  boolean byte char class double float int interface long short void
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Strings.
local sq_str = lexer.delimited_range("'")
local dq_str = lexer.delimited_range('"')
local triple_sq_str = "'''" * (lexer.any - "'''")^0 * P("'''")^-1
local triple_dq_str = '"""' * (lexer.any - '"""')^0 * P('"""')^-1
local regex_str = #P('/') * lexer.last_char_includes('=~|!<>+-*?&,:;([{') *
                  lexer.delimited_range('/', true)
lex:add_rule('string', token(lexer.STRING, triple_sq_str + triple_dq_str +
                                           sq_str + dq_str) +
                       token(lexer.REGEX, regex_str))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('=~|!<>+-/*?&.,:;()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
