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

## What are the dotted and dashed lines under variable names?

These are **scope indicators**; you can [change their types, colors, or disable them](doc-styles-color-schemes.html#indicators).

## How to specify a directory my script should be executed in for `require` commands to work?

You can set the [project directory](doc-getting-started.html#project_directory), which will be used to set the current directory when your application is run or debugged.

## Why stepping into function calls doesn't work in some cases?

You need to have a file opened in the IDE before you can step into functions defined in that file.
You can also configure the IDE to [auto-open files](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L71) for you.

## Why do I get a warning about attempt to connect to port 8172 when I start debugging?

The IDE is using port 8172 to communicate with the application being debugged.
If you get a firewall warning, you need to **allow the connection** for the debugging to work properly.

## Why am I getting "could not connect to ...:8172" message?

This may happen for several reasons:

- You start your application that uses `require('mobdebug').start()` call to connect to the IDE, but the **debugger server is not started** in the IDE.
You can fix this by selecting `Project | Start Debugger Server`; if it is disabled, the server is already started.
- Your **firewall is configured to block connection** to port 8172, which is used by the IDE to communicate with the application you are debugging.
You need to allow this connection for the debugging to work.
- In rare cases the IDE may **incorrectly detect the hostname** of the computer it runs on, which may prevent the debugging from working.
The **hostname is shown** in the Output window when the debugging is started: `Debugger server started at <hostname>:<port>`.
You can use a different hostname by setting `debugger.hostname` value in the [configuration file](doc-general-preferences.html#debugger).
For example, if the default hostname is incorrect, **try setting it to `localhost`** by using `debugger.hostname = "localhost"`.
- You may be **on VPN**, which may **block connections** or cause the IDE to **incorrectly detect the hostname**.
You may configure `debugger.hostname` as described above to see if this resolves the issue.

## Why my breakpoints are not triggered?

Breakpoints set in source files may not work for several reasons:

- A breakpoint may be **inside a coroutine**; by default breakpoints inside coroutines are not triggered.
To enable debugging in coroutines, including triggering of breakpoints, you may either
(1) add `require('mobdebug').on()` call to that coroutine, which will enable debugging for that particular coroutine, or
(2) add `require('mobdebug').coro()` call to your script, which will enable debugging for all coroutines created using `coroutine.create` later in the script.
- If you enable coroutine debugging using `require('mobdebug').coro()`, this will **not affect coroutines created using C API** or Lua code wrapped into `coroutine.wrap`.
You can still debug those fragments after adding `require('mobdebug').on()` to the coroutine code. 
- The path of the file known to the IDE may not be the same as the path known to the Lua engine.
For example, if you use an embedded engine, you may want to check if the path reported by the engine is normalized (doesn't include `../` references) by checking the result of `debug.getinfo(1,"S").source`.

## Is it possible to debug dynamic fragments loaded with `loadstring()`?

Yes; starting from v0.38 if you step into `loadstring()` call, the IDE will open a new window with the code you can then step through.
If you use an older version, you can specify a filename as the second parameter to `loadstring` and have that file in your project directory with the same content as what's loaded with `loadstring`.
You can then open that file in the IDE or configure it to [auto-open](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L71) it for you.

## Is debugging of Lua 5.2 applications supported?

Yes; see [Lua 5.2 debugging](doc-lua52-debugging.html) section for details.

## Is debugging of LuaJIT applications supported?

Starting from v0.35 the debugging of LuaJIT applications is supported out-of-the-box.
See [LuaJIT debugging](doc-luajit-debugging.html) section for details.

## Why am I getting compilation errors in the IDE when my code runs fine outside of it?

Starting from v0.39, ZeroBrane Studio is using LuaJIT as its internal Lua engine.
LuaJIT is a bit more strict than Lua 5.1 in some checks and may return errors even when your application runs fine by Lua 5.1.
One typical example is string escape sequences. Lua 5.1 lists [escape sequences it recognizes](http://www.lua.org/pil/2.4.html), but it will accept other sequences as well, for example, `\/`.
Running a script with this escape sequence under LuaJIT will trigger an error: `invalid escape sequence near ...`.

The solution in this case is to **"fix" the escape sequence** and replace `\/` with `/`, which will have the same effect in Lua 5.1, LuaJIT, and Lua 5.2.

## Why is the text blurry when running on Windows 8?

Right-click on ZeroBrane Studio icon -> `Properties` -> `Compatibility` -> `"Disable display scaling on high DPI settings"`.
See the link in [this ticket](https://github.com/pkulchenko/ZeroBraneStudio/issues/210) for alternative solutions if this doesn't work.

## Why is the text blurry in the editor when running on retina display (OSX)?

You can set `hidpi = true` in [configuration settings](doc-configuration.html).
Using this setting negatively affects [indicators](doc-styles-color-schemes.html#indicators) that have alpha property, so it is not enabled by default.

## How to change background color in the editor?

You can specify `styles.text.bg = {240,240,240}` in [configuration settings](doc-configuration.html).
See the [example](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua).
To modify colors and appearance of IDE elements, check [documentation on styles and color schemes](http://studio.zerobrane.com/doc-styles-color-schemes.html).

## How to accept keyboard input for applications started from the IDE?

"print" something using `print` or `io.write` before reading input.
You will see a prompt in the Output window where you can enter your input.

## Where is the configuration file stored?

This is covered in the description of system [configuration](doc-configuration.html).

## How can I modify a key mapping?

To modify a key mapping for a particular menu item, see the [key mapping](doc-general-preferences.html#key_mapping) section.
You may also review [xcode-keys](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/xcode-keys.lua) configuration file that can be used to modify keyboard shortcuts to match those in XCode.

## Why am I getting a warning about "invalid UTF8 character" in the files I open in the editor?

You probably have files created using one of Microsoft [Windows code pages](http://en.wikipedia.org/wiki/Windows_code_page#List); most likely 1252, 936, or 950.
ZeroBrane Studio is using [UTF-8 encoding](http://en.wikipedia.org/wiki/UTF-8), which allows users to use any supported language, but the files need to use Unicode encodings.
If you want to continue editing this file in the IDE, you have two choices:

1. Ignore the warning and **change `[SYN]` characters** to whatever text you need *inside ZeroBrane Studio*.
2. **Convert your files** from the encoding you are using to UTF-8 (65001) and then load them into the IDE.

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

## How do I show Corona SDK Console window on Windows?

You may add the following line to [system or user configuration](doc-configuration.html): `unhidewindow.ConsoleWindowClass = 0`.
