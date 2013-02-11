---
layout: default
title: General Preferences
---

To **modify default general preferences**, you can use these commands and apply them
as described in the [configuration](doc-configuration.html) section
and as shown in [user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua).
The values shown are the default values.

## General

- `activateoutput = true`: activate Output or Console window on new content added.
- `projectautoopen = true`: auto-open windows on project switch.
- `autorecoverinactivity = 10`: trigger saving auto-recovery after N seconds of inactivity.
- `allowinteractivescript = true`: allow interaction in the output window.
- `savebak = false`: create backup on file save.
- `filehistorylength = 20`: set history length for files.
- `projecthistorylength = 15`: set history length for projects.
- `language = "ru"`: set the language to use in the IDE; this requires `ru.lua` file in cfg/i18n directory.

## Debugger

- `debugger.verbose = false`: enable verbose output.
- `debugger.hostname = "hostname.or.IP.address"`: set hostname.

## Auto-complete

- `autocomplete = true`: enable auto-complete.
- `acandtip.shorttip = true`: show short calltip when typing; shows long calltip when set to `false`.
- `acandtip.nodynwords = true`: do not offer dynamic (user entered) words;
when set to `false` will collect all words from all open editor tabs and offer them as part of the auto-complete list.
- `acandtip.startat = 2`: start suggesting dynamic words after N characters.
