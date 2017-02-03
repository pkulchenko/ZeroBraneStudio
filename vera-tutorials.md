---
layout: vera
title: Tutorials
---

**Tutorial 1: General Vera debugging**
<a class="ytvideo" href="https://www.youtube-nocookie.com/embed/iZV2xMAUNWg?vq=hd720&amp;rel=0"></a>
This tutorial demonstrates how to use [debugging with Vera devices](http://notebook.kulchenko.com/zerobrane/debugging-on-vera-devices-with-zerobrane-studio).
Note that the interpreter has been renamed from `MCV/Vera Lua` to `Vera`.

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
