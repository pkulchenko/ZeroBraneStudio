---
layout: default
title: Download
---

# Download ZeroBrane Studio v1.30 (Jan 21 2016)

<ul class="download" id="download-options">
  <li><a class="mac" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.30-macos.dmg" onclick="var that=this;_gaq.push(['_trackEvent','Download-macos','ZeroBraneStudioEduPack-1.30-macos.dmg',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Mac OS X 10.6.8+ (dmg file)</a></li>
  <li><a class="winzip" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.30-win32.zip" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-1.30-win32.zip',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (zip archive)</a>
      <a class="winexe" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.30-win32.exe" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-1.30-win32.exe',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (exe installer)</a></li>
  <li><a class="linux" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.30-linux.sh" onclick="var that=this;_gaq.push(['_trackEvent','Download-linux','ZeroBraneStudioEduPack-1.30-linux.sh',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Linux 32/64bit (shell archive)</a></li>
</ul>
<div class="thank-you" id="thank-you">If you paid for ZeroBrane Studio, <strong>thank you for your contribution</strong>. If you have not, please consider <a href="support">supporting the project</a>.</div>
<div class="separator">&nbsp;</div>

## What are the most significant changes in this version?

- Added `markers` panel to show and navigate bookmarks and breakpoints.
- Added saving/restoring bookmarks and breakpoints.
- Added breakpoint prev/next navigation (`Project | Breakpoint` menu).
- Added find/replace in selection to search operations.
- Added printing of editor tabs and Console/Output windows (available on Windows and OSX).
- Added recursive processing of configuration files (using `include` command).
- Added `outline.showcompact` setting to keep outline more compact for large files.
- Added opening multiple files from the `Open` dialog.
- Updated Corona API for v2015.2731 and added handling of type inheritance.
- Updated love2d API for v0.10.0.
- **Changed `Toggle Breakpoint` shortcut** from `F9` to `Ctrl/Cmd-F9`.
- **Removed `Project | Break` shortcut** to avoid conflict with breakpoint navigation.

Full details are in the [changelog](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/CHANGELOG.md).

## Upgrade warning for Mac OSX users.

If you are using Mac OSX version, please make sure to **save your ZeroBrane Studio system settings** (`Edit | Preferences | Settings: System`) before upgrading as those are saved inside the application folder and **will be lost** during the upgrade.
As an alternative, you can **move those system settings to user settings** (`Edit | Preferences | Settings: User`) as those are not affected by the upgrade process.

## What if I have questions or want to receive product updates?

Several ways to stay in touch are listed [here](community).
