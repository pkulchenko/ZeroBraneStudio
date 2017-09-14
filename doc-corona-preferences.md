---
layout: default
title: Corona Preferences
---

## Corona SDK settings

- `corona = { skin = nil }`: set simulator skin for Corona projects; for example, `corona = { skin = 'iPad' }` will set `iPad` skin.
- `corona = { showconsole = nil }`: show Corona SDK console when the simulator launches on Windows (**v0.81+**) and on MacOS (**v0.91+**); set to `true` to show the console.

If you are using Corona Simulator that supports auto-reloading of the application,
you may want to set `debugger.allowediting = true` to enable editing of the files while debugging.
