# RFC 25, by Damian Conway: Operators: Multiway comparisons

This RFC was originally proposed on August 4th and frozen in a month.

It describes a simple and intuitive feature, making the code obey the Do What I Mean rule:

    if ( 0 <= $x =< 10 ) {
        print "digit"
    }

Twenty years ago it was not a great surprise to not expect that to work as one might want.

Now we can call it "operator chaining" and now it is not commonly available
among programming languages. One can think of [a number of reasons](https://softwareengineering.stackexchange.com/questions/316969/why-do-most-mainstream-languages-not-support-x-y-z-syntax-for-3-way-boolea) why is it so,
which include not considering it as an important
feature, a need to break backward compatibility and sometimes just not thinking about it.

However, with Raku programming language design process it became possible for all
kinds of wise people to suggest their ideas.

While one may see this as too small for a worthy feature to work on, Raku was designed under the "Fix the language, not the user" banner,
thus making even such changes wanted.

While this feature originally was missing from Perl, it [eventually got
such logical chaining support since v5.32](https://www.effectiveperlprogramming.com/2020/03/chain-comparisons-to-avoid-excessive-typing/) release.

# RFC 76, by Damian Conway: Builtin: reduce

This RFC proposes a built-in `reduce` function, inspired by one from `List::Utils` module written by Graham Barr.

Familiar to those who are interested in functional programming as `fold` or just `reduce`, this one is among
tools which help with data processing.

    $sum = reduce {$_[0]+$_[1]}     0, @numbers;
    $sum = reduce sub{$_[0]+$_[1]}, 0, @numbers;
    $sum = reduce ^_+^_,            0, @numbers;

The `reduce` subroutine, when given an operation to apply and a list of values, applies this operation
to the values in this fashion:

    result0 = init
    result1 = f(result0, list[0])
    result2 = f(result1, list[1])
    ...
    resultn = f(resultn-1, list[n-1])

However, since the Damian Conway has proposed this RFC on August 10th, and it became frozen a month later, the subroutine evolved into
an even more exciting tool.

In Raku, `reduce` additionally can:

    # Have an identity value as default when there are no items to run on:
    say reduce &infix:<+>, []; # OUTPUT: «0␤»

    # Have a method form as well:
    say [].reduce(&infix:<+>); # OUTPUT: «0␤»

    # Have operator application order depending on actual operator associativity:
    # 1) Define two operators with different associativity
    sub infix:<foo>($a, $b) is assoc<right> { "($a, $b)" }
    sub infix:<bar>($a, $b) is assoc<left> { "($a, $b)" }
    # 2)Observe!
    say [foo] 1, 2, 3, 4; # OUTPUT: «(1, (2, (3, 4)))␤»
    say [bar] 1, 2, 3, 4; # OUTPUT: «(((1, 2), 3), 4)␤»

    # Operate on Supply type, which is an thread-safe, asynchronous data stream,
    # allowing transforming of a Supply into another supply, which
    # reduces all asynchronous values and asynchronously emits result:
    my $supply = Supply.from-list(1..5).reduce({$^a + $^b});
    $supply.tap(-> $v { say "$v" }); # OUTPUT: «15␤»

This way, a seemingly simple suggestion affected multiply parts of the language,
keeping simple things simple and harder things possible.

# RFC 193, by Damian Conway: Objects: Core support for method delegation

Originally proposed on September 4th and frozen a bit later, this RFC introduces a concept of special
syntax sugar for method delegation.

In object-oriented programming, delegation pattern is a design pattern which allows to use an internal object to
handle calls to an outer object, allowing it to mimic the internal object without explicit inheritance or code duplication.

However, in many languages implementation of this pattern requires to explicitly write out all methods:

    // Java program to illustrate delegation
    class Inner {
        // the "delegate" 1
        void doWork() {
            System.out.println("It worked out!");
        }

        // the "delegate" 2
        void doMoreWork() {
            System.out.println("It worked out even better!");
        }
    }

    class Outer {
        // the "delegator"
        Inner inner = new Inner();

        // create the delegate 1
        void doWork() {
            inner.doWork(); // delegation
        }

        // create the delegate 2
        void doMoreWork() {
            inner.doMoreWork(); // delegation
        }
    }

Such manual approach introduces a lot of boilerplate to write: each method delegated has to be explicitly
written out with all the parameters and the call code.

The RFC in question suggest a pragma `delegation`, used in this way:

	use delegation
		attr1 => [qw( method1 method2 method3 )],
		attr2 => [qw( method4 method5 )],
		attr3 => __ALL__,
		attr4 => __ALL__,
		# etc.
		;

This significantly reduces the amount of boilerplate the user needs to write!

However, with Raku design obtaining traits, compile-time specifications of behavior which allow to
alter what the machine thinks of some code piece, implementation of this RFC eventually became even more elegant:

    class Inner {
        method doWork {
            say 'It worked out!';
        }

        method doMoreWork {
            say 'It worked out even better!';
        }
    }

    class Outer {
        has Inner $.i handles <doWork doMoreWork>;
    }

What a clean zero-boilerplate Raku way!

# In conclusion

In this article we discussed three separate features which seem small in the first glance, but at the end of the day
you have all the beauty of different parts of the language being connected with each other playing well together.

One concept inevitably pulls another and your tool belt becomes more and more versatile as you learn.

Kudos to all the people who went a long and demanding path of emerging all kinds of ideas into a solid piece of work
implemented and helping out in all kinds of situations.
