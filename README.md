# Project Description

ZBS-torch is a fork of ZeroBrane Studio to get it to work with Torch-7

For an overview of ZeroBrane Studio, see [README-zbs](https://github.com/soumith/zbs-torch/blob/master/README-zbs.md)

* Written in Lua, so easily customizable.
* Small, portable, and cross-platform (Windows, Mac OSX, and Linux).
* Auto-completion for functions, keywords, and custom APIs.
* Interactive console to directly test code snippets with local and remote execution.
* Integrated debugger (with support for local and remote debugging).
* Live coding with Lua ([demo](http://notebook.kulchenko.com/zerobrane/live-coding-in-lua-bret-victor-style)), Löve 2D ([demo](http://notebook.kulchenko.com/zerobrane/live-coding-with-love)), Gideros ([demo](http://notebook.kulchenko.com/zerobrane/gideros-live-coding-with-zerobrane-studio-ide)), Moai ([demo](http://notebook.kulchenko.com/zerobrane/live-coding-with-moai-and-zerobrane-studio)), and Corona SDK ([demo](http://notebook.kulchenko.com/zerobrane/debugging-and-live-coding-with-corona-sdk-applications-and-zerobrane-studio)).
* Support for plugin-like components:
  - specs (spec/): file syntax, lexer, keywords (e.g. glsl);
  - apis (api/): for code-completion and tool-tips;
  - interpreters (interpreters/): how a project is run;
  - config (cfg/): contains style and basic editor settings;
  - tools (tools/): additional tools (e.g. DirectX/Cg shader compiler...).

## Installation
=======
* Get Torch with the torch ezinstall script

```bash
curl -s https://raw.github.com/torch/ezinstall/master/install-all | bash
```
* Install mobdebug with torch-rocks with

```bash
$ torch-rocks install mobdebug
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

See LICENSE file.
