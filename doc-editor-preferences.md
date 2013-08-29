---
layout: default
title: Editor Preferences
---

To **modify default editor preferences**, you can use these commands and apply them 
as described in the [configuration](doc-configuration.html) section
and as shown in [user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua).
The values shown are the default values.

## Editor

- `editor.autoactivate = true`: auto-activate files during debugging.
- `editor.autotabs = false`: use tabs if detected.
- `editor.calltipdelay = 500`: calltip delay (assign `nil` or `0` to disable).
- `editor.caretline = true`: show caret line.
- `editor.checkeol = true`: check for mixed end-of-line encodings in loaded files (assign `nil` or `false` to disable).
- `editor.defaulteol = nil`: default EOL encoding (`wxstc.wxSTC_EOL_CRLF` or `wxstc.wxSTC_EOL_LF`).
- `editor.fold = true`: enable folding (0.39+).
- `editor.foldcompact = true`: set compact fold that includes empty lines after a block.
- `editor.fontname = "Courier New"`: set font name.
- `editor.fontsize = 10`: set font size.
- `editor.nomousezoom = false`: disable zoom with mouse wheel as it may be too sensitive.
- `editor.smartindent = true`: use smart indentation.
- `editor.showfncall = true`: mark function calls.
- `editor.tabwidth = 2`: set tab width.
- `editor.usetabs = false`: enable using tabs.
- `editor.usewrap = true`: wrap long lines in the editor.

## Output and Console

- `outputshell.fontname = "Courier New"`: set font name.
- `outputshell.fontsize = 10`: set font size.

## Project/Filetree

- `filetree.fontname = nil`: set font name; Project/Filetree window has no default font as it is system dependent.
- `filetree.fontsize = 10`: set font size.
