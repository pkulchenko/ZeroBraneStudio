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
- `editor.autoreload = false`: auto-reload externally modified files (if no conflict detected).
- `editor.autotabs = false`: use tabs if detected.
- `editor.backspaceunindent = true`: remove one level of indentation when use backspace on a tab stop; set to `false` to disable.
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
- `editor.indentguide = true`: show indentation guides (0.90+); set to `false` or `nil` to disable.
- `editor.nomousezoom = false`: disable zoom with mouse wheel as it may be too sensitive.
- `editor.saveallonrun = false`: save modified files before executing Run/Debug commands (0.39+).
- `editor.showfncall = true`: mark function calls.
- `editor.smartindent = true`: use smart indentation.
- `editor.tabwidth = 2`: set tab width.
- `editor.usetabs = false`: enable using tabs.
- `editor.usewrap = true`: wrap long lines.
- `editor.whitespace = false`: display whitespaces.
- `editor.wrapflags = nil`: enable drawing of visual flags to indicate wrapped lines (0.51+).
Possible values (can be combined): `wxstc.wxSTC_WRAPVISUALFLAG_END` (end of subline), `wxstc.wxSTC_WRAPVISUALFLAG_START` (beginning of subline), and `wxstc.wxSTC_WRAPVISUALFLAG_MARGIN` (line number margin).
- `editor.wrapindentmode = wxstc.wxSTC_WRAPINDENT_FIXED`: enable wrapped sublines to be indented to the position of their first subline or one more indent level (0.61+).
Possible values: `wxstc.wxSTC_WRAPINDENT_FIXED` (align to left of window plus amount set by `editor.wrapstartindent`), `wxstc.wxSTC_WRAPINDENT_SAME` (align to first subline indent), and `wxstc.wxSTC_WRAPINDENT_INDENT` (align to first subline indent plus one more level of indentation).
- `editor.wrapstartindent = 0`: set the size of indentation of sublines for wrapped lines in terms of the average character width (0.61+).

## Output and Console

- `outputshell.fontname = "Courier New"`: set font name.
- `outputshell.fontsize = 10`: set font size (the default value is `11` on OSX).
- `outputshell.nomousezoom = false`: disable zoom with mouse wheel in Output/Console windows as it may be too sensitive.
- `outputshell.usewrap = true`: wrap long lines (0.51+); set to `nil` or `false` to disable. This setting only applies to the Output window; the Console always wraps its lines.

## Project/Filetree

- `filetree.fontname = nil`: set font name; Project/Filetree window has no default font as it is system dependent.
- `filetree.fontsize = 10`: set font size (the default size is `11` on OSX).

## Keyboard shortcuts

The editor component provides its own shortcut handling mechanism linked to specific editor actions.
For example, `Ctrl-D` will duplicate the current line.

The editor provides [default commands](doc-editor-keyboard-shortcuts) that can be modified to map to the key combinations you prefer.
To modify the key mapping, you can add the following line to the configuration file:

{% highlight lua %}
editor.keymap[#editor.keymap+1] =
  {('E'):byte(), wxstc.wxSTC_SCMOD_CTRL, wxstc.wxSTC_CMD_LINEEND}
{% endhighlight %}

This will bind `Ctrl-E` combination to remove the line content from the current position to the end of the line.
The description takes four parameters:

- key code, which may be a code for a visible character (`('E'):byte()`) or a [special code](http://www.scintilla.org/ScintillaDoc.html#KeyBindings) (`wxstc.wxSTC_KEY_UP`);
- key modifiers, which is a combination of `wxstc.wxSTC_SCMOD_CTRL`, `wxstc.wxSTC_SCMOD_SHIFT`, `wxstc.wxSTC_SCMOD_META`, and `wxstc.wxSTC_SCMOD_ALT`.
To **combine several modifiers**, make a sum of their values: `wxstc.wxSTC_SCMOD_CTRL + wxstc.wxSTC_SCMOD_SHIFT`.
On **OSX**, the Command key is mapped to `wxstc.wxSTC_SCMOD_CTRL` and the Control key to `wxstc.wxSTC_SCMOD_META`.
- [Keyboard command](http://www.scintilla.org/ScintillaDoc.html#KeyboardCommands), which specify the action that needs to be tied to the key combination;
- operating system, which is one of `'Windows'`, `'Macintosh'`, and `'Unix'` strings. If no operating system is specified, then the combination is available on all systems.

Note that the editor key mapping is different from the IDE key mapping as the former only works when the editor is in focus and the latter may work when other components have focus.
When there is a conflict, the IDE shortcuts take preference over editor shortcuts.
