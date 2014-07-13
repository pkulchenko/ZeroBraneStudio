---
layout: vera
title: Plugin Debugging
---

To demonstrate **plugin debugging** we will first **create a simple virtual device**
and then show how its Lua code can be debugged.

## Creating a virtual device

A device is described in several XML files, each serving a specific purpose:

- **Device** file (usually `D_<device_name>.xml`),
which includes fields like `deviceType`, `friendlyName`, and others,
- **Implementation** file (usually `I_<device_name>.xml`),
which includes `implementation`, `actionList`, and other elements,
and
- **Service** file (usually `S_<device_name>.xml`).
- Other files may be used to store Lua scripts or UI descriptions.
See [plugin creation tutorial](http://wiki.micasaverde.com/index.php/Plugin_Creation_Tutorial) for details.

To **create a virtual device**, follow these steps:

- Open a new editor tab in the IDE, add the following code and
save it in a file named `D_SimplyVirtual.xml` (this is our device description).

{% highlight xml %}
<?xml version="1.0"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <specVersion>
    <major>1</major>
    <minor>0</minor>
  </specVersion>
  <device>
    <deviceType>urn:schemas-zerobrane-com:device:SimplyVirtual1</deviceType>
    <friendlyName>ZeroBrane Virtual Test</friendlyName>
    <manufacturer>ZeroBrane</manufacturer>
    <manufacturerURL>http://studio.zerobrane.com/vera.html</manufacturerURL>
    <implementationList>
      <implementationFile>I_SimplyVirtual.xml</implementationFile>
    </implementationList>
  </device>
</root>
{% endhighlight %}

- Open another tab, add the following code and
save it in a file named `I_SimplyVirtual.xml` (this is our implementation description).

{% highlight xml %}
<?xml version="1.0"?>
<implementation>
  <functions>
  function simply_virtual_startup(lul_device)
    require('mobdebug').start('IDE-ip-address') -- address of computer running IDE
    luup.log("Simply virtual #" .. lul_device)
    require('mobdebug').done()
    return true
  end
  </functions>
  <startup>simply_virtual_startup</startup>
</implementation>
{% endhighlight %}

- Start a debugging session on a Lua script (not an .xml file!) and upload `D_SimplyVirtual.xml`
and `I_SimplyVirtual.xml` files to the Vera device by using right click in the
editor and select `Upload to ...` option from the context menu.
- Now go to your **Vera device web interface** at `http://device-ip-address/cmh/`
and select `Apps`, then `Develop Apps`, and `Create device`.
- Enter the name of the **device file** (`D_SimplyVirtual.xml` in our case) into `Upnp Device Filename` field.
- (optional) You may enter the name of the **implementation file** (`I_SimplyVirtual.xml`),
but since we already added it as `<implementationFile>` to our device file, this is not needed.
- Enter `Simply Virtual` as the **name of the device** in the `Description` field.
- Select `Create device`.

In this example we used `urn:schemas-zerobrane-com:device:SimplyVirtual1` as the device type,
but you can reference one of the existing [device types](http://wiki.micasaverde.com/index.php/Luup_UPNP_Files#Device_Types).

## Debuging device `startup` Lua code

Note that we added `require('mobdebug').start()` and `require('mobdebug').done()` calls
to the function we registered as `startup` function. This function will be
**called when the device is loaded** and will make a debugging call to the IDE
(by using the IP address of the IDE you specified in the `start()` call).

Now if you **restart the luup engine** from the Vera UI (by selecting the `Reload` button)
or from the IDE (by selecting `Restart Luup engine` from the context menu in the editor)
you will see a new tab opened in the IDE with the content of your "startup" function:

{% highlight lua %}
function simply_virtual_startup(lul_device)
  require('mobdebug').start('IDE-ip-address') -- address of computer running IDE
  luup.log("Simply virtual #" .. lul_device)
  require('mobdebug').done()
  return true -- http://wiki.micasaverde.com/index.php/Luup_Declarations#.3Cstartup.3E
end
{% endhighlight %}

You should now see the debugging suspended at the `luup.log` line. You can
then step through the code (and will see the values printed to the
output window), inspect variables, and use other debugging functions.
