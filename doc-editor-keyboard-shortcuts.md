---
layout: default
title: Editor Keyboard Shortcuts
---

The editor used in ZeroBrane Studio is based on the [Scintilla editing component](http://www.scintilla.org/) and provides access to most of its functionality.
These commands can be modified using [editor key mapping](doc-general-preferences#editor-key-mapping) settings.

Other shortcuts used in the application can be modified as described in the [key mapping](doc-general-preferences#key-mapping) section.

**Text editing** commands with no menu equivalents:

- `Tab`: Indent line or current selection
- `Shift-Tab`: Unindent line or current selection
- `Ctrl-L`/`Ctrl-Y`: Cut current line
- `Ctrl-D`: Duplicate selection or current line
- `Ctrl-Shift-T`: Copy current line
- `Ctrl-Shift-U`: Uppercase current selection
- `Ctrl-Backspace`: Delete to the beginning of the current word
- `Ctrl-Delete`: Delete to the end of the current word
- `Ctrl-Shift-Backspace`: Delete to the beginning of the line
- `Ctrl-Shift-Delete`: Delete to the end of the line

**Navigation and selection** commands:

- `Alt-Shift-cursor`: Block selection
- `Ctrl-(Shift-)[`: Jump to previous paragraph; `Shift` extends selection
- `Ctrl-(Shift-)]`: Jump to next paragraph; `Shift` extends selection
- `Ctrl-(Shift-)Left`: Jump to previous word; `Shift` extends selection
- `Ctrl-(Shift-)Right`: Jump to next word; `Shift` extends selection
- `Ctrl-(Shift-)/`: Jump to previous word part; `Shift` extends selection
- `Ctrl-(Shift-)\`: Jump to next word part; `Shift` extends selection
- `Alt-End`: Jump to end of display line (for wrapped lines)
- `Alt-Home`: Jump to beginning of display line (for wrapped lines)
- `Ctrl-Tab`/`Ctrl-PgDn`: Cycle right through editor tabs
- `Ctrl-Shift-Tab`/`Ctrl-PgUp`: Cycle left through editor tabs
- `Ctrl-Alt-Click`: Jump to definition (if there is a variable under cursor)
- `Ctrl-DblClick`: Select all instance of a variable or (when there is no variable under cursor) include the word under cursor into multiple selection
- `Alt-Left`: Jump to previous position after `Jump to definition`

**Folding** commands:

- `Shift-FoldMarginClick`: Fold/Unfold the current scope
- `Shift-Ctrl-FoldMarginClick`: Fold/Unfold the current scope along with any other folds in it
- `Ctrl-FoldMarginClick`: Select the current scope

`FoldMarginClick` is a click on a fold margin.

**Text size adjustment** commands:

- `Ctrl-Keypad+`: Magnify text size
- `Ctrl-Keypad-`: Reduce text size
- `Ctrl-Keypad/`: Restore text size to normal
- `Ctrl-MouseWheel`: Magnify/Reduce text size

Note that some of the keyboard shortcuts can't be modified using the mechanism described in [doc-editor-preferences#keyboard-shortcuts](Keyboard shortcuts) section.
Specifically, none of the `Click`, `DblClick`, or `FoldMarginClick` shortcuts can be modified.

**Note for macOS users**: in all these editor commands `Ctrl` means `Cmd` key, except in `Ctrl-Tab`, `Ctrl-Shift-Tab`, `Ctrl-PgUp`, and `Ctrl-PgDn` commands.
Also, Use `Delete` for `Backspace` and `Fn+Delete` for `Delete`.
