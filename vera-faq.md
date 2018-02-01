---
layout: vera
title: Frequently Asked Questions
---

<ul id='toc'>&nbsp;</ul>

## Why do I see so many different names: Vera, Mi Casa Verde, MCV, MiOS?

Vera is the name of the device being sold by Vera Control,
[previously known](http://getvera.com/news-posts/mi-casa-verde-is-now-vera-control-ltd/) as Mi Casa Verde and MCV.
MiOS is a development company for the same software engine that runs on Vera devices.
See [this post](http://forum.micasaverde.com/index.php/topic,3132.msg13469.html#msg13469) for some additional details.

## What Vera devices are supported?

It has been confirmed to work with **VeraPlus**, **VeraEdge**, **VeraLite**, and **Vera 3** devices, but it *may* work with other versions of Vera devices as well.

## How can I check what version of the Vera plugin I have?

You can run `ide.packages.vera.version` in the Local console.

## Debugging doesn't start because of an incorrect IP address. How do I fix that?

Please check the [debugging troubleshooting section](vera-debugging#troubleshooting) for a possible solution.

## I have several Vera devices; how do I select one to work with?

When you start a debugging session and the IDE detects you have multiple devices, you will get a prompt to **select a particular device** you want to work with.
All the subsequent debugging and interactions will be done with that device.
You won't be asked again until you the IDE.

If you only work with one device and prefer not to see the dialog,
you can explicitly configure the IDE to use that device
by adding to the configuration file (`Edit | Preferences | Settings: User`) the following line:
`path.vera = 'ip.of.vera.device'`.

## What firewall ports do I need to open to get debugging to work?

The debugger needs to connect to your device and the device needs to connect to the IDE for debugging to work.
This requires ports `3480` and `80` to be opened on the device and port `8172` to be opened on the computer running the IDE.

## Will the IDE work with my device that is using UI6+?

(**The auto-detection has been improved since v0.27 of the Vera plugin, which is included with v1.40+, so no additional configuration should be needed.**)

The auto-detection step that identifies the address of your device to connect to may not work if your device is using *UI6* or *UI7* firmware.
If the debugging doesn't start or if you get an error message, you may manually configure the IDE to connect to your device
by adding the following line to the configuration file (`Edit | Preferences | Settings: User`):
`path.vera = 'ip.of.vera.device'`.

## How can I step into files loaded with `require`?

If you have files in `/etc/cmh-ludl` folder that you `require` from the main script, you may not be able to "step into" those files as their full path cannot be mapped to the project path known to the IDE.
To make it a relative path, which will avoid this issue, you may want to add `require('lfs').chdir('/etc/cmh-ludl')` to your script before `require` commands.

The file you want to "step into" needs to be in the same project folder as the main script.
To make the file available for debugging, you can either open it in the IDE or configure the IDE to auto-open it for you by adding `editor.autoactivate = true` to the configuration file (`Edit | Preferences | Settings: User`).

## I had to reset the device and the debugging stopped working. What should I do?

(**This is done automatically since v0.14 of the Vera plugin, which is included with v0.50+.**)

If you reset all the files on the device, you probably removed one of the components that is needed for the debugging to work.
To reset the current configuration, which will restore the removed component, you can run the following command in the Local console:
`ide.packages.vera:SetSettings({regkey = ide.packages.vera:GetSettings().regkey})`.

## Where is the configuration file stored?

This is covered in the description of system [configuration](doc-configuration).
