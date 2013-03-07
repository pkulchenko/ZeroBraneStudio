# Project Description

ZBS-torch is a fork of ZeroBrane Studio to get it to work with Torch-7

For an overview of ZeroBrane Studio, see [README-zbs](https://github.com/soumith/zbs-torch/blob/master/README-zbs.md)

## What works for torch-7?
* Visual debugging (see usage, slightly convoluted instructions)
* Full torch support

## Installation

* Get Torch with luarocks (You can automate this with this [script](https://github.com/clementfarabet/torchinstall/blob/master/install) thanks to Clement)
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

See LICENSE file.
