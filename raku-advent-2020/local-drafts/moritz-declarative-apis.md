# Declarative APIs

Out of the box, libraries tend to be pretty neat to use, with named
arguments and all the other nice features that make Raku code awesome.

But sometimes a library author goes above and beyond to produce
extra nice, declarative APIs. One example is [Cro](https://cro.services/), which allows you to write things like

    my $application = route {
        get -> 'greet', $name {
            content 'text/plain', "Hello, $name!";
        }
    }

to declare your routes, that is, callbacks that are tied to URL patterns,
and which Cro calls for you.

Today, we'll explore the mechanics that make such declarative APIs work,
and how you can enable similar interfaces for libraries you write.

## Declarative API Fundamentals

The example above relies on a few major ideas:

* bare words like `route`, `get` and `content` are just functions of the same name, and you can call them simply with their name followed by a space. The rest of the statement is interpreted as arguments to these functions.
* In `route { ... }`, the `{ ... }` returns a [`Block`](https://docs.raku.org/type/Block), that is, a piece of code like a function.
* Likewise, `-> 'greet', $name { ... }` is a function, this one with an explicit signature (the `'greet', $name` part). The library code can introspect this signature, that is, find the name of the parameters (`$name`) and the value of the constant string `'greet'`.
* There is also an invisible mechanism that ties the `get` to the outer `route { ... }` block.

This last point needs some more explanation. In Cro you could have multiple independent `route { }` blocks, like so:

    my $app1 = route {
        get -> 'meet' { content 'text/plain', 'Nice to see you' }
    }
    my $app2 = route {
        get -> 'greet' { content 'text/plain', 'Oh hai' }
    }

How does `Cro` know that the `meet` callback belongs to `$app1` and `greet` belongs to `$app2`? The `route` subroutine needs to call the block passed to it to find out what callbacks it declares, so it needs to inject some kind of context into the block. The way to do that is through a [dynamically scoped variable](https://docs.raku.org/language/variables#index-entry-Dynamically_scoped_variables).

In Raku, you can do that by setting a variable with the `*` sigil:

    sub outer(&callback) {
        my @*DYNAMIC;
        callback();
        return @*DYNAMIC.list;
    }
    sub inner() {
        @*DYNAMIC.push(42);
    }
    say outer(&inner);

Here sub `outer` declares a dynamic variable `@*DYNAMIC`. All called that is run until `outer` finishes can see that variable, including the inside of `inner`, which is bound to the parameter `&callback`. Thus, the code prints `[42]`.

If you look at [`Cro::HTTP`'s definition of `sub route`](https://github.com/croservices/cro-http/blob/5e636321ef16a3abae2927eb3948b19eb4de3d02/lib/Cro/HTTP/Router.pm6#L606), you can see that it uses  basically the same trick, except that initializes the dynamic variable with an empty `RouteSet` instead of an empty array.

## Getting Practical

Suppose you are writing a library that observes a directory tree, and you can configure it synchronize flies to another local, or to automatically delete them based on certain properties, or call your code when certain files change.

You want to provide an extra awesome, declarative API like this:

    my $syncer = directory 'Documents', {
        watch name => /.*/, -> $file { say "File $file changed" }
        delete name => /\.swp/;
        delete name => /\.swo/;
        delete age_days => * > 5; 
        sync extension => 'txt';
    }

To get this example to compile, you just need to declare the four functions
`directory`, `delete`, `sync` and `watch` with appropriate signatures:

    sub delete(*%conditions) {}
    sub sync(*%conditions) {}
    sub watch(&callback, *%conditions) {}

    sub directory(Str $path, &callback) {}

Of course, you also need to capture the conditions and the callback in a data structure so that your hypothetical library can do something with it.

This could be an enum to store the action type, and a class for the condition and the optional callback:

    enum Sync::Action <Delete Sync Watch>;
    class ConditionalRule {
        has Sync::Action $.action is required;
        has %.conditions;
        has &.callback;
    }

Plus a class that stores the directory and a list of `ConditionalRule` objects:

    class Sync::Spec {
        has Str $.path;
        has ConditionalRule @.rules;
        method add(ConditionalRule $r) { @.rules.append: $r }
    }

Finally, the four functions we started with need to be fleshed out. `directory` creates a `Sync::Spec` object and then calls its callback:

    sub directory(Str $path, &callback) {
        my $*SYNC = Sync::Spec.new(:$path);
        callback;
        return $*SYNC;
    }

The other three need to create new `ConditionalRule` objects, and add them
to `$*SYNC`:

    sub delete(*%conditions) {
        $*SYNC.add: ConditionalRule.new:
            :action(Sync::Action::Delete),
            :%conditions,
    }
    sub sync(*%conditions) {
        $*SYNC.add: ConditionalRule.new:
            :action(Sync::Action::Sync),
            :%conditions,
    }
    sub watch(&callback, *%conditions) {
        $*SYNC.add: ConditionalRule.new:
            :action(Sync::Action::Sync),
            :%conditions,
            :&callback,
    }

This is annoying boilerplate, but it allows the user of the pretty interface
to forego all the boilerplate.

Once you piece all of this together, `directory` returns a `Sync::Spec`
object that holds all the knowledge necessary to fuel the hypothetical syncer library.

All that is left is actually implementing it. A task well outside the scope
of this article -- left as the proverbial exercise to the reader, should you
chose those.

But wait, we aren't quite done yet, because when somebody misuses our neat
little API. If you just call `delete` outside of a `directory` block, you get
the error `Dynamic variable $*SYNC not found`, which is not worthy of the
awesomeness we aspire to.

Luckily, we can improve that easily:

    sub delete(*%conditions) {
        die 'delete outside a directory { } block'
            unless defined $*SYNC;
        $*SYNC.add: ConditionalRule.new:
            :action(Sync::Action::Delete),
            :%conditions,
    }

... and analogously for the three other two actions. Again more boilerplate,
inline with Raku's motto of tormenting the implementer on behalf of the user.
