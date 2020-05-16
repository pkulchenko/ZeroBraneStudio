-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Objective C LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('objective_c')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  -- From C.
  asm auto break case const continue default do else extern false for goto if
  inline register return sizeof static switch true typedef void volatile while
  restrict _Bool _Complex _Pragma _Imaginary
  -- Objective C.
  oneway in out inout bycopy byref self super
  -- Preprocessor directives.
  @interface @implementation @protocol @end @private @protected @public @class
  @selector @encode @defs @synchronized @try @throw @catch @finally
  -- Constants.
  TRUE FALSE YES NO NULL nil Nil METHOD_NULL
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  apply_t id Class MetaClass Object Protocol retval_t SEL STR IMP BOOL
  TypedStream
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
  define elif else endif error if ifdef ifndef import include line pragma undef
  warning
]]
lex:add_rule('preprocessor', #lexer.starts_line('#') *
                             token(lexer.PREPROCESSOR, '#' * S('\t ')^0 *
                                                       preproc_word))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%<>!=^&|?~:;.()[]{}')))

-- Fold symbols.
lex:add_fold_point(lexer.PREPROCESSOR, 'region', 'endregion')
lex:add_fold_point(lexer.PREPROCESSOR, 'if', 'endif')
lex:add_fold_point(lexer.PREPROCESSOR, 'ifdef', 'endif')
lex:add_fold_point(lexer.PREPROCESSOR, 'ifndef', 'endif')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
