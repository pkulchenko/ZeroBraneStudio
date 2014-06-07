---
layout: default
title: Editor Preferences
---

To **modify default editor preferences**, you can use these commands and apply them 
as described in the [configuration](doc-configuration.html) section
and as shown in [user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua).
The values shown are the default values.

## Editor

- `editor.autoactivate = false`: auto-activate files during debugging.
- `editor.autoreload = false`: auto-reload externally modified files (if no conflict detected).
- `editor.autotabs = false`: use tabs if detected.
- `editor.calltipdelay = 500`: calltip delay; set to `nil` or `0` to disable.
- `editor.caretline = true`: show caret line.
- `editor.checkeol = true`: check for mixed end-of-line encodings in loaded files; set to `nil` or `false` to disable.
- `editor.defaulteol = nil`: default EOL encoding (`wxstc.wxSTC_EOL_CRLF` or `wxstc.wxSTC_EOL_LF`).
- `editor.extraascent = nil`: extra spacing (in pixels) above the baseline (0.51+).
- `editor.extradescent = nil`: extra spacing (in pixels) below the baseline (0.61+).
- `editor.fold = true`: enable folding (0.39+).
- `editor.foldcompact = true`: set compact fold that includes empty lines after a block.
- `editor.foldtype = 'box'`: set folding style with `box`, `circle`, `arrow`, and `plus` as accepted values (0.51+).
- `editor.foldflags = wxstc.wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED`: set folding flags that control how folded lines are indicated in the text area (0.51+); set to `0` to disable all indicator lines.
Other values (can be combined): `wxstc.wxSTC_FOLDFLAG_LINEBEFORE_EXPANDED` (draw line above if expanded), `wxstc.wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED` (draw line above if contracted), `wxstc.wxSTC_FOLDFLAG_LINEAFTER_EXPANDED` (draw line below if expanded), and `wxstc.wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED` (draw line below if contracted).
- `editor.fontname = "Courier New"`: set font name.
- `editor.fontsize = 11`: set font size (the default value is `12` on OSX).
- `editor.nomousezoom = false`: disable zoom with mouse wheel as it may be too sensitive.
- `editor.saveallonrun = nil`: save modified files before executing Run/Debug commands (0.39+).
- `editor.smartindent = true`: use smart indentation.
- `editor.showfncall = true`: mark function calls.
- `editor.tabwidth = 2`: set tab width.
- `editor.usetabs = false`: enable using tabs.
- `editor.usewrap = true`: wrap long lines.
- `editor.whitespace = false`: display whitespaces.
- `editor.wrapflags = nil`: enable drawing of visual flags to indicate wrapped lines (0.51+).
Possible values (can be combined): `wxstc.wxSTC_WRAPVISUALFLAG_END` (end of subline), `wxstc.wxSTC_WRAPVISUALFLAG_START` (beginning of subline), and `wxstc.wxSTC_WRAPVISUALFLAG_MARGIN` (line number margin).
- `editor.wrapindentmode = wxstc.wxSTC_WRAPINDENT_FIXED`: enable wrapped sublines to be indented to the position of their first subline or one more indent level (0.61+).
Possible values: `wxstc.wxSTC_WRAPINDENT_FIXED` (align to left of window plus amount set by `editor.wrapstartindent`), `wxstc.wxSTC_WRAPINDENT_SAME` (align to first subline indent), and `wxstc.wxSTC_WRAPINDENT_INDENT` (align to first subline indent plus one more level of indentation).
- `editor.wrapstartindent = 0`: set the size of indentation of sublines for wrapped lines in terms of the average character width.

## Output and Console

- `outputshell.fontname = "Courier New"`: set font name.
- `outputshell.fontsize = 10`: set font size (the default value is `11` on OSX).
- `outputshell.nomousezoom = false`: disable zoom with mouse wheel in Output/Console windows as it may be too sensitive.
- `outputshell.usewrap = true`: wrap long lines (0.51+); set to `nil` or `false` to disable. This setting only applies to the Output window; the Console always wraps its lines.

## Project/Filetree

- `filetree.fontname = nil`: set font name; Project/Filetree window has no default font as it is system dependent.
- `filetree.fontsize = 10`: set font size (the default size is `11` on OSX).
