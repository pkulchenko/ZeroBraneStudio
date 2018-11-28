# Project Description

[ZeroBrane Studio](http://studio.zerobrane.com/) is a lightweight cross-platform Lua IDE with code completion,
syntax highlighting, remote debugger, code analyzer, live coding,
and debugging support for various Lua engines
([Lua 5.1](http://studio.zerobrane.com/doc-lua-debugging),
[Lua 5.2](http://studio.zerobrane.com/doc-lua52-debugging),
[Lua 5.3](http://studio.zerobrane.com/doc-lua53-debugging),
[Lua 5.4](http://studio.zerobrane.com/doc-lua54-debugging),
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

* Small, portable, and **cross-platform** (Windows, macOS, and Linux).
* Written in Lua and is extensible with Lua packages.
* **Syntax highlighting** and folding for 125+ languages and file formats.
* **Project view** with auto-refresh and ability to hide files and directories from the list.
* Bundled with several of **the most popular Lua modules**
([luasocket](https://github.com/diegonehab/luasocket),
[luafilesystem](https://github.com/keplerproject/luafilesystem),
[lpeg](http://www.inf.puc-rio.br/~roberto/lpeg/),
and [luasec](https://github.com/brunoos/luasec))
compiled for all supported Lua versions.
* **Auto-complete** for functions, keywords, and custom APIs with **scope-aware completion** for variables.
* [Scope-aware variable indicators](http://notebook.kulchenko.com/zerobrane/scope-aware-variable-indicators-zerobrane-studio) for Lua code.
* **Integrated debugger** with local and [remote debugging](http://studio.zerobrane.com/doc-remote-debugging)
for [Lua 5.1](http://studio.zerobrane.com/doc-lua-debugging),
[Lua 5.2](http://studio.zerobrane.com/doc-lua52-debugging),
[Lua 5.3](http://studio.zerobrane.com/doc-lua53-debugging),
[Lua 5.4](http://studio.zerobrane.com/doc-lua54-debugging),
[LuaJIT](http://studio.zerobrane.com/doc-luajit-debugging),
and [other Lua engines](http://studio.zerobrane.com/documentation#debugging).
* **Interactive console** to directly test code snippets with local and remote execution.
* [Live coding](http://studio.zerobrane.com/documentation#live_coding)
with [Lua](http://notebook.kulchenko.com/zerobrane/live-coding-in-lua-bret-victor-style),
[LÖVE](http://notebook.kulchenko.com/zerobrane/live-coding-with-love),
[Gideros](http://notebook.kulchenko.com/zerobrane/gideros-live-coding-with-zerobrane-studio-ide),
[Moai](http://notebook.kulchenko.com/zerobrane/live-coding-with-moai-and-zerobrane-studio),
[Corona SDK](http://notebook.kulchenko.com/zerobrane/debugging-and-live-coding-with-corona-sdk-applications-and-zerobrane-studio),
GSL-shell, and other engines.
* **Static analysis** to catch errors and typos during development.
* **Function outline**.
* **Go to definition** navigation.
* **Multi-cursor editing** with **scope-aware variable selection and renaming**.
* **Fuzzy search** with `Go To File`, **project-wide** `Go To Symbol` navigation, and `Insert Library Function`.
* Find and replace in multiple files with **preview and undo**.
* Several **ways to extend** the current functionality:
  - packages (`packages/`): [plugins](http://studio.zerobrane.com/doc-plugin) that provide additional functionality;
  - translations (`cfg/i18n/`): [translations](http://studio.zerobrane.com/doc-translation) of the menus and messages to other languages;
  - user configuration (`cfg/`): settings for various components, styles, color themes, and other preferences.

## Documentation

* A [short and simple overview](http://studio.zerobrane.com/doc-getting-started) for those who are new to this development environment.
* A list of [frequently asked questions](http://studio.zerobrane.com/doc-faq) about the IDE.
* [Tutorials and demos](http://studio.zerobrane.com/tutorials) that cover debugging and live coding for different environments.
* [Tips and tricks](http://studio.zerobrane.com/doc-tips-and-tricks).

## Installation

The IDE can be **installed into and run from any directory**. There are three options to install it:

* Download [installation package for the latest release](https://studio.zerobrane.com/) for individual platforms (Windows, OSX, or Linux);
* Download [snapshot of the repository for each of the releases](releases), which works for all platforms;
* Clone the repository to access the current development version; this option also works for all platforms.

**No compilation is needed** for any of the installation options, although the scripts to compile required libraries for all supported platforms are available in the `build/` directory.

See the [installation section](https://studio.zerobrane.com/doc-installation) in the documentation for further details and uninstallation instructions.

## Usage

The IDE can be launched by using the `zbstudio` command with slight variations depending on whether a packaged installation or a repository copy is used:

* **Windows**: Run `zbstudio` from the directory that the IDE is installed to or create a shortcut pointing to `zbstudio.exe`.
* **Linux**: Run `zbstudio` when installed from the package installation or run `./zbstudio.sh` when using a snapshot/clone of the repository.
* **macOS**: Launch the `ZeroBrane Studio` application if installed or run `./zbstudio.sh` when using a snapshot/clone of the repository.

The general command for launching is the following: `zbstudio [option] [<project directory>] [<filename>...]`.

* **Open files**: `zbstudio <filename> [<filename>...]`.
* **Set project directory** (and optionally open files): `zbstudio <project directory> [<filename>...]`.
* **Overwrite default configuration**: `zbstudio -cfg "string with configuration settings"`, for example: `zbstudio -cfg "editor.fontsize=12; editor.usetabs=true"`.
* **Load custom configuration file**: `zbstudio -cfg <filename>`, for example: `zbstudio -cfg cfg/xcode-keys.lua`.

All configuration changes applied from the command line are only effective for the current session.

If you are loading a file, you can also **set the cursor** on a specific line or at a specific position by using `filename:<line>` and `filename:p<pos>` syntax (0.71+).

In all cases only one instance of the IDE will be allowed to launch by default:
if one instance is already running, the other one won't launch, but the directory and file parameters
passed to the second instance will trigger opening of that directory and file(s) in the already started instance.

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md).

## Author

### ZeroBrane Studio and MobDebug

  **ZeroBrane LLC:** Paul Kulchenko (paul@zerobrane.com)

### Estrela Editor

  **Luxinia Dev:** Christoph Kubisch (crazybutcher@luxinia.de)

## Where is Estrela?

The [Estrela project](http://www.luxinia.de/index.php/Estrela/) that this IDE is based on has been merged into ZeroBrane Studio.
If you have used Estrela for graphics shader authoring, you can use [this GraphicsCodePack](https://github.com/pixeljetstream/zbstudio-graphicscodepack)
to get access to all API files, specifications and tools.
  
## License

See [LICENSE](LICENSE).
