---
layout: default
title: Plugins
---

ZeroBrane Studio supports several ways to customize its functionality:
specification files (`spec/`) to describe syntax and keywords,
apis (`api/`) to provide code completion and tooltips, and
interpreters (`interpreters/`): to implement components for setting debugging and run-time project environment.

In addition to these options, it also provides plugin API to extend its functionality in a more fine graned way.
For example, one can write a plugin to add a menu item to turn line wrapping `on` or `off` from the IDE or a plugin to map a shortcut to a character not present on the keyboard.

## Plugin structure

A plugin is a Lua file that returns a table with several fields -- `name`, `description`, `author`, `version` -- and various [event handlers](#event_handler).

For example, the following plugin has only one event handler (`onRegister`) that is called when the plugin is registered:

{% highlight lua %}
return {
  name = "Sample plugin",
  description = "Sample plugin with one event handler.",
  author = "Paul Kulchenko",
  version = 0.1,

  onRegister = function(self) DisplayOutputLn("Sample plugin registered") end,
}
{% endhighlight %}

The plugin may also return `nil` instead of the table, which will skip the registeration.
This is useful when some environmental conditions are not satisfied (for example, a program that the plugin integrates with is not installed).

## Plugin installation

A plugin can be placed in `packages/` or `HOME/.zbstudio/packages` folder.
The first location allows you to have per-instance plugins, while the second allows to have per-user plugins.
The second option may also be preferrable for Mac OS X users as the `packages/` folder may be overwritten during an application upgrade.

## Event handler

A plugin can register various [event handlers](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/packages/sample.lua).

Each handler receives the plugin object as the first parameter and some other parameters depending on the type of the event:
`onEditor*` events get `editor` object as the second parameter, `onMenu*` events get `menu` as the second parameter, `onApp*` events get `application` as the second parameter, `onProject*` get `project`, and `onInterpreter*` get `interpreter`.
Events may also get other parameters as documented in the file referenced above.

## Registering a specification

Registering a specification as part of a plugin allows you to provide custom syntax highlighting for files with a particular extension.
For example, the following code will register a specification that is linked to `.xml` extension:

{% highlight lua %}
local spec = {
  exts = {"xml"},
  lexer = wxstc.wxSTC_LEX_XML,
  apitype = "xml",
  stylingbits = 7,
  lexerstyleconvert = {
    text = {wxstc.wxSTC_H_DEFAULT,},
    comment = {wxstc.wxSTC_H_COMMENT,},
    stringeol = {wxstc.wxSTC_HJ_STRINGEOL,},
    number = {wxstc.wxSTC_H_NUMBER,},
    stringtxt = {wxstc.wxSTC_H_DOUBLESTRING,wxstc.wxSTC_H_SINGLESTRING,},
    lexerdef= {wxstc.wxSTC_H_OTHER,wxstc.wxSTC_H_ENTITY,wxstc.wxSTC_H_VALUE,},
    keywords0 = {wxstc.wxSTC_H_TAG,wxstc.wxSTC_H_ATTRIBUTE,},
  },
  keywords = {[[foo bar]]]},
}

return {
  name = "...",
  description = "...",
  author = "...",
  version = 0.1,

  onRegister = function(self)
    -- add specification with name "sample"
    ide:AddSpec("sample", spec)
  end,

  onUnRegister = function(self)
    -- remove specification with name "sample"
    ide:RemoveSpec("sample")
  end,
}
{% endhighlight %}

The name of the specification is not critical, but to avoid conflicts with other plugins you may want to include the name of your plugin in your specification name (`sample` in the example above).
This registering of the specification will have the same effect as putting this specification code a file in `spec/` folder, but will only be used when the plugin is activated.

## Registering an API

{% highlight lua %}
local api = {
 sample = {
  childs = {
   val1 = {
    description = "Value 1.",
    type = "value"
   },
   val2 = {
    description = "Value 2.",
    type = "value"
   },
  }
 }
}

