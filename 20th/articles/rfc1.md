# RFC 1, by Bryan C. Warnock: Threads

It might or might not be the case that the need for a real multithreaded architecture in Perl was the real motive behind the creation of what was initially called simply Perl, then Perl 6, and eventually [Raku](https://raku.org).

It was probably late 90s or early 10s, when we had a contract with a big company that needed to download stuff from the web really fast. We needed those threads, and they finally arrived in Perl 5.10. However, our threads were very basic, didn't need any kind of communication, just the bare parallel thing, and underneath them, operating system processes were used; there were no real *threads* at the Perl VM level. And they were sorely needed. Which is why [RFC1](https://raku.org/archive/rfc/1.html) read:

> Implementation of Threads in Perl

It was originally proposed on August 1st (hence the 20th aniversary thing), and finally *frozen* a couple of month later, by September 28th.

It basically proposes a way to implement low-level threads, including new namespaces (`global`, for sharing variables among threads) as well as the `Threads` class, with this example:

```
use Threads;
# the main thread has all four above in its arena

my $thread2 = Threads->new(\&start_thread2);
#...

sub start_thread2 { ... }
```

The main thread is implicit, and gets all other modules into its namespace, the second one inherits from the main thread. It makes sense, in general, except it's a very low level mechanism to use threads, and in fact it looks more like a way to handle processes than what we call nowadays threads. There's another RFC for those, which are called ["lightweight threads"](https://raku.org/archive/rfc/178.html), which was started a few week later and frozen pretty much at the same time. It contains the graphic simile:


> Perl → Swiss-army chain saw; Perl with threads → juggling chain saws

It's difficult to see what's the difference between them, except for the explicit sharing of variables and the fact that it uses `Thread` instead of `Threads` as the main class.

Eventually, that was the keyword chosen for threads in Raku: [`Thread`](https://docs.raku.org/type/Thread.html). This uses `new` to create a thread, but you have then to issue a `.run` to actually run it. Alternatively, you can simply use `.start` to create *and* run a thread inmediately.

```perl6
#!/usr/bin/env raku

constant $interval = 100000;

my @threads = (^10).map: -> $i {
    Thread.start(
        name => "Checking primes from {$i * $interval } to { ($i+1)*$interval}",
        sub {
            for ($i * $interval)..^(($i+1)*$interval) -> $n {
		next if ( $n %% 2 ) | ( $n %% 3 ) | ($n %% 5 );
		say "Prime $n found in $*THREAD" if $n.is-prime;
	    }
        },
    );
}

.finish for @threads;
```

This is taken pretty much directly from the example in the Thread manual page, and shows the differences between Raku and what its early inceptions looked like. It uses a `map` to start 10 threads (using a Range); every thread will work on a range of numbers to check if there's a prime in then. After cribbing out a few easy ones, it will simply check, using the is-prime function, if the number is prime, and it will print the number and the thread it's in. The [`$*THREAD`](https://docs.raku.org/language/variables#index-entry-$*THREAD) variable allows for easy introspection of the thread one is in, which will make this print something like this:

```
...
Prime 76579 found in Thread<4>(Checking primes from 0 to 100000)
Prime 994997 found in Thread<13>(Checking primes from 900000 to 1000000)
Prime 655043 found in Thread<10>(Checking primes from 600000 to 700000)
Prime 483991 found in Thread<8>(Checking primes from 400000 to 500000)
Prime 169283 found in Thread<5>(Checking primes from 100000 to 200000)
Prime 995009 found in Thread<13>(Checking primes from 900000 to 1000000)
Prime 761533 found in Thread<11>(Checking primes from 700000 to 800000)
...
```

Every thread has specialized in a specific range; thread number 13 gets from 900K to 1000K, for instance. Working with threads is much more efficient, but a process needs to be pinned to a specific thread to do this. This is why low-level thread access is not really the best way to create a concurrent program. Working with [higher-level APIs](https://docs.raku.org/language/concurrency) make a lot of more sense.

However, in 2000 it was enough to have the insight that a thread engine was needed for a modern, 100-year language like Raku. And Bryan C. Warnock, who became famous because of the [Warnock's Dilemma](https://en.wikipedia.org/wiki/Warnock%27s_dilemma), had, if not the insight of the original idea, at least the laziness, impatience and hubris of putting it down in what eventually became the first RFC for Raku, 20 years ago today.

> The origin of Warnock's dilemma, according to Wikipedia, is pretty much in the same month, and actually originated in the [`bootstrap` (for perl6) mailing list](https://www.nntp.perl.org/group/perl.perl6.language/2003/05/msg15407.html). And it is totally related to the fact that the response to that RFC was underwhelming, which indicates that either no one cared, or it was just perfect. I tend to think the latter, so thanks, Bryan, for this.
