---
layout: default
title: General Preferences
---

<ul id='toc'>&nbsp;</ul>

To **modify default general preferences**, you can use these commands and apply them
as described in the [configuration](doc-configuration) section
and as shown in [user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua).
The values shown are the default values.

## General

- `activateoutput = true`: activate Output or Console window on new content added.
- `allowinteractivescript = true`: allow interaction in the output window.
- `autoanalyzer = true`: enable autoanalyzer that adds scope aware indicators to variables (up to v0.50 it was spelled as `autoanalizer`).
- `autorecoverinactivity = 10`: trigger saving autorecovery after N seconds of inactivity; set to `nil` to disable autorecovery.
- `filehistorylength = 20`: set history length for files.
- `hotexit = false`: enable quick exit without prompting to save files (0.71+).
The changes in files and all unsaved buffers should be restored during the next launch.
This session information is saved in the [.ini file](#session-configuration).
- `ini = nil`: provide an alternative location for the [.ini file](#session-configuration).
If the filename is absolute, it's used as the new location; if it's relative, then the file is created relative to the [system-dependent location](#session-configuration).
- `language = "en"`: set the language to use in the IDE; this requires a language file in cfg/i18n directory.
- `projectautoopen = true`: auto-open windows on project switch.
- `projecthistorylength = 20`: set history length for projects.
- `savebak = false`: create backup on file save.
- `singleinstance = true`: enable check that prevents starting multiple instances of the IDE.

## Debugger

- `debugger.allowediting = false`: enable editing of files while debugging.
- `debugger.hostname = "hostname.or.IP.address"`: set hostname to use for debugging.
- `debugger.redirect = nil`: specify how `print` results should be redirected in the application being debugged (0.39+).
Use `'c'` for 'copying' (appears in the application output and the Output panel),
`'r'` for 'redirecting' (only appears in the Output panel),
or `'d'` for 'default' (only appears in the application output).
This is mostly useful for remote debugging to specify how the output should be redirected.
- `debugger.runonstart = false`: execute script immediately after starting debugging.
- `debugger.verbose = false`: enable verbose output.

## Auto-complete and tooltip

- `acandtip.nodynwords = true`: do not offer dynamic (user entered) words;
when set to `false` will collect all words from all open editor tabs and offer them as part of the auto-complete list.
- `acandtip.shorttip = true`: show short calltip when typing; shows long calltip when set to `false`.
- `acandtip.startat = 2`: start suggesting dynamic words after N characters.
- `acandtip.strategy = 2`: method of selecting auto-complete candidates:
    - `0`: substring comparison (`fo`, but not `fb` matches `foo_bar`);
    - `1`: substring leading characters, CamelCase or _ separated (`fo` and `fb`, but not `fa` match `foo_bar`);
    - `2`: leading + any correctly ordered fragments (`fo`, `fa`, `fb`, but not `bf` match `foo_bar`).
- `acandtip.width = 60`: specify width of the tooltip window in characters.
- `autocomplete = true`: enable auto-complete.

## Outline

- `outline.showanonymous = '~'`: set the name to be used for anonymous functions (0.81+); set to `false` to hide anonymous functions.
- `outline.showflat = false`: show all functions as one list (no hierarchy) (0.91+).
- `outline.showmethodindicator = false`: show different icons for method indicators (0.81+).
- `outline.showonefile = false`: show only functions from the current active file in the outline (0.81+); when set to `false`, show several files in the outline with the current one expanded.
- `outline.sort = false`: sort functions by name (0.91+); when set to `false`, show functions in the order of their appearance.

## Custom APIs

- `api = nil`: set the list of APIs to be loaded for specific or all interpreters (0.91)+.
For example, `api = {'foo', luadeb = {'bar'}}` will load `foo` API for all interpreters and `bar` API for the `luadeb` interpreter.

## Toolbar

- `toolbar.iconmap = { [ID_OPEN] = {"FILE-OPEN", "Description" }, ... }`: sets the content of toolbar buttons (the icon and the description).
- `toolbar.icons = { ID_NEW, ID_OPEN, ... ID_SEPARATOR, ...}`: sets the order of the buttons in the toolbar.
- `toolbar.iconsize = ide.osname == 'Macintosh' and 24 or 16`: the size of the icons in the toolbar. Only two sizes are currently supported: 16 and 24 pixels.

The icon used may **refer to the existing image** file by name (`"FILE-OPEN"`) or to `wx.wxBitmap` object; see this plugin for an [example on how to create a toolbar bitmap](https://github.com/pkulchenko/ZeroBranePackage/blob/master/maketoolbar.lua).

Any existing button on the toolbar can be **removed individually** by setting `toolbar.icons[ID-of-the-button]` to `false`.
If all the buttons between two separators are removed, then two separators are merged into one to keep proper spacing.

When you reference ID value from the config file, make sure to reference them in the **global environment**: `local G = ...; toolbar.icons[G.ID_NEW] = false`.

## Formats

- `format.menurecentprojects = "%f | %i"`: format of the `Recent Project` menu and the toolbar dropdown.
- `format.apptitle = "%T - %F"`: format of the application title.

Possible placeholder values to use in formats (0.61+):

- `%f`: full project name (project path)
- `%s`: short project name (directory name)
- `%i`: interpreter name
- `%S`: file name
- `%F`: file path
- `%n`: line number
- `%c`: line content
- `%T`: application title
- `%v`: application version
- `%t`: current tab name

## Key mapping

To modify a key mapping for a particular menu item, you can add the following command to your [configuration](doc-configuration):
`local G = ...; keymap[G.ID_STARTDEBUG] = "Ctrl-Shift-D"`.
This will modify the default shortcut for `Program | Start Debugging` command.

See an [example in user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L18),
the description for possible [accelerator values](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/src/editor/keymap.lua#L4),
and the full list of IDs in [src/editor/keymap.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/src/editor/keymap.lua).

## Editor key mapping

The editor component provides its own shortcut handling mechanism linked to specific editor actions.
For example, `Ctrl-D` will duplicate the current line.

The editor provides [default commands](doc-editor-keyboard-shortcuts) that can be modified to map to the key combinations you prefer.
To modify the key mapping, you can add the following line to the configuration file:

{% highlight lua %}
editor.keymap[#editor.keymap+1] =
  {('E'):byte(), wxstc.wxSTC_SCMOD_CTRL, wxstc.wxSTC_CMD_LINEEND}
{% endhighlight %}

This will bind `Ctrl-E` combination to remove the line content from the current position to the end of the line.
The description takes four parameters:

- key code, which may be a code for a visible character (`('E'):byte()`) or a [special code](http://www.scintilla.org/ScintillaDoc.html#KeyBindings) (`wxstc.wxSTC_KEY_UP`);
- key modifiers, which is a combination of `wxstc.wxSTC_SCMOD_CTRL`, `wxstc.wxSTC_SCMOD_SHIFT`, `wxstc.wxSTC_SCMOD_META`, and `wxstc.wxSTC_SCMOD_ALT`. On OSX, the Command key is mapped to wxSTC_SCMOD_CTRL and the Control key to wxSTC_SCMOD_META.
- [Keyboard command](http://www.scintilla.org/ScintillaDoc.html#KeyboardCommands), which specify the action that needs to be tied to the key combination;
- operating system, which is one of `'Windows'`, `'Macintosh'`, and `'Unix'` strings. If no operating system is specified, then the combination is available on all systems.

Note that the editor key mapping is different from the IDE key mapping as the former only works when the editor is in focus and the latter may work when other components have focus.
When there is a conflict, the IDE shortcuts take preference over editor shortcuts.

## Session configuration

Some configuration information that needs to be preserved between launches (windows and panels sizes and positions, open editor tabs, recently used projects and files and so on) is saved in a special file.
The location (and the name) of this file is system dependent:
it is located in `%HOME%\ZeroBraneStudio.ini` (for v0.35 and earlier) and in `C:\Users\<user>\AppData\Roaming\ZeroBraneStudio.ini` (for v0.36 and later) on Windows,
`$HOME/Library/Preferences/ZeroBraneStudio Preferences` on Mac OSX, and in
`$HOME/.ZeroBraneStudio` on Linux. 
You can see the location of the HOME directory if you type `wx.wxGetHomeDir()` into the Local console.

## Command line parameters

(0.50+) Command line parameters can be specified in two ways (for those interpreters that support them):
(1) by going to `Project | Command Line Parameters` and entering command line parameters (if the menu item is disabled, it means that the interpeter doesn't support command line parameters), and
(2) by setting `arg.any` value in the config file. For example, `arg.any = 'a "b c"'` will pass two parameters to the script: `a` and `b c`.

The parameters set using the first option will only be active until you exit the IDE. If you want to remove parameters, set the value to the empty string.

Some interpreters also allow interpreter specific arguments:

- `arg.lua`: sets arguments for Lua interpreters,
- `arg.love2d`: sets arguments for Love2d interpreter, and
- `arg.gslshell`: sets arguments for GSL-shell interpreter.

## Interpreter path

These settings can be used to change the location of the executable file for different interpreters.
In most cases you don't need to specify this as ZeroBrane Studio will check default locations for the executable, but in those cases when auto-detection fails, you can specify the path yourself.
You can use this setting to specify an alternative interpreter you want to use (for example, LuaJIT instead of Lua interpreter).

Note that the **full executable name** is expected, not a directory name. The values shown are examples, not default values.

- `path.lua = 'd:/lua/lua'`: specify path to Lua interpreter.
- `path.love2d = 'd:/lua/love/love'`: specify path to love2d executable.
- `path.moai = 'd:/lua/moai/moai'`: specify path to Moai executable.
- `path.gideros = 'd:/Program Files/Gideros/GiderosPlayer.exe'`: specify path to Gideros executable.
- `path.corona = 'd:/path/to/Corona SDK/Corona Simulator.exe'`: specify path to Corona executable.
- `path.gslshell = [[D:\Lua\gsl-shell\gsl-shell.exe]]`: specify path to GSL-shell executable.
