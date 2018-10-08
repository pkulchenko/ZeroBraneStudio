---
layout: default
title: Download
---

# Download ZeroBrane Studio v1.80 (Oct 07 2018)

<ul class="download" id="download-options">
  <li><a class="mac" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.80-macos.dmg" onclick="var that=this;_gaq.push(['_trackEvent','Download-macos','ZeroBraneStudioEduPack-1.80-macos.dmg',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    macOS 10.7+ (dmg file)</a></li>
  <li><a class="winzip" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.80-win32.zip" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-1.80-win32.zip',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (zip archive)</a>
      <a class="winexe" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.80-win32.exe" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-1.80-win32.exe',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (exe installer)</a></li>
  <li><a class="linux" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.80-linux.sh" onclick="var that=this;_gaq.push(['_trackEvent','Download-linux','ZeroBraneStudioEduPack-1.80-linux.sh',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Linux 32/64bit (shell archive)</a></li>
</ul>
<div class="thank-you" id="thank-you">If you paid for ZeroBrane Studio, <strong>thank you for your contribution</strong>. If you have not, please consider <a href="support">supporting the project</a>.</div>
<div class="separator">&nbsp;</div>

## What are the most significant changes in this version?

- Added drag-n-drop into project tree to set project or map directories.
- Added lexer detection based on the shebang content for unknown extensions.
- Implemented a large number of improvements and bug fixes.
- Tested debugger and luasocket support with Lua 5.4-work1 version.
- Updated Gideros API for v2018.2.1 and fixed showing methods for Gideros types.
- Updated Love2d API for 0.11.1.
- Upgraded LuaCheck to v0.23.0.

Full details are in the [changelog](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/CHANGELOG.md).

## Upgrade warnings.

If you are using **macOS**, make sure to **save your ZeroBrane Studio system settings** (`Edit | Preferences | Settings: System`) before upgrading as those are saved inside the application folder and **will be lost** during the upgrade.
As an alternative, you can **move those system settings to user settings** (`Edit | Preferences | Settings: User`) as those are not affected by the upgrade process.

If you are using **Windows or Linux**, made any modifications to the files in the distribution,
and plan to install the upgrade into the same location, make sure to **save your changes** before proceeding.

## What if I have questions or want to receive product updates?

Several ways to stay in touch are listed on the [community page](community).
