---
layout: vera
title: Remote Debugging
---

There are two main ways to debug Lua code running on your Vera device:
in one case the **debugging is initiated from the IDE** (`Project | Start Debugging`),
and in the other case the **debugging is started remotely**, from the Vera device,
when triggered by a scene, plugin, or as part of startup Lua code.

If you are already familiar with [Vera debugging you start from the IDE](vera-debugging.html)
you may notice that it didn't require any modifications to the Lua code itself,
but in the case of a remote request we need to **specify when to start and
stop debugging** and where to send the debugging request.

There are **two methods for initiating a remote debugging session** in your Luup code,
and they both use `require('mobdebug').start()` to start the debugging
and `require('mobdebug').done()` to continue execution of the script without debugging.

Both of these methods are described using [scene debugging](vera-scene-debugging.html) as an example,
but they work in exactly the same way for other types of debugging
([plugins](vera-plugin-debugging.html),
[watch](vera-watch-debugging.html),
[request](vera-request-debugging.html), and others).

## Method 1

This method will require you to specify the **domain name or IP address** of the computer running ZeroBrane Studio as a parameter to the `.start()` function call.
You will do this as follows (using `device-IP-address` as the address in this example):
 
- Copy the following code into a new Automation scene on the Vera under the Luup tab.  You can call the scene whatever you want, but for this example, we will use `ZBSTest`.

{% highlight lua %}
local sunset = luup.sunset()
require('mobdebug').start('device-IP-address')
luup.log(luup.version, sunset)
print(luup.version, os.clock(), 1)
require('mobdebug').done()
{% endhighlight %}

- Run the scene.

When you start this code on your Vera, the code `require('mobdebug').start('device-IP-address')` will initiate a remote debugging session, causing a new window to open on in the IDE showing the code being run on your Vera.
This session will continue until it is terminated or the `.done()` function is called.

You **need to have the debugger server started** in the IDE (if it hasn't been started already) for this method to work.
It will be started automatically if you started debugging at least once, but if it's not started yet, you can do that by going to `Project | Start Debugger Server`
(if the option is unavailable, it means the server is already started).
 
## Method 2

This method is similar to the first method, but you will not specify the IP address of the remote system running the IDE.
Instead, you will **start the debugging session** in the IDE before running the code on your Vera.
 
- Copy the following code into a new Automation scene on the Vera under the Luup tab.
You can call the scene whatever you want, but we will use `ZBSTest`.
If you already have created a scene called `ZBSTest`, then replace the Luup code from before with the code here:

{% highlight lua %}
local sunset = luup.sunset()
require('mobdebug').start() --<-- no IP address
luup.log(luup.version, sunset)
print(luup.version, os.clock(), 1)
require('mobdebug').done()
{% endhighlight %}

- Start debugging in the IDE by selecting `Project | Start Debugging`.
You can run any simple code as the only reason for the step is to "register"
the address of the IDE with the Vera device, so the next time the debugging
is triggered from the device, it is connected to the IDE.

- Run the scene.

This will start a debugging session like before, the only change is you had to "register" the debugging session in order for the debugger to find the system with the IDE supporting the remote debugging and start it.

This method only works until the Luup engine is restarted (and in some cases it can be restarted by the Vera device without warning).
If you can't get the debugging started in the IDE, try running step #2 one more time.

You don't need to worry about leaving `start()` calls in your code as if the debugger can't connect to the IDE,
it will continue execution of the script after a small delay.
