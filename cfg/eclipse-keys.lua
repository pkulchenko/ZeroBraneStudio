-- Add to your user / system configuration file: include "eclipse-keys"
-- See the [configuration](http://studio.zerobrane.com/doc-configuration.html) page for details.

-- Alt-Shift-Cmd-X (Alt maps to Option, Ctrl maps to Command)
-- The mapping is largely based on [Eclipse Keyboard Shortcuts](http://eclipse-tools.sourceforge.net/Keyboard_shortcuts_(3.0).pdf).
local map = {
-- File menu
  [ID.NEW]              = "Ctrl-N",
  [ID.OPEN]             = "Ctrl-O",
  [ID.CLOSE]            = "Ctrl-W",
  [ID.SAVE]             = "Ctrl-S",
  [ID.SAVEAS]           = "Alt-Ctrl-S",
  [ID.SAVEALL]          = "Shift-Ctrl-S",
  [ID.RECENTFILES]      = "",
  [ID.EXIT]             = "Ctrl-Q",
-- Edit menu
  [ID.CUT]              = "Ctrl-X",
  [ID.COPY]             = "Ctrl-C",
  [ID.PASTE]            = "Ctrl-V",
  [ID.SELECTALL]        = "Ctrl-A",
  [ID.UNDO]             = "Ctrl-Z",
  [ID.REDO]             = "Ctrl-Y",
  [ID.SHOWTOOLTIP]      = "F2",
  [ID.AUTOCOMPLETE]     = "Ctrl-Space",
  [ID.AUTOCOMPLETEENABLE] = "",
  [ID.COMMENT]          = "Ctrl-/",
  ---
  [ID.FOLD]             = "F12",
  [ID.FOLDLINE]         = "Shift-F12",
  ---
  [ID.CLEARDYNAMICWORDS] = "",
  [ID.REINDENT]         = "Ctrl-I",
  ---
  [ID.BOOKMARKTOGGLE]   = "Ctrl-F2",
  [ID.BOOKMARKNEXT]     = "F2",
  [ID.BOOKMARKPREV]     = "Shift-F2",
  ---
  [ID.NAVIGATETOFILE]   = "Ctrl-Shift-R",
  [ID.NAVIGATETOLINE]   = "Ctrl-G",
  [ID.NAVIGATETOSYMBOL] = "Ctrl-Shitf-T",
  [ID.NAVIGATETOMETHOD] = "Ctrl-;",

-- Search menu
  [ID.FIND]             = "Ctrl-F",
  [ID.FINDNEXT]         = "Ctrl-K",
  [ID.FINDPREV]         = "Shift-Ctrl-K",
  [ID.REPLACE]          = "Alt-Ctrl-F",
  [ID.FINDINFILES]      = "Ctrl-H",
  [ID.REPLACEINFILES]   = "Alt-Ctrl-H",
  [ID.SORT]             = "",
--- View menu
  [ID.VIEWFILETREE]     = "Ctrl-Shift-P",
  [ID.VIEWOUTPUT]       = "Ctrl-Shift-O",
  [ID.VIEWWATCHWINDOW]  = "Ctrl-Shift-W",
  [ID.VIEWCALLSTACK]    = "Ctrl-Shift-C",
  [ID.VIEWDEFAULTLAYOUT] = "",
  [ID.VIEWFULLSCREEN]   = "Ctrl-Shift-A",
  [ID.ZOOMRESET]        = "Ctrl-0",
  [ID.ZOOMIN]           = "Ctrl-+",
  [ID.ZOOMOUT]          = "Ctrl--",
-- Project menu
  [ID.RUN]              = "Ctrl-F11",
  [ID.RUNNOW]           = "Ctrl-F6",
  [ID.COMPILE]          = "Ctrl-B",
  [ID.ANALYZE]          = "Shift-F7",
  [ID.STARTDEBUG]       = "F11",
  [ID.ATTACHDEBUG]      = "",
  [ID.DETACHDEBUG]      = "",
  [ID.STOPDEBUG]        = "Shift-F11",
  [ID.STEP]             = "F5",
  [ID.STEPOVER]         = "F6",
  [ID.STEPOUT]          = "F7",
  [ID.RUNTO]            = "F8",
  [ID.TRACE]            = "F10",
  [ID.BREAK]            = "",
  [ID.BREAKPOINTTOGGLE] = "Ctrl-F9",
  [ID.BREAKPOINTNEXT]   = "F9",
  [ID.BREAKPOINTPREV]   = "Shift-F9",
  [ID.CLEAROUTPUT]      = "",
  [ID.INTERPRETER]      = "",
  [ID.PROJECTDIR]       = "",
-- Help menu
  [ID.ABOUT]            = "F1",
-- Watch window menu items
  [ID.ADDWATCH]         = "Ins",
  [ID.EDITWATCH]        = "F2",
  [ID.DELETEWATCH]      = "Del",
-- Editor popup menu items
  [ID.QUICKADDWATCH]    = "",
  [ID.QUICKEVAL]        = "",
-- Filetree popup menu items
  [ID.RENAMEFILE]       = "F2",
  [ID.DELETEFILE]       = "Del",
-- Special global accelerators
  [ID.NOTEBOOKTABNEXT]  = "RawCtrl-PgDn",
  [ID.NOTEBOOKTABPREV]  = "RawCtrl-PgUp",
}

for id, key in pairs(map) do keymap[id] = key end
