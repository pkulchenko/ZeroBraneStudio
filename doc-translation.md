---
layout: default
title: Translation
---

ZeroBrane Studio provides a way to translate its interface elements (menus and captions) and messages to a different language.

## Language file

Create `i18n/*.lua` file for your language-country. The name of the file (`ll-cc.lua`) has two segments:

* ll (mandatory) -- two letter [language code](http://en.wikipedia.org/wiki/List_of_ISO_639-1_codes);
* cc (optional) -- two letter [country code](http://en.wikipedia.org/wiki/ISO_3166-1#Officially_assigned_code_elements).

You can either copy one of the existing files or create a new one with all messages that need to be translated using the following command (let's say your language is "fr"; use `bin\lua` if you are on Windows):

{% highlight sh %}
> bin/lua build/messages.lua >cfg/i18n/fr.lua
{% endhighlight %}

You can also update an existing file to add/modify those messages that have recently changed in the source code (the script will keep all the translated messages intact):

{% highlight sh %}
> bin/lua build/messages.lua cfg/i18n/ru.lua >cfg/i18n/runew.lua
{% endhighlight %}

## Configuring language

You can specify the language for the user interface by adding the following line to one of the [configuration files](doc-configuration.html):

{% highlight lua %}
language = "ru"
{% endhighlight %}

The value of the language setting should match the name of the file (without the extension).

## Translating plural forms

The internalization component also provides a way to handle different forms of words (for example, `1 record` and `0 records`).
This handling requires two steps:

(1) Add a function that returns an index for different values; for example, for English this function looks like the following (the function is always assigned to `[0]` index):

{% highlight lua %}
  [0] = function(c) return c == 1 and 1 or 2 end,
{% endhighlight %}

It returns index 1 for singular and 2 for plural values.
Other languages may require more than two values (for example, Russian requires three).

(2) To translate the value, you can then specify an array of values, instead of a string:

{% highlight lua %}
  ["traced %d instruction"] = {"traced %d instruction", "traced %d instructions"}, -- src\editor\debugger.lua
{% endhighlight %}

The first form will be used when the index returned is 1 and the second one with index 2, resulting in "traced 1 instruction" and "traced 2 instructions" messages.
