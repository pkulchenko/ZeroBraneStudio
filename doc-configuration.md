---
layout: default
title: Configuration
---

<ul id='toc'>&nbsp;</ul>

ZeroBrane Studio uses Lua files to allow users to modify its default settings and to set editor color scheme, UI language, paths to executables, and other [general](doc-general-preferences) and [editor](doc-editor-preferences) preferences.
These configuration files can be specified in three ways: **system-wide**, **per user**, and via **command line**.
The settings set in these files are applied in the same **order**: system, user, command line (thus parameters specified using the command line will overwrite those specified in the system-wide configuration file).

System and user configuration changes **do not take effect** until the configuration file is saved and ZeroBrane Studio is restarted.

## System-wide configuration

**System-wide** `cfg/user.lua` (which you may need to create) is located under the directory you installed ZeroBrane Studio to.
You can **access this configuration file** by going to `Edit | Preferences | Settings: System` (v0.37+).
If you are using an older version, you may need to open and edit the file directly.
For example, on macOS it is going to be `/Applications/ZeroBraneStudio.app/Contents/ZeroBraneStudio/cfg/user.lua`;
you may need to right click on "ZeroBrane Studio" application and select `Show Package Contents`.

**System-wide** packages are stored in `packages/` directory.

Note that on macOS the per-system configuration file and packages **may be overwritten** when a new version of ZeroBrane Studio is installed to the `Applications` directory, so you may want to save them before upgrading.

## Per-user configuration

**Per-user** configuration is stored in `HOME/.zbstudio/user.lua` (where `HOME` is the path specified by the `HOME` environment variable).
You can **access this configuration file** by going to `Edit | Preferences | Settings: User` (v0.37+).

**Per-user** packages are stored in `HOME/.zbstudio/packages/` directory.

On Windows, if `HOME` environment variable is not set, then the concatenation of `HOMEDRIVE` and `HOMEPATH` environment variables is used instead.

## Configuration via command line

In addition to system-wide and per-user configurations, it is also possible to provide a set of parameters that will be in effect only for one session.
**Command line** configuration can be specified by adding `-cfg <filename>` parameter when the application is started.
For example, on Windows the command `zbstudio.exe -cfg myconfig.lua` will apply settings from `myconfig.lua`.

Individual commands can also be specified as configuration parameters; for example, `zbstudio.exe -cfg "language='ru'"` will set Russian as the user interface language in the IDE.
The format of the arguments passed using the command line is exactly the same as specified in the configuration files. If you need to set several values you can separate them with a semicolon: `zbstudio.exe -cfg "language='ru'; editor.fontsize = 12"`.

## Configuration file commands

The configuration files allow for several special commands:

- `include "file.lua"`: includes another (configuration) file using relative or absolute name.
The relative name is checked against the directory (1) of the current configuration file, (2) of the **per-user** configuration file, and (3) of the **system-wide** configuration file (in that order).
As soon as the file is found, it's processed and the search is stopped.
- `package {}`, `package "path/"`, and `package "file.lua"`: loads and processes the file as the package in the IDE.
The first syntax (`package {}`) allows to include the package code in the config file, where the table passed is the package code.
The other two load all files from a folder as packages or one particular package.
Path and file names may be relative or absolute. The relative name is checked against `.` (current directory), `packages/`, and `../packages/` directories (in this order and all relative to the directory of the current configuration file).
As soon as the file is found, it's processed and the search is stopped.

## Configuration variables

There are some rare cases in which you may need to access or change some values that are not configuration settings in the IDE.
For example, you may need access the spec configuration (`ide.specs.lua`) or call lua functions from an inline package (`package { onRegister = function() table.insert(something, 'else') end }`).
Before version 1.21, `local G = ...` was used to provide access to the global environment from the config file.
Starting from version 1.21, this is no longer needed, as the global environment is already available, so those methods can be used directly (as can be seen in `cfg/user-sample.lua`).
The access and the processing is the same for all config files.
