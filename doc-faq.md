---
layout: default
title: Frequently Asked Questions
---

<ul id='toc'>&nbsp;</ul>

## What does the bluish line under or around some names mean?

It identifies **function calls**.
Depending on your current style it may also be shown as a solid line or a rounded box around a function name.
You can [disable it](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L98),
[change its type](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L104),
or [change its color](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L101).
(Note that before v0.38 you'd need to set/modify `styles.fncall` instead of `styles.indicator.fncall`.)

## How to specify a directory my script should be executed in for `require` commands to work?

You can set the [project directory](doc-getting-started.html#project_directory), which will be used to set the current directory when your application is run or debugged.

## Why stepping into function calls doesn't work in some cases?

You need to have a file opened in the IDE before you can step into functions defined in that file.
You can also configure the IDE to [auto-open files](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L71) for you.

## Why do I get a warning about attempt to connect to port 8172 when I start debugging?

The IDE is using port 8172 to communicate with the application being debugged.
If you get a firewall warning, you need to **allow the connection** for the debugging to work properly.

## Why am I getting "could not connect to ...:8172" message?

This may happen for three reasons:

- You start your application that uses `require('mobdebug').start()` call to connect to the IDE, but the **debugger server is not started** in the IDE.
You can fix this by selecting `Project | Start Debugger Server`; if it is disabled, the server is already started.
- Your **firewall is configured to block connection** to port 8172, which is used by the IDE to communicate with the application you are debugging.
You need to allow this connection for the debugging to work.
- In rare cases the IDE may **incorrectly detect the hostname** of the computer it runs on, which may prevent the debugging from working.
The **hostname is shown** in the Output window when the debugging is started: `Debugger server started at <hostname>:<port>`.
You can use a different hostname by setting `debugger.hostname` value in the [configuration file](doc-general-preferences.html#debugger).

## Why is the text blurry when running on Windows 8?

Right-click on ZeroBrane Studio icon -> `Properties` -> `Compatibility` -> `"Disable display scaling on high DPI settings"`.
See the link in [this ticket](https://github.com/pkulchenko/ZeroBraneStudio/issues/210) for alternative solutions if this doesn't work.

## How to change background color in the editor?

You can put `styles.text.bg = {240,240,240}` in `cfg/user.lua`.
See the [example](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua).
To modify colors and appearance of IDE elements, check [documentation on styles and color schemes](http://studio.zerobrane.com/doc-styles-color-schemes.html).

## Is it possible to debug dynamic fragments loaded with `loadstring()`?

Yes; starting from v0.38 if you step into `loadstring()` call, the IDE will open a new window with the code you can then step through.
If you use an older version, you can specify a filename as the second parameter to `loadstring` and have that file in your project directory with the same content as what's loaded with `loadstring`.
You can then open that file in the IDE or configure it to auto-open it for you.

## Is debugging of Lua 5.2 applications supported?

Yes; see [Lua 5.2 debugging](doc-lua52-debugging.html) section for details.

## Is debugging of LuaJIT applications supported?

Starting from v0.35 the debugging of LuaJIT applications is supported out-of-the-box.
See [LuaJIT debugging](doc-luajit-debugging.html) section for details.

## How to accept keyboard input for applications started from the IDE?

"print" something using `print` or `io.write` before reading input.
You will see a prompt in the Output window where you can enter your input.

## Where is the configuration file stored?

This is covered in the description of system [configuration](doc-configuration.html).

## How can I modify a key mapping?

To modify a key mapping for a particular menu item, you can add the following command to your [configuration](doc-configuration.html):
`local G = ...; keymap[G.ID_STARTDEBUG] = "Ctrl-Shift-D"`.
This will modify the default shortcut for `Program | Start Debugging` command.

See an [example in user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L18),
the description for possible [accelerator values](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/src/editor/keymap.lua#L4),
and the full list of IDs in [src/editor/keymap.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/src/editor/keymap.lua).

## How do I start two ZeroBrane Studio instances to debug two applications at the same time?

You can start one instance as you normally do and then start the second instance using the following command: `zbstudio -cfg "singleinstance=false; debugger.port = 8173`.
This command disables a singleinstance check for the second instance and configures it to use port 8173 for debugging.
You can then use `require('mobdebug').start("domain-name", 8173)` in your application to connect to the second instance for debugging.

If you use Mac OSX, you may need to run the command as `open ZeroBraneStudio.app --args -cfg "singleinstance=false; debugger.port = 8173`.

## How do I restore default configuration for recent files, projects, and editor tabs?

You can **remove the configuration file** ZeroBrane Studio is using to store these settings.
The location (and the name) of this file is system dependent:
it is located in `%HOME%\ZeroBraneStudio.ini` (for v0.35 and earlier) and in `C:\Users\<user>\AppData\Roaming\ZeroBraneStudio.ini` (for v0.36 and later) on Windows,
`$HOME/Library/Preferences/ZeroBraneStudio Preferences` on Mac OSX, and in
`$HOME/.ZeroBraneStudio` on Linux. 
You can see the location of the HOME directory if you type `wx.wxGetHomeDir()` into the Local console.
