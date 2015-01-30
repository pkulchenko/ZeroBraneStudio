---
layout: default
title: Download
---

# Download ZeroBrane Studio v0.95 (Jan 30 2015)

<ul class="download" id="download-options">
  <li><a class="mac" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-0.95-macos.dmg" onclick="var that=this;_gaq.push(['_trackEvent','Download-macos','ZeroBraneStudioEduPack-0.95-macos.dmg',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Mac OS X 10.6.8+ (dmg file)</a></li>
  <li><a class="winzip" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-0.95-win32.zip" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-0.95-win32.zip',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (zip archive)</a>
      <a class="winexe" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-0.95-win32.exe" onclick="var that=this;_gaq.push(['_trackEvent','Download-win32','ZeroBraneStudioEduPack-0.95-win32.exe',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (exe installer)</a></li>
  <li><a class="linux" href="https://download.zerobrane.com/ZeroBraneStudioEduPack-0.95-linux.sh" onclick="var that=this;_gaq.push(['_trackEvent','Download-linux','ZeroBraneStudioEduPack-0.95-linux.sh',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Linux 32/64bit (shell archive)</a></li>
</ul>
<div class="thank-you" id="thank-you">If you paid for ZeroBrane Studio, <strong>thank you for your contribution</strong>. If you have not, please consider <a href="support.html">supporting the project</a>.</div>
<div class="separator">&nbsp;</div>

## What are the most significant changes in this version?

- Added fuzzy search with `Go To File`, `Go To Symbol`, `Go To Line`, and `Insert Library Function` (available through `Search | Navigate` menu).
- Added auto-complete support for LDoc '@tparam' and '@param[type=...]'.
- Added armhf architecture support (thanks to Ard van Breemen).
- Updated static analyzer and internal parser to support `goto`/labels and bitops for Lua 5.2/5.3.
- Updated Mobdebug to improve Lua 5.3 compatibility (thanks to Andrew Starks).
- Update API descriptions with functions new in Lua 5.3.

Full details are in the [changelog](https://github.com/pkulchenko/ZeroBraneStudio/blob/master/CHANGELOG.md).

## Upgrade warning for Mac OSX users.

If you are using Mac OSX version, please make sure to **save your ZeroBrane Studio system settings** (`Edit | Preferences | Settings: System`) before upgrading as those are saved inside the application folder and **will be lost** during the upgrade.
As an alternative, you can **move those system settings to user settings** (`Edit | Preferences | Settings: User`) as those are not affected by the upgrade process.

## What if I have questions or want to receive product updates?

Several ways to stay in touch are listed [here](community.html).
