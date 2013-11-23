---
layout: vera
title: Download
---

# Download ZeroBrane Studio for Vera v0.39

<ul class="download" id="download-options" style="display: none">
  <li><a class="download mac" href="https://download.zerobrane.com/vera/ZeroBraneStudioVera-0.39-macos.dmg" onclick="var that=this;_gaq.push(['_trackEvent','Download-Vera-macos','ZeroBraneStudioVera-0.39-macos.dmg',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Mac OS X 10.6.8+ (dmg file)</a></li>
  <li><a class="download winzip" href="https://download.zerobrane.com/vera/ZeroBraneStudioVera-0.39-win32.zip" onclick="var that=this;_gaq.push(['_trackEvent','Download-Vera-win32','ZeroBraneStudioVera-0.39-win32.zip',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (zip archive)</a>
      <a class="download winexe" href="https://download.zerobrane.com/vera/ZeroBraneStudioVera-0.39-win32.exe" onclick="var that=this;_gaq.push(['_trackEvent','Download-Vera-win32','ZeroBraneStudioVera-0.39-win32.exe',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Windows 32bit (exe installer)</a></li>
  <li><a class="download linux" href="https://download.zerobrane.com/vera/ZeroBraneStudioVera-0.39-linux.sh" onclick="var that=this;_gaq.push(['_trackEvent','Download-Vera-linux','ZeroBraneStudioVera-0.39-linux.sh',this.href]);setTimeout(function(){location.href=that.href;},200);return false;">
    Linux 32/64bit (shell archive)</a></li>
</ul>

<div class="thank-you" id="key-message" style="display: none">This is your product key: <strong><span id="product-key">&nbsp;</span></strong>. You will need to enter it when you first connect to your device from ZeroBrane Studio for Vera.</div>

<div class="thank-you" id="thank-you">
  Thank you for your interest in ZeroBrane Studio for Vera.
  You do not seem to have a valid product key to download ZeroBrane Studio for Vera.
  You can review <a href="vera.html">information about the product</a> and <a href="vera-documentation.html">the documentation</a>, or <a href="vera-buy.html">buy the product</a>.
</div>

<script>
  var key = location.href.match(/key=(\w+)/);
  if (key) {
    $('#download-options').show();
    $('#thank-you').hide();
    $('#key-message').show();
    $('#product-key').html(key[1]);
    $('a.download').each(function(){
      var href = $(this).attr('href');
      $(this).attr('href', href + (href.match(/\?/) ? String.fromCharCode(38) : '?') + 'key=' + key[1]);
    });
  }
</script>

<div class="separator">&nbsp;</div>

If you are new to the product, you can start by checking
the [Getting Started guide](vera-getting-started.html),
the [tutorial page](vera-tutorials.html),
or by reading the [documentation page](vera-documentation.html)
with links to debugging overview and other useful resources.

## What do I do if I have questions or want to receive product updates?

Several ways to stay in touch are listed [here](community.html). If you have any problems, please [contact us](email:support@zerobrane.com) and we will get it sorted out.
We also read [Vera/MCV user forums](http://forum.micasaverde.com/) and will be happy to answer any questions you may have there.
