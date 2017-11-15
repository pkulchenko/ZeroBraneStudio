---
layout: vera
title: Download
---

# Download ZeroBrane Studio for Vera v1.40

<ul class="download" id="download-options" style="display: none">
  <li><a class="download mac" href="https://download.zerobrane.com/vera/ZeroBraneStudioVera-1.40-macos.dmg" onclick="var that=this;_gaq.push(['_trackEvent','Download-Vera-macos','ZeroBraneStudioVera-1.40-macos.dmg',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    macOS 10.7+ (dmg file)</a></li>
  <li><a class="download winzip" href="https://download.zerobrane.com/vera/ZeroBraneStudioVera-1.40-win32.zip" onclick="var that=this;_gaq.push(['_trackEvent','Download-Vera-win32','ZeroBraneStudioVera-1.40-win32.zip',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (zip archive)</a>
      <a class="download winexe" href="https://download.zerobrane.com/vera/ZeroBraneStudioVera-1.40-win32.exe" onclick="var that=this;_gaq.push(['_trackEvent','Download-Vera-win32','ZeroBraneStudioVera-1.40-win32.exe',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (exe installer)</a></li>
  <li><a class="download linux" href="https://download.zerobrane.com/vera/ZeroBraneStudioVera-1.40-linux.sh" onclick="var that=this;_gaq.push(['_trackEvent','Download-Vera-linux','ZeroBraneStudioVera-1.40-linux.sh',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Linux 32/64bit (shell archive)</a></li>
</ul>
<div class="thank-you" id="key-message" style="display: none">This is your product key: <strong><span id="product-key">&nbsp;</span></strong>. You will need to enter it when you first connect to your device from ZeroBrane Studio for Vera.</div>
<div class="thank-you" id="thank-you">
  Thank you for your interest in ZeroBrane Studio for Vera.
  You do not seem to have a valid product key to download ZeroBrane Studio for Vera.
  You can review <a href="vera">information about the product</a> and <a href="vera-documentation">the documentation</a>, or <a href="vera-buy">buy the product</a>.
</div>
<div class="separator">&nbsp;</div>

If you are new to the product, you can start by checking
the [Getting Started guide](vera-getting-started),
the [tutorial page](vera-tutorials),
or by reading the [documentation page](vera-documentation)
with links to debugging overview and other useful resources.

## What are the most significant changes in this version?

- Added fuzzy search with `Go To File`, `Go To Symbol`, `Go To Line`, and `Insert Library Function`.
- Added symbol indexing of project files for project-wide search.
- Added tracking file system changes in the project tree to auto-refresh it.
- Added `markers` panel to show and navigate bookmarks and breakpoints.
- Added saving/restoring bookmarks and breakpoints.
- Added breakpoint prev/next navigation (`Project | Breakpoint` menu).
- Added printing of editor tabs and Console/Output windows (available on Windows and MacOS).
- Added ability to load/save files with invalid UTF-8 encoded characters.
- Added opening files on drag-n-drop on Linux and on dock icon on MacOS.
- Redesigned search functionality; added incremental search and replace-in-files preview.
- Updated Windows launcher to add dpi awareness for high dpi monitors.
- (**Incompatibility**) Changed `Toggle Breakpoint` shortcut from `F9` to `Ctrl/Cmd-F9`.

## Upgrade warnings.

If you are using **macOS**, make sure to **save your ZeroBrane Studio system settings** (`Edit | Preferences | Settings: System`) before upgrading as those are saved inside the application folder and **will be lost** during the upgrade.
As an alternative, you can **move those system settings to user settings** (`Edit | Preferences | Settings: User`) as those are not affected by the upgrade process.

If you are using **Windows or Linux**, made any modifications to the files in the distribution,
and plan to install the upgrade into the same location, make sure to **save your changes** before proceeding.

## What do I do if I have questions or want to receive product updates?

Several ways to stay in touch are listed [here](community). If you have any problems, please [contact us](email:support@zerobrane.com) and we will get it sorted out.
We also read [Vera/MCV user forums](http://forum.micasaverde.com/) and will be happy to answer any questions you may have there.
