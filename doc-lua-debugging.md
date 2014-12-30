---
layout: default
title: Lua Debugging
---

<ul id='toc'>&nbsp;</ul>

## General debugging

<img style="background:url(images/debugging.png) -234px -234px" src="images/t.gif" class="inline"/>

The debugger allows to execute Lua scripts and applications step by step, pause them, inspect variables, evaluate expressions, make changes to variables, and then continue execution.
To **start debugging** go to `Project | Start Debugging`.
Depending on your interpreter configuration, the debugger may stop your program on the first instruction (this is a default for most interpreters) or may execute it immediately (as configured for `Moai` and `Corona` interpreters).

When your program is running, you can **pause** it by going to `Project | Break`, which will stop your program at the next lua command executed.

When the debugger is stopped, you can **set/remove breakpoints** (using `Project | Toggle Breakpoint`),
**step through the code** (using `Step Into`, `Step Over`, and `Step Out` commands),
**inspect variables** using the Watch window (`View | Watch Window`),
**view the call stack** using the Stack window (`View | Stack Window`),
**run Lua commands** in the [console](#console-window),
and **continue** execution of your program (using `Project | Continue`).

## Live coding

**Live coding** (also known as **Running as Scratchpad**) is a special debugging mode that allows for the changes you make in the editor to be immediately reflected in your application.
To **enable** this mode go to `Project | Run as Scratchpad` (when it is available) and your program will be started as during debugging.
You will continue to have access to the editor tab from which the scratchpad has been started and all the changes you make will be seen in your application.

In addition to regular editing, you can also mouse over a number (all the number in your script will be underlined as you can see in the screenshot on the right) and drag a virtual sliders left or right to change the value of that number.
If you make an error (whether a compile or run-time), it will be reported in the Output window.

To **exit** the scratchpad mode you can close the application, go to `Project | Stop Process`, or go to `Project | Run as Scratchpad`.

Note that this functionality is highly interpreter dependent and some interpreters may not provide it at all (for example, `Corona`) and some may provide in a way that doesn't restart the entire application (for example, `Love2d`, `Moai`, or `Gideros` interpreters).
Your code may also need to be written in a way that accomodates requirements of those engines. Please consult [live coding tutorials](documentation#live-coding) for details.

## Console window

<img style="background:url(images/unicode-console.png) -9px -499px" src="images/t.gif" class="inline"/>

The **Console window** allows to run Lua code fragments and calculate values of Lua expressions.
It will switch automatically between a **local console** that gives you access to the Lua interpreter that runs the IDE
and a **remote console** that allows you to execute code fragments and change variable values in your application when it is stopped in the debugger.

You can execute any expression in the console and the result will be pretty printed for you. You can also do `=expression` to pretty print the results in the block form.

## Stack window

<img style="background:url(images/debugging.png) -674px -133px" src="images/t.gif" class="inline"/>

The Stack window provides not only the call stack with function names, but also presents all local variables and upvalues for each of the stack frames.
You can even drill down to get values of individual elements in tables.

## Watch window

<img style="background:url(images/debugging.png) -674px -360px" src="images/t.gif" class="inline"/>

The Watch view provides a convenient way to evaluate variables and expressions after every step of the debugger.
You can also drill down to get values of individual elements in tables.

In addition to viewing the values that variables or expressions are evaluated to, you may also **change the values of those variables or expressions** and those changes will be reflected in the current stack frame of the application.
For example, if `tbl` is a table with three values (`{'a', 'b', 'c'}`), you can expand the table, right click on the second element, and select `Edit Value`.
You can then edit the value of the second element.
The result is equivalent to executing `tbl[2] = "new value"` in the Console window, but provides an easy way to update the value without retyping the expression.

## The tooltip

In addition to being able to use the Console or the Watch window to see the values of variables and expressions,
you can also mouse over a variable (or select an expression and mouse over it) during debugging to see its value.

The value is shown for the simplest expression the cursor is over; for example, if the cursor is over 'a' in `foo.bar`, you will see the value for `foo.bar`, but if the cursor is over 'o' in the same expression, you'll see the value of `foo` instead.
You can always select the expression to be shown in the tooltip to avoid ambiguity.

## How debugging works

Even though there are different ways to start debugging in the IDE, all of them work the same way:
the debugger component is loaded into the application being debugged and establishes a socket connection to the IDE.
The IDE then accepts user commands (step, set breakpoint, remove breakpoint, evaluate an expression, and so on) and sends those commands to the debugger component in the application and receives the results back (if any).

When the application is suspended because of a `step` command, `break` command, or a breakpoint, the IDE will attempt to find and activate a source file where the application is suspended.
If the file is already opened in the IDE, it will be activated with the current line marker (green arrow by default) pointing to the location of the statement executed next.
If the file is not opened in the IDE, but the IDE is configured to auto-activate files (`editor.autoactivate = true`), the file will be loaded into the IDE.

See [remote debugging section](doc-remote-debugging) of the documentation for details on how to configure and initiate debugging from your application.

## Turning debugging `off` and `on`

You may notice that in some cases the application you are debugging runs much slower than without debugging; when you run it without the debugger the speed is likely to be three to ten times faster.
This may be okay for many situations, but in some cases when the application is complex, things may get slow.

The debugger provides two methods that allow you to temporarily turn the debugging on and off. If you turn it on/off right around where the changes need to be applied, you can get almost the same performance you see without the debugger.

For example, let's say you have a `bodyCollision` function where you check for collisions and you want to break when a body collision is detected.
You can turn the debugging off (`require("mobdebug").off()`) right after starting debugging (using `require("mobdebug").start()`) and then turn it on and off around the section you are interested in:

{% highlight lua %}
function bodyCollision(event)
  local target = event.target
  if event.phase == "began" then
    require("mobdebug").on() --<-- turn the debugger on
    -- do whatever else needed for collision handling
    require("mobdebug").off() --<-- turn the debugger off
  end
end
{% endhighlight %}

If you set a breakpoint somewhere between `on()` and `off()` calls, it will fire as expected.
The rest of the application will be running with a "normal" speed in this case (you can see the difference if you remove all `off()` calls).

## Coroutine debugging

The debugging of coroutines is disabled by default.
To enable debugging in coroutines, including stepping into `resume`/`yield` calls and triggering of breakpoints, you may do one of the following:

- add `require('mobdebug').on()` call to that coroutine, which will enable debugging for that particular coroutine, or
- add `require('mobdebug').coro()` call to your script, which will enable debugging for all coroutines created using `coroutine.create` later in the script.

If you enable coroutine debugging using `require('mobdebug').coro()`, this will **not affect coroutines created using C API** or Lua code wrapped into `coroutine.wrap`.
You can still debug those fragments after adding `require('mobdebug').on()` to the coroutine code. 
