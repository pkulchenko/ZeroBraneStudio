# Project Description

ZBS-torch is a fork of ZeroBrane Studio to get it to work with Torch-7

For an overview of ZeroBrane Studio, see [README-zbs](https://github.com/soumith/zbs-torch/blob/master/README-zbs.md)

* Written in Lua, so easily customizable.
* Small, portable, and cross-platform (Windows, Mac OSX, and Linux).
* Auto-completion for functions, keywords, and custom APIs.
* Interactive console to directly test code snippets with local and remote execution.
* Integrated debugger with local and [remote debugging](http://studio.zerobrane.com/doc-remote-debugging)
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
* Function outline.
* Fuzzy search with `Go To File`, `Go To Symbol`, and `Insert Library Function`.
* Several ways to extend the current functionality:
  - specs (`spec/`): specifications for file syntax, lexer, and keywords;
  - apis (`api/`): descriptions for [code completion and tooltips](http://studio.zerobrane.com/doc-api-auto-complete);
  - interpreters (`interpreters/`): components for setting debugging and run-time project environment;
  - packages (`packages/`): [plugins](http://studio.zerobrane.com/doc-plugin) that provide additional functionality;
  - config (`cfg/`): settings for styles, color themes, and other preferences;
  - translations (`cfg/i18n/`): [translations](http://studio.zerobrane.com/doc-translation) of the menus and messages to other languages;
  - tools (`tools/`): additional tools.

## Installation
=======
* Get Torch 

* Install mobdebug with luarocks with

```bash
$ luarocks install mobdebug
```

```bash
$ git clone https://github.com/soumith/zbs-torch.git
$ cd zbs-torch
$ sh zbstudio.sh
```

## Usage

To debug a torch file,

* Start zbs from the zbs-torch directory with the command

```bash
$ sh zbstudio.sh
```
* Start the debugger server from "Project->Start Debugger Server"

* Change the interpreter to Torch-7 "Project->Lua Interpreter->Torch-7" 

* Add the following line to the top of the file you are debugging

```lua
require('mobdebug').start()
```
For Example, this file
```lua
require 'image'
print('Wheres Waldo?')
a=image.rotate(image.lena(), 1.0)
image.display(a)
print('OK Bye')
```
becomes
```lua
require('mobdebug').start()
require 'image'
print('Wheres Waldo?')
a=image.rotate(image.lena(), 1.0)
image.display(a)
print('OK Bye')
```

* Run the file from the menu "Project->Run"
* You should see the debugger stop at the first line of the file, then you can set breakpoints, continue, step etc.

## Original Author

### ZeroBrane Studio and MobDebug

  **ZeroBrane LLC:** Paul Kulchenko (paul@kulchenko.com)
## License

See [LICENSE](LICENSE).
