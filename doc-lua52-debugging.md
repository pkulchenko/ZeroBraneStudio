---
layout: default
title: Lua 5.2 Debugging
---

ZeroBrane Studio supports **debugging of Lua 5.2 applications** in two ways:

1. A Lua 5.2 application can be debugged as any other application using [remote debugging](doc-remote-debugging.html).
2. (v0.35+) A Lua 5.2 interpreter can **replace the default Lua interpreter** used by ZeroBrane Studio.
To do that, you need to set `path.lua = "/full/path/to/lua52.exe"` in [cfg/user.lua](doc-configuration.html).

Make sure you **compile [luasocket](https://github.com/diegonehab/luasocket) with Lua 5.2** and make it available to your application as the version of luasocket that comes with ZeroBrane Studio is not compatible with Lua 5.2.

Note that the internal Lua engine in ZeroBrane Studio is still using Lua 5.1 and you will not be able to compile any code that uses Lua 5.2 features (like goto statements).
To work around that you can copy the existing Lua interpreter (`interpreters/luadeb.lua` into a different file) and add `skipcompile = true,` option to it, which will skip a required compilation step before executing your script.
