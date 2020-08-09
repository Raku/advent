## Intro

RFC 43, titled ['Integrate BigInts (and BigRats) Support Tightly With The Basic Scalars'](https://raku.org/archive/rfc/43.html) was submitted by Jarkko Hietaniemi  on 5 August 2000. It remains at version 1 and was never frozen during the official RFC review process.

Despite this somewhat "unoffical" seeming status, the rational (or `Rat`) numeric type sits at the very core of the [Raku](https://raku.org) programming language today.

## A legacy of imprecision

There is a dirty secret at the core of computing: most computations of reasonable complexity are imprecise. Specifically, computations involving floating point arithmetic have known imprecision _dynamics_ even while the imprecision _effects_ are largely un-mapped and under-discussed. 

The standard logic is that this imprecision is so small in it's _individual_ expression -- in other words, because the imprecision is so negligible when considered in the context of an individual equation it is taken for granted that the overall imprecision of the system is "fine."

Testing the accuracy of this gut feeling in most , however, would involve re-creating the business logic of that given system to use a different, more accurate representation for fractional values. This is a luxury that most projects do not get.

## Trust the data, question the handwaves

What could be much more worrisome, however, is the failure rate of systems that _do_ attempt the conversion. In researching this topic I almost immediately encountered third party anecdotes. Both come from a single individual and arrived withing minutes of broaching the floating point imprecision question.[^1]

One related the unresolved issue of a company that cannot switch their accounting from floating point to integer math -- a rewrite that must necessarily touch every equation in the system -- without "losing" money. Since it would "cost" the company too much to compute their own accounting accurately, they simply don't.

Another anecdote related the story of a health equipment vendor whose equipment became less effective at curing cancer when they attempted to migrate from floating point to arbitrary precision.

In a stunning example of an exception that just might prove the rule of "it's a feature, not a bug", it turned out that the tightening up of the equation ingredients resulted in a less effective dose of radiation _because the floating point was producing systemic imprecisions that made a device output radiation beyond it's designed specification._

In both cases it could be argued that the better way to do things would be to re-work the systems so that expectations matched reality. I do have much more sympathy for continued use of the life-saving imprecision than I do for a company's management to prefer living in a dream world of made up money than actually accounting for themselves in reality, though.

In fact, many financing and accounting departments have strict policies banning floating point arithmetic. Should we really only be so careful when money is on the line?

## Precision-first programming

It is probably safe to say that when Jarkko submitted his RFC for native support high-precision `bigint`/`bigrat` types that he didn't necessarily imagine that his proposal might result in the adoption of "non-big" rats (that it is, arbitrary precision rationals shortened into typically playful Perl-ese) as the default fractional representation in Perl 6.[^2]

Quoting the thrust of Jarkko's proposal, with emphasis added:

> Currently Perl 'transparently' starts using double floating point numbers when the numeric values grow too large for the native integer types (int, long, quad) can no more hold quantities that large. Because double floats are at their heart a lie, they cannot truly represent large numbers accurately. Therefore _sometimes when the application would prefer to stay accurate,_ the use of 'bigints' (and for division, 'bigrats') would be preferable.

Larry, it seems, decided to focus on a different phrase in the stated problem: _"because double floats are at their heart a lie"._ In a radical break from the dominant performance-first paradigm, it was decided that the core representation of fractional values would default to the most precise available -- regardless of the performance implications.

Perl always had a focus on "losing as little information as possible" when it came to your data. Scalars dynamically change shape and type based on what you put into them at any given time in order to ensure that they can hold that new value.

Perl also always had a focus on DWIM -- Do What I Mean. Combining DWIM with the "lose approximately nothing" principle in the case of division of numbers, Perl 6 would thus default to understanding your meaning to be a desire to have a precise fractional representation of this math that you just asked the computer to compute.

Likewise, Perl has also always had a focus on putting in curbs where other languages build walls. Nothing would force the user to perform their math at the "speed of rational" (to turn a new phrase) as they would have the still-essential `Num` type available.

In this sense, nothing was removed -- rather, `Rat` was added and the default behavior of representing parsed decimal values was to create a `Rat` instead of a `Num`. Many languages introduce rationals as a separate syntax, thus making precision opt-in (a la `1r5` in J). In Perl 6, the opposite is true -- those who want imprecision must opt-in instead.

## A visual example thanks to a matrix named Hilbert

In pursuit of a nice example of programming concerns solved by arbitrary precision rationals  that are a bit less abstract than the naturally unfathomable "we have no _actual_ idea how large the problem of imprecision is in effect on our individual systems let alone society as a whole", I came across the excellent presentation from 2011 by Roger Hui of Dyalog where he demonstrates a development version of Dyalog APL which included rational numbers.

In his presentation he uses the example of Hilbert matrices, a very simple algorithm for generating a matrix that is notorious for the difficulty of getting a "clean" identity matrix (don't worry, the upcoming visual examples should make this clear enough to us non-experts in matrix algebra). 

Here is the (very) procedural for generating our Hilberts for comparison (full script in [this gist](https://gist.github.com/ab5tract/3e25e4a2ce63a349b7eb4601a85b6993#file-rationale-matrique-raku)):[^3]

```
my %TYPES = :Num(1e0), :Rat(1);
subset FractionalRepresentation of Str where {%TYPES{$^t}:exists};
sub generate-hilbert($n, $type) {
    my @hilbert = [ [] xx $n ];
    for 1..$n -> $i {
        for 1..$n -> $j {
            @hilbert[$i-1;$j-1] = %TYPES{$type} / ($i + $j - 1);
        }
    }
    @hilbert
}
```

One of the most important aspects of having rationals as a first-class member of your numeric type hierarchy is that only extremely minimal changes are required of the math to switch between rational and floating point.

There is a danger, as Roger Hui notes in both his video and in a follow-up email to a query I sent about "where the rationals" went, that rational math will seep out into your application and unintentionally slow everything down. This is a valid concern that I will return to in just a bit.


### Floating Hilbert

Here are the results of the floating point dot product between a Hilbert and it's inverse -- an operation that generally reseults in an identity matrix (all 0's except for a straight diagonal of 1's from the top left corner down to the bottom right).

```
Floating Hilbert
         1       0.5  0.333333      0.25       0.2
       0.5  0.333333      0.25       0.2  0.166667
  0.333333      0.25       0.2  0.166667  0.142857
      0.25       0.2  0.166667  0.142857     0.125
       0.2  0.166667  0.142857     0.125  0.111111
 
Inverse of Floating Hilbert
     25    -300     1050    -1400     630
   -300    4800   -18900    26880  -12600
   1050  -18900    79380  -117600   56700
  -1400   26880  -117600   179200  -88200
    630  -12600    56700   -88200   44100

Floating Hilbert ⋅ Inverse of Floating Hilbert
            1             0            0             0            0
            0             1            0  -7.27596e-12  1.81899e-12
  2.84217e-14  -6.82121e-13            1  -3.63798e-12            0
  1.42109e-14  -2.27374e-13  2.72848e-12             1            0
            0  -2.27374e-13  9.09495e-13  -1.81899e-12            1

```

All those tiny floating point values are "infinitisemal" -- yet some human needs to choose at what point of precision we determine the cutoff. Since we "know" that the inverse dot product is supposed to yield an identity matrix for Hilberts, we can code our algorithm to translate everything below `e-11` into zeroes.

But what about situations that aren't so certain? Some programmers undoubtedly write formal proofs of the safety of using a given cutoff -- however I doubt any claims that this population represents a significant subset of programmers based on lived experience.

### Rational Hilbert

With the rational representation of Hilbert, it's a lot easier to see what is going on with the Hilbert algorithm as the pattern in the rationals clearly evokes the progression. This delivers an ability to "reason backwards" about the numeric data in a way that is not quite as seamless with decimal notation of fractions.[^4]

```
Rational Hilbert
    1  1/2  1/3  1/4  1/5
  1/2  1/3  1/4  1/5  1/6
  1/3  1/4  1/5  1/6  1/7
  1/4  1/5  1/6  1/7  1/8
  1/5  1/6  1/7  1/8  1/9

Inverse (same output, trimmed here for space)

Rational Hilbert ⋅ Inverse of Rational Hilbert
  1  0  0  0  0
  0  1  0  0  0
  0  0  1  0  0
  0  0  0  1  0
  0  0  0  0  1
```

Notice the lack of ambiguity in both the initial Hilbert data set and the final output of the inverse dot product 


[^1]: I say this because it implies that these are hardly the only two occasions where people have chosen an imprecise representation, have seen that imprecision manifest at significant scale, and have chosen to continue with the imprecise representation for mostly dubious reasons.
[^2]: To date I'm not aware of any other programming languages designed and implemented in the 21st century that take this same "precision-first" approach. It apparently remains a controversial/unpopular choice in language design.
[^3]: 
	This is called from inside some glue that sepearates the timings and type cheacking from the underlying details.

	```
	sub inner-hilbert(Int $n, FractionalRepresentation $type, $show-timings) {
    	my $start = DateTime.now;
    	my $hilbert = Math::Matrix.new: generate-hilbert($n,$type);
		say "Created '$type' Hilbert of {$n}x{$n}: {DateTime.now - $start}s"
        	if $show-timings;
    	$hilbert
	}
	```
[^4]: I patched a local version of `Math::Matrix` to print it's rationals always as fractions, so your output will look different for the rational Hilbert (ie the same as fractional Hilbert) if you end up running the code in this [gist](https://gist.github.com/ab5tract/3e25e4a2ce63a349b7eb4601a85b6993#file-rationale-matrique-raku).