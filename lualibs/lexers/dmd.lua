-- Copyright 2006-2018 Mitchell mitchell.att.foicica.com. See License.txt.
-- D LPeg lexer.
-- Heavily modified by Brian Schott (@Hackerpilot on Github).

local lexer = require('lexer')
local token, word_match = lexer.token, lexer.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = {_NAME = 'dmd'}

-- Whitespace.
local ws = token(lexer.WHITESPACE, lexer.space^1)

-- Comments.
local line_comment = '//' * lexer.nonnewline_esc^0
local block_comment = '/*' * (lexer.any - '*/')^0 * P('*/')^-1
local nested_comment = lexer.nested_pair('/+', '+/')
local comment = token(lexer.COMMENT, line_comment + block_comment +
                                     nested_comment)

-- Strings.
local sq_str = lexer.delimited_range("'", true) * S('cwd')^-1
local dq_str = lexer.delimited_range('"') * S('cwd')^-1
local lit_str = 'r' * lexer.delimited_range('"', false, true) * S('cwd')^-1
local bt_str = lexer.delimited_range('`', false, true) * S('cwd')^-1
local hex_str = 'x' * lexer.delimited_range('"') * S('cwd')^-1
local other_hex_str = '\\x' * (lexer.xdigit * lexer.xdigit)^1
local del_str = lexer.nested_pair('q"[', ']"') * S('cwd')^-1 +
                lexer.nested_pair('q"(', ')"') * S('cwd')^-1 +
                lexer.nested_pair('q"{', '}"') * S('cwd')^-1 +
                lexer.nested_pair('q"<', '>"') * S('cwd')^-1 +
                P('q') * lexer.nested_pair('{', '}') * S('cwd')^-1
local string = token(lexer.STRING, del_str + sq_str + dq_str + lit_str +
                                   bt_str + hex_str + other_hex_str)

-- Numbers.
local dec = lexer.digit^1 * ('_' * lexer.digit^1)^0
local hex_num = lexer.hex_num * ('_' * lexer.xdigit^1)^0
local bin_num = '0' * S('bB') * S('01_')^1
local oct_num = '0' * S('01234567_')^1
local integer = S('+-')^-1 * (hex_num + oct_num + bin_num + dec)
local number = token(lexer.NUMBER, (lexer.float + integer) * S('uUlLdDfFi')^-1)

-- Keywords.
local keyword = token(lexer.KEYWORD, word_match{
  'abstract', 'align', 'asm', 'assert', 'auto', 'body', 'break', 'case', 'cast',
  'catch', 'const', 'continue', 'debug', 'default', 'delete',
  'deprecated', 'do', 'else', 'extern', 'export', 'false', 'final', 'finally',
  'for', 'foreach', 'foreach_reverse', 'goto', 'if', 'import', 'immutable',
  'in', 'inout', 'invariant', 'is', 'lazy', 'macro', 'mixin', 'new', 'nothrow',
  'null', 'out', 'override', 'pragma', 'private', 'protected', 'public', 'pure',
  'ref', 'return', 'scope', 'shared', 'static', 'super', 'switch',
  'synchronized', 'this', 'throw','true', 'try', 'typeid', 'typeof', 'unittest',
  'version', 'virtual', 'volatile', 'while', 'with', '__gshared', '__thread',
  '__traits', '__vector', '__parameters'
})

-- Types.
local type = token(lexer.TYPE, word_match{
  'alias', 'bool', 'byte', 'cdouble', 'cent', 'cfloat', 'char', 'class',
  'creal', 'dchar', 'delegate', 'double', 'enum', 'float', 'function',
  'idouble', 'ifloat', 'int', 'interface', 'ireal', 'long', 'module', 'package',
  'ptrdiff_t', 'real', 'short', 'size_t', 'struct', 'template', 'typedef',
  'ubyte', 'ucent', 'uint', 'ulong', 'union', 'ushort', 'void', 'wchar',
  'string', 'wstring', 'dstring', 'hash_t', 'equals_t'
})

-- Constants.
local constant = token(lexer.CONSTANT, word_match{
  '__FILE__', '__LINE__', '__DATE__', '__EOF__', '__TIME__', '__TIMESTAMP__',
  '__VENDOR__', '__VERSION__', '__FUNCTION__', '__PRETTY_FUNCTION__',
  '__MODULE__',
})

local class_sequence = token(lexer.TYPE, P('class') + P('struct')) * ws^1 *
                                         token(lexer.CLASS, lexer.word)

-- Identifiers.
local identifier = token(lexer.IDENTIFIER, lexer.word)

-- Operators.
local operator = token(lexer.OPERATOR, S('?=!<>+-*$/%&|^~.,;()[]{}'))

