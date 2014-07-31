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

## How can I check what version of the Vera plugin I have?

You can run `ide.packages.vera.version` in the Local console.

## Debugging doesn't start because of an incorrect IP address. How do I fix that?

Please check the [debugging troubleshooting section](vera-debugging.html#troubleshooting) for a possible solution.

## I have several Vera devices; how do I select one to work with?

When you start a debugging session and the IDE detects you have multiple devices, you will get a prompt to **select a particular device** you want to work with.
All the subsequent debugging and interactions will be done with that device.
You won't be asked again until you restart ZeroBrane Studio.

If you only work with one device and prefer not to see the dialog,
you can explicitly configure ZBS to use that device
by adding to the configuration file (`Edit | Preferences | Settings: User`) the following line:
`path.vera = 'ip.of.vera.device'`.

## I had to reset the device and the debugging stopped working. What should I do?

(This is done automatically since v0.14 of the Vera plugin, which is included with v0.50+)
If you reset all the files on the device, you probably removed one of the components that is needed for the debugging to work.
To reset the current configuration, which will restore the removed component, you can run the following command in the Local console:
`ide.packages.vera:SetSettings({regkey = ide.packages.vera:GetSettings().regkey})`.

## Where is the configuration file stored?

This is covered in the description of system [configuration](doc-configuration.html).
