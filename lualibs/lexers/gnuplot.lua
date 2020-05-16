-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Gnuplot LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('gnuplot')

-- Whitespace.
lex:add_rule('whitespace', token(lexer.WHITESPACE, lexer.space^1))

-- Keywords.
lex:add_rule('keyword', token(lexer.KEYWORD, word_match[[
  cd call clear exit fit help history if load pause plot using with index every
  smooth thru print pwd quit replot reread reset save set show unset shell splot
  system test unset update
]]))

-- Functions.
lex:add_rule('function', token(lexer.FUNCTION, word_match[[
  abs acos acosh arg asin asinh atan atan2 atanh besj0 besj1 besy0 besy1 ceil
  cos cosh erf erfc exp floor gamma ibeta inverf igamma imag invnorm int
  lambertw lgamma log log10 norm rand real sgn sin sinh sqrt tan tanh column
  defined tm_hour tm_mday tm_min tm_mon tm_sec tm_wday tm_yday tm_year valid
]]))

-- Variables.
lex:add_rule('variable', token(lexer.VARIABLE, word_match[[
  angles arrow autoscale bars bmargin border boxwidth clabel clip cntrparam
  colorbox contour datafile decimalsign dgrid3d dummy encoding fit fontpath
  format functions function grid hidden3d historysize isosamples key label
  lmargin loadpath locale logscale mapping margin mouse multiplot mx2tics mxtics
  my2tics mytics mztics offsets origin output parametric plot pm3d palette
  pointsize polar print rmargin rrange samples size style surface terminal tics
  ticslevel ticscale timestamp timefmt title tmargin trange urange variables
  version view vrange x2data x2dtics x2label x2mtics x2range x2tics x2zeroaxis
  xdata xdtics xlabel xmtics xrange xtics xzeroaxis y2data y2dtics y2label
  y2mtics y2range y2tics y2zeroaxis ydata ydtics ylabel ymtics yrange ytics
  yzeroaxis zdata zdtics cbdata cbdtics zero zeroaxis zlabel zmtics zrange ztics
  cblabel cbmtics cbrange cbtics
]]))

-- Identifiers.
lex:add_rule('identifier', token(lexer.IDENTIFIER, lexer.word))

-- Strings.
lex:add_rule('string', token(lexer.STRING, lexer.delimited_range("'") +
                                           lexer.delimited_range('"') +
                                           lexer.delimited_range('[]', true) +
                                           lexer.delimited_range('{}', true)))

-- Comments.
lex:add_rule('comment', token(lexer.COMMENT, '#' * lexer.nonnewline^0))

-- Operators.
lex:add_rule('operator', token(lexer.OPERATOR, S('-+~!$*%=<>&|^?:()')))

return lex
