---
layout: default
title: Remote Debugging
---

ZeroBrane Studio supports remote debugging that allows to debug arbitrary Lua applications.
The application may be running on the same or a different computer from the one running a ZeroBrane Studio instance
(the debugger is using a socket interface to interact with the application).

## Remote debugging

* Open ZeroBrane Studio. 
Go to `Project | Start Debugger Server` and **start the debugger server** (if this menu item is disabled, the server is already started).
* **Open the Lua file** you want to debug.
* **Select the project folder** by going to `Project | Project Directory | Choose...`
or using `Project | Project Directory | Set From Current File`.
* Add `require('mobdebug').start()` call to your file.
If the application is running on a **different computer**, you need to specify an address of the computer where ZeroBrane Studio is running as the first parameter to the `start()` call: `require('mobdebug').start("12.345.67.89")` or `require('mobdebug').start("domain.name")`.
You can see the **domain name** to connect to in the Output window when you start debugger server: `Debugger server started at <domain>:8172.`
* Make `mobdebug.lua` and `luasocket` available to your application. This can be done in one of three ways:
(1) Set `LUA_PATH` and `LUA_CPATH` before starting your application (see [Setup environment for debugging](#setup_environment_for_debugging));
(2) Reference path to `mobdebug.lua` and `luasocket` using `package.path` and `package.cpath` (see [Configure path for debugging](#configure_path_for_debugging)); or
(3) Include `mobdebug.lua` with your application by copying it from `lualibs/mobdebug/mobdebug.lua` (this assumes your application already provides `luasocket` support).
* **Run your application**. You should see a green arrow next to the `start()` call in ZeroBrane Studio and should be able to step through the code.

## Setup environment for debugging

You can use a simple script to set `LUA_PATH` and `LUA_CPATH` environmental variables to reference `mobdebug` and `luasocket` files that come with ZeroBrane Studio:

    set ZBS=D:\path\to\ZeroBraneStudio
    set LUA_PATH=./?.lua;%ZBS%/lualibs/?/?.lua;%ZBS%/lualibs/?.lua
    set LUA_CPATH=%ZBS%/bin/?.dll;%ZBS%/bin/clibs/?.dll
    myapplication

## Configure path for debugging

In a similar way, instead of specifying `LUA_PATH` and `LUA_CPATH`, you can set `package.path` and `package.cpath` (if needed) directly from your script:

    package.path = package.path .. ";/usr/lib/zbstudio/lualibs/mobdebug/?.lua"

## Examples

See [Debugging Wireshark lua scripts](http://notebook.kulchenko.com/zerobrane/debugging-wireshark-lua-scripts-with-zerobrane-studio) for detailed description on how this remote debugging works with Wireshark scripts.

## Troubleshooting

* **How do I find a path to `mobdebug.lua`?**
`mobdebug.lua` is located in `lualibs/mobdebug` folder under your ZeroBrane Studio installation folder.
The location of ZeroBrane Studio is system dependent; on **Windows** it is the location of the folder you installed ZeroBrane Studio to; on **Linux** it is `/usr/lib/zbstudio`; and on **Mac OS X** it is `/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio`.
* **I can't step into functions defined in other files in my project.**
You either need to open them in the IDE before you want to step through them, or to [configure](doc-configuration.html) the IDE to auto-open files requested during debugging using `editor.autoactivate = true`.
* **The host name is detected incorrectly.**
In some rare cases the domain name detected by ZeroBrane Studio cannot be resolved, which prevents the debugger from working.
You can specify the domain name or address you want to use by [configuring](doc-configuration.html) the IDE with `debugger.hostname="domain"`.
* **I get "Debugger error: unexpected response after EXEC/LOAD '201 Started ...'".**
This is caused by not having a filename associated with a dynamic chunk loaded by your application.
If you are using `loadstring()`, you should pass a second parameter that is a filename for the fragment (and that file can then be debugged in ZBS if it's placed in the project directory).
If you are using `luaL_loadstring` (which has no option to label the chunk with it's file path), you can switch to using `luaL_loadbuffer` to pass that information.
