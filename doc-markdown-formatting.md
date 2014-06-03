---
layout: default
title: Markdown formatting
---

ZeroBrane Studio provides limited support for Markdown formatting in comments.
This can be used to provide documentation and educational materials integrated
with the IDE. For example, the materials can include bold and italic text
elements, links for navigation between the pages, snippets that can be executed
in the Local console by clicking on them, and other elements that add
interactivity to source code pages.

## Markdown elements 

There are six elements that are supported in the IDE:

- `_` - italic, for example, _italic_ (`_italic_`)
- `**` - bold, for example, **bold** (`**bold**`)
- `[link description](link itself)` - links, for example, [ZeroBrane Studio project](http://studio.zerobrane.com) (`[ZeroBrane Studio project](http://studio.zerobrane.com)`)
- ` - code, for example `print(1+2)`
- `#` - header, for example, `# Section 1`
- `|` - highlight, for example, `|warning|` (this is an extension of Markdown syntax)

Combinations of different styles is not supported; for example, `_**foo**_` will show only as italic (with text including asterisks), not as bold italic. This is similar to how Markdown handles other markup inside code fragments.

Headers are marked at the first position of the line. All markers require whitespace outside and non-whitespace inside of them, for example, `something **else**` will be highlighted, but `something**else**` will not.

There are links of three types:
(1) URLs, which will open a default browser window when clicked,
(2) IDE files, which will load in the current window or a new window if prepended with `+`, and
(3) IDE commands, like `macro:shell(2+3)` or `macro:inline(ProjectRun())`.
The difference between `shell` and `inline` is that `shell` will show executed command in the Console and `inline` will not.

The colors/styles of markup elements can be customized by referencing their symbols as the field in the `styles` table.
For example, `styles.['['] = {hs = {0, 0, 255}}` will set the link color to blue.
