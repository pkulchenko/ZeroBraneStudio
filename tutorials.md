---
layout: default
title: Tutorials
---

**Tutorial 1: Live coding in Lua**
<a class="ytvideo" href="https://www.youtube-nocookie.com/embed/rDKzl7Nrq94?vq=hd720&amp;rel=0"></a>
[Live coding in Lua](http://notebook.kulchenko.com/zerobrane/live-coding-in-lua-bret-victor-style)
demonstrates how to use _live coding_ with different scripts running in ZeroBrane Studio.

**Tutorial 2: LÖVE debugging**
<a class="ytvideo" href="https://www.youtube-nocookie.com/embed/Gi6rrwWvMFE?vq=hd720&amp;rel=0"></a>
[LÖVE debugging](http://notebook.kulchenko.com/zerobrane/love2d-debugging)
demonstrates _debugging and auto-complete_ support for [LÖVE game engine](http://love2d.org/).

**Tutorial 3: Live coding with LÖVE**
<a class="ytvideo" href="https://www.youtube-nocookie.com/embed/odGXWCa2oAY?vq=hd720&amp;rel=0"></a>
[Live coding with Löve](http://notebook.kulchenko.com/zerobrane/live-coding-with-love) tutorial
demonstrates how to use _live coding to change game parameters_ using [LÖVE](http://love2d.org/)
scripts running in ZeroBrane Studio.

**Tutorial 4: Gideros live coding**
<a class="ytvideo" href="https://www.youtube-nocookie.com/embed/wPYvJxFxMkM?vq=hd720&amp;rel=0"></a>
[Gideros live coding](http://notebook.kulchenko.com/zerobrane/gideros-live-coding-with-zerobrane-studio-ide) demonstration
by [Andy Bower](http://bowerhaus.eu/blog/files/live_coding.html) shows how to 
use _live coding_ (Run as Scratchpad) with [Gideros SDK](http://giderosmobile.com/) to develop an 
application running on an actual device in real-time.

**Tutorial 5: Moai debugging**
<a class="ytvideo" href="https://www.youtube-nocookie.com/embed/rDKzl7Nrq94?vq=hd720&amp;rel=0"></a>
[Moai debugging](http://notebook.kulchenko.com/zerobrane/moai-debugging-with-zerobrane-studio) tutorial
demonstrates how to configure and use debugging with [Moai 2D game engine](http://getmoai.com/)
by showing _Stack and Watch views, remote console, updating variables,
breakpoints, and stepping through the code_.

**Tutorial 6: Gideros debugging**
<a class="ytvideo" href="https://www.youtube-nocookie.com/embed/GIipyzSpSr0?vq=hd720&amp;rel=0"></a>
[Gideros debugging](http://notebook.kulchenko.com/zerobrane/gideros-debugging-with-zerobrane-studio-ide) tutorial
demonstrates how to configure and use debugging with [Gideros SDK](http://giderosmobile.com/)
by showing _Watch view, remote console, updating variables,
breakpoints, and stepping through the code_.

**Tutorial 7: Corona debugging**
<a class="ytvideo" href="https://www.youtube-nocookie.com/embed/0D6lWfdz9Gk?vq=hd720&amp;rel=0"></a>
[Corona debugging and live coding](http://notebook.kulchenko.com/zerobrane/debugging-and-live-coding-with-corona-sdk-applications-and-zerobrane-studio) tutorial
demonstrates how to use _debugging_ and _live coding_ with [Corona SDK](http://www.coronalabs.com/products/corona-sdk/)
by showing _Stack view, updating variables, remote console, 
breakpoints,_ and using _live coding to change game parameters_.

**Tutorial 8: Marmalade debugging**
<a class="ytvideo" href="https://www.youtube-nocookie.com/embed/vt1uXuB02nI?vq=hd720&amp;rel=0"></a>
[Marmalade Quick debugging](http://notebook.kulchenko.com/zerobrane/marmalade-quick-debugging-with-zerobrane-studio) tutorial
demonstrates how to configure and use _debugging_ with [Marmalade Quick engine](http://www.madewithmarmalade.com/)
by showing _Stack view, remote console, updating variables,
breakpoints, and stepping through the code_.

<script type="text/javascript">//<![CDATA[
function getElementsByClassName(node,classname) {
  if (node.getElementsByClassName) { // use native implementation if available
    return node.getElementsByClassName(classname);
  } else {
    return (function getElementsByClass(searchClass,node) {
        if ( node == null )
          node = document;
        var classElements = [],
            els = node.getElementsByTagName("*"),
            elsLen = els.length,
            pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)"), i, j;

        for (i = 0, j = 0; i < elsLen; i++) {
          if ( pattern.test(els[i].className) ) {
              classElements[j] = els[i];
              j++;
          }
        }
        return classElements;
    })(classname, node);
  }
}

var elements = getElementsByClassName(document, "ytvideo");
for (var i = elements.length-1; i >= 0; i--) {
  var e = elements[i];
  var frame = document.createElement("iframe");
  frame.width = 512; frame.height = 362; frame.src = e.href;
  e.parentNode.replaceChild(frame, e);
}

//]]></script>
