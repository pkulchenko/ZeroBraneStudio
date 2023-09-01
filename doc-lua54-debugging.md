---
layout: default
title: Lua 5.4 Debugging
---

ZeroBrane Studio supports **debugging of Lua 5.4 applications** in several ways:

1. (**v2.00+**) A Lua 5.4 interpreter is included in ZeroBrane Studio. You can select it by going to `Project | Lua Interpreter | Lua 5.4`.
2. A Lua 5.4 application can be debugged as any other application using [remote debugging](doc-remote-debugging).

If you are using Lua 5.4 interpreter that is **statically compiled on Windows**, you have two options to get it working:

1. **statically compile luasocket** into your application, or
2. **put lua54.dll proxy DLL** into the folder with your executable to make all calls to Lua 5.4 interpreter be forwarded to your statically compiled interpreter (follow the instructions for `mkforwardlib-gcc-52.lua` on [this page](http://lua-users.org/wiki/LuaProxyDllThree), but change the name to match lua54).
