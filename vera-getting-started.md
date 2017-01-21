---
layout: vera
title: Getting Started
---

<ul id='toc'>&nbsp;</ul>

## Editor

The editor allows you to open several script files and work on them at the same time.
Each opened file has its own page with a name and a tab at the top of the page.
You can **switch** between pages by clicking on those tabs.
You can also **close** those pages when you don't need them by using the `File | Close Page` menu or its shortcut `Ctrl-W` (`Cmd-W` on OSX).

## Saving and opening programs

To **save** a program you can go to the `File | Save` menu at the top of the window or use its shortcut `Ctrl-S` (`Cmd-S` on OSX). If the program does not have a name yet, you will be asked to provide a name for it.

To **open** a program or file you can go to the `File | Open` menu (or use its shortcut) or double click on the file name in the `Project` panel on the left. The editor will open that file for you or will activate one of the existing pages if the file is already opened.

## Exiting the IDE

To **exit** the development environment you are using, go to the `File | Quit` menu.
You will be prompted to save any unsaved changes.
The IDE will restore the editor tabs you are using the next time you start it.

## Running programs

To **execute** a program you can go to `Project | Run` menu.
The Output window will show the output of the program (if any) and some messages from the IDE that details what script is being executed and from what directory.

To **abort** the program while it is running, you can go to `Project | Stop Process`.
You will see a message in the Output window when the program is stopped.

## Output window

<img style="background:url(images/vera-debugging.png) -10px -575px" src="images/t.gif" class="inline"/>

The **Output window** captures the output of the programs you run, plus any **errors** and additional messages you may get during execution of those programs.

It will show messages your application "prints" during debugging.
Note that the output of `print` commands will be pretty-printed: `print(sometable)` will print the table content, showing `{a = 1, b = 2}` in the output (assuming that was the content of `sometable`).

## Console window

<img style="background:url(images/vera-debugging.png) -470px -575px" src="images/t.gif" class="inline"/>

The **Console window** allows to run Lua code fragments and calculate values of Lua expressions.
It will switch automatically between a **local console** that gives you access to the Lua interpreter that runs the IDE
and a **remote console** that allows you to execute code fragments and change variable values in your application when it is stopped in the debugger.

## Project directory

<img style="background:url(images/vera-debugging.png) -10px -70px" src="images/t.gif" class="inline"/>

The current project directory is displayed in the **Project panel**.
The project panel helps you in several ways: it provides a bird's-eye view of all files in your project, it highlights the file you are working with (as long as it is in the same project), and it allows you to open a file by selecting a file and pressing `Enter` or double-clicking on it.

To **change** the current project directory you have several options:

1. use the dropdown to select one of the project directories you used previously,
2. type or copy a new path into the dropdown at the top of the project panel,
3. go to `Project | Project Directory | Choose...` and set a new directory, or
4. go to `Project | Project Directory | Set From Current File` to set it to the same directory as the path of the current file.

## Selecting interpreter

<img style="background:url(images/vera-debugging.png) -744px -608px" src="images/t.gif" class="inline"/>

_ZeroBrane Studio for Vera_ includes support for different Lua engines that may require different parameters or settings when running or debugging.
The settings are specified by **interpreters** that can be selected by going to `Project | Lua Interpreter` and selecting an interpreter you need from the list.

When you switch a project directory, the currently selected interpreter is saved and restored when you switch back to the current project.
The current interpreter is shown on the right side of the status bar (for example, in the screenshot on the right `Vera` interpreter is selected).

## Debugging programs

<img style="background:url(images/vera-debugging.png) -240px -425px" src="images/t.gif" class="inline"/>

In addition to running programs you can also debug them, which gives you the ability to pause them, inspect variables, evaluate expressions, make changes to the values, and then continue.
To **start debugging** go to `Project | Start Debugging`.
The debugger will launch your application and stop on the first instruction.

