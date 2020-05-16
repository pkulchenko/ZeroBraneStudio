-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Perl LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V

local lex = lexer.new('perl')

-- Whitespace.
lex:add_rule('perl', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  STDIN STDOUT STDERR BEGIN END CHECK INIT
  require use
  break continue do each else elsif foreach for if last local my next our
  package return sub unless until while __FILE__ __LINE__ __PACKAGE__
  and or not eq ne lt gt le ge
]]))

-- Markers.
lex:add_rule('marker', token(lexer.COMMENT, word_match[[__DATA__ __END__]] *
                                            lexer.any^0))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, word_match[[
  abs accept alarm atan2 bind binmode bless caller chdir chmod chomp chop chown
  chr chroot closedir close connect cos crypt dbmclose dbmopen defined delete
  die dump each endgrent endhostent endnetent endprotoent endpwent endservent
  eof eval exec exists exit exp fcntl fileno flock fork format formline getc
  getgrent getgrgid getgrnam gethostbyaddr gethostbyname gethostent getlogin
  getnetbyaddr getnetbyname getnetent getpeername getpgrp getppid getpriority
  getprotobyname getprotobynumber getprotoent getpwent getpwnam getpwuid
  getservbyname getservbyport getservent getsockname getsockopt glob gmtime goto
  grep hex import index int ioctl join keys kill lcfirst lc length link listen
  localtime log lstat map mkdir msgctl msgget msgrcv msgsnd new oct opendir open
  ord pack pipe pop pos printf print prototype push quotemeta rand readdir read
  readlink recv redo ref rename reset reverse rewinddir rindex rmdir scalar
  seekdir seek select semctl semget semop send setgrent sethostent setnetent
  setpgrp setpriority setprotoent setpwent setservent setsockopt shift shmctl
  shmget shmread shmwrite shutdown sin sleep socket socketpair sort splice split
  sprintf sqrt srand stat study substr symlink syscall sysread sysseek system
  syswrite telldir tell tied tie time times truncate ucfirst uc umask undef
  unlink unpack unshift untie utime values vec wait waitpid wantarray warn write
]]))

local delimiter_matches = {['('] = ')', ['['] = ']', ['{'] = '}', ['<'] = '>'}
local literal_delimitted = P(function(input, index) -- for single delimiter sets
  local delimiter = input:sub(index, index)
  if not delimiter:find('%w') then -- only non alpha-numerics
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
local literal_delimitted2 = P(function(input, index) -- for 2 delimiter sets
  local delimiter = input:sub(index, index)
  -- Only consider non-alpha-numerics and non-spaces as delimiters. The
  -- non-spaces are used to ignore operators like "-s".
  if not delimiter:find('[%w ]') then
    local match_pos, patt
    if delimiter_matches[delimiter] then
      -- Handle nested delimiter/matches in strings.
      local s, e = delimiter, delimiter_matches[delimiter]
      patt = lexer.delimited_range(s..e, false, false, true)
    else
      patt = lexer.delimited_range(delimiter)
    end
    first_match_pos = lpeg.match(patt, input, index)
    final_match_pos = lpeg.match(patt, input, first_match_pos - 1)
    if not final_match_pos then -- using (), [], {}, or <> notation
      final_match_pos = lpeg.match(lexer.space^0 * patt, input, first_match_pos)
    end
    return final_match_pos or #input + 1
  end
end)

-- Strings.
local sq_str = lexer.delimited_range("'")
local dq_str = lexer.delimited_range('"')
local cmd_str = lexer.delimited_range('`')
local heredoc = '<<' * P(function(input, index)
  local s, e, delimiter = input:find('([%a_][%w_]*)[\n\r\f;]+', index)
  if s == index and delimiter then
    local end_heredoc = '[\n\r\f]+'
    local _, e = input:find(end_heredoc..delimiter, e)
    return e and e + 1 or #input + 1
  end
end)
local lit_str = 'q' * P('q')^-1 * literal_delimitted
local lit_array = 'qw' * literal_delimitted
local lit_cmd = 'qx' * literal_delimitted
local lit_tr = (P('tr') + 'y') * literal_delimitted2 * S('cds')^0
local regex_str = #P('/') * lexer.last_char_includes('-<>+*!~\\=%&|^?:;([{') *
                  lexer.delimited_range('/', true) * S('imosx')^0
local lit_regex = 'qr' * literal_delimitted * S('imosx')^0
local lit_match = 'm' * literal_delimitted * S('cgimosx')^0
local lit_sub = 's' * literal_delimitted2 * S('ecgimosx')^0
lex:add_rule('string',
             token(lexer.STRING, sq_str + dq_str + cmd_str + heredoc + lit_str +
                                 lit_array + lit_cmd + lit_tr) +
             token(lexer.REGEX, regex_str + lit_regex + lit_match + lit_sub))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Comments.
local line_comment = '#' * lexer.nonnewline_esc^0
local block_comment = lexer.starts_line('=') * lexer.alpha *
                      (lexer.any - lexer.newline * '=cut')^0 *
                      (lexer.newline * '=cut')^-1
lex:add_rule('comment', token(lexer.COMMENT, block_comment + line_comment))

-- Numbers.
lex:add_rule('number', token(lexer.NUMBER, lexer.float + lexer.integer))

-- Variables.
local special_var = '$' * ('^' * S('ADEFHILMOPSTWX')^-1 +
                           S('\\"[]\'&`+*.,;=%~?@<>(|/!-') +
                           ':' * (lexer.any - ':') +
                           P('$') * -lexer.word +
                           lexer.digit^1)
local plain_var = ('$#' + S('$@%')) * P('$')^0 * lexer.word + '$#'
lex:add_rule('variable', token(lexer.VARIABLE, special_var + plain_var))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('-<>+*!~\\=/%&|^.?:;()[]{}')))

-- Fold points.
lex:add_fold_point(lexer.OPERATOR, '[', ']')
lex:add_fold_point(lexer.OPERATOR, '{', '}')
lex:add_fold_point(lexer.COMMENT, '#', lexer.fold_line_comments('#'))

return lex
