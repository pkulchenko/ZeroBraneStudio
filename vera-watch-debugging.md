---
layout: vera
title: Watch callback debugging
---

Vera plugins may have **variables** and to monitor
when variable values change you can **register a (callback) function**
using [variable_watch](http://wiki.micasaverde.com/index.php/Luup_Lua_extensions#function:_variable_watch)
Luup function call.

For example, the call `luup.variable_watch("var_watch", "urn:schemas-zerobrane-com:serviceId:SimplyVirtual1", nil, 4)`
registers a callback function `var_watch` that will be
called when any variable (`nil` is passed for a variable name)
for the specified service (`urn:schemas-zerobrane-com:serviceId:SimplyVirtual1`)
and specified device (`4`) changes its value.

The [callback function](http://wiki.micasaverde.com/index.php/Luup_Declarations#.3Cwatch.3E_.28callback.29)
gets device, serviceid, and variable name as its first three parameters
and also gets the old and the new values for the variable.

## Debugging Lua code in a watch (`variable_watch`) callback

ZeroBrane Studio provides [two methods to debug Lua code](vera-remote-debugging.html)
for events triggered from the Vera device:
[scenes](vera-scene-debugging.html),
[plugins](vera-plugin-debugging.html),
[watch](vera-watch-debugging.html),
[request](vera-request-debugging.html),
and [others](vera-documentation.html#development-and-debugging).

In this example we will be using the [simpler method](vera-remote-debugging.html#method-2) that doesn't require
specifying the IP address of the computer that runs ZeroBrane Studio:

- Open a new editor tab in the IDE, add the following code and
save it in a file. In this example I am using device 4 and a
particular serviceId, but you can use whatever device and service you have.

{% highlight lua %}
function var_watch(lul_device, lul_service, lul_variable, lul_value_old, lul_value_new)
  require('mobdebug').start() --<-- start debugging
  print(lul_device, lul_service, lul_variable, lul_value_old, lul_value_new)
  require('mobdebug').done() --<-- stop debugging
end
luup.variable_watch("var_watch", "urn:schemas-zerobrane-com:serviceId:SimplyVirtual1", nil, 4)
{% endhighlight %}

- Start debugging in the IDE by selecting `Project | Start Debugging`
and then run the script using `Project | Continue`.

- Point your browser to
[the URL that sets new variable value](http://device-IP-address:3480/data_request?id=variableset&DeviceNum=4&serviceId=urn:schemas-zerobrane-com:serviceId:SimplyVirtual1&Variable=On&Value=1)
(it is using [variableset Luup request](http://wiki.micasaverde.com/index.php/Luup_Requests#variableset)).
Make sure to change the IP address to the address of your Vera device.
Note that the callback is only triggered when the value changes, so you may want to change the `Value` parameter in the URL.

You should now see the debugging suspended at the "print" line. You can
then step through the code (and will see the values printed to the
output window), inspect variables, and use other debugging functions.
 
This method only works until the Luup engine is restarted (and in some cases it can be restarted by the Vera device without warning).
If you can't get the debugging started in the IDE, try running the second step one more time.
