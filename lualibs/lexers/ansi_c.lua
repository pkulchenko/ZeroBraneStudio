-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- C LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('ansi_c')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  auto break case const continue default do else extern for goto if inline
  register restrict return sizeof static switch typedef volatile while
  -- C11.
  _Alignas _Alignof _Atomic _Generic _Noreturn _Static_assert _Thread_local
]]))

-- Types.
lex:add_rule('type', token(lexer.TYPE, word_match[[
  char double enum float int long short signed struct union unsigned void
  _Bool _Complex _Imaginary
  -- Stdlib types.
  ptrdiff_t size_t max_align_t wchar_t intptr_t uintptr_t intmax_t uintmax_t
]] + P('u')^-1 * 'int' * (P('_least') + '_fast')^-1 * R('09')^1 * '_t'))

-- Constants.
lex:add_rule('constants', token(lexer.CONSTANT, word_match[[
  NULL
  -- Preprocessor.
  __DATE__ __FILE__ __LINE__ __TIME__ __func__
  -- errno.h.
  E2BIG EACCES EADDRINUSE EADDRNOTAVAIL EAFNOSUPPORT EAGAIN EALREADY EBADF
  EBADMSG EBUSY ECANCELED ECHILD ECONNABORTED ECONNREFUSED ECONNRESET EDEADLK
  EDESTADDRREQ EDOM EDQUOT EEXIST EFAULT EFBIG EHOSTUNREACH EIDRM EILSEQ
  EINPROGRESS EINTR EINVAL EIO EISCONN EISDIR ELOOP EMFILE EMLINK EMSGSIZE
  EMULTIHOP ENAMETOOLONG ENETDOWN ENETRESET ENETUNREACH ENFILE ENOBUFS ENODATA
  ENODEV ENOENT ENOEXEC ENOLCK ENOLINK ENOMEM ENOMSG ENOPROTOOPT ENOSPC ENOSR
  ENOSTR ENOSYS ENOTCONN ENOTDIR ENOTEMPTY ENOTRECOVERABLE ENOTSOCK ENOTSUP
  ENOTTY ENXIO EOPNOTSUPP EOVERFLOW EOWNERDEAD EPERM EPIPE EPROTO
  EPROTONOSUPPORT EPROTOTYPE ERANGE EROFS ESPIPE ESRCH ESTALE ETIME ETIMEDOUT
  ETXTBSY EWOULDBLOCK EXDEV
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
local sq_str = P('L')^-1 * lexer.delimited_range("'", true)
local dq_str = P('L')^-1 * lexer.delimited_range('"', true)
lex:add_rule('string', token(lexer.STRING, sq_str + dq_str))

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1 +
                      lexer.starts_line('#if') * S(' \t')^0 * '0' *
                      lexer.space *
                      (lexer.any - lexer.starts_line('#endif'))^0 *
                      (lexer.starts_line('#endif'))^-1
lex:add_rule('comment', token(lexer.COMMENT, line_comment + block_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Preprocessor.
local preproc_word = word_match[[
  define elif else endif if ifdef ifndef line pragma undef
]]
lex:add_rule('preprocessor',
             #lexer.starts_line('#') *
             (token(lexer.PREPROCESSOR, '#' * S('\t ')^0 * preproc_word) +
              token(lexer.PREPROCESSOR, '#' * S('\t ')^0 * 'include') *
              (token(lexer.WHITESPACE, S('\t ')^1) *
               token(lexer.STRING,
                     lexer.delimited_range('<>', true, true)))^-1))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+-/*%<>~!=^&|?~:;,.()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.PREPROCESSOR, '#if', '#endif')
lex:add_fold_point(lexer.PREPROCESSOR, '#ifdef', '#endif')
lex:add_fold_point(lexer.PREPROCESSOR, '#ifndef', '#endif')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '/*', '*/')
lex:add_fold_point(lexer.COMMENT, '//', lexer.fold_line_comments('//'))

return lex
