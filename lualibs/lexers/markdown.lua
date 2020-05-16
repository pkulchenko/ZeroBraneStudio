-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- Markdown LPeg lexer.

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local lex = lexer.new('markdown')

-- Block elements.
lex:add_rule('header',
             token('h6', lexer.starts_line('######') * lexer.nonnewline^0) +
             token('h5', lexer.starts_line('#####') * lexer.nonnewline^0) +
             token('h4', lexer.starts_line('####') * lexer.nonnewline^0) +
             token('h3', lexer.starts_line('###') * lexer.nonnewline^0) +
             token('h2', lexer.starts_line('##') * lexer.nonnewline^0) +
             token('h1', lexer.starts_line('#') * lexer.nonnewline^0))
local font_size = lexer.property_int['fontsize'] > 0 and
                  lexer.property_int['fontsize'] or 10
local hstyle = 'fore:$(color.red)'
lex:add_style('h6', hstyle)
lex:add_style('h5', hstyle..',size:'..(font_size + 1))
lex:add_style('h4', hstyle..',size:'..(font_size + 2))
lex:add_style('h3', hstyle..',size:'..(font_size + 3))
lex:add_style('h2', hstyle..',size:'..(font_size + 4))
lex:add_style('h1', hstyle..',size:'..(font_size + 5))

lex:add_rule('blockquote',
             token(lexer.STRING,
                   lpeg.Cmt(lexer.starts_line(S(' \t')^0 * '>'),
                            function(input, index)
                              local _, e = input:find('\n[ \t]*\r?\n', index)
                              return (e or #input) + 1
                            end)))

lex:add_rule('list', token('list', lexer.starts_line(S(' \t')^0 * (S('*+-') +
                                                     R('09')^1 * '.')) *
                                   S(' \t')))
lex:add_style('list', lexer.STYLE_CONSTANT)

lex:add_rule('block_code',
             token('code', lexer.starts_line(P(' ')^4 + P('\t')) * -P('<') *
                           lexer.nonnewline^0 * lexer.newline^-1) +
             token('code', lexer.starts_line(P('```')) * (lexer.any - '```')^0 *
                           P('```')^-1))
lex:add_rule('inline_code',
             token('code', P('``') * (lexer.any - '``')^0 * P('``')^-1 +
                           lexer.delimited_range('`', false, true)))
lex:add_style('code', lexer.STYLE_EMBEDDED..',eolfilled')

lex:add_rule('hr',
             token('hr',
                   lpeg.Cmt(lexer.starts_line(S(' \t')^0 * lpeg.C(S('*-_'))),
                            function(input, index, c)
                              local line = input:match('[^\r\n]*', index)
                              line = line:gsub('[ \t]', '')
                              if line:find('[^'..c..']') or #line < 2 then
                                return nil
                              end
                              return (select(2, input:find('\r?\n', index)) or
                                      #input) + 1
                            end)))
lex:add_style('hr', 'back:$(color.black),eolfilled')

-- Whitespace.
local ws = token(lexer.WHITESPACE, S(' \t')^1 + S('\v\r\n')^1)
lex:add_rule('whitespace', ws)

-- Span elements.
lex:add_rule('escape', token(lexer.DEFAULT, P('\\') * 1))

lex:add_rule('link_label',
             token('link_label', lexer.delimited_range('[]') * ':') * ws *
             token('link_url', (lexer.any - lexer.space)^1) *
             (ws * token(lexer.STRING, lexer.delimited_range('"', false, true) +
                                       lexer.delimited_range("'", false, true) +
                                       lexer.delimited_range('()')))^-1)
lex:add_style('link_label', lexer.STYLE_LABEL)
lex:add_style('link_url', 'underlined')

lex:add_rule('link',
             token('link', P('!')^-1 * lexer.delimited_range('[]') *
                           (P('(') * (lexer.any - S(') \t'))^0 *
                            (S(' \t')^1 *
                             lexer.delimited_range('"', false, true))^-1 * ')' +
                            S(' \t')^0 * lexer.delimited_range('[]')) +
                           'http' * P('s')^-1 * '://' *
                           (lexer.any - lexer.space)^1))
lex:add_style('link', 'underlined')

lex:add_rule('strong', token('strong', P('**') * (lexer.any - '**')^0 *
                                       P('**')^-1 +
                                       P('__') * (lexer.any - '__')^0 *
                                       P('__')^-1))
lex:add_style('strong', 'bold')
lex:add_rule('em', token('em', lexer.delimited_range('*', true, true) +
                               lexer.delimited_range('_', true, true)))
lex:add_style('em', 'italics')

-- Embedded HTML.
local html = lexer.load('html')
local start_rule = lexer.starts_line(S(' \t')^0) * #P('<') *
                   html:get_rule('element')
local end_rule = token(lexer.DEFAULT, P('\n')) -- TODO: lexer.WHITESPACE errors
lex:embed(html, start_rule, end_rule)

return lex