When the debugger is stopped, you can **set/remove breakpoints** (using `Project | Toggle Breakpoint`),
**step through the code** (using `Step Into`, `Step Over`, and `Step Out` commands),
**inspect variables** using the [Watch window](#watch-window) (`View | Watch Window`),
**view the call stack** using the [Stack window](#stack-window) (`View | Stack Window`),
**run Lua commands** in the [console](#console-window),
**check the value of a variable or expression** in a [tooltip](#tooltip),
and **continue** execution of your program (using `Project | Continue`).

When your program is running, you can **pause** it by going to `Project | Break`, which will stop your program at the next lua command to be executed.

[Debugging overview](vera-debugging) and [remote debugging](vera-remote-debugging) sections cover this topic in more detail and provide code examples.

## Stack window

<img style="background:url(images/debugging.png) -674px -133px" src="images/t.gif" class="inline"/>

The Stack window provides not only the call stack with function names, but also presents all local variables and upvalues for each of the stack frames.
You can even drill down to get values of individual elements in tables.

## Watch window

<img style="background:url(images/debugging.png) -674px -360px" src="images/t.gif" class="inline"/>

The Watch view provides a convenient way to evaluate variables and expressions after every step of the debugger.
You can also drill down to get values of individual elements in tables.

In addition to viewing the values that variables or expressions are evaluated to, you may also **change the values of those variables or expressions** and those changes will be reflected in the current stack frame of the application.
For example, if `tbl` is a table with three values (`{'a', 'b', 'c'}`), you can expand the table, right click on the second element, and select `Edit Value`.
You can then edit the value of the second element.
The result is equivalent to executing `tbl[2] = "new value"` in the Console window, but provides an easy way to update the value without retyping the expression.

## Tooltip

In addition to being able to use the Console or the Watch window to see the values of variables and expressions,
you can also mouse over a variable (or select an expression and mouse over it) during debugging to see its value.

The value is shown for the simplest expression the cursor is over; for example, if the cursor is over 'a' in `foo.bar`, you will see the value for `foo.bar`, but if the cursor is over 'o' in the same expression, you'll see the value of `foo` instead.
You can always select the expression to be shown in the tooltip to avoid ambiguity.

## Vera functions

<img style="background:url(images/vera-debugging.png) -345px -375px" src="images/t.gif" class="inline"/>

_ZeroBrane Studio for Vera_ integrates several functions that make your work with Vera devices more convenient.
If you have an active debugging session, you can **upload a file to the device** by using right click in the Editor or by right clicking on a file in the Project tree.

You can also **download `LuaUPnP.log` file** and **restart Luup engine** by selecting a proper menu item from the same context menu in the Editor.
You will see a confirmation message in the Output window: `Uploaded file '/etc/cmh-ludl/...'.`.

## Auto-complete

The editor provides **auto-complete for Lua and Luup functions** and tables.
For example, if you type `luup.` you will see a list of functions available
as part of luup API and if you type `luup.call` you will see suggestions
for  `call_action`, `call_delay`, and `call_timer` functions.

In addition to auto-complete suggestions, you will also get tooltips with
information about parameters, return values, and descriptions for Luup
functions. You can see them when you type `(` after a function call or when
you click `Ctrl/Cmd-T` with the cursor being on a function call.

## Toolbar

<img style="background:url(images/vera-debugging.png) -180px -45px" src="images/t.gif" class="inline"/>

Some of the most frequently used commands in the editor are also available on the **toolbar** (which is right above the editor window and below the menu bar).
There you will find commands to open a new or an existing file, save a file, commands to undo and redo your changes, and commands to search and replace text in your programs.
You will also find most frequently used debugger commands (`Start Debugging`, `Stop process`, `Break`, `Step Into`, `Step Over`, `Step Out`, `Toggle Breakpoint`, `Stack Windows`, and `Watch Window`).
The toolbar also includes a dropdown that lists all the functions recognized in the currently edited file and allows to navigate between those functions by selecting them from the list.

## Configuring the IDE

The default settings and layout should work for most users, but occasionally you may want to have more space available on the screen or prefer to have a window moved to a different position.

You can **close** the `Project` and `Output/Console` windows if you are not using them to get more screen space. You can switch back to the default by using `View | Default Layout`.

You can **resize** the windows by dragging the splitters between them. You can also **move** the windows by clicking and holding the mouse on the window caption area and dragging the window to a new location. You can release the mouse when one side of the main window changes its color to light blue. The new configuration will then be used until you reset or change it.
