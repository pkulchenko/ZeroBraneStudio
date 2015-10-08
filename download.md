---
layout: default
title: Download
---

# Download ZeroBrane Studio v1.20 (Oct 08 2015)

<ul class="download" id="download-options">
  <li><a class="mac" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.20-macos.dmg" onclick="var that=this;_gaq.push(['_trackEvent','Download-macos','ZeroBraneStudioEduPack-1.20-macos.dmg',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Mac OS X 10.6.8+ (dmg file)</a></li>
  <li><a class="winzip" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.20-win32.zip" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-1.20-win32.zip',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (zip archive)</a>
      <a class="winexe" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.20-win32.exe" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-1.20-win32.exe',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (exe installer)</a></li>
  <li><a class="linux" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.20-linux.sh" onclick="var that=this;_gaq.push(['_trackEvent','Download-linux','ZeroBraneStudioEduPack-1.20-linux.sh',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Linux 32/64bit (shell archive)</a></li>
</ul>
<div class="thank-you" id="thank-you">If you paid for ZeroBrane Studio, <strong>thank you for your contribution</strong>. If you have not, please consider <a href="support">supporting the project</a>.</div>
<div class="separator">&nbsp;</div>

## What are the most significant changes in this version?

- Added indexing of project files for project-wide symbol search.
- Added support for `file@symbol` fuzzy search.
- Improved auto-complete order of results and suggestions for case-sensitive matches.
- Improved application performance and memory usage.
- Improved memory handling for large files.
- Updated Windows launcher to add dpi awareness for high dpi monitors.
- Upgraded Lua 5.3 interpreter to 5.3.1.
- Fixed a memory leak after a search panel is opened.
- Fixed an occasional crash from the filetree on Linux.

Full details are in the [changelog](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/CHANGELOG.md).

## Upgrade warning for Mac OSX users.

If you are using Mac OSX version, please make sure to **save your ZeroBrane Studio system settings** (`Edit | Preferences | Settings: System`) before upgrading as those are saved inside the application folder and **will be lost** during the upgrade.
As an alternative, you can **move those system settings to user settings** (`Edit | Preferences | Settings: User`) as those are not affected by the upgrade process.

## What if I have questions or want to receive product updates?

Several ways to stay in touch are listed [here](community).
