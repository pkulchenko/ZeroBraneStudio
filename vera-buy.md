---
layout: vera
title: Buy
---

# Buy ZeroBrane Studio for Vera. Download and run in 60 seconds.

<form action="#" id="PayForm" name="PayForm">
 <div id="pricing-table">&nbsp;</div>
 <div id="next-step">
  <span class="gh-btn"><a class="button" id="pay-with-card-button" href="#">Pay with Card</a></span>
  <span class="pay-message">By buying <em>ZeroBrane Studio for Vera</em> you are agreeing to this <a href="vera-license-agreement.html">License Agreement</a>.</span>
 </div>
</form>

<script>
$(document).ready(function(){
  $('a#pay-with-card-button').click(function(e){
    var selected = $('input[name=plan]:checked');
    var url = 'https://zerobrane.com/pay/vera/'+selected.attr('id');
    modal.open({content: "<iframe src='"+url+"' style='width: 430px; height: 350px' frameborder='0' scrolling='no'></iframe>"});
    e.preventDefault();
  });
});
</script>

All options provide **immediate access** to the product and include **personal service** from the ZeroBrane team.

<div class="separator">&nbsp;</div>

## What do I get?
You get packages for three platforms:
**Windows** XP or later (zip or self-extracting archive), **Mac OS X** 10.6.8+ (dmg file), or **Linux** (shell archive for Debian, Ubuntu, Xubuntu, Mint, ArchLinux, Fedora, Gentoo and other distributions).

You also get a product key that allows you to use _ZeroBrane Studio for Vera_ from up to three computers.

## What Vera devices are supported?

It has been tested with **Vera 3** and **VeraLite** devices, but it *may* work with other versions of Vera devices as well.
You should feel free to buy and try if it works for you; if it doesn't, we can either try to make it work or refund your payment.

## What does non-commercial mean?

**Non-commercial** means the use of _ZeroBrane Studio for Vera_ in the manner that is **not** intended for or directed toward commercial advantage or private monetary compensation,
and is limited to **individual users who use the product for personal purposes** (for example, hobby, learning, or entertainment).

## Do you offer refunds?

Yes. We offer a **30 day unconditional money back guarantee**.
If you are not happy with the product, send us an email at [support@zerobrane.com](mailto:support@zerobrane.com) with your email address and purchase identification and we will refund what you paid for it.

If you are **happy with the product**, [send us an email](mailto:support@zerobrane.com) or spread the word as we love to hear that!

## Do you offer a trial version?

No, but we offer a 30-day refund policy.
You can review the [documentation](vera-documentation.html) and [tutorial](vera-tutorials.html) pages to see if the product works for you.
You can also download and use [ZeroBrane Studio](http://studio.zerobrane.com) before making your decision to buy _ZeroBrane Studio for Vera_.

## What if I need to change my Vera device? Will the product key still work?

Yes, you can change your Vera device two times (from a device A to device B and then to device C).
To continue using the product, you will need to request an extension or a new key by sending an email to [support@zerobrane.com](mailto:support@zerobrane.com).

## I have several Vera devices; how will this work in my case?

When you start a debugging session and the IDE detects you have multiple devices, you will get a prompt to **select a particular device** you want to work with.
All the subsequent debugging and interactions will be done with that device.
You won't be asked again until you restart ZeroBrane Studio.

If you need to **work with several devices**, make sure you select one of subscription plans that give you access to multiple devices (depending on the plan).

## Can I cancel my subscription?

You can cancel your subscription at any time with no questions asked by sending us an email to [support@zerobrane.com](mailto:support@zerobrane.com).

## This looks great, but I still have a question or two. How do I get more information?

You can review the [documentation](documentation.html) and [tutorial](tutorials.html) pages to see if it is answered there.
If you still have questions or need some special arrangement, you may contact us at [support@zerobrane.com](mailto:support@zerobrane.com).
We also read [Vera/MCV user forums](http://forum.micasaverde.com/) and will be happy to answer any questions you may have there.
