---
layout: vera
title: Debugging
---

_ZeroBrane Studio for Vera_ integrates a powerful debugger that supports
**debugging of Lua code** running on your Vera device. This simplifies
writing and debugging of any Luup code you may need to work with.

1. Start _ZeroBrane Studio for Vera_, select `Vera` interpreter if it's not already selected (`Project | Lua Interpreter`),
open new file (`File | New`), and copy the following script:

        local sunset = luup.sunset()
        luup.log(luup.version, sunset)
        print("Printed from Vera device", sunset, luup.devices[1].category_num)
        print(luup.version, os.clock(), 1)

2. Save the script to a folder of your choice and set that folder as
the current project folder (`Project | Project Directory | Set From Current File`).

3. Start debugging (`Project | Start Debugging`).

If you run this for the **first time** you will be asked for a product key;
use the key you received after your purchase.
If you are **connected to multiple devices**, you will see a prompt with
the list of devices that have been detected and can select one device you
want to work with. The name of the device will be stored and used
for subsequent debugging requests (until you restart the IDE).

When the debugger is stopped, you can **set/remove breakpoints** (using `Project | Toggle Breakpoint`),
**step through the code** (using `Step Into`, `Step Over`, and `Step Out` commands),
**inspect variables** using the Watch window (`View | Watch Window`),
**view the call stack** using the Stack window (`View | Stack Window`),
**run Lua commands** in the Remote console,
and **continue** execution of your program (using `Project | Continue`).

You can use the [Watch window](vera-getting-started#watch-window) to **monitor variable values and expression results**
or quickly check **the value of a variable or expression** in a [tooltip](#tooltip).
The [Stack window](vera-getting-started#stack-window) allows you to **see the stack trace with local variables and upvalues** shown for each stack frame.

Using remote console you can **run arbitrary Lua expressions**, including Luup calls, that will be executed in the context of your (suspended) script.
For example, if the value of a variable `count` in the script is `10` and you execute `count = count + 1`, then the variable value will become `11`, as you'd expect.

In addition to running/debugging Lua code from ZeroBrane Studio, you can
also start the debugging from the device (which may be triggered by Lua code
included in scenes or plugins). See the [remote debugging](vera-remote-debugging.html)
section for details on how this can be done.

## Vera functions

<img style="background:url(images/vera-debugging.png) -345px -375px" src="images/t.gif" class="inline"/>

Several Vera-specific functions are available from the right click menu in the editor:

1. `Upload to '/etc/cmh-ludl/...'` allows you to upload the current file to the device.
2. `Download '/var/log/cmh/LuaUPnP.log'` retrieves the log file from the device and opens it in a new editor window.
3. `Restart Luup engine` restarts the Luup engine on the device (you will see the progress and completion status in the Output window).

The first two functions are only available during the debugging.
You can also **upload** files from the Project tree by also using the right click menu.

## Print redirect

The results of `print` commands executed during debugging are "redirected"
to the Output window in the IDE, which provides a convenient way of seeing
the results without going through the logs.

The values you print are also pretty-printed, so you can do
`print(mytable)` and the table content will be printed as `{a = 1, b = 2}`
instead of `table: address`.

## Troubleshooting

* **Debugging doesn't start becase the IDE address is detected incorrectly.**
When you start debugging, the IDE may display the message with the server address: `Using 'x.x.x.x' as the debugger server address.` (You'll see the message if you are using `vera` plugin v0.12+).
If the address shown is not correct, or can't be reached from the Vera device, the debugging is not going to work.
To **set the correct address**, you can specify `debugger.hostname = 'correct.IPaddress.or.hostname'` in the [configuration](doc-configuration.html) file and restart the IDE.

* **Debugging doesn't start because the address of the device or the IDE is detected incorrectly.**
When you start debugging, the IDE will try to detect the address of the device and will use the IP address of the computer to configure the debugger.
If you are **running on VPN**, it may cause the IDE to incorrectly detect the address of the device or the computer running the IDE.
You may want to disable the VPN (and run `ipconfig /renew`) or configure `debugger.hostname` as described above to see if this resolves the issue.

* **Debugging doesn't start because of a conflict with existing Lua installation (OSX).**
In some rare cases the debugging doesn't start as the system fails to load a dynamic library that has incorrect architecture.
You may see a message `dyld: Library not loaded: liblua.dylib`
or `Reason: no suitable image found. Did find: /usr/local/lib/liblua.dylib: mach-o, but wrong architecture`
in the Output window.
You may want to **remove the Lua installation** to resolve the conflict.

* **Debugging aborted prematurely.**
It has been reported that in some rare cases a debugging session may be
aborted prematurely. If this happens, try to reduce the amount of logging
you do (using `luup.log` command).
