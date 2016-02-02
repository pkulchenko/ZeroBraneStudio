---
layout: default
title: Adding API and auto-complete description
---

ZeroBrane Studio supports custom API definitions that are used in providing information for auto-complete and tooltip functions.

By providing a description for `io.open`, users may not only see `open` suggested after typing `io.`, but also see a description for this function after they type `io.open(` or when they request a tooltip for `io.open(...)`.

## API definition format

API definitions are stored in the form of Lua files that return a table of the following structure:

```lua
{
  foo = {
    type = "lib",
    description = "this does something",

    -- function/methods:
    args = "(blah,blubb)",
    returns = "(foo)",

    -- children in the class hierarchy
    childs = { -- recursive
      bar = {
        type = "function",
        description = "this does something",
        valuetype = "mytype",
      }
    }
  },

  baz = {
    type = "value",
    --...
  },
}
```

This structure defines a value `baz`, a library `foo`, and a function in that library `foo.bar()` that returns a value with type `mytype`.

Recognized **element values** are:

- `type`: one of the following values:
    * `keyword`: to describe language keywords, like `do` and `end`;
    * `class` and `lib`: to describe groups of functions, methods, values, and other classes and libraries;
    * `value`: to describe specific values (for example, constants);
    * `function`: to describe a function that accepts parameters (`args`) and returns values (`returns`), possibly of a specific type (`valuetype`);
    * `method`: to describe method calls; methods are described similar to functions and also accept arguments and return values and value types. The only difference is that methods are only suggested after `:` in auto-complete, while functions are suggested after `.` and `:`.
- `description`: a text that describes the item of the specified type. The description may include new lines that are included in the displayed text. Long descriptions will be abbreviated to make sure they fit on the screen.
- `args`: an (optional) string with arguments; for example, `"(file: file)"`.
- `returns`: an (optional) string with return values; for example, `"(boolean|nil [, string, number])"`.
- `childs`: an (optional) table with sub-elements of the current element; for example, methods in a class or functions/values in a library.
- `valuetype`: an (optional) string with a type value that acts as a hint for type processing in auto-complete. For example, using `valuetype = "f"` indicates that the current element returns value of type `f`. The value may be a complex name; for example, `foo.bar`.
- `inherits`: an (optional) string to specify inheritance chain for the current class. May include multiple classes separated by spaces.

When `valuetype` is specified for a `method` or a `function`, it is used for auto-complete type guessing.
If the value is used in an expression, then the variable this value is assigned to is treated as having the value type;
e.g. if `somefunc` has `valuetype` of `math`, then after `test = somefunc()`, typing `test.` will be treated as `math.` in auto-complete logic.

When `inherits` is specified for a class, it is used by auto-complete logic to suggest values, functions, and methods from the base class(es) in addition to the methods from the current class.
You may specify several classes (`inherits = 'a b'`) and complex class names (`inherits = 'b2.Shape'`).
The entire inheritance chain will be looked at during the analysis.

## How to reference API definitions

API definitions can be referenced by name in interpreter files as part of the `api` table.
For example, `interpreters/luadeb.lua` file references `wxwidgets` and `baselib` API definitions, which can be found in files `api/lua/wxwidgets.lua` and `api/lua/baselib.lua`.

```lua
return {
  name = "Lua",
  description = "Lua interpreter with debugger",
  api = {"wxwidgets","baselib"},
  ...
```

Make sure to use exactly the same name when you reference files with API definitions even on case-insensitive systems.
If you name the file `api/lua/BaseLib.lua`, but reference it as `'baselib'`, the link won't work.

## Example

```lua
return {
  -- I/O library
  io = {
    type = "lib",
    description = "The I/O library provides two different styles for file manipulation.",
    childs = {
      stdin = { type = "value" },
      stdout = { type = "value" },
      stderr = { type = "value" },
      open = {
        type = "function",
        description = [[This function opens a file, in the mode specified in the string mode.
It returns a new file handle, or, in case of errors, nil plus an error message.
The mode string can be any of the following:

* "r": read mode (the default);
* "w": write mode;
* "a": append mode;
* "r+": update mode, all previous data is preserved;
* "w+": update mode, all previous data is erased;
* "a+": append update mode, previous data is preserved, writing is only allowed at the end of file.

The mode string can also have a 'b' at the end, which is needed in some systems to open the file in binary mode.]],
        args = "(filename: string [, mode: string])",
        returns = "(file|nil [, string])",
        valuetype = "f", -- indicates that io.open returns value of type `f`
      },
    },
  },

  f = {
    type = "class",
    description = "Pseudoclass for operations on file handles.",
    childs = {
      close = {
        type = "method",
        description = "Closes file.",
        args = "(file: file)",
        returns = "(boolean|nil [, string, number])",
      },
    },
  },
}
```

This generates the following description for `io.open`: `(file|nil [, string]) io.open (filename: string [, mode: string])`.

When `io.open` is used in an expression, its return value gets the value of `valuetype` `f` (in this particular case), which allows auto-complete to suggest values, functions, and methods defined for that class:

```lua
local foo = io.open("myfile")
foo:
```

After typing `foo:`, the user will get `close` as an option. Since it is described as `method`, rather than `function`, it will not be suggested after typing `foo.`.
