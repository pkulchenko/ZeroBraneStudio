---
layout: default
title: Remote Debugging
---

ZeroBrane Studio supports **remote debugging** that allows to debug arbitrary Lua applications.
The application may be running on the same or a different computer from the one running
the IDE instance (the debugger is using a socket interface to interact with the application).

## Remote debugging

* Launch the IDE.
Go to `Project | Start Debugger Server` and **start the debugger server** (if this menu item is disabled, the server is already started).
* **Open the Lua file** you want to debug.
* **Select the project directory** by going to `Project | Project Directory | Choose...`
or using `Project | Project Directory | Set From Current File`.
* Add `require('mobdebug').start()` call to your file.
If the application is running on a **different computer**, you need to specify an address of the computer running the IDE as the first parameter to the `start()` call: `require('mobdebug').start("12.345.67.89")` or `require('mobdebug').start("domain.name")`.
You can see the **domain name** to connect to in the Output window when you start debugger server: `Debugger server started at <domain>:8172.`
* Make `mobdebug.lua` and `luasocket` available to your application. This can be done in one of three ways:
  1. Set `LUA_PATH` and `LUA_CPATH` before starting your application (see [Setup environment for debugging](#setup-environment-for-debugging));
  2. Reference path to `mobdebug.lua` and `luasocket` using `package.path` and `package.cpath` (see [Configure path for debugging](#configure-path-for-debugging)); or
  3. Include `mobdebug.lua` with your application by copying it from `lualibs/mobdebug/mobdebug.lua` (this assumes your application already provides `luasocket` support).
* **Run your application**. You should see a green arrow pointing to the next statement after the `start()` call in the IDE and should be able to step through the code.

## Setup environment for debugging

You can use a simple script to set `LUA_PATH` and `LUA_CPATH` environmental variables to reference `mobdebug` and `luasocket` files that come with the IDE:

    set ZBS=D:\path\to\ZeroBraneStudio
    set LUA_PATH=./?.lua;%ZBS%/lualibs/?/?.lua;%ZBS%/lualibs/?.lua
    set LUA_CPATH=%ZBS%/bin/?.dll;%ZBS%/bin/clibs/?.dll
    myapplication

If you are running this on Linux, make sure you use the same path separator (`;`)
and reference proper location depending on your Linux architecture (replace `x86` with `x64` if you are running this on a 64bit system):

    export ZBS=/opt/zbstudio
    export LUA_PATH="./?.lua;$ZBS/lualibs/?/?.lua;$ZBS/lualibs/?.lua"
    export LUA_CPATH="$ZBS/bin/linux/x86/?.so;$ZBS/bin/linux/x86/clibs/?.so"
    ./myapplication

Note that these instructions are for **Lua 5.1**- and **LuaJIT**-based systems.
If your application is using **Lua 5.2** or **Lua 5.3** interpreters, then replace `clibs` in `LUA_CPATH`
values with `clibs52` or `clibs53`, respectively, to load proper versions of the required modules.

## Debugging of 64bit applications

If you are debugging a **64bit application on Windows**, you need to make the 64bit luasocket library available to your application
and set `package.cpath` appropriately (to make sure it references 64bit libraries before any other library that may be referenced there)
as the libraries included with the IDE are compiled for 32bit architecture and will not work with 64bit applications.

macOS and Linux don't require any special handling for 64bit applications as Linux version are available for both 32bit and 64bit architectures
and macOS libraries are compiled as universal libraries (and can be loaded from 32bit and 64bit applications).

If you also plan to launch the 64bit application from the IDE (instead of or in addition to
launching it outside of the IDE), you need to configure `path.lua` to point to the location of your Lua executable
(as described in the [general preferences section](doc-general-preferences#interpreter-path)).

## Configure path for debugging

In a similar way, instead of specifying `LUA_PATH` and `LUA_CPATH`, you can set `package.path` and `package.cpath` (if needed) directly from your script:

    package.path = package.path .. ";/opt/zbstudio/lualibs/mobdebug/?.lua"

## Examples

See [Debugging Wireshark lua scripts](http://notebook.kulchenko.com/zerobrane/debugging-wireshark-lua-scripts-with-zerobrane-studio) for detailed description on how this remote debugging works with Wireshark scripts.

## Troubleshooting

* **How do I find a path to `mobdebug.lua`?**
`mobdebug.lua` is located in `lualibs/mobdebug` directory under your ZeroBrane Studio installation directory.
The location of ZeroBrane Studio is system dependent;
on **Windows** it is the location of the directory you installed ZeroBrane Studio to;
on **Linux** it is `/opt/zbstudio`;
and on **macOS** it is `/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio`
(You may need to right click on the application and select `Show Package Contents` to navigate to that location on macOS).

* **I can't step into functions defined in other files in my project.**
You either need to open them in the IDE before you want to step through them, or to [configure](doc-configuration) the IDE to auto-open files requested during debugging using `editor.autoactivate = true`.

* **Breakpoints are not triggered.**
You may want to check [this FAQ answer](doc-faq#why-breakpoints-are-not-triggered) for possible reasons and suggestions on how to fix this.

* **The host name is detected incorrectly.**
In some rare cases the domain name detected by ZeroBrane Studio cannot be resolved, which prevents the debugger from working.
You can specify the domain name or address you want to use by [configuring](doc-configuration) the IDE with `debugger.hostname="domain"`.

* **I get `dynamic libraries not enabled` error.**
You may get the following error when loading `socket.core` on Linux:
_error loading module 'socket.core' from file '/opt/zstudio/bin/linux/x86/clibs/socket/core.so': dynamic libraries not enabled; check your Lua installation_.
This most likely means that the Lua interpreter you are using was built without `LUA_USE_DLOPEN` option enabled.
You can either enable it or statically link your application with luasocket.

* (Note: you should not see this error if you are using v0.38 or later) **I get "Debugger error: unexpected response after EXEC/LOAD '201 Started ...'".**
This is caused by not having a filename associated with a dynamic chunk loaded by your application.
If you are using `loadstring()`, you should pass a second parameter that is a filename for the fragment (and that file can then be debugged in ZeroBrane Studio if it's placed in the project directory).
If you are using `luaL_loadstring` (which has no option to label the chunk with its file path), you can switch to using `luaL_loadbuffer` to pass that information.
