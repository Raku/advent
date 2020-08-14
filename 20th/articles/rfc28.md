https://raku.org/archive/rfc/28.html

# RFC 28 - Perl Should Stay Perl

Originally Submitted by Simon Cozens, [RFC 28](https://raku.org/archive/rfc/28.html) on August 4, 2020, this RFC asked the community to make sure that whatever updates were made, that Perl 6 was still definitely recognizable as Perl. After 20 years of design, proofs-of-concept, implementations, two released language versions, we've ended up with something that is definitely Perlish, even if we're no longer a Perl.

At the time the RFCs were submitted, the thought was that this language would be the next Perl in line, Perl 6. As time went on before an official language release, Perl 5 development picked up again, and that team & community wanted to continue on its own path. A few months ago, Perl 6 officially changed its name to Raku - not to get away from our Perl legacy, but to free the Perl 5 community to continue on their path as well. It was a difficult path to get to Raku, but we are happy with the language we're shipping, even if we do miss having the Perl name on the tin. 

# "Attractive Nuisances"

Let's dig into some of the specifics Simon mentions in his RFC.

> We've got a golden opportunity here to turn Perl into whatever on earth we like. Let's not take it.

This was a fine line that we ended up crossing, even before the rename. Specific design decisions were changed, we started with a fresh implementation (more than once if you count Pugs & Parrot & Niecza ...). We are Perlish, inspired by Perl, but Raku is definitely different.

> Nobody wins if we bend the Perl language out of all recognition, because it won't be Perl any more.

I argue that eventually, everyone won - we got a new and improved Perl 5 (and soon, a 7), *and* we got a brand new language in Raku. The path wasn't clear 20 years ago, but we ended up in a good place.

> Some things just don't need heavy object orientation.

Raku's OO is everywhere: but it isn't required. While you can treat everything as an object:

```
3.sqrt.say;
```

You can still use the familiar Perlish forms for most features.
```
say sqrt 3;
```

Even native scalars (which don't have the overheard of objects) let you treat them as OO if you want.

```
my uint32 $x = 32;
say $x;
$x.^name.say;
```

Even though $x here doesn't start out as an object, by calling a meta-method on it, the compiler cheats on our behalf and outputs ```Int``` here, the closest class to our native int.

But we avoid going the extent of Java; for example, we don't have to define a class with a main method in order to execute a program.

> Strong typing does not equal legitimacy.

Similar to the OO approach, we don't *require* typing, but allow you to gradually add it. You can start with an untyped scalar variable, but as you further develop your code, you can add a type to that declared variable, and to parameters to subs & methods. The types can be single classes, subsets, Junctions, where clauses with complicated logic: you can use as much or as little typing as you want. Raku's multi routines (subs or methods with the same name but different arguments) give you a way to split up your code based on types that is then optimized by the compiler. But you can use as little or as much of it as you want.

> Just because Perl has a map operator, this doesn't make it a functional programming language. 

I think Raku stayed true to this point - while there are functional elements, the polyglot approach (supporting multiple different paradigms) means that any one of them, including functional, doesn't take over the language. But you can declare routines ```pure```, allowing the compiler to constant fold calls to that routine when the args are known at compile time.

> Perl is really hard for a machine to parse. ... It's meant to be easy for humans to understand. 

Development of Raku definitely embraced this thought - "torture the implementators on behalf of the users". This is one of the reasons it took us a while to get to here. But on that journey, we designed and developed new language parsing tools that we not only use to build and run Raku, but we expose to our users as well, allowing them to implement their own languages and "Slangs" on top of our compiler.

## fin

Finally, now that the Perl team is proposing a version jump to 7, I suspect the Perl community will raise similar points in their new path forward. While you're waiting on 7, please try out Raku if you haven't already!
