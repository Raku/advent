# RFC22: Control flow: Builtin switch statement, by Damian Conway

## The problem

C has switch/case, and many other languages either copied it, or created a similar construct. Perl in 2000 didn't have any such thing, and this was seen as a lack.

## A Tale of Two Languages

[This RFC](https://raku.org/archive//rfc/22.html) not only became two (related) features, it did so in both Perl and Raku with dramatically different results: in Perl it's widely considered the biggest design failure of the past two decades, whereas in Raku it's an entirely non-controversial. The switch that Perl ended up with is working very similar to the original proposal. This is actually helpful in analysing what changes were necessary to make it a successful feature. It looks something like this (in both languages):

~~~
given $foo {
	when /foo/ {
		say "No dirty words here";
	}
	when "None" {

	}
	when 1 {
		say "One!";
	}
	when $_ > 42 {
		say "It's more than life, the universe and everything";
	}
}

~~~

The switch is actually two features (for the price of only one RFC): smartmatch and [given/when](https://docs.raku.org/language/control#index-entry-switch_(given)) on top of it. Smartmatch is an operator `~~` that checks if the left hand side fits the constraints of the right hand side. Given/when is a construct that smartmatches the given argument to a series of when arguments (e.g. `$given ~~ $when`) until one succeeds.

However, one of the distinguishing features of Perl is that it doesn't generally overload operators, instead it has different operators for different purposes (e.g. `==` for comparing numbers and `eq` for comparing strings). Smartmatch however is inherently all about overloading. This mismatch is essentially the source of all the trouble of smartmatch in Perl. Raku on the other hand has an extensive type-system, and is not so dependent on type specific operators (though it still has some for convenience), and hence is much more predictable.

Most obviously, the type system of Raku means that it doesn't use a table of possibilities, but instead `$left ~~ $right` just translates to `$right.ACCEPTS($left)`. The right-first semantics makes it a lot easier to reason about (e.g. matching against a number will always do numeric equality).

It means it can easily distinguish between a string and an integer, unlike Perl which has to guess what you meant: `$foo ~~ 1` always means `$foo == 1`, and `$foo ~~ "foo"` always means `$foo eq "foo"`. In Perl, `$foo ~~ "1"` would do a numeric match.

But perhaps the most important rule is smartmatching booleans. Perl doesn't have them, and this makes `when` so much more complicated than most people realize. The problem is with statements like `$_ > 42`, which need boolean logic. Perl solves this using a [complex heuristic](https://perldoc.perl.org/perlsyn.html#Experimental-Details-on-given-and-when) that no one really can remember (no really, no one). Most surprisingly, that means that `when /foo/` does not use smartmatching (this becomes obvious when the left hand side is an arrayref).

Raku uses a very different method to solve this problem. In Raku, when *always* smartmatches. Smartmatching against a `Bool` (like in `$_ > 42`), will always return that bool, so `$foo ~~ True` always equals `True`. This enables a wide series of boolean expressions to be used as `when` condition without problems. It's a much simpler, and surprisingly effective method of dealing with this challenge.

## Other uses

The other difference between smartmatching in Perl versus Raku is that it is actually used outside of given/when. In particular, selecting methods such as `grep` and `first` use it to great effect: `@array.grep(1)`, `@array.grep(Str)`, `@array.grep(/foo/)`, `@array.grep(&function)`, `@array.grep(1..3)`, and `@array.grep((1, *, 3))`* all do what you probably expect them to do. Likewise it's used in a number of other places where one checks if a value is part of a certain group or not, like the ending argument of a sequence (e.g. `1000, 1001 ... *.is-prime`) and the flip-flop operators.

Smartmatch is all about making code do what you mean, and it's pretty useful and reusable for that.
