---
layout: default
title: Frequently Asked Questions
---

<ul id='toc'>&nbsp;</ul>

## What does the bluish line underlying some names mean?

It identifies function calls. 
You can [disable it](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L98),
[change its type](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L104),
or [change its color](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L101).

## How to specify a directory my script should be executed in for `require` commands to work?

You can set the [project folder](doc-getting-started.html#project_folder), which will be used to set the current folder when your application is run or debugged.

## How to change background color in the editor?

You can put `styles.text.bg = {240,240,240}` in `cfg/user.lua`. See the [example](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua).

## Why stepping into function calls doesn't work in some cases?

You need to have a file opened in the IDE before you can step into functions defined in that file.
You can also configure the IDE to [auto-open files](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L71) for you.

## Is it possible to debug dynamic fragments loaded with `loadstring()`?

Yes; you can specify a filename as the second parameter to `loadstring` and have that file in your project folder with the same content as what's loaded with `loadstring`.
You can then open that file in the IDE or configure it to auto-open it for you.

## Is debugging of Lua 5.2 applications supported?

Yes; you need to add `getfenv` and `setfenv` functions from [compat_env](https://github.com/davidm/lua-compat-env) to the application you want to debug.

## How to accept keyboard input for applications started from the IDE?

Simply make sure that you "print" something using `print` or `io.write` before reading the input.
You will see a prompt in the Output window where you can enter your input.

## Where is the configuration file stored?

This is covered in the description of system [configuration](doc-configuration.html).

## How to modify a key mapping?

To modify a key mapping for a particular menu item, you can add the following command to your [configuration](doc-configuration.html):
`local G = ...; keymap[G.ID_STARTDEBUG] = "Ctrl-Shift-D"`.
This will modify the default shortcut for `Program | Start Debugging` command.

See an [example in user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L18),
the description for possible [accelerator values](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/src/editor/keymap.lua#L4),
and the full list of IDs in [src/editor/keymap.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/src/editor/keymap.lua).

## How do I restore default configuration for recent files, projects, and editor tabs?

You can **remove the configuration file** ZeroBrane Studio is using to store these settings.
The location (and the name) of this file is system dependent:
it is located in `%HOME%\ZeroBraneStudio.ini` on Windows,
`$HOME/Library/Preferences/ZeroBraneStudio Preferences` on Mac OSX, and in
`$HOME/.ZeroBraneStudio` on Linux. 
You can see the location of the HOME directory if you type `wx.wxGetHomeDir()` into the Local console.
