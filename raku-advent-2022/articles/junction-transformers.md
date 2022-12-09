Junction Transformers
=====================

Consider a junction of digits:

```raku
say any 0..9; # OUTPUT: any(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
```

This carries `'any'` as a type of operation and `0..9` as a list of
*eigenstates* internally. In a smartmatch context, this can match against any
object that can smartmatch against any digit. Its list of eigenstates is not
exposed, but there is a means of processing its contents.

The `~~` smartmatch operator delegates to the `ACCEPTS` method on the RHS prior
to a `Bool` coercion on its result. For example, we'll depend on `Code.ACCEPTS`
directly as a means of introducing side effects into the smartmatch operation:

```raku
sub sum(Mu $topic is raw) {
    my $sum is default(0);
    sub sum($topic) { $sum += $topic }
    &sum.ACCEPTS: $topic;
    $sum
}

say sum any 0..9;        # OUTPUT: 45
say sum 0 & (9 ^ 9) & 0; # OUTPUT: 18
```

In this case, it forwards a single argument (its "topic") to an invokation of
itself, allowing us to take a sum of eigenstates.

We give `&sum` a closure to give us fresh `$sum` for each call. Because the
`$topic` of the inner `&sum` has no type, it carries a `Mu` type like the outer
`$topic`, but will *autothread* a `Junction:D` argument over `Any` eigenstates.
Because the outer `$topic` is explicitly typed `Mu` and `is raw` however, it
will leave both junctions and containers on input alone. Note that
autothreading recurses over `Junction:D` eigenstates.

If we're going to just accept one argument given a junction, it could just as
well be a `Mu` eigenstate instead of the junction itself. `Mu.ACCEPTS` can
*thread* its topic over `Mu` instead of `Any` given a `Mu:U` invocant (`Mu:D`
is NYI; `Any:D` defaults to `&[===]`). Similarly, `Junction.CALL-ME` threads
its invocant over `Mu`. Because a junction will *not* shortcircuit as it is
threaded, these can be chained to traverse one's eigenstates:

```raku
class JMap does Callable {
    has &!transform is built(:bind);

    multi method ACCEPTS(::?CLASS:U: Mu $topic is raw) {
        self.bless: transform => { &^function($topic) }
    }
    multi method ACCEPTS(::?CLASS:D: Mu $topic is raw) {
        &!transform.ACCEPTS: -> Mu $thread is raw { $thread.ACCEPTS: $topic }
    }

    proto method CALL-ME(Mu) {*}
    multi method CALL-ME(::?CLASS:U: Mu $topic is raw) {
        self.ACCEPTS: $topic
    }
    multi method CALL-ME(::?CLASS:D: &function) is raw {
        &!transform(&function)
    }
}

say JMap(any 0..9)(*[]);       # OUTPUT: any(0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
say JMap(any 0..9)(2 ** *);    # OUTPUT: any(1, 2, 4, 8, 16, 32, 64, 128, 256, 512)
say JMap(0 & (9 ^ 9) & 0)(?*); # OUTPUT: all(False, one(True, True), False)
```

`JMap` gets its one chance to thread a `Junction:D` as a type object, so we
forward the junction to map before its `Callable`. After a `CALL-ME`, we wind
up with either a callable or a new junction of callables that is invokable, but
does not qualify as `Callable` itself. Despite `ACCEPTS` being typed with a
`Mu` topic over `JMap`, the threading of junctions still wins in a dispatch.

`JMap` can process the eigenstates of a junction generically, but carries
overhead in a second round of threading prior to any smartmatching against the
result. If you have a particular `Callable` in mind with which to map, this
`JTransformer` template can be followed:

```raku
class JTransformer does Callable is repr<Uninstantiable> {
    multi method ACCEPTS(Mu --> Code:D) { ... }

    method CALL-ME(Mu $topic is raw) is raw { self.ACCEPTS: $topic }
}
```

In general, a `CALL-ME` would be used to thread its `Mu $topic is raw` through
`ACCEPTS`. Instead of instantiating the invocant, this would return a bare
block or `anon sub`, which would perform a tailored smartmatch operation given
the threaded `Mu` in its context and a topic from any later smartmatch on said
code object.

If a junction produced by `CALL-ME` is cached, the `ACCEPTS` candidate written
can shoulder part of its resultant thunk's work to make *that* cheaper to
smartmatch, e.g. by preprocessing the path to a particular block. It can be
cheapened further in this sense by subtyping `Mu` directly in lieu of the
default `Any` for a simpler dispatch, though it becomes more difficult to work
with in doing so:

```raku
class JTransformer is Mu does Callable is repr<Uninstantiable> { ... }
```

A practical example of a `JTransformer`-like class is the internal `class
Refine` that backs my [`Kind`](https://raku.land/zef:Kaiepi/Kind) subsets'
refinements (`where` clauses) as of
[v1.0.2](https://github.com/Kaiepi/ra-Kind/blob/v1.0.2/lib/Kind.pm6#L45-L74).
Because it's dabbling in metaobjects, `Any` cannot be assumed (e.g. `Mu`,
`Junction`), but junctions can allow for complex checks against multiple
metaroles. If a metaobject threaded by its `ACCEPTS` call cannot typecheck as
`Mu` for any reason, it will substitute a block wrapping a low-level typecheck
against it, otherwise thunking a boolification of an `ACCEPTS` call.
