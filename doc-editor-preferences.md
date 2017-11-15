---
layout: default
title: Editor Preferences
---

To **modify default editor preferences**, you can use these commands and apply them 
as described in the [configuration](doc-configuration) section
and as shown in [user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua).
The values shown are the default values.

## Editor

- `editor.autoactivate = false`: auto-activate files during debugging.
- `editor.autoreload = true`: auto-reload externally modified files (if no conflict detected).
- `editor.autotabs = false`: use tabs if detected.
- `editor.backspaceunindent = true`: remove one level of indentation when use backspace on a tab stop; set to `false` to disable.
- `editor.calltipdelay = 500`: calltip delay; set to `nil` or `0` to disable.
- `editor.caretline = true`: show caret line.
- `editor.checkeol = true`: check for mixed end-of-line encodings in loaded files; set to `nil` or `false` to disable.
- `editor.commentlinetoggle = false`: set to toggle comments all at once (when set to `false`) or line-by-line (when set to `true`) (**v1.31+**).
The difference can be seen on a fragment that includes a mix of regular and commented lines; when set to `true`, each line is toggled individually (so commented lines will be uncommented), but when set to `false`, all lines will be commented out.
- `editor.defaulteol = nil`: default EOL encoding (`wxstc.wxSTC_EOL_CRLF` or `wxstc.wxSTC_EOL_LF`).
- `editor.edge = false`: set editor edge to mark lines that exceed a given length (**v1.61+**);
set to `true` to enable (at 80 columns) or to a number to set to specific column.
- `editor.edgemode = wxstc.wxSTC_EDGE_NONE`: set how the edge for the long lines is displayed (**v1.61+**);
set to `wxstc.wxSTC_EDGE_LINE` to display as a line or
set to `wxstc.wxSTC_EDGE_BACKGROUND` to display as a different background color of characters after the column limit.
The color of the characters or the edge line is controlled by `style.edge.fg` configuration setting.
- `editor.extraascent = nil`: extra spacing (in pixels) above the baseline (**v0.51+**).
- `editor.extradescent = nil`: extra spacing (in pixels) below the baseline (**v0.61+**).
- `editor.fold = true`: enable folding (**v0.39+**).
- `editor.foldcompact = true`: set compact fold that includes empty lines after a block.
- `editor.foldtype = 'box'`: set folding style with `box`, `circle`, `arrow`, and `plus` as accepted values (**v0.51+**).
- `editor.foldflags = wxstc.wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED`: set folding flags that control how folded lines are indicated in the text area (**v0.51+**); set to `0` to disable all indicator lines.
Other values (can be combined): `wxstc.wxSTC_FOLDFLAG_LINEBEFORE_EXPANDED` (draw line above if expanded), `wxstc.wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED` (draw line above if contracted), `wxstc.wxSTC_FOLDFLAG_LINEAFTER_EXPANDED` (draw line below if expanded), and `wxstc.wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED` (draw line below if contracted).
- `editor.fontname = "Courier New"`: set font name.
- `editor.fontsize = 11`: set font size (the default value is `12` on macOS).
- `editor.indentguide = true`: show indentation guides (**v0.90+**);
set to `false` or `nil` to disable;
set to `wxstc.wxSTC_IV_LOOKFORWARD` to show indentation guides beyond the actual indentation up to the level of the next non-empty line
and to `wxstc.wxSTC_IV_LOOKBOTH` to show indentation guides beyond the actual indentation up to the level of the next non-empty line or previous non-empty line whichever is the greater (**v1.11+**).
- `editor.linenumber = true`: show line numbers (**v1.31+**).
- `editor.nomousezoom = false`: disable zoom with mouse wheel as it may be too sensitive.
- `editor.saveallonrun = false`: save modified files before executing Run/Debug commands (**v0.39+**).
- `editor.showfncall = false`: mark function calls;
set to `true` to add an [indicator for function calls](doc-styles-color-schemes#indicators).
- `editor.smartindent = true`: use smart indentation.
- `editor.tabwidth = 2`: set tab width.
- `editor.usetabs = false`: enable using tabs.
- `editor.usewrap = true`: wrap long lines.
- `editor.whitespace = false`: display whitespaces;
set to `true` or `wxstc.wxSTC_WS_VISIBLEALWAYS` to display white space characters drawn as dots and arrows;
set to `wxstc.wxSTC_WS_VISIBLEAFTERINDENT` to show white spaces after the first visible character only
and to `wxstc.wxSTC_WS_VISIBLEONLYININDENT` to show white spaces used for indentation only (**v1.61+**).
- `editor.whitespacesize = 1`: set the size of dots indicating whitespaces when shown (**v1.61+**).
- `editor.wrapflags = nil`: enable drawing of visual flags to indicate wrapped lines (**v0.51+**).
Possible values (can be combined): `wxstc.wxSTC_WRAPVISUALFLAG_END` (end of subline), `wxstc.wxSTC_WRAPVISUALFLAG_START` (beginning of subline), and `wxstc.wxSTC_WRAPVISUALFLAG_MARGIN` (line number margin).
- `editor.wrapindentmode = wxstc.wxSTC_WRAPINDENT_FIXED`: enable wrapped sublines to be indented to the position of their first subline or one more indent level (**v0.61+**).
Possible values: `wxstc.wxSTC_WRAPINDENT_FIXED` (align to left of window plus amount set by `editor.wrapstartindent`), `wxstc.wxSTC_WRAPINDENT_SAME` (align to first subline indent), and `wxstc.wxSTC_WRAPINDENT_INDENT` (align to first subline indent plus one more level of indentation).
- `editor.wrapmode = wxstc.wxSTC_WRAP_WORD`: set the type of wrapping applied (**v1.21+**).
Possible values: `wxstc.wxSTC_WRAP_WORD` (wrap on word or style boundaries), `wxstc.wxSTC_WRAP_CHAR` (wrap between any characters), `wxstc.wxSTC_WRAP_WHITESPACE` (wrap on whitespace), and `wxstc.wxSTC_WRAP_NONE` (no line wrapping).
- `editor.wrapstartindent = 0`: set the size of indentation of sublines for wrapped lines in terms of the average character width (**v0.61+**).

## Keyboard shortcuts

The editor component provides its own shortcut handling mechanism linked to specific editor actions.
For example, `Ctrl-D` will duplicate the current line.

The editor provides [default commands](doc-editor-keyboard-shortcuts) that can be modified to map to the key combinations you prefer.
To modify the key mapping, you can add the following line to the configuration file:

```lua
editor.keymap[#editor.keymap+1] =
  {('E'):byte(), wxstc.wxSTC_SCMOD_CTRL, wxstc.wxSTC_CMD_LINEEND}
```

This will bind `Ctrl-E` combination to remove the line content from the current position to the end of the line.
The description takes four parameters:

- key code, which may be a code for a visible character (`('E'):byte()`) or a [special code](http://www.scintilla.org/ScintillaDoc.html#KeyBindings) (`wxstc.wxSTC_KEY_UP`);
- key modifiers, which is a combination of `wxstc.wxSTC_SCMOD_CTRL`, `wxstc.wxSTC_SCMOD_SHIFT`, `wxstc.wxSTC_SCMOD_META`, and `wxstc.wxSTC_SCMOD_ALT`.
To **combine several modifiers**, make a sum of their values: `wxstc.wxSTC_SCMOD_CTRL + wxstc.wxSTC_SCMOD_SHIFT`.
On **macOS**, the Command key is mapped to `wxstc.wxSTC_SCMOD_CTRL` and the Control key to `wxstc.wxSTC_SCMOD_META`.
- [Keyboard command](http://www.scintilla.org/ScintillaDoc.html#KeyboardCommands), which specify the action that needs to be tied to the key combination;
- (optional) operating system, which is one of `'Windows'`, `'Macintosh'`, or `'Unix'` strings. If no operating system is specified, then the combination is available on all systems.

Note that the editor key mapping is different from the IDE key mapping as the former only works when the editor is in focus and the latter may work when other components have focus.
When there is a conflict, the IDE shortcuts take preference over editor shortcuts.
