---
layout: default
title: Download
---

# Download ZeroBrane Studio v1.40 (Aug 26 2016)

<ul class="download" id="download-options">
  <li><a class="mac" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.40-macos.dmg" onclick="var that=this;_gaq.push(['_trackEvent','Download-macos','ZeroBraneStudioEduPack-1.40-macos.dmg',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Mac OS X 10.6.8+ (dmg file)</a></li>
  <li><a class="winzip" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.40-win32.zip" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-1.40-win32.zip',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (zip archive)</a>
      <a class="winexe" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.40-win32.exe" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-1.40-win32.exe',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (exe installer)</a></li>
  <li><a class="linux" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.40-linux.sh" onclick="var that=this;_gaq.push(['_trackEvent','Download-linux','ZeroBraneStudioEduPack-1.40-linux.sh',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Linux 32/64bit (shell archive)</a></li>
</ul>
<div class="thank-you" id="thank-you">If you paid for ZeroBrane Studio, <strong>thank you for your contribution</strong>. If you have not, please consider <a href="support">supporting the project</a>.</div>
<div class="separator">&nbsp;</div>

## What are the most significant changes in this version?

- Added ability to load/save files with invalid UTF-8 encoded characters.
- Added support for IME composition to input Chinese characters.
- Added support for dead key combinations (used on international keyboads).
- Added support for handling Unicode paths and parameters on Windows.
- Added luasec v0.6 (with openssl 1.0.2h).
- Added lpeg v1.0.
- Added lfs v1.6.3.
- Added tracking file system changes in the project tree to auto-refresh it.
- Added opening files on drag-n-drop on dock icon on OSX.
- Added opening files on drag-n-drop on Linux.
- Added refresh of search results from the right-click-on-tab menu.
- Added reverse search on `Shift-Enter`.
- Updated Gideros API for v2016.06.
- Updated Corona API for v2016.2906.
- Updated Love2d API for v0.10.1.

Full details are in the [changelog](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/CHANGELOG.md).

## Upgrade warning for Mac OSX users.

If you are using Mac OSX version, please make sure to **save your ZeroBrane Studio system settings** (`Edit | Preferences | Settings: System`) before upgrading as those are saved inside the application folder and **will be lost** during the upgrade.
As an alternative, you can **move those system settings to user settings** (`Edit | Preferences | Settings: User`) as those are not affected by the upgrade process.

## What if I have questions or want to receive product updates?

Several ways to stay in touch are listed [here](community).
