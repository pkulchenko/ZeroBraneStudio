---
layout: default
title: Download
---

# Download ZeroBrane Studio v0.70 (Jun 18 2014)

<ul class="download" id="download-options">
  <li><a class="mac" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-0.70-macos.dmg" onclick="var that=this;_gaq.push(['_trackEvent','Download-macos','ZeroBraneStudioEduPack-0.70-macos.dmg',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Mac OS X 10.6.8+ (dmg file)</a></li>
  <li><a class="winzip" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-0.70-win32.zip" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-0.70-win32.zip',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (zip archive)</a>
      <a class="winexe" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-0.70-win32.exe" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-0.70-win32.exe',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (exe installer)</a></li>
  <li><a class="linux" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-0.70-linux.sh" onclick="var that=this;_gaq.push(['_trackEvent','Download-linux','ZeroBraneStudioEduPack-0.70-linux.sh',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Linux 32/64bit (shell archive)</a></li>
</ul>
<div class="thank-you" id="thank-you">If you paid for ZeroBrane Studio, <strong>thank you for your contribution</strong>. If you have not, please consider <a href="support.html">supporting the project</a>.</div>
<div class="separator">&nbsp;</div>

## What are the most significant changes in this version?

- Added support for [OpenResty/Nginx](http://notebook.kulchenko.com/zerobrane/debugging-openresty-nginx-lua-scripts-with-zerobrane-studio),
[Lapis](http://notebook.kulchenko.com/zerobrane/lapis-debugging-with-zerobrane-studio),
and [moonscript](http://notebook.kulchenko.com/zerobrane/moonscript-debugging-with-zerobrane-studio) debugging.
- Added **re-indentation** of selected fragment or entire file (`Edit | Source | Correct Indentation`).
- Added **line mapping support** for debugging Lua-based languages (e.g. moonscript).
- Added `editor.wrapindentmode` and `editor.wrapstartindent` settings.
- Fixed debugger **compatibility with Lua 5.2**.
- Fixed `F2` shortcut not working in file tree and watch panel.
- Fixed replace-in-files when saving backup copy is turned off.

Full details are in the [changelog](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/CHANGELOG.md).

## Upgrade warning for Mac OSX users.

If you are using Mac OSX version, please make sure to **save your ZeroBrane Studio system settings** (`Edit | Preferences | Settings: System`) before upgrading as those are saved inside the application folder and **will be lost** during the upgrade.
As an alternative, you can **move those system settings to user settings** (`Edit | Preferences | Settings: User`) as those are not affected by the upgrade process.

## What if I have questions or want to receive product updates?

Several ways to stay in touch are listed [here](community.html).
