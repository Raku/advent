RFC 43: Integrate BigInts (and BigRats) Support Tightly With The Basic Scalars

## Intro

TODO

## A legacy of imprecision

There is a dirty secret at the core of computing: most computations of reasonable complexity are imprecise. Specifically, computations involving floating point arithmetic have known imprecision _dynamics_ even while the imprecision _effects_ are largely un-mapped and under-discussed. 

The standard logic is that this imprecision is so small in it's _individual_ expression -- in other words, because the imprecision is so negligible when considered in the context of an individual equation it is taken for granted that the overall imprecision of the system is "fine."

Testing the accuracy of this gut feeling in most , however, would involve re-creating the business logic of that given system to use a different, more accurate representation for fractional values. This is a luxury that most projects do not get.

## Trust the data, not the handwaves

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

Larry, it seems, decided to focus on a different phrase in the stated problem: _"because double floats are at their heart a lie"._ In a radical break from the vastly dominant performance-first paradigm, it was decided that the core representation of fractional values would default to the most precise available -- regardless of the performance implications.

Perl always had a focus on "losing as little information as possible" when it came to your data. Scalars dynamically change shape and type based on what you put into them at any given time in order to ensure that they can hold that new value.

Perl also always had a focus on DWIM -- Do What I Mean. Combining DWIM with the "lose approximately nothing" principle in the case of division of numbers, Perl 6 would thus default to understanding your meaning to be a desire to have a precise fractional representation of this math that you just asked the computer to compute.

Likewise, Perl has also always had a focus on putting in curbs where other languages build walls. Nothing would force the user to perform their math at the "speed of rational" (to turn a new phrase) as they would have the still-essential `Num` type available.

In this sense, nothing was removed -- rather, `Rat` was added and the default behavior of representing parsed decimal values was to create a `Rat` instead of a `Num`. Many languages introduce rationals as a separate syntax, thus making precision opt-in (a la `1r5` in J). In Perl 6, the opposite is true -- those who want imprecision must opt-in instead.

## A visual example





[^1]: I say this because it implies that these are hardly the only two occasions where people have chosen an imprecise representation, have seen that imprecision manifest at significant scale, and have chosen to continue with the imprecise representation for mostly dubious reasons.
[^2]: To date I'm not aware of any other programming languages designed and implemented in the 21st century that have this "precision-first" approach. It apparently remains a controversial/unpopular choice in language design.