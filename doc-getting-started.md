---
layout: default
title: Getting Started
---

<ul id='toc'>&nbsp;</ul>

## Editor

The editor allows you to open several programs or files and work on them at the same time.
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
This will run your program in a separate process using the interpreter you selected to run it (the Lua interpreter by default).
The Output window will show the output of the program (if any) and some messages from the IDE that details what script is being executed and from what directory.

To **abort** the program from the IDE you can go to `Project | Stop Process`.
You will see a message in the Output window when the program is stopped.

## Output window

<img style="background:url(images/integrated-materials.png) -9px -497px" src="images/t.gif" class="inline"/>

The **Output window** captures the output of the programs you run, plus any **errors** and additional messages you may get during execution of those programs.

The Output window is also used to enter the text your program may read. You will see a prompt in the Output window where the text is expected to be entered.

## Console window

<img style="background:url(images/unicode-console.png) -9px -499px" src="images/t.gif" class="inline"/>

The **Console window** allows to run Lua code fragments and calculate values of Lua expressions.
It will switch automatically between a **local console** that gives you access to the Lua interpreter that runs the IDE
and a **remote console** that allows you to execute code fragments and change variable values in your application when it is stopped in the debugger.

## Project directory

<img style="background:url(images/debugging.png) -8px -76px" src="images/t.gif" class="inline"/>

The current project directory is displayed in the **Project panel**.
The project panel helps you in several ways: it provides a bird's-eye view of all files in your project, it highlights the file you are working with (as long as it is in the same project), and it allows you to open a file by selecting a file and pressing `Enter` or double-clicking on it.

To **change** the current project directory you have several options:
(1) use the dropdown to select one of the project directories you used previously,
(2) type or copy a new path into the dropdown at the top of the project panel,
(3) go to `Project | Project Directory | Choose...` and set a new directory, or
(4) go to `Project | Project Directory | Set From Current File` to set it to the same directory as the path of the current file.

## Selecting interpreter

<img style="background:url(images/debugging.png) -744px -608px" src="images/t.gif" class="inline"/>

ZeroBrane Studio provides support for different Lua engines that may require different parameters or settings when running or debugging.
The settings are specified by **interpreters** that can be selected by going to `Project | Lua Interpreter` and selecting an interpreter you need from the list.
This not only sets the environment for running and debugging of your application, but also auto-complete, scratchpad, and other engine-dependent settings.

When you switch a project directory, the currently selected interpreter is saved and restored when you switch back to the current project.
The current interpreter is shown on the right side of the status bar (for example, in the screenshot on the right `Moai` interpreter is selected).

## Debugging programs

<img style="background:url(images/debugging.png) -234px -234px" src="images/t.gif" class="inline"/>

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

## Live coding

<img style="background:url(images/scratchpad-linux-mint.png) -270px -120px" src="images/t.gif" class="inline"/>

**Live coding** (also known as **Running as Scratchpad**) is a special debugging mode that allows for the changes you make in the editor to be immediately reflected in your application.
To **enable** this mode go to `Project | Run as Scratchpad` (when it is available) and your program will be started as during debugging.
You will continue to have access to the editor tab from which the scratchpad has been started and all the changes you make will be seen in your application.

In addition to regular editing, you can also mouse over a number (all the number in your script will be underlined as you can see in the screenshot on the right) and drag a virtual sliders left or right to change the value of that number.
If you make an error (whether a compile or run-time), it will be reported in the Output window.

To **exit** the scratchpad mode you can close the application, go to `Project | Stop Process`, or go to `Project | Run as Scratchpad`.

Note that this functionality is highly interpreter dependent and some interpreters may not provide it at all (for example, `Corona`) and some may provide in a way that doesn't restart the entire application (for example, `Love2d`, `Moai`, or `Gideros` interpreters).
Your code may also need to be written in a way that accomodates requirements of those engines. Please consult [live coding tutorials](documentation#live-coding) for details.

## Toolbar

<img style="background:url(images/debugging.png) -248px -48px" src="images/t.gif" class="inline"/>

Some of the most frequently used commands in the editor are also available on the **toolbar** (which is right above the editor window and below the menu bar).
There you will find commands to open a new or an existing file, save a file, commands to undo and redo your changes, and commands to search and replace text in your programs.
You will also find most frequently used debugger commands (`Start Debugging`, `Stop process`, `Break`, `Step Into`, `Step Over`, `Step Out`, `Toggle Breakpoint`, `Stack Windows`, and `Watch Window`).
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