return {
  name = "...",
  description = "...",
  author = "...",
  version = 0.1,

  onRegister = function(self)
    -- add API with name "sample" and group "lua"
    ide:AddAPI("lua", "sample", api)
  end,

  onUnRegister = function(self)
    -- remove API with name "sample" from group "lua"
    ide:RemoveAPI("lua", "sample")
  end,
}
{% endhighlight %}

## Registering an interpreter

{% highlight lua %}
local interpreter = {
  name = "Sample",
  description = "Lua sample interpreter",
  api = {"baselib", "sample"},
  frun = function(self,wfilename,rundebug)
    CommandLineRun("lua "..wfilename,self:fworkdir(wfilename),true,false)
  end,
  fprojdir = function(self,wfilename)
    return wfilename:GetPath(wx.wxPATH_GET_VOLUME)
  end,
  fworkdir = function (self,wfilename)
    return ide.config.path.projectdir or wfilename:GetPath(wx.wxPATH_GET_VOLUME)
  end,
  hasdebugger = true,
  fattachdebug = function(self) DebuggerAttachDefault() end,
}

return {
  name = "...",
  description = "...",
  author = "...",
  version = 0.1,

  onRegister = function(self)
    -- add interpreter with name "sample"
    ide:AddInterpreter("sample", interpreter)
  end,

  onUnRegister = function(self)
    -- remove interpreter with name "sample"
    ide:RemoveInterpreter("sample")
  end,
}
{% endhighlight %}

## Example: 

{% highlight lua %}
local pairs = {
  ['('] = ')', ['['] = ']', ['{'] = '}', ['"'] = '"', ["'"] = "'"}
local closing = [[)}]'"]]
return {
  name = "Auto-insertion of delimiters",
  description = [[Adds auto-insertion of delimiters (), {}, [], '', and "".]],
  author = "Paul Kulchenko",
  version = 0.1,

  onEditorCharAdded = function(self, editor, event)
    local keycode = event:GetKey()
    local char = string.char(keycode)
    local curpos = editor:GetCurrentPos()

    if closing:find(char, 1, true) and editor:GetCharAt(curpos) == keycode then
      -- if the entered text matches the closing one
      -- and the current symbol is the same, then "eat" the character
      editor:DeleteRange(curpos, 1)
    elseif pairs[char] then
      -- if the entered matches opening delimiter, then insert the pair
      editor:InsertText(-1, pairs[char])
    end
  end,
}
{% endhighlight %}

## Example:

{% highlight lua %}
local G = ...
local id = G.ID("popupmenu.popupshow")
local iditem = G.ID("popupmenu.popupitem")
local menuid
return {
  name = "Sample plugin with popup menu",
  description = "Sample plugin showing how to setup and use popup menu.",
  author = "Paul Kulchenko",
  version = 0.1,

  onRegister = function(self)
    -- add menu item that will activate popup menu
    local menu = ide:GetMenuBar():GetMenu(ide:GetMenuBar():FindMenu(TR("&Edit")))
    menuid = menu:Append(id, "Show Popup\tCtrl-Alt-T")
    ide:GetMainFrame():Connect(id, wx.wxEVT_COMMAND_MENU_SELECTED, function()
      GetEditor():AddPendingEvent(wx.wxContextMenuEvent(wx.wxEVT_CONTEXT_MENU))
    end)
  end,

  onUnRegister = function(self)
    -- remove added menu item when plugin is unregistered
    local menu = ide:GetMenuBar():GetMenu(ide:GetMenuBar():FindMenu(TR("&Edit")))
    ide:GetMainFrame():Disconnect(id, wx.wxID_ANY, wx.wxEVT_COMMAND_MENU_SELECTED)
    if menuid then menu:Destroy(menuid) end
  end,

  onMenuEditor = function(self, menu, editor, event)
    -- add a separator and a sample menu item to the popup menu
    menu:AppendSeparator()
    menu:Append(iditem, "Popup Menu Item")

    -- attach a function to the added menu item
    editor:Connect(iditem, wx.wxEVT_COMMAND_MENU_SELECTED,
      function(event) DisplayOutputLn("Selected popup item") end)
  end
}
{% endhighlight %}
