---
layout: default
title: Configuration
---

ZeroBrane Studio uses Lua files to allow users to modify its default settings and to set editor color scheme, UI language, paths to executables, and other [general](doc-general-preferences.html) and [editor](doc-editor-preferences.html) preferences.
These configuration files can be specified in three ways: **system-wide**, **per user**, and via **command line**.
The settings set in these files are applied in the same **order**: system, user, command line (thus parameters specified using the command line will overwrite those specified in the system-wide configuration file).

## System-wide configuration

**System-wide** `cfg/user.lua` (which you may need to create) is located under the directory you installed ZeroBrane Studio to.
You can **access this coniguration file** by going to `Edit | Preferences | Settings: System` (v0.37+).
If you are using an older version, you may need to open and edit the file directly.
For example, on Mac OSX it is going to be `/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio/cfg/user.lua`;
you may need to right click on "ZeroBrane Studio" application and select `Show Package Contents`.

Note that on Mac OSX the per-system configuration file **may be overwritten** when a new version of ZeroBrane Studio is installed to the `Applications` directory, so you may want to save it before upgrading.

## Per-user configuration

**Per-user** configuration is stored in `HOME/.zbstudio/user.lua` (where `HOME` is the path specified by the `HOME` environment variable).
You can **access this coniguration file** by going to `Edit | Preferences | Settings: User` (v0.37+).

## Configuration via command line

In addition to system-wide and per-user configurations, it is also possible to provide a set of parameters that will be in effect only for one session.
**Command line** configuration can be specified by adding `-cfg <filename>` parameter when the application is started.
For example, on Windows the command `zbstudio.exe -cfg myconfig.lua` will apply settings from `myconfig.lua`.

Individual commands can also be specified as configuration parameters; for example, `zbstudio.exe -cfg "language='ru'"` will set Russian as the user interface language in the IDE.
The format of the arguments passed using the command line is exactly the same as specified in the configuration files. If you need to set several values you can separate them with a semicolon: `zbstudio.exe -cfg "language='ru'; editor.fontsize = 12"`.
