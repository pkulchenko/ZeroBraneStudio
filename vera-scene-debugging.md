---
layout: vera
title: Scene Debugging
---

Before describing how you can debug Lua code **triggered by a scene**,
let's first review how you can add this code to a scene.

## Adding Lua code to a scene

To **add some Lua code to a scene**, go to
your **Vera device web interface** at `http://device-ip-address/cmh/`
and use the following steps:

- Select `Automation`, then `New Scene`.
- Change `New scene` name to `ZBSTest`.
- Select `LUUP`.
- Copy the Lua code into the `Code` box.
- Select `Save lua` button under the box.
- Confirm `Close` on `Lua code updated.` message.
- Select `Confirm changes` and then `SAVE` message to save changes.

If you need to **edit code for an existing scene**, then instead of using
`New Scene` you can mouse over the title of an existing scene and click
on a "wrench" icon that will appear. You can then select `LUUP` and follow
the same process as described above.

## Debugging Lua code in a scene

ZeroBrane Studio provides [two methods to debug Lua code](vera-remote-debugging)
for events triggered from the Vera device:
[scenes](vera-scene-debugging),
[plugins](vera-plugin-debugging),
[watch](vera-watch-debugging),
[request](vera-request-debugging),
and [others](vera-documentation#development-and-debugging).

In this example we will be using the [simpler method](vera-remote-debugging#method-2) that doesn't require
specifying the IP address of the computer that runs ZeroBrane Studio:

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

You should now see the debugging suspended at the `luup.log` line. You can
then step through the code (and will see the values printed to the
output window), inspect variables, and use other debugging functions.
 
This method only works until the Luup engine is restarted (and in some cases it can be restarted by the Vera device without warning).
If you can't get the debugging started in the IDE, try running the second step one more time.
