Conditionally Writeable Attributes
==================================

While designing an event system for a personal project, I ran across a requirement
which I knew could be implemented elegantly with Raku's metaprogramming capabilities.
Specifically, I wanted both sync and async events, with the sync events allowing
mutation of fields (e.g. for cancellation), and the async ones being merely
informational and thus immutable.

First, I needed an `Event` role to group eventy behavior and
[be inherited](https://docs.raku.org/language/typesystem#trait_does) by all the
event classes. Then, choosing [mixins](https://docs.raku.org/syntax/Mixins) over
inheritance, I decided that sync and async would also be roles (`Sync` and `Async`)
*not* related to `Event` in the type hierarchy, but rather mixed into instances of
`Event`'s inheritors as appropriate.

```raku
# no relations between these types!
role Event is export {}
role Sync is export {}
role Async is export {} 
```

Using mixins for the sync/async distinction here eliminates the need to write two
versions of each event class, one doing a theoretical `SyncEvent` role and the other
a theoretical `AsyncEvent` role (which would in turn both do the `Event` god-role).
Instead, we write the inheriting class once and reuse it—a much cleaner design!

However, this presents the issue indicated in the topic. Because sync—but *not*
async—events are meant to be mutable by event handlers, how do we write each event
class once yet have differing behavior without duplicating logic in every method
(shown below)? After all, the `Sync` and `Async` roles cannot have advance knowledge
of the exact structure of what they'll be mixed into, so *they* can't provide the
differentiating functionality.

```raku
class ConfigLoadEvent does Event {
    has Int $!timeout;

    # Horribly tedious!
    method get-timeout { $!timeout; }
    method set-timeout(Int $timeout) {
        fail unless self ~~ Sync;
        $!timeout = $timeout;
    }
}
```

The solution is a type-aware (specifically mixin-aware)
[trait](https://docs.raku.org/language/traits) which I decided to name `sync-rw`.
This will be applied to attributes of the various classes doing the `Event` role
which have some data that sync handlers can change but which ought not to be touched
by async handlers.

Like Raku's built-in `rw` trait, this trait allows us to run some code at compile
time to alter runtime behavior in and around language object we applied said trait
to. "Language object" could mean subroutine, class, method, parameter, and so on.
In this case, we want a trait specifically for use with object attributes,[^1]
i.e., stuff declared with the
[`has` declarator](https://docs.raku.org/language/variables#The_has_declarator).

With that said, what precisely *should* `sync-rw` do to the attribute? Actually,
nothing. That wasn't a trick question, either: the fact is, we needn't change
anything about the attribute itself, rather the code that gets generated for the
class *containing* the attribute.

For those unfamiliar, Raku generates an accessor for you when you use the `.` 
[twigil](https://docs.raku.org/language/classtut#Attributes) on an attribute, as
shown below. By default, this accessor returns a readonly container. With the `rw`
trait, it returns a writeable container, again as demonstrated below. Note that
when I say "accessor" I don't mean anything special at a language level; I just
mean a method that happens to provide access to an attribute. This results in what
*looks* like direct attribute access à la C structs but is in fact a method call
whose name happens to match the attribute name and which happens to give you access
to the attribute.

```raku
class Foo {
    has $!secret; # no accessor
    has $.bar;
    has $.baz is rw;
}
my Foo $foo .= new: :2bar, :2baz;
say $foo.bar;
$foo.baz = 3;
say $foo.baz(); # parens to demonstrate this is a method
```

This ability to return a writeable container is not unique to code generated for
classes by the compiler. You, the user, can get this functionality with
[`return-rw`](https://docs.raku.org/syntax/return-rw). That and the
[Metaobject Protocol](https://docs.raku.org/language/mop) (MOP) are about all we
need to write our `sync-rw` trait.

```raku
multi trait_mod:<is>(Attribute $attr, :$sync-rw!) is export {
    $attr.package.^add_method:
        $attr.name.substr(2),
        anon method :: {
            if self ~~ Sync {
                return-rw $attr.get_value: self;
            }
            elsif self ~~ Async {
                return $attr.get_value: self;
            }
            else {
                die "{ self.^name } with attributes marked `is sync-rw`"
                    ~ ' must have either Sync or Async mixed in';
            }
        };
}
```

Let's break down this code. First, `trait_mod:<is>` is how we refer to the `is`
pseudo-operator.[^2] We're using a multi here because there are already built-in
definitions for `is`, and we want to add another candidate. This candidate
takes an [`Attribute`](https://docs.raku.org/type/Attribute) (a meta-class
representing an object attribute) as its left-hand argument and the bare term
`sync-rw` as its right-hand argument. The colon makes `$sync-rw` a
[named parameter](https://docs.raku.org/language/signatures#Positional_vs._named_arguments),
which normally we would pass with a colon on the caller side, but `is` has some
syntax sugaring, so we needn't write `is :sync-rw`. The exclamation makes it
required (named params are optional by default).

We're exporting this routine because we want it available to other code units. (Yes,
[`export` is also a trait](https://docs.raku.org/type/Mu#trait_is_export)!) Looking
at the body of the routine, our first line gets the package in which the `Attribute`
lives, which will be the class that `has` the attribute. We use a meta-method call
(indicated by the carat) to [add a method](https://docs.raku.org/routine/add_method)
to that class. Another way of saying "meta-method call" is "method call on the
object's [meta representation](https://docs.raku.org/type/Metamodel/ClassHOW)."

The first parameter for `add_method` is the new method's name. We take `$attr`'s
name, strip the first two characters (which will be the sigil and twigil like `$.`),
and use that for the method name. Just like the built-in accessor we get from the `.`
twigil, this will make the generated method's name match the attribute name.

If Raku generates a method, and we're also generating a method with the same name,
will the two code generation processes interfere? Nope. Raku's built-in accessor
generation only happens if there is not already a method defined with that name,
allowing the user to define a custom accessor (or method which does something entirely
different) without it getting steamrolled. The way we're defining the method here is
out of the ordinary, but the result is the same, and Raku will refrain from generating
the default accessor.

The second parameter is an anonymous method object. The
[`anon` declarator](https://docs.raku.org/syntax/anon) prevents the symbol from being
installed in any scope or symbol table. The root package `::` is used in place of a
name. While you can give `anon method`s a name (which only the method itself would
know), we don't need or want a proper name here.

The body of the method checks to see whether the invocant (`self`, the object on
which the method will be called at runtime) is `Sync`, `Async`, or neither. If it's
`Sync`, we `return-rw`; if it's `Async`, we do a regular `return`; and if it's
neither, we generate an error.

We retrieve the actual value with `$attr.get_value: self`. It needs to be passed
the `self` instance because `Attribute`s represent a part of your code. They know
what class they're in, but they're at a *class* (or *package*) level, not an *instance*
level. Once we give it the instance, `$attr` knows how to retrieve the relevant
value from that instance.

As an aside, we don't strictly need the `Event` role for this minimized example.
For the real thing, we can and should check inside our `trait_mod:<is>` candidate
that the attribute's package (class) `does` the `Event` role, throwing an error
otherwise.

And that's all the code we need. I spent a while explaining the why and how, but the
final volume of code is barely over a dozen significant lines. For a task that delves
into metaprogramming, Raku gets us to the solution shockingly fast and with nearly zero
boilerplate code.

Now, we'll throw the role and trait definitions together in an `Event.rakumod` file so
we can test it with the below `.rakutest` file.

```raku
use v6.d;
use Test;

use lib '.';
use Event;

class Foo does Event {
    has $.attr is sync-rw;
}

# The value can be updated when the instance is Sync
my $rw = (Foo but Sync).new(attr => 'old');
lives-ok  { $rw.attr = 'new' };
ok $rw.attr eq 'new';

# But not when Async
my $non-rw = (Foo but Async).new(attr => 'old');
throws-like { $non-rw.attr = 'new'; }, X::AdHoc,
    message => 'Cannot assign to a readonly variable or a value';

throws-like { Foo.new(attr => 'invalid').attr; }, X::AdHoc,
    message => 'Foo with attributes marked `is sync-rw` must have either Sync or Async mixed in';
```

And there we have it! All the tests pass, and we have a generic solution which is
easily reused and prevents a lot of nasty code duplication. One could argue that
meta-object fiddling is nasty in itself, but it's O(1) nastiness compared to the
O(n) nastiness that code duplication would be. In the end, I find this a rather
elegant interface because it parallels Raku's built-in `rw` trait and requires
so little effort on the usage side. Slap `is sync-rw` on and that's it.

Hopefully this serves as a lesson in language design, too. Such an elegant yet
easy-to-implement solution is only possible because Raku exposes to the user
(nearly) all the same tools the language designers have, with a concise and
straightforward interface out of the box—no third-party tools needed. If you've
ever done reflection in Java, you'll understand how much there is to appreciate
here.

Finally, I'd like to give credit to guifa from the Raku IRC for the exact form
of the trait code. Prior to their suggestion, I had something much messier
because I didn't know what was available and how well things would DWIM.

[^1]: The `rw` trait can also be applied in other places such as parameter
declarations.

[^2]: While you can treat `is` like an operator in some ways, such as adding
a new candidate like we are here, it is special-cased because it needs to do
special (compile-time) things.
