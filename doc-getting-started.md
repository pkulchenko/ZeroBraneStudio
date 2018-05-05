---
layout: default
title: Getting Started
---

<ul id='toc'>&nbsp;</ul>

## Editor

The editor allows you to open several programs or files and work on them at the same time.
Each file is opened in its own page, with its name in a tab at the top of the page.
You can **switch** between pages by clicking on those tabs.
You can also **close** those pages when you don't need them by using the `File | Close Page` menu command or its shortcut `Ctrl-W` (`Cmd-W` on macOS).

## Opening and saving files

To **open** a program or file you can select the `File | Open` menu command or use its shortcut `Ctrl-O` (`Cmd-O` on macOS). Or, you can double click on the file name in the `Project` panel on the left. The editor will open that file for you in a new tab, or will activate one of the existing tabs if the file is already opened.

To **save** a program you can select the `File | Save` menu command at the top of the window or use its shortcut `Ctrl-S` (`Cmd-S` on macOS). If the program does not have a name yet, you will be asked to provide a name for it.

## Exiting the IDE

To **exit** ZeroBrane Studio, select the `File | Quit` menu command.
You will be prompted to save any unsaved changes.
The IDE will restore the editor tabs you are using the next time you start it.

## Running programs

To **execute** a program you can select `Project | Run` menu command.
This will run your program in a separate process using the interpreter you selected to run it; by default this is the Lua interpreter, which executes your code in LuaJIT.
The [Output window](#output-window) will show the output of the program (if any) and some messages from the IDE that detail what script is being executed and from what directory.

To **abort** the program from the IDE you can go to `Project | Stop Process`.
You will see a message in the Output window when the program is stopped.

## Output window

<img style="background:url(images/integrated-materials.png) -9px -682px" src="images/t.gif" class="inline"/>

The **Output window** captures the output of the programs you run, plus any **errors** and additional messages you may get during execution of those programs.

The Output window is also used to enter the text your program may read. You will see a prompt in the Output window where the text is expected to be entered.

## Console window

<img style="background:url(images/debugging.png) -9px -682px" src="images/t.gif" class="inline"/>

The **Console window** allows you to run Lua code fragments and calculate values of Lua expressions.
It will switch automatically between a **local console** that gives you access to the Lua interpreter that runs the IDE
and a **remote console** that allows you to execute code fragments and change variable values in your application when it is stopped in the debugger.

## Project directory

<img style="background:url(images/debugging.png) -9px -96px" src="images/t.gif" class="inline"/>

The current project directory is displayed in the **Project panel**.
The project panel helps you in several ways: it provides a bird's-eye view of all files in your project, it highlights the file you are working with (as long as it is in the same project), and it allows you to open a file by selecting its name and pressing `Enter`, or double-clicking on it.

To **change** the current project directory you have several options:

1. use the dropdown to select one of the project directories you used previously,
2. type or copy a new path into the dropdown at the top of the project panel,
3. go to `Project | Project Directory | Choose...` and set a new directory, or
4. go to `Project | Project Directory | Set From Current File` to set it to the same directory as the path of the current file.

## Selecting interpreter

<img style="background:url(images/integrated-materials.png) -994px -750px" src="images/t.gif" class="inline"/>

ZeroBrane Studio provides support for different Lua engines that may require different parameters or settings when running or debugging.
The settings are specified by **interpreters** that can be selected by going to `Project | Lua Interpreter` and selecting an interpreter you need from the list.
This not only sets the environment for running and debugging of your application, but also auto-complete, scratchpad, and other engine-dependent settings.

When you switch a project directory, the currently selected interpreter is saved and restored when you switch back to the current project.
The current interpreter is shown on the right side of the status bar (for example, in the screenshot on the right `Moai` interpreter is selected).

## Debugging programs

<img style="background:url(images/debugging.png) -320px -440px" src="images/t.gif" class="inline"/>

In addition to running programs you can also debug them, which gives you the ability to pause them, inspect variables, evaluate expressions, make changes to the values, and then continue.
To **start debugging** go to `Project | Start Debugging`.
Depending on your interpreter configuration, the debugger may stop your program on the first instruction (this is a default for most interpreters) or may execute it immediately (as configured for `Moai` and `Corona` interpreters).

When your program is running, you can **pause** it by going to `Project | Break`, which will stop your program at the next lua command executed.

When the debugger is stopped, you can **set/remove breakpoints** (using `Project | Toggle Breakpoint`),
**step through the code** (using `Project | Step Into`, `Project | Step Over`, and `Project | Step Out` commands),
**inspect variables** using the Watch window (`View | Watch Window`),
**view the call stack** using the Stack window (`View | Stack Window`),
**run Lua commands** in the [console](#console-window),
**run to cursor location** (`Project | Run To Cursor`),
and **continue** execution of your program (using `Project | Continue`).

## Stack window

<img style="background:url(images/debugging.png) -871px -682px" src="images/t.gif" class="inline"/>

The **Stack window** provides not only the call stack with function names, but also presents all **local variables and upvalues** for each of the stack frames.
You can even drill down to get values of individual elements in tables.

## Watch window

<img style="background:url(images/debugging.png) -516px -682px" src="images/t.gif" class="inline"/>

The **Watch window** provides a convenient way to evaluate variables and expressions after every stopping in the debugger.
You can also drill down to get values of individual elements in tables.

In addition to viewing the values that variables or expressions are evaluated to, you may also **change the values of those variables or expressions** and those changes will be reflected in the current stack frame of the application.
For example, if `tbl` is a table with three values (`{'a', 'b', 'c'}`), you can expand the table, right click on the second element, and select `Edit Value`.
You can then edit the value of the second element.
After entering the new value and pressing `Enter`, the new value will be sent to the application being debugger and will also be reflected in the Watch window.
The result is equivalent to executing `tbl[2] = "new value"` in the Console window, but provides an easy way to update the value without retyping the expression.

## Outline window

<img style="background:url(images/debugging.png) -9px -444px" src="images/t.gif" class="inline"/>

The **Outline window** provides a way to see the structure of the current file with all the functions and their parameters shown either in the order in which they are defined in a file (default) or as a sorted list.

Clicking on the function name will scroll the file to the position where the function is defined.
Anonymous functions are indicated using `~` for the name. There are several settings specific to display of the outlines, as documented in the [Outline section](doc-general-preferences#outline).

## Markers window

<img style="background:url(images/integrated-materials.png) -311px -682px" src="images/t.gif" class="inline"/>

The **Markers window** provides a way to see and navigate **bookmarks and breakpoints** in all opened project files.

Clicking on the marker line will jump to the line in the file where the marker is set, while clicking on the marker icon will remove the marker.

## Live coding

<img style="background:url(images/scratchpad-linux-mint.png) -270px -120px" src="images/t.gif" class="inline"/>

**Live coding** (also known as **Running as Scratchpad**) is a special debugging mode that allows for the changes you make in the editor to be immediately reflected in your application.
To **enable** this mode go to `Project | Run as Scratchpad` (when it is available) and your program will be started as during debugging.
You will continue to have access to the editor tab from which the scratchpad has been started and all the changes you make will be seen in your application.

In addition to regular editing, you can also mouse over a number (all numbers will be underlined as seen in the screenshot on the right) and drag a virtual slider left or right to change the value of that number.
If you make an error (whether a compile or run-time), it will be reported in the Output window.

To **exit** the scratchpad mode you can close the application, go to `Project | Stop Process`, or go to `Project | Run as Scratchpad` again to toggle scratchpad mode off.

Note that this functionality is highly interpreter dependent and some interpreters may not provide it at all and some may provide in a way that doesn't restart the entire application (for example, `LÖVE`, `Moai`, or `Gideros` interpreters).
Your code may also need to be written in a way that accomodates requirements of those engines. Please consult [live coding tutorials](documentation#live-coding) for details.

## Toolbar

<img style="background:url(images/debugging.png) -310px -60px" src="images/t.gif" class="inline"/>

Some of the most frequently used commands in the editor are also available on the **toolbar** (which is right above the editor window, and below the menu bar on Windows and Linux).
There you will find commands to open a new or existing file, or save a file, commands to undo and redo your changes, and commands to search and replace text in your programs.

You will also find the most frequently used debugger commands (`Start Debugging`, `Stop process`, `Break`, `Step Into`, `Step Over`, `Step Out`, `Toggle Breakpoint`, `Stack Windows`, and `Watch Window`).
The toolbar also includes a dropdown that lists all the functions recognized in the currently edited file and allows to navigate between those functions by selecting them from the list.

## Configuring the IDE

The default settings and layout should work for most users, but occasionally you may want to have more space available on the screen or prefer to have a window moved to a different position.

You can **close** the `Project` and `Output/Console` windows if you are not using them to get more screen space.
You can switch back to the default by using `View | Default Layout`.

You can **resize** the windows by dragging the splitters between them.
You can also **move** the windows by clicking and holding the mouse on the window caption area and dragging the window to a new location.
You can release the mouse when one side of the main window changes its color to light blue.
The new configuration will then be used until you reset or change it.

You can change the
[color scheme](doc-styles-color-schemes),
[general preferences](doc-general-preferences),
[editor preferences](doc-editor-preferences),
and the [IDE keymap](doc-faq#how-can-i-modify-a-key-mapping).

## Extending the IDE

In addition to the functionality included by default, there are also **50+ extension packages** in the [package repository](https://github.com/pkulchenko/ZeroBranePackage),
including packages like
[DocumentMap](https://github.com/pkulchenko/ZeroBranePackage/blob/master/documentmap.lua),
[UniqueTabName](https://github.com/pkulchenko/ZeroBranePackage/blob/master/uniquetabname.lua),
[CloneView](https://github.com/pkulchenko/ZeroBranePackage/blob/master/cloneview.lua),
[ProjectSettings](https://github.com/pkulchenko/ZeroBranePackage/blob/master/projectsettings.lua),
[SyntaxCheckOnType](https://github.com/pkulchenko/ZeroBranePackage/blob/master/syntaxcheckontype.lua),
and many others. You can create your own package (or modify an existing one) by following the [plugin documentation](doc-plugin).
