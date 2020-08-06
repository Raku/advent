# RFC 64: New pragma 'scope' to change Perl's default scoping

Let's talk about a fun RFC that mostly did *not* make its way into current day Raku, nor is it planned for later implementation.

This is about [RFC 64](https://raku.org/archive/rfc/64.html). Let me quote the abstract:

> Historically, Perl has had the default "everything's global" scope. This means that you must explicitly define every variable with my, our, or its absolute package to get better scoping. You can 'use strict' to force this behavior, but this makes easy things harder, and doesn't fix the actual problem.
>
> Those who don't learn from history are doomed to repeat it. Let's fix this.

It seems `use strict;` simply has won, despite Nathan Wiger's dislike for it.

Raku enables it by default, even for one-liners with the `-e` option, Perl 5 enables it with `use 5.012` and later versions, and these days there's even talk to enable it by default in version 7 or 8.

I'd say the industry as a whole has moved in the direction of accepting the tiny inconvenience of having to declare variables over the massive benefit in safety and protection against typos and other errors. Hey, even javascript got a `"use strict"` and TypeScript enables it by default in modules. [PHP 7 also got something comparable](https://stackoverflow.com/questions/3193072/strict-mode-in-php). The only holdout in the "no strict" realm seems to be python.

But, there's always a "but", isn't there?

One of the primary motivations for not wanting to declare variables was laziness, and Raku did introduce several features that allow to you avoid some declarations:

* Parameters in signatures are an implicit declaration, The RFC's example `sub squre` could be written in Raku simply as `sub square($x) { $x * $x }`. No explicit declaration necessary.
* Self-declaring formal parameters with the `^` twigil also imply a declaration, for example `sub square { $^x * $^x }`.
* There are many functional features in Raku that you can use to avoid explicit variables altogether, like meta operators, Whatever star currying etc.

I am glad Raku requires variable declarations by default, and haven't seen any code in the wild that explicitly states `no strict;. And without declarations, where would you even fit the type constraint?
