---
layout: default
title: Lua 5.2 Debugging
---

ZeroBrane Studio supports **debugging of Lua 5.2 applications** in several ways:

1. (v0.39+) A Lua 5.2 interpreter is included in ZeroBrane Studio. You can select it by going to `Project | Lua Interpreter | Lua 5.2`.
2. A Lua 5.2 application can be debugged as any other application using [remote debugging](doc-remote-debugging.html).
3. (v0.35+) A Lua 5.2 interpreter can **replace the default Lua interpreter** used by ZeroBrane Studio.
To do that, you need to set `path.lua = "/full/path/to/lua52.exe"` in [cfg/user.lua](doc-configuration.html).

If you are using your own Lua 5.2 interpreter and have it **statically compiled on Windows**, you *may* run into issues with debugging as the luasocket library that is included with ZeroBrane Studio is compiled against lua52.dll.
You have two options to get it working:
(1) **statically compile luasocket** into your application, and
(2) **put lua52.dll proxy DLL** into the folder with your executable to make all calls to Lua 5.2 interpreter be forwarded to your statically compiled interpreter (follow the instructions for `mkforwardlib-gcc-52.lua` on [this page](http://lua-users.org/wiki/LuaProxyDllThree)).

(**This note is no longer relevant sarting from v0.39+**) Note that the internal Lua engine in ZeroBrane Studio is still using Lua 5.1 and you will not be able to compile any code that uses Lua 5.2 features (like goto statements).
To work around that you can copy the existing Lua interpreter (`interpreters/luadeb.lua` into a different file) and add `skipcompile = true,` option to it, which will skip a required compilation step before executing your script.
