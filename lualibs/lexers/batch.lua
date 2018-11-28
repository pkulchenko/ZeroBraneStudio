-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Batch LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('batch', {case_insensitive_fold_points = true})

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match([[
  cd chdir md mkdir cls for if echo echo. move copy ren del set call exit
  setlocal shift endlocal pause defined exist errorlevel else in do NUL AUX PRN
  not goto pushd popd
]], true)))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, word_match([[
  APPEND ATTRIB CHKDSK CHOICE DEBUG DEFRAG DELTREE DISKCOMP DISKCOPY DOSKEY
  DRVSPACE EMM386 EXPAND FASTOPEN FC FDISK FIND FORMAT GRAPHICS KEYB LABEL
  LOADFIX MEM MODE MORE MOVE MSCDEX NLSFUNC POWER PRINT RD REPLACE RESTORE
  SETVER SHARE SORT SUBST SYS TREE UNDELETE UNFORMAT VSAFE XCOPY
]], true)))

-- Comments.
local rem = (P('REM') + 'rem') * lexer.space
lex:add_rule('comment', token(lexer.COMMENT, (rem + '::') * lexer.nonnewline^0))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range('"', true)))

-- Variables.
lex:add_rule('variable', token(lexer.VARIABLE,
                               '%' * (lexer.digit + '%' * lexer.alpha) +
                               lexer.delimited_range('%', true, true)))

-- Labels.
lex:add_rule('label', token(lexer.LABEL, ':' * lexer.word))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('+|&!<>=')))

-- Fold points.
lex:add_fold_point(lexer.KEYWORD, 'setlocal', 'endlocal')

return lex
