---
layout: default
title: Tips and Tricks
---

<ul id='toc'>&nbsp;</ul>

## Use arbitrary expressions in watches

Watches can be used to display not only variables, but also **any expression or function call**;
for example: `1+2`, `collectgarbage('count')`, or `tbl and tbl[1] or nil`.

## Show several values as one watch

To **show multiple values as one watch**, you can wrap them into a table literal: `{'a','b','c'}` or `{(function_that_returns_several_values()}`.

## Show selected elements from a table in the Watch window

To **show only some elements from a large table**, you can use an expression that may look like this: `tbl and {x=tbl.x, y=tbl.y} or nil`.

## Go to definition

(**v0.39+**) To **jump to the definition of a local variable** (also works for loop variables and parameters), you can use `Alt/Opt+Ctrl+Click` or right mouse click and select `Go To Definition`.
You can then **navigate back to the original location** by using `Alt/Opt-Left`.

## Select all instances of a variable

(**v0.38+**) To **select all instances of a variable** (scope-aware), you can use `Ctrl/Cmd+DblClick` or right mouse click and select `Rename All Instances`.
The menu item will also show how many instances will be selected ([screenshot and details](http://notebook.kulchenko.com/zerobrane/scope-aware-variable-indicators-zerobrane-studio)).

## Quick search

To **quickly search for previously searched word**, you can use `Find Next` (`F3`) and `Find Previous` (`Shift-F3`).

To **quickly search for selected string** (when it's different from the previous search string), you can use `Select and Find Next` (`Ctrl/Cmd-F3`) and `Select and Find Previous` (`Ctrl/Cmd-Shift-F3`).

## Navigate selected instances of a variable

When you select all instance of a variable, you can **navigate them forward and backward** using `Find Next` (`F3`) and `Find Previous` (`Shift-F3`).

## Search in the console history

(**v0.39+**) To **search and auto-complete commands in the console history**, you can start typing the command and then use `TAB`, which will auto-complete the last matching command.
You can see other matches if you continue pressing `TAB`.

## Auto-reload externally modified files

(**v0.50+**) To **auto-reload externally modified files** set `editor.autoreload` configuration setting to true.
If no conflict is detected, the file content is going to be reloaded and its current markers (breakpoints and others) are going to be restored if possible.

(**v0.80+**) This option is enabled by default.

## Hiding files in the Project tree

You can hide files with specific extensions in the Project tree by opening a local menu in the tree (right click on any tree item) and selecting `Hide '.ext' Files`.
You can unhide hidden files by selecting `Show Hidden Files` from the same menu.

## Refresh search results

You can refresh search results by using right click on the tab and selecting `Refresh Search Results` from the popup menu.

## Close search results pages

You can close search multiple results pages by using right click on the tab and selecting `Close Search Results Pages` from the popup menu.

## Quick jump to the function call from the Stack view

To **jump to the position in the source code referred to in the Stack window**, double click on a function name in the stack frame.

## Search or replace with regular expressions

To **search or replace using regular expressions**, you can enable a checkbox `Regular Expression`.
These regular expressions do not accept Lua character classes that start with `%` (like `%s`, `%d`, and others), but accept `.` (as any character), char-sets (`[]` and `[^]`), modifiers `+` and `*`, and characters `^` and `$` to match beginning and end of the string.
Regular expressions only match within a single line (not over multiple lines).
See [Scintilla documentation](http://www.scintilla.org/ScintillaDoc.html#SCI_GETTAG) for details on what special characters are accepted.

## Search and replacement with regular expressions and captures

(**v0.39+**) When regular expression search is used with search and replace, `\n` refer to first through ninth **pattern captures** marked with brackets `()`.
For example, when searching for `MyVariable([1-9])` and replacing with `MyOtherVariable\1`, `MyVariable1` will be replaced with `MyOtherVariable1`, `MyVariable2` with `MyOtherVariable2`, and so on.

## Pretty printing in the Console window

All results shown in the `Console` window are pretty printed as one line, with all complex results shown with all their elements.
To print complex elements on multiple lines, you can prepend the expression with `=`, as in `={1,2,3,'a','b','c'}`.

## Limit results shown while pretty printing in the Console window

To limit the number of levels shown during pretty printing, instead of `val`, use `return require('mobdebug').line(val, {maxlevel = 1})`, and instead of `=val`, use `return require('mobdebug').line(a, {indent = ' ', maxlevel = 1})`.

(**v1.51+**) Another option to limit the number of levels shown during pretty printing, is to add a comment with serializer options, so instead of `val`, use `val -- {maxlevel = 2}`.
You can use any [option supported by the Serpent serializer](https://github.com/pkulchenko/serpent#options), for example, you can change the format for the results of the expression using `numformat` option: `val --{numformat = "%x"}`.

## Quick jump to the source of the error

To **jump to the position referred to in the error message** shown in the `Output` window, you can double click on the line showing the error message.
This also works for messages in the stack trace as long as they include the file name.

## Run multiple instances of the IDE

To run **multiple instances of the IDE**, you can start one instance as you normally do, and then start the second instance using this command: `zbstudio -cfg "singleinstance=false"`.
If you are on macOS, you may need to use `open -n ZeroBraneStudio.app`.

## Run multiple instances of the IDE to debug two applications at the same time

To run **multiple instances of the IDE to debug two applications**, you can start one instance as you normally do, and then start the second instance using this command: `zbstudio -cfg "singleinstance=false; debugger.port = 8173"`.
If you are on macOS, you may need to use `open -n ZeroBraneStudio.app --args -cfg "debugger.port = 8173"`.

## Merge and split windows and tabs

You can **resize** windows by dragging the splitters between them.
To **undock** or **re-dock** the window, doubleclick on the tab background of the notebook in that window (**v0.60+**).
To **move** the window, click and hold the mouse on the window caption area (when the window is undocked); then drag the window to a new location.
To **dock** the window, release the mouse when one side of the main window changes its color to light blue.
If you want to avoid docking, press `Ctrl`/`Cmd` button before releasing the mouse button.
The new configuration will be used until you reset or change it.

Tabs in notebooks can also be **split vertically or horizontally**. Click and hold the mouse on the tab and drag it to the location you want it to split to until the light blue color appears showing the proposed split. Release the mouse to fix the split.
Some of the auxiliary panels can be **pulled out** of the notebook. For example, click and hold the mouse on the tab of the Markers panel and drag it out of the notebook. When you release the mouse, the panel will become a standalone window that you can then re-position and dock as described earlier in this section.

## Move windows without docking them

`Ctrl-Drag`/`Cmd-Drag` will move the window without trying to dock it.

## Project switching

You can **change the current project** in several ways:

1. Use `Project | Project Directory | Choose...`.
2. Use `File | Recent Projects` (**v0.60+**).
3. Use the context menu in the Project tree (mouse right click) and then `Project Directory` (**v0.60+**).
4. Use `Choose a project directory` icon on the toolbar.
5. Use dropdown next to the `Choose a project directory` icon on the toolbar (**v0.60+**).

## Project tree refresh

(**v1.40+**) All the changes in the file system will be reflected in the Project tree when they happen in the folders expanded in the tree.

To refresh the project tree manually you have several options:

1. Collapse/Expand a particular directory, which will refresh its content.
2. (**v1.10+**) Use `Refresh` item in the context menu in the project tree (mouse right click).

If you are using one of the earlier versions, you can check [Refresh Project](https://github.com/pkulchenko/ZeroBranePackage/blob/master/refreshproject.lua) plugin (Windows only).

## Show Output and Console windows side by side

The default configuration shows `Output` and `Console` windows as tabs in the same window.
If you want to see them side by side, you can **drag one of the tabs to a different location** inside the same window and dock it there.

## Clear the content of the Output window

The content of the `Output` window can be cleared by accessing context menu (right click of the mouse) and selecting `Clear Output Window`.

## Zooming all editor tabs

(**v0.41+**) Use `Shift+Zoom` (`Shift+Ctrl+Scroll`) to zoom all editors.
Using `Ctrl+Scroll` still zooms only the current editor tab.

## Sorting of functions in the Outline

To change the order of functions displayed in the `Outline` between **sorted** and **in the order of appearence in the source file**,
access the context menu (right click on the mouse) in the `Outline` and select toggle `Sort By Name`.

To change the default order, add the following to the [configuration](doc-configuration) file: `outline.sort = true/false`.

## Copying value from the Watch window

To copy a value from the Watch window to the clipboard (which may be useful if the string representation of the value doesn't fit in the window),
access the context menu (right click on the mouse while pointing to the value to copy) and select `Copy Value`.

## Show numeric values in Console in hexadecimal format

To change the format of numeric values, add the following fragment to the [configuration](doc-configuration) file or execute it in the Local Console (in which case it will only be active for the current session):

```lua
debugger.init = [[
  local mdb = require('mobdebug')
  mdb.origline, mdb.line = mdb.line, function(v) return mdb.origline(v, {numformat = "0x%x"}) end
]]
```

This will affect all the numbers shown in the Watch, Stack, tooltips, and Remote Console windows.
To switch back either remove the configuration setting or reset `debugger.init` back to an empty value.

## Change format for numeric values in Stack/Watch windows

(**v1.51+**) To change the format of numeric values shown in Stack/Watch windows, set `debugger.numformat` contiguration setting to the desired value.
For example, to show  the values in the hexadecimal format, add the following fragment to the [configuration](doc-configuration) file:

```lua
debugger.numformat = "0x%x"
```
This will affect all the numbers shown in the Watch, Stack, and tooltips, but will *not* affect Local/Remote Console windows.

## Adding custom API

To add your own custom API to be recognized in auto-complete and tooltips, you can use the [`api` configuration setting](doc-general-preferences#custom-apis).

## Document map (plugin)

To enable document map that provides a bird's-eye view of the currently edited document, you can use [document map plugin](https://github.com/pkulchenko/ZeroBranePackage/blob/master/documentmap.lua).

## Clone view (plugin)

To open and edit the same file in multiple windows, you can use [clone view plugin](http://notebook.kulchenko.com/zerobrane/clone-editor-view-plugin-for-zerobrane-studio).

## Highlight selected (plugin)

To highlight all instances of the currently selected word, you can use [highlight selected plugin](https://github.com/pkulchenko/ZeroBranePackage/blob/master/highlightselected.lua).

## Real-time watches (plugin)

To display values from your program while it is running, you can use [real-time watches view plugin](http://notebook.kulchenko.com/zerobrane/real-time-watches-plugin-zerobrane-studio).

## Project settings (plugin)

To set project-specific settings, you can use [project settings plugin](https://github.com/pkulchenko/ZeroBranePackage/blob/master/projectsettings.lua).

## Auto-start debugger (plugin)

To start the debugger server automatically when the IDE is started, you can use [autostart debugger plugin](https://github.com/pkulchenko/ZeroBranePackage/blob/master/autostartdebug.lua).
