---
layout: default
title: Editor Preferences
---

To **modify default editor preferences**, you can use these commands and apply them 
as described in the [configuration](doc-configuration.html) section
and as shown in [user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua).
The values shown are the default values.

## Editor

- `editor.fontname = "Courier New"`: set font name.
- `editor.fontsize = 10`: set font size.
- `editor.caretline = true`: show caret line.
- `editor.showfncall = true`: mark function calls.
- `editor.tabwidth = 2`: set tab width.
- `editor.usetabs = false`: enable using tabs.
- `editor.autotabs = false`: use tabs if detected.
- `editor.usewrap = true`: wrap long lines in the editor.
- `editor.calltipdelay = 500`: calltip delay (assign `nil` or `0` to disable).
- `editor.autoactivate = true`: auto-activate files during debugging.
- `editor.smartindent = true`: use smart indentation.
- `editor.defaulteol = nil`: default EOL encoding (`wxstc.wxSTC_EOL_CRLF` or `wxstc.wxSTC_EOL_LF`).
- `editor.checkeol = false`: turn off checking for mixed end-of-line encodings in loaded files.
- `editor.foldcompact = true`: set compact fold that doesn't include empty lines after a block.
- `editor.nomousezoom = true`: disable zoom with mouse wheel as it may be too sensitive.

## Output and Console

- `outputshell.fontname = "Courier New"`: set font name.
- `outputshell.fontsize = 10`: set font size.

## Project/Filetree

- `filetree.fontname = nil`: set font name; Project/Filetree window has no default font as it is system dependent.
- `filetree.fontsize = 10`: set font size.
