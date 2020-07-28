# RFC 1, by Bryan C. Warnock: Threads

It might ot might not be the case that the need for a real multithreaded architecture in Perl was the real motive behind the creation of what was initially called simply Perl, then Perl 6, and eventually [Raku](https://raku.org).

It was probably late 90s or early 10s, when we had a contract with a big company that needed to download stuff from the web really fast. We needed those threads, and they finally arrived in Perl 5.10. However, our threads were very basic, didn't need any kind of communication, just the bare parallel thing, and underneath them, operating system processes were used; there were no real *threads* at the Perl VM level. And they were sorely needed. Which is why [RFC1](https://raku.org/archive/rfc/1.html) read:

> Implementation of Threads in Perl

It was originally proposed in August 1th (hence the 20th aniversary thing), and finally *frozen* a couple of month later, by September 28th.

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

