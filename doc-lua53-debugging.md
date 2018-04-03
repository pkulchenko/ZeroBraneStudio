---
layout: default
title: Lua 5.3 Debugging
---

ZeroBrane Studio supports **debugging of Lua 5.3 applications** in several ways:

1. (**v0.90+**) A Lua 5.3 interpreter is included in ZeroBrane Studio. You can select it by going to `Project | Lua Interpreter | Lua 5.3`.
2. A Lua 5.3 application can be debugged as any other application using [remote debugging](doc-remote-debugging).

If you are using your own Lua 5.3 interpreter and have it **statically compiled on Windows**, you *may* run into issues with debugging as the luasocket library that is included with ZeroBrane Studio is compiled against lua53.dll.
You have two options to get it working:

1. **statically compile luasocket** into your application, or
2. **put lua53.dll proxy DLL** into the folder with your executable to make all calls to Lua 5.3 interpreter be forwarded to your statically compiled interpreter (follow the instructions for `mkforwardlib-gcc-52.lua` on [this page](http://lua-users.org/wiki/LuaProxyDllThree), but change the name to match lua53).
