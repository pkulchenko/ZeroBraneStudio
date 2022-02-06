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
-  (**removed in v1.30**) `allowinteractivescript = true`: allow interaction in the output window.
- `autoanalyzer = true`: enable autoanalyzer that adds scope aware indicators to variables (**up to v0.50** it was spelled as `autoanalizer`).
- `autorecoverinactivity = 10`: trigger saving autorecovery after N seconds of inactivity; set to `nil` to disable autorecovery.
- `bordersize = 3`: set the size of the border (sash) between windows and panels (**v0.91+**, updated default in **v1.31+**).
- `codepage = false`: set the codepage for the script output on Windows (**v1.61+**);
set to `true` to enable auto-detection of the current code page, or
set to `<number>` to set a specific code page (for example, use `936` for Simplified Chinese/GB2312).
- `commandlinehistorylength = 10`: set history length for command lines (**v1.31+**); the history is kept across all projects.
- `filehistorylength = 20`: set history length for files.
- `hotexit = false`: enable quick exit without prompting to save files (**v0.71+**).
The changes in files and all unsaved buffers should be restored during the next launch.
This session information is saved in the [.ini file](#session-configuration).
- `ini = false`: provide an alternative location for the [.ini file](#session-configuration).
If the filename is absolute, it is used as the new location;
(**v1.11+**) if it is relative and includes a path component (for example, `./file.ini` or `path/file.ini`), then the file is created relative to the IDE directory;
if it only contains the file name (for example, `file.ini`), then the file is created in the [system-dependent location](#session-configuration).
- `language = "en"`: set the language to use in the IDE; this requires a language file in `cfg/i18n` directory.
- `menuicon = true`: show icons in the menu (**v1.31+**).
On Linux may not show even when set to `true`, as it is also controlled by `gtk-menu-images` setting.
- `outlineinactivity = 0.250`: trigger Outline update after N seconds of inactivity (**v1.0+**); set to `nil` to disable Outline handling.
- `projectautoopen = true`: auto-open windows on project switch.
- `projecthistorylength = 20`: set history length for projects.
- `savebak = false`: create backup on file save.
- `showhiddenfiles = false`: display hidden files (those that have "hidden" attribute set on Windows or those that start with `.` on Linux) in the project tree (**v1.21+**);
set to `true` to display both files and directories or to `wx.wxDIR_FILES` to display only files and to `wx.wxDIR_DIRS` to display only directories.
- `showmemoryusage = nil`: display memory usage stats in the Status bar (**v1.11+**);
set to `true` to display the stats.
- `singleinstance = true`: enable check that prevents starting multiple instances of the IDE.
- `symbolindexinactivity = 2`: trigger indexing of project files for symbol search after N seconds of inactivity (**v1.11+**).

## Debugger

- `debugger.allowediting = false`: enable editing of files while debugging.
- `debugger.hostname = "hostname.or.IP.address"`: set hostname to use for debugging.
- `debugger.ignorecase = false`: make debugger to ignore case mismatch when activating files (**v1.41+**);
This can be used to activate files that have different spelling of the file names (case-wise);
for example, `Test` vs `test` vs `TEST`.
- `debugger.init = nil`: specify code to run (as a **string**) at the beginning of the debugger session.
This may be used to provide some initialization to be applied before the debugging starts.
For example, `debugger.init = [[some initialization code]]`.
- `debugger.linetobreakpoint = false`: move the current line in the editor to the line with the triggered breakpoint (**v1.41+**).
- `debugger.maxdatalength = 256`: set (approximate) limit (in bytes) for the data shown in the Stack and Watch results.
- `debugger.maxdatanum = 128`: limit the number of elements for tables shown in the Stack and Watch results.
- `debugger.maxdatalevel = 3`: limit the number of nested levels for tables shown in the Stack and Watch results as well as in the tooltips.
- `debugger.numformat = "%.16g"`: specify numeric format used in the Stack and Watch results (**v1.51+**).
The numbers in the Console are shown using `"%.17g"` format, which is needed for preserving all significant bits in double values.
- `debugger.port = 8172`: set port number to use for debugging.
- `debugger.redirect = nil`: specify how `print` results should be redirected in the application being debugged (**v0.39+**).
Use `'c'` for 'copying' (appears in the application output and the Output panel),
`'r'` for 'redirecting' (only appears in the Output panel),
or `'d'` for 'default' (only appears in the application output).
This is mostly useful for remote debugging to specify how the output should be redirected.
- (**removed in v1.30**) `debugger.requestattention = true`: request attention (in OS-dependent way) when debugging is started and the focus is on another application (**v1.0+**).
- `debugger.runonstart = false`: execute script immediately after starting debugging (when set to `true`) or stop on the first Lua statement (when set to `false`).
- `debugger.showtostring = false`: show values returned by `__tostring` when serializing tables with metatables that provide that method (**v1.61+**).
When set to `false`, the tables are shown as tables; when set to `true`, the value returned by `__tostring` method is shown instead.
- `debugger.verbose = false`: enable verbose output.

## Auto-complete and tooltip

- `acandtip.droprest = true`: drop the rest of the word on auto-complete (**v1.11+**);
set to `false` to disable and keep the rest of the word.
- `acandtip.fillups = nil`: set characters that can be used to confirm the current selection during auto-complete (**v1.41+**);
for example, `acandtip.fillups = ".("` will allow `.` and `(` to complete the auto-complete selection (instead of canceling it).
- `acandtip.ignorecase = false`: set to ignore character case during auto-complete.
- `acandtip.nodynwords = true`: do not offer dynamic (user entered) words;
set to `false` to collect all words from all open editor tabs and offer them as part of the auto-complete list.
- `acandtip.shorttip = true`: show short calltip when typing;
set to `false` to show a long calltip.
- `acandtip.startat = 2`: start suggesting dynamic words after N characters.
- `acandtip.strategy = 2`: method of selecting auto-complete candidates:
    - `0`: leading substring comparison (`fo`, but not `fb` matches `foo_bar` and `FooBar`);
    - `1`: leading substring characters, CamelCase or `_` separated (`fo` and `fb`, but not `fa` match `foo_bar` and `FooBar`);
    - `2`: leading + any correctly ordered fragments (`fo`, `fa`, `fb`, but not `bf` match `foo_bar` and `FooBar`).
- `acandtip.symbols = true`: offer local and global variables in the current file in auto-complete (**v0.90+**);
both local and global variables are offered in a scope-aware way, so they are offered only in those scopes where they are available.
Lower case values are matched in case-insensitive manner (`a` matches both `a` and `A`), but upper case values are match exactly (`A` matches only `A`).
Other possible values include setting strategy for selecting auto-complete candidates, similar to `acandtip.strategy` (**v1.61+**):
    - `0`: leading substring comparison (`fo`, but not `fb` matches `foo_bar` and `FooBar`);
    - `2`: leading + any correctly ordered fragments (`fo`, `fa`, `fb`, but not `bf` match `foo_bar` and `FooBar`).
- `acandtip.width = 60`: specify width of the tooltip window in characters.
- `autocomplete = true`: enable auto-complete.

## Output

`outputshell` option to specify Output window attributes has been replaced by `output` in  **v1.61+**.
Use `outputshell` instead of `output` in earlier versions.

- `output.fontname = "Courier New"`: set font name.
- `output.fontsize = 10`: set font size (the default value is `11` on macOS).
- `output.lineactivate = {['.-%[string "([^"]+)"%]:(%d+)%s*:'] = false, ["%s*(.-):(%d+):(%d+):"] = false, ["%s*(.-):(%d+)%s*:"] = true, ["%((.-):(%d+)%s*:"] = false}`: specify pattern for activating line in the output window (**v1.71+**).
The pattern "returns" `filename`, `line`, and (optional) `position` values that are used to navigate to that file and location.
The value corresponding to the pattern may be `false` (stop and actiate), `true` (continue checking other values), or function (in which case the function will get the matches returned by the pattern ans is expected to return `filename`, `line`, and (optional) `position`.
Activation is triggered on double click on the line, at which time patterns are checked (in unspecified order), and the first matched pattern is handled (unless its value is `true`, in which case other patterns are checked as well).
- `output.nomousezoom = false`: disable zoom with mouse wheel in the Output window as it may be too sensitive.
- `output.showansi = true`: enable handling of ANSI escapes in the Output window (**v1.70+**).
- `output.usewrap = true`: wrap long lines (**v0.51+**); set to `nil` or `false` to disable.

## Console

`outputshell` option to specify Console window attributes has been replaced by `console` in  **v1.61+**.
Use `outputshell` instead of `console` in earlier versions.

- `console.fontname = "Courier New"`: set font name.
- `console.fontsize = 10`: set font size (the default value is `11` on macOS).
- `console.nomousezoom = false`: disable zoom with mouse wheel in the Console window as it may be too sensitive.

## Project/Filetree

- `filetree.fontname = nil`: set font name; Project/Filetree window has no default font as it is system dependent.
- `filetree.fontsize = 10`: set font size (the default size is `11` on macOS).
- `filetree.iconfontname = nil`: set font name used in filetree icon text (**v1.90+**). This value is set based on the default editor font, but is preserved and can be changed independenty to better match icons when the editor font is changed.
- `filetree.iconmap = {}`: set mapping from extension to colors to use in Project/Filetree icons (**v1.51+**);
set to `false` to disable showing extensions in icons.
The color associated with an extension is in `{r,g,b}` format; for example, to associate `lua` extension with `red` color, use `filetree.iconmap.lua = {fg = {255, 0, 0}}`.
- `filetree.showchanges = true`: track and show file system changes in the filetree (**v1.40+**).
- `filetree.mousemove = true`: enable moving files and directories in the filetree using drag-and-drop (**v0.80+**);
set to `false` to disable.

## Outline

- `outlineinactivity = 0.250`: trigger Outline update after N seconds of inactivity (**v1.0+**);
set to `nil` to disable Outline handling.
- `outline.activateonclick = true`: allow navigation on the outline on a single mouse click (**v1.41+**);
when set to `false`, a double click is required to jump to the function in the source code.
Setting activation to `false` allows to set focus on the outline to enable mouse/touchpad scrolling.
- `outline.jumptocurrentfunction = true`: scroll the Outline window to the current function under the cursor (**v1.11+**);
this setting requires `outline.showcurrentfunction` to be enabled.
- `outline.showanonymous = '~'`: set the name to be used for anonymous functions (**v0.81+**); set to `false` to hide anonymous functions.
- `outline.showcompact = false`: set outline to display only one level of functions by default, which makes it more compact for large files (**v1.21+**).
- `outline.showcurrentfunction = true`: highlight the current function under the cursor in the Outline window (**v1.11+**).
- `outline.showflat = false`: show all functions as one list (no hierarchy) (**v0.91+**).
- `outline.showmethodindicator = false`: show different icons for method indicators (**v0.81+**).
- `outline.showonefile = false`: show only functions from the current active file in the outline (**v0.81+**);
set to `false` to show several files in the outline with the current one expanded.
- `outline.sort = false`: sort functions by name (**v0.91+**);
set to `false` to show functions in the order of their appearance.

## Search

- `search.autohide = false`: hide search panel after find/replace operation (**v1.01+**).
- `search.autocomplete = true`: enable auto-complete suggestions in find/replace fields (**v1.01+**).
- `search.autoinselection = true`: enable search-in-selection when the find/replace dialog is opened and the selected fragment has more than one line (**v1.61+**);
set to `false` to disable, in which case search-in-selection will have to be manually selected.
- `search.contextlinesafter = 2`: set the number of context lines to shown _after_ the match line in search results (**v1.01+**).
- `search.contextlinesbefore = 2`: set the number of context lines to shown _before_ the match line in search results (**v1.01+**).
- `search.showaseditor = false`: show search results next to the `Output` tab (**v1.01+**);
set to `true` to show the search results as an editor tab.
- `search.zoom = 0`: set the zoom level for the search results (**v1.01+**);
set the value to a to a negative number (from -1 to -7) to make the results smaller or to a positive number (from 1 to 7) to make the results larger than the default value.

## Static analyzer

- `staticanalyzer.infervalue = false`: enable static analysis that infers values (**v0.96+**).
This allows for additional reporting on unknown fields, but takes significantly more time.
This setting only has effect with the default ([LuaInspect](https://github.com/davidm/lua-inspect)-based) analyzer.
- `staticanalyzer.luacheck = false`: set to use [Luacheck](https://github.com/mpeterv/luacheck) as the static analyzer instead of the default one based on LuaInspect (**v1.61+**);
set to `true` to enable or to a table with options to pass to Luacheck (for example, `staticanalyzer.luacheck = {options = {max_line_length = false, ignore = {"11.", "6.."}}}`).

## Command Bar

- `commandbar.filecache = true`: enable caching for files shown in the commandbar (**v1.61+**).
set to `false` to disable.
- `commandbar.maxitems = 30`: set maximum number of items to show (**v1.11+**).
- `commandbar.maxlines = 8`: set maximum number of lines to show (**v1.50+**).
- `commandbar.prefilter = 250`: set the number of records processed in command bar at which to apply pre filtering to speed up fuzzy matching process (**v0.91+**).
The records that don't have all symbols entered will be filtered out before matching algorithm is applied.
- `commandbar.showallsymbols = true`: show symbols from all indexed files in the project and not just from currently opened files (**v1.11+**);
set to `false` to limit the symbols to currently opened files.
- `commandbar.width = 0.35`: set command bar width (**v1.11+**); when the value is less than 1, the size is in proportion to the width of the application window; otherwise, it is the size in pixels.

## File exclusion lists

- `excludelist = { [".svn/"] = true, [".git/"] = true, [".hg/"] = true, ["CVS/"] = true, ["*.pyc"] = true, ["*.pyo"] = true, ["*.exe"] = true, ["*.dll"] = true, ["*.obj"] = true, ["*.o"] = true, ["*.a"] = true, ["*.lib"] = true, ["*.so"] = true, ["*.dylib"] = true, ["*.ncb"] = true, ["*.sdf"] = true, ["*.suo"] = true, ["*.pdb"] = true, ["*.idb"] = true, [".DS_Store"] = true, ["*.class"] = true, ["*.psd"] = true, ["*.db"] = true }`: set the list of files to be excluded from any processing by the IDE (**v1.10+**).
These files and directories will not be displayed in the project tree and will not be searched.
They can still be opened in the IDE when opened directly using `File Open` and similar operations.
- `binarylist = { ["*.jpg"] = true, ["*.jpeg"] = true, ["*.png"] = true, ["*.gif"] = true, ["*.ttf"] = true, ["*.tga"] = true, ["*.dds"] = true, ["*.ico"] = true, ["*.eot"] = true, ["*.pdf"] = true, ["*.swf"] = true, ["*.jar"] = true, ["*.zip"] = true, ["*.gz"] = true, ["*.rar"] = true }`: set the list of files to be recognized as binary files (**v1.10+**).
These files are displayed in the project tree, but will be skipped from fuzzy search and find- and replace-in-files operations.

(**v1.61+**) The format of the lists has been changed from array (`{"*.jpg", "*.png"}`) to hash (`{["*.jpg"] = true, ["*.png"] = true}`) to simplify addition and removal of values. The array syntax is still supported, but deprecated.

File names without a wildcard `*` will be applied as is; file names that end with a path separator (both file separators `\` and `/` work on all platforms) will be applied as directory names.
For example, `.svn` and `*.svn` will exclude all files with `svn` extension and `.svn/` and `.svn\` will completely skip processing of the `.svn` directory.

In addition to that, `**` pattern is handled differently from `*` pattern and means a match in all (sub-)directories.
For example, `abc/*.lua` will exclude all Lua files in `abc` directory, but not in its subdirectories, while `abc/**.lua` will exclude all Lua files in `abc` directory and all its subdirectories and `abc/` will exclude `abc` directory along with all its subdirectories.

## Printing

- `print.magnification = -3`: set font size used for printing relative to the screen font size (**v1.21+**).
- `print.wrapmode = wxstc.wxSTC_WRAP_WORD`: set the text wrapping to wrap on word and style boundaries for printed content (**v1.21+**).
Possible values: `wxstc.wxSTC_WRAP_WORD` (wrap on word or style boundaries),
`wxstc.wxSTC_WRAP_CHAR` (wrap between any characters),
`wxstc.wxSTC_WRAP_WHITESPACE` (wrap on whitespace),
and `wxstc.wxSTC_WRAP_NONE` (no line wrapping).
- `print.colourmode = wxstc.wxSTC_PRINT_BLACKONWHITE`: set to print all text as black on white background (**v1.21+**).
Possible values: `wxstc.wxSTC_PRINT_NORMAL` (print using the current screen colors),
`wxstc.wxSTC_PRINT_INVERTLIGHT` (invert colors for dark backgrounds),
`wxstc.wxSTC_PRINT_BLACKONWHITE` (print all text as black on white background),
`wxstc.wxSTC_PRINT_COLOURONWHITE` (print everything in its own color on white background),
and `wxstc.wxSTC_PRINT_COLOURWHITEDEFAULTBG` (print everything in its own color on white background except line numbers that use their own background color).
- `print.edgemode = wxstc.wxSTC_EDGE_NONE`: set how the edge for the long lines is displayed (**v1.91+**);
set to `wxstc.wxSTC_EDGE_LINE` to display as a line.
- `print.footer = nil`: set the footer for printed content (**v1.21+**).
- `print.header = "%S\t%D\t%p/%P"`: set the header for printed content (**v1.21+**).

The values for the header and the footer are strings that may include arbitraty text and various placeholders.
In addition to [placeholders from this list](#formats), `%D` can be used for the current timestamp, `%p` for the current page, and `%P` for the total number of pages.
Each string may include tabs to separate parts of the header/footer that have different adjustments.
The first value is left adjusted, the second value is centered and the third value is right adjusted.
For example, the value `\t\tPage %p of %P` for the header will print `Page 1 of 1` adjusted to the right for one-page output.

## Default

- `default.interpreter = nil`: set the default interpreter used for new projects (**v1.20+**).
Use a string value with the name of the interpreter to set the interpreter.
The name of the interpreter is either its file name (without an extension) or a name used in `ide:AddInterpreter()` call.
For example, to select the LÖVE interpreter, use `interpreter = "love2d"`.
- `default.extension = 'lua'`: set the default file extension to be used when `default.usecurrentextension` is set to `false` or when no editor tab is opened (**v1.61+**).
- `default.name = 'untitled'`: set the default file name for files created in the IDE.
- `default.usecurrentextension = true`: use extension from the current editor tab when creating a new file (**v1.61+**).
Set to `false` to always use `default.extension`, which is also used when no editor tab is opened.

## Custom APIs

- `api = nil`: set the list of APIs to be loaded for specific or all interpreters (**v0.91+**).
For example, `api = {'foo', luadeb = {'bar'}}` will load `foo` API for all interpreters and `bar` API for the `luadeb` interpreter.

## Toolbar

- `toolbar.iconmap = { [ID.OPEN] = {"FILE-OPEN", "Description" }, ... }`: set the content of toolbar buttons (the icon and the description).
- `toolbar.icons = { ID.NEW, ID.OPEN, ... ID.SEPARATOR, ...}`: set the order of the buttons in the toolbar.
- `toolbar.iconsize = nil`: set the size of the icons in the toolbar.
**Starting from v1.11+** the default size for icons is 24 pixels on macOS or on screens 1500+ pixels wide; all the other configurations are using 16 pixel icons.
**Starting from v1.90+** the default size for icons is 24 pixels on macOS or on screens 1280+ pixels wide; all the other configurations are using 16 pixel icons.
The size of icons is scaled by the scaling factor (as configured in the OS). You can still set the values to any size divisible by `16` or `24` (before **v1.90** only `16` and `24` sizes were supported).

The icon used may **refer to the existing image** file by name (`"FILE-OPEN"`) or to `wx.wxBitmap` object; see this plugin for an [example on how to create a toolbar bitmap](https://github.com/pkulchenko/ZeroBranePackage/blob/master/maketoolbar.lua).

Any existing button on the toolbar can be **removed individually** by setting `toolbar.icons[ID-of-the-button]` to `false`.
If all the buttons between two separators are removed, then two separators are merged into one to keep proper spacing.

When you reference ID value from the config file, make sure to use `ID.value` syntax: `toolbar.icons[ID.NEW] = false` (**v0.95+**).
When using an older version (**before v0.95**), reference them in the **global environment**: `local G = ...; toolbar.icons[G.ID_NEW] = false`.

## Images

Images loaded as toolbar and other icons can be **tinted**; this allows for easy changes to the style of the IDE without any modifications to the images themselves.

- `imagetint = false`: set the color (as `{0-255, 0-255, 0-255}` for red, green, and blue values) to tint images with (**v1.10+**); for example,
    - `imagetint={ 0, 71, 171}`: <span style="color: rgb(0,71,171)">cobalt color</span>
    - `imagetint={196, 30, 58}`: <span style="color: rgb(196,30,58)">cardinal color</span>
    - `imagetint={168, 81, 11}`: <span style="color: rgb(168,81,11)">amber color</span>
    - `imagetint={81, 168, 11}`: <span style="color: rgb(81,168,11)">swamp color</span>
    - `imagetint={81, 11, 168}`: <span style="color: rgb(81,11,168)">pink color</span>
    - `imagetint={168, 11, 81}`: <span style="color: rgb(168,11,81)">red color</span>
    - `imagetint={11, 168, 81}`: <span style="color: rgb(11,168,81)">verdigris color</span>

Markers are also tinted (when images are tinted); this can be disabled by setting `markertint` to `false` (**v1.31+**).

## Formats

- `format.menurecentprojects = "%f | %i"`: format of the `Recent Project` menu and the toolbar dropdown.
- `format.apptitle = "%T - %F"`: format of the application title.

Possible placeholder values to use in formats (**v0.61+**):

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
it is located in `%APPDATA%\ZeroBraneStudio.ini` (**for v0.36 and later**) and in `%HOME%\ZeroBraneStudio.ini` (**for v0.35 and earlier**) on Windows (`%APPDATA%` is mapped to a hidden folder `C:\Users\<user>\AppData\Roaming`),
`$HOME/Library/Preferences/ZeroBraneStudio Preferences` on macOS, and in
`$HOME/.ZeroBraneStudio` on Linux. 
You can see the location of the HOME directory if you type `wx.wxGetHomeDir()` into the Local console.

## Command line parameters

(**v0.50+**) Command line parameters can be specified in several ways (for those interpreters that support them):

- by going to `Project | Command Line Parameters` and entering command line parameters (if the menu item is disabled, it means that the interpeter doesn't support command line parameters), and
- by setting `arg.any` value in the config file. For example, `arg.any = 'a "b c"'` will pass two parameters to the script: `a` and `b c`.

The command line parameters will be shown next to the interpreter in the right panel of the status bar.
You can click the area that shows command line parameters and select other recently used parameters from the list.

(**v1.30+**) Any configured parameters will be saved and restored on the next IDE launch.

(**v1.40+**) The parameters will be saved per-project and restored when the project directory is updated.

Some interpreters also allow interpreter specific arguments in configuration file(s):

- `arg.lua`: set arguments for Lua interpreters,
- `arg.love2d`: set arguments for LÖVE/Love2d interpreter, and
- `arg.gslshell`: set arguments for GSL-shell interpreter.

Command line parameters configured from the IDE (`Project | Command Line Parameters`) take precedence over `arg.*` parameters in configuration file(s).

## Interpreter path

These settings can be used to change the location of the executable file for different interpreters.
In most cases you don't need to specify this as ZeroBrane Studio will check default locations for the executable, but in those cases when auto-detection fails, you can specify the path yourself.
You can use this setting to specify an alternative interpreter you want to use (for example, LuaJIT instead of Lua interpreter).

Note that the **full executable name** is expected, not a directory name.
The values shown are example values for a Windows-based system, not default values.
If you are using macOS or Linux, set the path accordingly.

- `path.lua = 'd:/lua/lua'`: specify path to the default Lua interpreter.
- `path.lua52 = 'd:/lua/lua52'`: specify path to the Lua 5.2 interpreter (used when `Lua 5.2` interpreter is selected).
- `path.lua53 = 'd:/lua/lua53'`: specify path to the Lua 5.3 interpreter (used when `Lua 5.3` interpreter is selected).
- `path.love2d = 'd:/lua/love/love'`: specify path to LÖVE/love2d executable.
- `path.moai = 'd:/lua/moai/moai'`: specify path to Moai executable.
- `path.gideros = 'd:/Program Files/Gideros/GiderosPlayer.exe'`: specify path to Gideros executable.
- `path.corona = 'd:/path/to/Corona SDK/Corona Simulator.exe'`: specify path to Corona executable.
- `path.gslshell = [[D:\Lua\gsl-shell\gsl-shell.exe]]`: specify path to GSL-shell executable.
