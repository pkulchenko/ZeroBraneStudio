---
layout: default
title: Payment
---

# Support ZeroBrane Studio. Pay what you want. Download and run in 30 seconds.

<img style="float: right; padding: 10px 40px 10px 0px" src="images/lua-ide-benefits-screenshot.png" />

<form action="https://authorize.payments.amazon.com/pba/paypipeline" method="post">
  <input type="hidden" name="returnUrl" value="http://studio.zerobrane.com/download.html" />
  <input type="hidden" name="processImmediate" value="1" />
  <input type="hidden" name="accessKey" value="11SEM03K88SD016FS1G2" />
  <input type="hidden" name="collectShippingAddress" value="0" />
  <input type="hidden" name="isDonationWidget" value="0" />
  <input type="hidden" name="amazonPaymentsAccountId" value="OJTYLZFEJNKY1APV69AUQEB63URVVVN6GMMA8V" />
  <input type="hidden" name="referenceId" value="ZeroBraneStudio" />
  <input type="hidden" name="cobrandingStyle" value="logo" />
  <input type="hidden" name="immediateReturn" value="1" />
  <input type="hidden" name="description" value="ZeroBrane Studio" />
<table class="payment" id="payment-options">
<tr><td class="amount">  $1</td><td class="description"><input name="amount" id="amount1" value="USD 1" type="radio" /><label for="amount1">I will give you my entire weekly allowance</label></td></tr>
<tr><td class="amount">  $5</td><td class="description"><input name="amount" id="amount5" value="USD 5" type="radio" /><label for="amount5">This is better than chocolate Mocha</label></td></tr>
<tr><td class="amount"> $10</td><td class="description"><input name="amount" id="amount10" value="USD 10" type="radio" /><label for="amount10">I will pay more when my game sells</label></td></tr>
<tr><td class="amount"> $24</td><td class="description"><input name="amount" id="amount24" checked="checked" value="USD 24" type="radio" /><label for="amount24"><strong>Exactly what I was looking for</strong></label></td></tr>
<tr><td class="amount"> $50</td><td class="description"><input name="amount" id="amount50" value="USD 50" type="radio" /><label for="amount50">I feel lucky and generous today</label></td></tr>
<tr><td class="amount">$100</td><td class="description"><input name="amount" id="amount100" value="USD 100" type="radio" /><label for="amount100">Take my money; just keep working on it</label></td></tr>
<tr><td class="amount">$500</td><td class="description"><input name="amount" id="amount500" value="USD 500" type="radio" /><label for="amount500">I will email you the feature I want to have</label></td></tr>
</table>
<div id="next-step">
  <input class="payment-button" type="image" src="http://g-ecx.images-amazon.com/images/G/01/asp/beige_small_paynow_withlogo_whitebg.gif" border="0" />
  <a href="download.html?not-this-time" id="no-payment-text">Take me to the download page this time &#187;</a>
</div>
</form>

<div class="separator">&nbsp;</div>

## What do I get?
You get packages for three platforms:
**Windows** XP or later (zip or self-extracting archive), **Mac OS X** 10.6.8+ (dmg file), or **Linux** (shell archive for Debian, Ubuntu, and Mint distributions).

## How much do I pay?
This is completely up to you. How much do you value being able to find
an issue with your code in 5 minutes instead of 15? Get your mobile 
application out faster? Have fun helping your kids or friends learn
programming using Lua and examples included with the IDE?

## Isn't this an open source project?
Yes and we make it easy for you to get code from GitHub and
run it from a cloned copy or an archive. We would still **appreciate your 
payment in support of this project.** If you decide not to provide financial
support this time, please consider spreading the word, contributing code,
helping with [fixes](https://github.com/pkulchenko/ZeroBraneStudio/issues)
or [documentation](https://github.com/pkulchenko/ZeroBraneStudio/tree/gh-pages),
and answering questions other users may have.