-- Properties.
local properties = (type + identifier + operator) * token(lexer.OPERATOR, '.') *
  token(lexer.VARIABLE, word_match{
    'alignof', 'dig', 'dup', 'epsilon', 'idup', 'im', 'init', 'infinity',
    'keys', 'length', 'mangleof', 'mant_dig', 'max', 'max_10_exp', 'max_exp',
    'min', 'min_normal', 'min_10_exp', 'min_exp', 'nan', 'offsetof', 'ptr',
    're', 'rehash', 'reverse', 'sizeof', 'sort', 'stringof', 'tupleof',
    'values'
  })

-- Preprocs.
local annotation = token('annotation', '@' * lexer.word^1)
local preproc = token(lexer.PREPROCESSOR, '#' * lexer.nonnewline^0)

-- Traits.
local traits_list = token('traits', word_match{
  'allMembers', 'classInstanceSize', 'compiles', 'derivedMembers',
  'getAttributes', 'getMember', 'getOverloads', 'getProtection', 'getUnitTests',
  'getVirtualFunctions', 'getVirtualIndex', 'getVirtualMethods', 'hasMember',
  'identifier', 'isAbstractClass', 'isAbstractFunction', 'isArithmetic',
  'isAssociativeArray', 'isFinalClass', 'isFinalFunction', 'isFloating',
  'isIntegral', 'isLazy', 'isNested', 'isOut', 'isOverrideFunction', 'isPOD',
  'isRef', 'isSame', 'isScalar', 'isStaticArray', 'isStaticFunction',
  'isUnsigned', 'isVirtualFunction', 'isVirtualMethod', 'parent'
})

local scopes_list = token('scopes', word_match{'exit', 'success', 'failure'})

-- versions
local versions_list = token('versions', word_match{
  'AArch64', 'AIX', 'all', 'Alpha', 'Alpha_HardFloat', 'Alpha_SoftFloat',
  'Android', 'ARM', 'ARM_HardFloat', 'ARM_SoftFloat', 'ARM_SoftFP', 'ARM_Thumb',
  'assert', 'BigEndian', 'BSD', 'Cygwin', 'D_Coverage', 'D_Ddoc', 'D_HardFloat',
  'DigitalMars', 'D_InlineAsm_X86', 'D_InlineAsm_X86_64', 'D_LP64',
  'D_NoBoundsChecks', 'D_PIC', 'DragonFlyBSD', 'D_SIMD', 'D_SoftFloat',
  'D_Version2', 'D_X32', 'FreeBSD', 'GNU', 'Haiku', 'HPPA', 'HPPA64', 'Hurd',
  'IA64', 'LDC', 'linux', 'LittleEndian', 'MIPS32', 'MIPS64', 'MIPS_EABI',
  'MIPS_HardFloat', 'MIPS_N32', 'MIPS_N64', 'MIPS_O32', 'MIPS_O64',
  'MIPS_SoftFloat', 'NetBSD', 'none', 'OpenBSD', 'OSX', 'Posix', 'PPC', 'PPC64',
  'PPC_HardFloat', 'PPC_SoftFloat', 'S390', 'S390X', 'SDC', 'SH', 'SH64',
  'SkyOS', 'Solaris', 'SPARC', 'SPARC64', 'SPARC_HardFloat', 'SPARC_SoftFloat',
  'SPARC_V8Plus', 'SysV3', 'SysV4', 'unittest', 'Win32', 'Win64', 'Windows',
  'X86', 'X86_64'
})

local versions = token(lexer.KEYWORD, 'version') * lexer.space^0 *
                 token(lexer.OPERATOR, '(') * lexer.space^0 * versions_list

local scopes = token(lexer.KEYWORD, 'scope') * lexer.space^0 *
               token(lexer.OPERATOR, '(') * lexer.space^0 * scopes_list

local traits = token(lexer.KEYWORD, '__traits') * lexer.space^0 *
               token(lexer.OPERATOR, '(') * lexer.space^0 * traits_list

local func = token(lexer.FUNCTION, lexer.word) *
             #(lexer.space^0 * (P('!') * lexer.word^-1 * lexer.space^-1)^-1 *
               P('('))

M._rules = {
  {'whitespace', ws},
  {'class', class_sequence},
  {'traits', traits},
  {'versions', versions},
  {'scopes', scopes},
  {'keyword', keyword},
  {'variable', properties},
  {'type', type},
  {'function', func},
  {'constant', constant},
  {'string', string},
  {'identifier', identifier},
  {'comment', comment},
  {'number', number},
  {'preproc', preproc},
  {'operator', operator},
  {'annotation', annotation},
}

M._tokenstyles = {
  annotation = lexer.STYLE_PREPROCESSOR,
  traits = 'fore:$(color.yellow)',
  versions = lexer.STYLE_CONSTANT,
  scopes = lexer.STYLE_CONSTANT
}

M._foldsymbols = {
  _patterns = {'[{}]', '/[*+]', '[*+]/', '//'},
  [lexer.OPERATOR] = {['{'] = 1, ['}'] = -1},
  [lexer.COMMENT] = {
    ['/*'] = 1, ['*/'] = -1, ['/+'] = 1, ['+/'] = -1,
    ['//'] = lexer.fold_line_comments('//')
  }
}

return M
