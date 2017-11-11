---
layout: default
title: Download
---

# Download ZeroBrane Studio v1.70 (Nov 11 2017)

<ul class="download" id="download-options">
  <li><a class="mac" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.70-macos.dmg" onclick="var that=this;_gaq.push(['_trackEvent','Download-macos','ZeroBraneStudioEduPack-1.70-macos.dmg',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Mac OS X 10.6.8+ (dmg file)</a></li>
  <li><a class="winzip" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.70-win32.zip" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-1.70-win32.zip',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (zip archive)</a>
      <a class="winexe" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.70-win32.exe" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-1.70-win32.exe',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (exe installer)</a></li>
  <li><a class="linux" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-1.70-linux.sh" onclick="var that=this;_gaq.push(['_trackEvent','Download-linux','ZeroBraneStudioEduPack-1.70-linux.sh',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Linux 32/64bit (shell archive)</a></li>
</ul>
<div class="thank-you" id="thank-you">If you paid for ZeroBrane Studio, <strong>thank you for your contribution</strong>. If you have not, please consider <a href="support">supporting the project</a>.</div>
<div class="separator">&nbsp;</div>

## What are the most significant changes in this version?

- Added support for using **luacheck**.
- Added progress bar indicator for commandbar processing.
- Added cache for files in the commandbar.
- Added encoding output based on `codepage` setting.
- Added support for **ansi escapes** to color text in Output window.
- Improved UI responsiveness during find-in-files search.
- Updated commandbar to improve prefiltering performance on search through large file sets.
- Updated moai API to community version 1.8 RC.
- Fixed multiple instance launch on **MacOS High Sierra**.
- Fixed lexlpeg styling on Linux; **110+ languages and formats** are now styled on all platforms.
- Fixed debugging for Lua 5.2/5.3 when `LUA_PATH_5_2`/`5_3` env variable is set.

Full details are in the [changelog](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/CHANGELOG.md).

## Upgrade warnings.

If you are using **MacOS**, make sure to **save your ZeroBrane Studio system settings** (`Edit | Preferences | Settings: System`) before upgrading as those are saved inside the application folder and **will be lost** during the upgrade.
As an alternative, you can **move those system settings to user settings** (`Edit | Preferences | Settings: User`) as those are not affected by the upgrade process.

If you are using **Windows or Linux**, made any modifications to the files in the distribution,
and plan to install the upgrade into the same location, make sure to **save your changes** before proceeding.

## What if I have questions or want to receive product updates?

Several ways to stay in touch are listed on the [community page](community).
