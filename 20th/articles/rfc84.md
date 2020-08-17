# RFC 84 by Damian Conway: Replace => (stringifying comma) with => (pair constructor)

Yet another nice goodie from Damian, truly what you might expect from the interlocutor and explicator!

The fat comma operator, `=>`, was originally used to separate values - with a twist. It behave just like `,` operator did, but modified parsing to stringify left operand.

It saved you some quoting for strings and so this code for hash initialization:

```perl
my %h = (
    'a', 1,
    'b', 2,
);
```

could be written as:

```perl
my %h = (
    a => 1,
    b => 2,
);
```

Here, bare `a` and `b` are parsed correctly, without a need to quote them into strings. However, the usual hash assignment semantics is still the same: pairs of values are processed one by one, and given that `=>` is just a "left-side stringifying" comma operator, interestingly enough the code above is equivalent to this piece:

```perl
my %h = ( a => 1 => b => 2 => );
```

The proposal suggested changing the meaning of this "special" operator to become a constructor of a new data type, [Pair](https://docs.raku.org/type/Pair).

A Pair is constructed from a key and a value:

```perl6
my @pairs = a => 42, 1 => 2;
say @pairs[0];           # a => 42
say @pairs[1];           # 1 => 2;
say @pairs[1].key.^name; # Int, not a Str
```

The `@pairs` list contains just 2 values here, not 4, one is conveniently stringified for us and the second just uses bare Int literal as a key.

It turns out, introducing `Pair` is not only a convenient data type to operate on, but this change offers new opportunities for... subroutines.

Raku has first class support of signatures, both for the sake of the "first travel class" pun here and for the matter of it, yes, actually having [Signature](https://docs.raku.org/type/Signature), [Parameter](https://docs.raku.org/type/Parameter) and [Capture](https://docs.raku.org/type/Capture) as first-class objects, which allows for surprising solutions. It is not a surprise it supports named parameters with plenty of syntax for it. And `Pair` class has blended in quite naturally.

If a Pair is passed to a subroutine with a named parameter where keys match, it works just so, otherwise you have a "full" Pair, and if you want to insist, a bit of syntax can help you here:

```perl6
sub foo($pos, :$named) {
    say "$pos.gist(), $named.gist()";
}

foo(42);                         # 42, (Any)
try foo(named => 42);            # Oops, no positionals were passed!
foo((named => 42));              # named => 42, (Any)
foo((named => 42), named => 42); # named => 42, 42
```

As we can see, designing a language is interesting: a change made in one part can have consequences in some other part, which might seem quite unrelated, and you better hope your choices will work out well when connected together. Thanks to Damian and all the people who worked on Raku design, for putting in an amazing amount of efforts into it!

And last, but not the least: what happened with the `=>` train we saw? Well, now it does what you mean if you mean what it does:

```perl6
my %a = a => 1 => b => 2;
say %a.raku; # {:a(1 => :b(2))}
```

And yes, this is a key `a` pointing to a value of Pair of `1` pointing to a value of Pair of `b` pointing to value of 2, so at least the direction is nice this time. Good luck and keep your directions!
