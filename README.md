# Project Description

[ZeroBrane Studio](http://studio.zerobrane.com/) is a lightweight cross-platform Lua IDE with code completion,
syntax highlighting, remote debugger, code analyzer, live coding,
and debugging support for various Lua engines
([Lua 5.1](http://studio.zerobrane.com/doc-lua-debugging),
[Lua 5.2](http://studio.zerobrane.com/doc-lua52-debugging),
[Lua 5.3](http://studio.zerobrane.com/doc-lua53-debugging),
[LuaJIT](http://studio.zerobrane.com/doc-luajit-debugging),
[LÖVE](http://notebook.kulchenko.com/zerobrane/love2d-debugging),
[Moai](http://notebook.kulchenko.com/zerobrane/moai-debugging-with-zerobrane-studio),
[Gideros](http://notebook.kulchenko.com/zerobrane/gideros-debugging-with-zerobrane-studio-ide),
[Corona](http://notebook.kulchenko.com/zerobrane/debugging-and-live-coding-with-corona-sdk-applications-and-zerobrane-studio),
[Marmalade Quick](http://notebook.kulchenko.com/zerobrane/marmalade-quick-debugging-with-zerobrane-studio),
[Cocos2d-x](http://notebook.kulchenko.com/zerobrane/cocos2d-x-simulator-and-on-device-debugging-with-zerobrane-studio),
[OpenResty/Nginx](http://notebook.kulchenko.com/zerobrane/debugging-openresty-nginx-lua-scripts-with-zerobrane-studio),
[Torch7](http://notebook.kulchenko.com/zerobrane/torch-debugging-with-zerobrane-studio),
[Redis](http://notebook.kulchenko.com/zerobrane/redis-lua-debugging-with-zerobrane-studio),
[GSL-shell](http://notebook.kulchenko.com/zerobrane/gsl-shell-debugging-with-zerobrane-studio),
[Adobe Lightroom](http://notebook.kulchenko.com/zerobrane/debugging-lightroom-plugins-zerobrane-studio-ide),
[Lapis](http://notebook.kulchenko.com/zerobrane/lapis-debugging-with-zerobrane-studio),
[Moonscript](http://notebook.kulchenko.com/zerobrane/moonscript-debugging-with-zerobrane-studio),
and others).

![ZeroBrane Studio debugger screenshot](http://studio.zerobrane.com/images/debugging.png)

## Features

* Small, portable, and **cross-platform** (Windows, Mac OSX, and Linux).
* Written in Lua and is extensible with Lua packages.
* Bundled with several of **the most popular Lua modules**
([luasocket](https://github.com/diegonehab/luasocket),
[luafilesystem](https://github.com/keplerproject/luafilesystem),
[lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/),
and [luasec](https://github.com/brunoos/luasec))
compiled for all supported Lua versions.
* **Auto-complete** for functions, keywords, and custom APIs with **scope-aware completion** for variables.
* **Syntax highlighting** and [scope-aware variable indicators](http://notebook.kulchenko.com/zerobrane/scope-aware-variable-indicators-zerobrane-studio).
* **Interactive console** to directly test code snippets with local and remote execution.
* **Integrated debugger** with local and [remote debugging](http://studio.zerobrane.com/doc-remote-debugging)
for [Lua 5.1](http://studio.zerobrane.com/doc-lua-debugging),
[Lua 5.2](http://studio.zerobrane.com/doc-lua52-debugging),
[Lua 5.3](http://studio.zerobrane.com/doc-lua53-debugging),
[LuaJIT](http://studio.zerobrane.com/doc-luajit-debugging),
and [other Lua engines](http://studio.zerobrane.com/documentation#debugging).
* [Live coding](http://studio.zerobrane.com/documentation#live_coding)
with [Lua](http://notebook.kulchenko.com/zerobrane/live-coding-in-lua-bret-victor-style),
[LÖVE](http://notebook.kulchenko.com/zerobrane/live-coding-with-love),
[Gideros](http://notebook.kulchenko.com/zerobrane/gideros-live-coding-with-zerobrane-studio-ide),
[Moai](http://notebook.kulchenko.com/zerobrane/live-coding-with-moai-and-zerobrane-studio),
[Corona SDK](http://notebook.kulchenko.com/zerobrane/debugging-and-live-coding-with-corona-sdk-applications-and-zerobrane-studio),
GSL-shell, and other engines.
* **Project view** with auto-refresh and ability to hide files and directories from the list.
* **Static analysis** to catch errors and typos during development.
* **Function outline**.
* **Go to definition** navigation.
* **Multi-cursor editing** and selecting and **renaming all instances** of a variable.
* **Fuzzy search** with `Go To File`, **project-wide** `Go To Symbol` navigation, and `Insert Library Function`.
* Find and replace in multiple files with **preview and undo**.
* Several **ways to extend** the current functionality:
  - packages (`packages/`): [plugins](http://studio.zerobrane.com/doc-plugin) that provide additional functionality;
  - translations (`cfg/i18n/`): [translations](http://studio.zerobrane.com/doc-translation) of the menus and messages to other languages;
  - user configuration (`cfg/`): settings for various components, styles, color themes, and other preferences;
  - apis (`api/`): descriptions for [code completion and tooltips](http://studio.zerobrane.com/doc-api-auto-complete);
  - interpreters (`interpreters/`): components for setting debugging and run-time project environment;
  - specs (`spec/`): specifications for file syntax, lexer, and keywords;
  - tools (`tools/`): additional tools.

## Documentation

* A [short and simple overview](http://studio.zerobrane.com/doc-getting-started) for those who are new to this development environment.
* A list of [frequently asked questions](http://studio.zerobrane.com/doc-faq) about the IDE.
* [Tutorials and demos](http://studio.zerobrane.com/tutorials) that cover debugging and live coding for different environments.
* [Tips and tricks](http://studio.zerobrane.com/doc-tips-and-tricks).

## Installation

The IDE can be **installed into and run from any directory**. There are three options to install it:

* Download [installation package for the latest release](https://studio.zerobrane.com/) for individual platforms (Windows, OSX, or Linux);
* Download [snapshot of the repository for each of the releases](releases), which works for all platforms;
* Clone the repository to access the current development version.

**No compilation is needed** for any of the installation options, although the scripts to compile required libraries for all supported platforms are available in the `build/` directory.

## Usage

```
Open file(s):
  zbstudio [option] [<project directory>] <filename> [<filename>...]
  non-options are treated as a project directory to set or a file to open

Set project directory:
  zbstudio <project directory> [<filename>...]
  (0.39+) a directory passed as a parameter will be set as the project directory

Overwrite default configuration:
  zbstudio -cfg "<lua configuration code>" [<filename>]
  e.g.: zbstudio -cfg "editor.fontsize=12" somefile.lua

Load custom configuration:
  zbstudio -cfg path/file.lua [<filename>]
  e.g.: zbstudio -cfg cfg/estrela.lua
```

If you are loading a file, you can also request the cursor to be set on a particular line or at a particular position by using `filename:<line>` and `filename:p<pos>` syntax (0.71+).

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md).

## Author

### ZeroBrane Studio and MobDebug

  **ZeroBrane LLC:** Paul Kulchenko (paul@zerobrane.com)

### Estrela Editor

  **Luxinia Dev:** Christoph Kubisch (crazybutcher@luxinia.de)

## Where is Estrela?

The [Estrela project](http://www.luxinia.de/index.php/Estrela/) that this IDE is based on has been merged into ZeroBrane Studio.
If you have used Estrela for graphics shader authoring or luxinia, create/modify the `cfg/user.lua` and
add `include "estrela"` (1.21+) to load all tools and specifications by default again.
  
## License

See [LICENSE](LICENSE).
