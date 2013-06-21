---
layout: default
title: Styles and Color schemes
---

To **modify colors and appearance** of text, markers, or indicators in the editor and Output/Console panels,
you can use these commands and apply them as described in the [configuration](doc-configuration.html) section
and as shown in [user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua).

## Example

The following configuration will set text background to be light red: `styles.text = {bg = {250,200,200}}`.

## Style attributes

- `fg`: foreground; a table with three color components `{red,green,blue}` (0-255)
- `bg`: background; a table with three color components `{red,green,blue}` (0-255)
- `u`: underline; boolean value
- `b`: bold; boolean value
- `i`: italic; boolean value
- `fill`: fill to the end of line; boolean value
- `fn`: font face name; string ("Lucida Console")
- `fs`: font size; number (11)

## Style elements

See [tomorrow.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/tomorrow.lua#L185-L225) for the complete list.

## Indicators (0.38+)

Indicators add visual elements to the text in the editor, for example, a dotted underline for local variables or a solid line for global ones.

- `styles.indicator.fncall`: function call
- `styles.indicator.varlocal`: local variable
- `styles.indicator.varglobal`: global variable
- `styles.indicator.varmasking`: masking variable
- `styles.indicator.varmasked`: masked variable

You can change the color of an indicator (by setting its `fg` property), its type (by setting its `st` property) or disable it by setting its value to `nil`:

- `styles.indicator.fncall = {st = wxstc.wxSTC_INDIC_PLAIN, fg = {240,0,0}}`: set color and type
- `styles.indicator.fncall = {fg = {240,0,0}}`: set color
- `styles.indicator.fncall = nil`: disable the indicator

## Color schemes

Color schemes allow configuring colors and attributes in coordinated set.
See [tomorrow.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/tomorrow.lua) for an example of how these colors and attributes can be manipulated,
[scheme-picker.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/scheme-picker.lua) for how they can be used,
and [user-sample.lua](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/cfg/user-sample.lua#L83-L88) for how a color scheme can be configured.
