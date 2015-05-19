---
layout: default
title: LuaJIT Debugging
---

ZeroBrane Studio supports **debugging of [LuaJIT](http://luajit.org/) applications** in several ways:

1. (v0.39+) **LuaJIT (v2.0.2) interpreter is included** in ZeroBrane Studio and is the default interpreter (`Project | Lua Interpreter | Lua`).
2. A LuaJIT application can be debugged as any other application using [remote debugging](doc-remote-debugging.html).

Or, if you are running v0.38 or earlier:

1. A LuaJIT interpreter can **replace the default Lua interpreter** used by ZeroBrane Studio.
To do that, you need to set `path.lua = "/full/path/to/luajit_executable"` in [cfg/user.lua](doc-configuration.html).
This setup will use luasocket bundled with ZeroBrane Studio.
If your LuaJIT version is not compatible with luasocket (for example, you compiled LuaJIT for 64bit, but included luasocket is 32bit), you will need to compile [luasocket](https://github.com/diegonehab/luasocket) yourself and make the libraries available to your script.
2. If running on Windows, another option (assuming LuaJIT is compiled for 32bit) is to simply replace `bin/lua51.dll` with `lua51.dll` from LuaJIT.
This will make ZeroBrane Studio itself to **run on LuaJIT** as well as all Lua processes started from it (in this case `path.lua` changes are not needed).
With this option both the [local console](doc-getting-started.html#console-window) will provide access to the LuaJIT interpreter.

Make sure you **use the latest version of LuaJIT** (at least v2.0.1+) as it is needed to enable all debugging features.
Also note that **LuaJIT debugging behavior** is slightly different from Lua 5.1: it may step on the same line several times (which is not a bug);
Lua 5.1 will only step several times if it leaves the line (for example for a function call), and then returns back to it.
