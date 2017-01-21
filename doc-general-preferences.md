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
-  (**removed** in 1.30) `allowinteractivescript = true`: allow interaction in the output window.
- `autoanalyzer = true`: enable autoanalyzer that adds scope aware indicators to variables (up to v0.50 it was spelled as `autoanalizer`).
- `autorecoverinactivity = 10`: trigger saving autorecovery after N seconds of inactivity; set to `nil` to disable autorecovery.
- `bordersize = 3`: set the size of the border (sash) between windows and panels (0.91+, updated default in 1.31+).
- `commandlinehistorylength = 10`: set history length for command lines (1.31+); the history is kept across all projects.
- `filehistorylength = 20`: set history length for files.
- `hotexit = false`: enable quick exit without prompting to save files (0.71+).
The changes in files and all unsaved buffers should be restored during the next launch.
This session information is saved in the [.ini file](#session-configuration).
- `ini = nil`: provide an alternative location for the [.ini file](#session-configuration).
If the filename is absolute, it is used as the new location;
(1.11+) if it is relative and includes a path component (for example, `./file.ini` or `path/file.ini`), then the file is created relative to the IDE directory;
if it only contains the file name (for example, `file.ini`), then the file is created in the [system-dependent location](#session-configuration).
- `interpreter = nil`: set the default interpreter used for new projects (1.11+).
Use a string value with the name of the interpreter to set the interpreter.
The name of the interpreter is either its file name (without an extension) or a name used in `ide:AddInterpreter()` call.
For example, to select the LÖVE interpreter, use `interpreter = "love2d"`.
- `language = "en"`: set the language to use in the IDE; this requires a language file in `cfg/i18n` directory.
- `menuicon = true`: show icons in the menu (1.31+).
On Linux may not show even when set to `true`, as it is also controlled by `gtk-menu-images` setting.
- `outlineinactivity = 0.250`: trigger Outline update after N seconds of inactivity (1.0+); set to `nil` to disable Outline handling.
- `projectautoopen = true`: auto-open windows on project switch.
- `projecthistorylength = 20`: set history length for projects.
- `savebak = false`: create backup on file save.
- `showhiddenfiles = false`: display hidden files (those that have "hidden" attribute set on Windows or those that start with `.` on Linux) in the project tree (1.21+);
set to `true` to display both files and directories or to `wx.wxDIR_FILES` to display only files and to `wx.wxDIR_DIRS` to display only directories.
- `showmemoryusage = nil`: display memory usage stats in the Status bar (1.11+);
set to `true` to display the stats.
- `singleinstance = true`: enable check that prevents starting multiple instances of the IDE.
- `symbolindexinactivity = 2`: trigger indexing of project files for symbol search after N seconds of inactivity (1.11+).

## Debugger

- `debugger.allowediting = false`: enable editing of files while debugging.
- `debugger.hostname = "hostname.or.IP.address"`: set hostname to use for debugging.
- `debugger.ignorecase = false`: make debugger to ignore case mismatch when activating files (1.41+);
This can be used to activate files that have different spelling of the file names (case-wise);
for example, `Test` vs `test` vs `TEST`.
- `debugger.init = nil`: specify code to run (as a **string**) at the beginning of the debugger session.
This may be used to provide some initialization to be applied before the debugging starts.
For example, `debugger.init = [[some initialization code]]`.
- `debugger.linetobreakpoint = false`: move the current line in the editor to the line with the triggered breakpoint (1.41+).
- `debugger.maxdatalength = 400`: set limit (in bytes) for the data shown in the Stack and Watch results.
- `debugger.maxdatanum = 400`: limit the number of elements for tables shown in the Stack and Watch results.
- `debugger.maxdatalevel = 3`: limit the number of nested levels for tables shown in the Stack and Watch results.
- `debugger.port = 8172`: set port number to use for debugging.
- `debugger.redirect = nil`: specify how `print` results should be redirected in the application being debugged (0.39+).
Use `'c'` for 'copying' (appears in the application output and the Output panel),
`'r'` for 'redirecting' (only appears in the Output panel),
or `'d'` for 'default' (only appears in the application output).
This is mostly useful for remote debugging to specify how the output should be redirected.
- (**removed** in 1.30) `debugger.requestattention = true`: request attention (in OS-dependent way) when debugging is started and the focus is on another application (1.0+).
- `debugger.runonstart = false`: execute script immediately after starting debugging (when set to `true`) or stop on the first Lua statement (when set to `false`).
- `debugger.verbose = false`: enable verbose output.

## Auto-complete and tooltip

- `acandtip.droprest = true`: drop the rest of the word on auto-complete (1.11+);
set to `false` to disable and keep the rest of the word.
- `acandtip.fillups = nil`: set characters that can be used to confirm the current selection during auto-complete (1.41+);
for example, `acandtip.fillups = ".("` will allow `.` and `(` to complete the auto-complete selection (instead of canceling it).
- `acandtip.nodynwords = true`: do not offer dynamic (user entered) words;
set to `false` to collect all words from all open editor tabs and offer them as part of the auto-complete list.
- `acandtip.shorttip = true`: show short calltip when typing;
set to `false` to show a long calltip.
- `acandtip.startat = 2`: start suggesting dynamic words after N characters.
- `acandtip.strategy = 2`: method of selecting auto-complete candidates:
    - `0`: substring comparison (`fo`, but not `fb` matches `foo_bar` and `FooBar`);
    - `1`: substring leading characters, CamelCase or `_` separated (`fo` and `fb`, but not `fa` match `foo_bar` and `FooBar`);
    - `2`: leading + any correctly ordered fragments (`fo`, `fa`, `fb`, but not `bf` match `foo_bar` and `FooBar`).
- `acandtip.symbols = true`: offer local and global variables in the current file in auto-complete (0.90+);
both local and global variables are offered in a scope-aware way, so they are offered only in those scopes where they are available.
- `acandtip.width = 60`: specify width of the tooltip window in characters.
- `autocomplete = true`: enable auto-complete.

## Output and Console

- `outputshell.fontname = "Courier New"`: set font name.
- `outputshell.fontsize = 10`: set font size (the default value is `11` on OSX).
- `outputshell.nomousezoom = false`: disable zoom with mouse wheel in Output/Console windows as it may be too sensitive.
- `outputshell.usewrap = true`: wrap long lines (0.51+); set to `nil` or `false` to disable. This setting only applies to the Output window; the Console always wraps its lines.

## Project/Filetree

- `filetree.fontname = nil`: set font name; Project/Filetree window has no default font as it is system dependent.
- `filetree.fontsize = 10`: set font size (the default size is `11` on OSX).
- `filetree.showchanges = true`: track and show file system changes in the filetree (1.40+).
- `filetree.mousemove = true`: enable moving files and directories in the filetree using drag-and-drop (0.80+);
set to `false` to disable.

## Outline

- `outlineinactivity = 0.250`: trigger Outline update after N seconds of inactivity (1.0+);
set to `nil` to disable Outline handling.
- `outline.activateonclick = true`: allow navigation on the outline on a single mouse click (1.41+);
when set to `false`, a double click is required to jump to the function in the source code.
Setting activation to `false` allows to set focus on the outline to enable mouse/touchpad scrolling.
- `outline.jumptocurrentfunction = true`: scroll the Outline window to the current function under the cursor (1.11+);
this setting requires `outline.showcurrentfunction` to be enabled.
- `outline.showanonymous = '~'`: set the name to be used for anonymous functions (0.81+); set to `false` to hide anonymous functions.
- `outline.showcompact = false`: set outline to display only one level of functions by default, which makes it more compact for large files (1.21+).
- `outline.showcurrentfunction = true`: highlight the current function under the cursor in the Outline window (1.11+).
- `outline.showflat = false`: show all functions as one list (no hierarchy) (0.91+).
- `outline.showmethodindicator = false`: show different icons for method indicators (0.81+).
- `outline.showonefile = false`: show only functions from the current active file in the outline (0.81+);
set to `false` to show several files in the outline with the current one expanded.
- `outline.sort = false`: sort functions by name (0.91+);
set to `false` to show functions in the order of their appearance.

## Search

- `search.autohide = false`: hide search panel after find/replace operation (1.01+).
- `search.autocomplete = true`: enable auto-complete suggestions in find/replace fields (1.01+).
- `search.contextlinesafter = 2`: set the number of context lines to shown _after_ the match line in search results (1.01+).
- `search.contextlinesbefore = 2`: set the number of context lines to shown _before_ the match line in search results (1.01+).
- `search.showaseditor = false`: show search results next to the `Output` tab (1.01+);
set to `true` to show the search results as an editor tab.
- `search.zoom = 0`: set the zoom level for the search results (1.01+);
set the value to a to a negative number (from -1 to -7) to make the results smaller or to a positive number (from 1 to 7) to make the results larger than the default value.

## Static analyzer

- `staticanalyzer.infervalue = false`: enable static analysis that infers values (0.96+).
This allows for additional reporting on unknown fields, but takes significantly more time.

## Command Bar

- `commandbar.maxitems = 30`: set maximum number of items to show (1.11+).
- `commandbar.prefilter = 250`: set the number of records processed in command bar at which to apply pre filtering to speed up fuzzy matching process (0.91+).
The records that don't have all symbols entered will be filtered out before matching algorithm is applied.
- `commandbar.showallsymbols = true`: show symbols from all indexed files in the project and not just from currently opened files (1.11+);
set to `false` to limit the symbols to currently opened files.
- `commandbar.width = 0.35`: set command bar width (1.11+); when the value is less than 1, the size is in proportion to the width of the application window; otherwise, it is the size in pixels.

## File exclusion lists

- `excludelist = {".svn/", ".git/", ".hg/", "CVS/", "*.pyc", "*.pyo", "*.exe", "*.dll", "*.obj","*.o", "*.a", "*.lib", "*.so", "*.dylib", "*.ncb", "*.sdf", "*.suo", "*.pdb", "*.idb", ".DS_Store", "*.class", "*.psd", "*.db"}`: set the list of files to be excluded from any processing by the IDE (1.10+).
These files and directories will not be displayed in the project tree and will not be searched.
They can still be opened in the IDE when opened directly using `File Open` and similar operations.
- `binarylist = {"*.jpg", "*.jpeg", "*.png", "*.gif", "*.ttf", "*.tga", "*.dds", "*.ico", "*.eot", "*.pdf", "*.swf", "*.jar", "*.zip", ".gz", ".rar"}`: set the list of files to be recognized as binary files (1.10+).
These files are displayed in the project tree, but will be skipped from fuzzy search and find- and replace-in-files operations.

File names without a wildcard `*` will be applied as is; file names that end with a path separator (both `\\` and `/` work on all platforms) will be applied as directory names.
For example, `.svn` and `*.svn` will exclude all files with `svn` extension and `.svn/` and `.svn\` will completely skip processing of the `.svn` directory.

In addition to that, `**` pattern is handled differently from `*` pattern and means a match in all (sub-)directories.
For example, `abc/*.lua` will exclude all Lua files in `abc` directory, but not in its subdirectories, while `abc/**.lua` will exclude all Lua files in `abc` directory and all its subdirectories and `abc/` will exclude `abc` directory along with all its subdirectories.

## Printing

- `print.magnification = -3`: set font size used for printing relative to the screen font size (1.21+).
- `print.wrapmode = wxstc.wxSTC_WRAP_WORD`: set the text wrapping to wrap on word and style boundaries for printed content (1.21+).
Possible values: `wxstc.wxSTC_WRAP_WORD` (wrap on word or style boundaries),
`wxstc.wxSTC_WRAP_CHAR` (wrap between any characters),
`wxstc.wxSTC_WRAP_WHITESPACE` (wrap on whitespace),
and `wxstc.wxSTC_WRAP_NONE` (no line wrapping).
- `print.colourmode = wxstc.wxSTC_PRINT_BLACKONWHITE`: set to print all text as black on white background (1.21+).
Possible values: `wxstc.wxSTC_PRINT_NORMAL` (print using the current screen colors),
`wxstc.wxSTC_PRINT_INVERTLIGHT` (invert colors for dark backgrounds),
`wxstc.wxSTC_PRINT_BLACKONWHITE` (print all text as black on white background),
`wxstc.wxSTC_PRINT_COLOURONWHITE` (print everything in its own color on white background),
and `wxstc.wxSTC_PRINT_COLOURWHITEDEFAULTBG` (print everything in its own color on white background except line numbers that use their own background color).
- `print.header = "%S\t%D\t%p/%P"`: set the header for printed content (1.21+).
- `print.footer = nil`: set the footer for printed content (1.21+).

The values for the header and the footer are strings that may include arbitraty text and various placeholders.
In addition to [placeholders from this list](#formats), `%D` can be used for the current timestamp, `%p` for the current page, and `%P` for the total number of pages.
Each string may include tabs to separate parts of the header/footer that have different adjustments.
The first value is left adjusted, the second value is centered and the third value is right adjusted.
For example, the value `\t\tPage %p of %P` for the header will print `Page 1 of 1` adjusted to the right for one-page output.

## Custom APIs

- `api = nil`: set the list of APIs to be loaded for specific or all interpreters (0.91)+.
For example, `api = {'foo', luadeb = {'bar'}}` will load `foo` API for all interpreters and `bar` API for the `luadeb` interpreter.

## Toolbar

- `toolbar.iconmap = { [ID.OPEN] = {"FILE-OPEN", "Description" }, ... }`: set the content of toolbar buttons (the icon and the description).
- `toolbar.icons = { ID.NEW, ID.OPEN, ... ID.SEPARATOR, ...}`: set the order of the buttons in the toolbar.
- `toolbar.iconsize = nil`: set the size of the icons in the toolbar.
Only two sizes are currently supported: `16` and `24` pixels.
Starting from v1.11+ the default size for icons is 24 pixels on OSX or on screens 1500+ pixels wide; all the other configurations are using 16 pixel icons.
You can still set the values to `16` or `24` as desired.

The icon used may **refer to the existing image** file by name (`"FILE-OPEN"`) or to `wx.wxBitmap` object; see this plugin for an [example on how to create a toolbar bitmap](https://github.com/pkulchenko/ZeroBranePackage/blob/master/maketoolbar.lua).

Any existing button on the toolbar can be **removed individually** by setting `toolbar.icons[ID-of-the-button]` to `false`.
If all the buttons between two separators are removed, then two separators are merged into one to keep proper spacing.

When you reference ID value from the config file, make sure to use `ID.value` syntax: `toolbar.icons[ID.NEW] = false` (0.95+).
When using an older version (before 0.95), reference them in the **global environment**: `local G = ...; toolbar.icons[G.ID_NEW] = false`.

## Images

Images loaded as toolbar and other icons can be **tinted**; this allows for easy changes to the style of the IDE without any modifications to the images themselves.

- `imagetint = nil`: set the color (as `{0-255, 0-255, 0-255}` for red, green, and blue values) to tint images with (1.10+); for example,
    - `imagetint={ 0, 71, 171}`: <span style="color: rgb(0,71,171)">cobalt color</span>
    - `imagetint={196, 30, 58}`: <span style="color: rgb(196,30,58)">cardinal color</span>
    - `imagetint={168, 81, 11}`: <span style="color: rgb(168,81,11)">amber color</span>
    - `imagetint={81, 168, 11}`: <span style="color: rgb(81,168,11)">swamp color</span>
    - `imagetint={81, 11, 168}`: <span style="color: rgb(81,11,168)">pink color</span>
    - `imagetint={168, 11, 81}`: <span style="color: rgb(168,11,81)">red color</span>
    - `imagetint={11, 168, 81}`: <span style="color: rgb(11,168,81)">verdigris color</span>

Markers are also tinted (when images are tinted); this can be disabled by setting `markertint` to `false` (1.31+).

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
`keymap[ID.STARTDEBUG] = "Ctrl-Shift-D"`.
This will modify the default shortcut for `Program | Start Debugging` command.

See an [example in user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L18),
the description for possible [accelerator values](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/src/editor/keymap.lua#L4),
and the full list of IDs in [src/editor/keymap.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/src/editor/keymap.lua).

## Editor key mapping

The editor provides [default shortcuts](doc-editor-keyboard-shortcuts) that can be modified using [editor key mapping](doc-editor-preferences#keyboard-shortcuts) settings.

## Session configuration

Some configuration information that needs to be preserved between launches (windows and panels sizes and positions, open editor tabs, recently used projects and files and so on) is saved in a special file.
The location (and the name) of this file is system dependent:
it is located in `%HOME%\ZeroBraneStudio.ini` (for v0.35 and earlier) and in `%APPDATA%\ZeroBraneStudio.ini` (for v0.36 and later) on Windows (`%APPDATA%` is mapped to a hidden folder `C:\Users\<user>\AppData\Roaming`),
`$HOME/Library/Preferences/ZeroBraneStudio Preferences` on Mac OSX, and in
`$HOME/.ZeroBraneStudio` on Linux. 
You can see the location of the HOME directory if you type `wx.wxGetHomeDir()` into the Local console.

## Command line parameters

(0.50+) Command line parameters can be specified in two ways (for those interpreters that support them):

1. by going to `Project | Command Line Parameters` and entering command line parameters (if the menu item is disabled, it means that the interpeter doesn't support command line parameters), and
2. by setting `arg.any` value in the config file. For example, `arg.any = 'a "b c"'` will pass two parameters to the script: `a` and `b c`.

(1.30+) Any configured parameters will be saved and restored on the next IDE launch.

(1.40+) The parameters will be saved per-project and restored when the project directory is updated.

Some interpreters also allow interpreter specific arguments in configuration file(s):

- `arg.lua`: set arguments for Lua interpreters,
- `arg.love2d`: set arguments for LÖVE/Love2d interpreter, and
- `arg.gslshell`: set arguments for GSL-shell interpreter.

Command line parameters configured from the IDE (`Project | Command Line Parameters`) take precedence over `arg.*` parameters in configuration file(s).

## Interpreter path

These settings can be used to change the location of the executable file for different interpreters.
In most cases you don't need to specify this as ZeroBrane Studio will check default locations for the executable, but in those cases when auto-detection fails, you can specify the path yourself.
You can use this setting to specify an alternative interpreter you want to use (for example, LuaJIT instead of Lua interpreter).

Note that the **full executable name** is expected, not a directory name. The values shown are example values for a Windows system, not default values.

- `path.lua = 'd:/lua/lua'`: specify path to the default Lua interpreter.
- `path.lua52 = 'd:/lua/lua52'`: specify path to the Lua 5.2 interpreter (used when `Lua 5.2` interpreter is selected).
- `path.lua53 = 'd:/lua/lua53'`: specify path to the Lua 5.3 interpreter (used when `Lua 5.3` interpreter is selected).
- `path.love2d = 'd:/lua/love/love'`: specify path to LÖVE/love2d executable.
- `path.moai = 'd:/lua/moai/moai'`: specify path to Moai executable.
- `path.gideros = 'd:/Program Files/Gideros/GiderosPlayer.exe'`: specify path to Gideros executable.
- `path.corona = 'd:/path/to/Corona SDK/Corona Simulator.exe'`: specify path to Corona executable.
- `path.gslshell = [[D:\Lua\gsl-shell\gsl-shell.exe]]`: specify path to GSL-shell executable.
