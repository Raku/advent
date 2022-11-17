# Santa and the Rakupod Wranglers

Santa's world was increasingly going high-tech, and his IT department was polishing off its new process that could take the millions of letters received from boys and girls around the world, scan them into digital form with state-of-the-art optical character recognition hardware, and produce outputs that could greatly streamline the Santa Corporation's production for Christmas delivery.

One problem had initially stymied them, but consultants from the Raku community came to their aid. (As you may recall, IT had become primarily a Raku shop because of the power of the language for all their programming needs ranging from shop management to long-range planning.)

The problem was converting the digital output from the OCR hardware to final PDF products for the factories and toy makers. The growing influence of [https://github.com](https://github.com) and its Github-flavored Markdown format had resulted in IT's post-OCR software converting the text into that format.

That was fine for initial use for production planning, but for archival purposes it lacked the capability to provide textual hints to create beautiful digital documents for permanent storage. The Raku consultants suggested converting the Markdown to Rakupod which has as much potential expressive, typesetting power as Donald Knuth's TeX and its descendants (e.g., Leslie Lamport's LaTex, ConTeXt, and XeTeX). As opposed to those formats, the product is much easier to scan visually and, although current Raku products are in the early stages of development, the existing Rakupod-to-PDF process can be retroactively improved by modifying the existing Rakupod when future products are improved.

Side note: Conversion between various digital document formats has been a fruitful arena for academics as well as developers. Raku already has excellent converters from Rakupod to:

  * Textfancy-advent1.md

  * Markdown

  * HTML

Other non-Raku converters include [https://pandoc.org](Pandoc) and [https://sphinx-doc.org](Sphinx) which strive to be *universal* converters with varying degrees of fidelity depending upon the input or output formats chosen.

But back to the immediate situation: getting Markdown transformed to PDF.

The first step is made possible through use of Anton Antonov's **Markdown::Grammar:ver<0.4.0>** module. The code for that is shown here:

```raku
use Markdown::Grammar:ver<0.4.0>;
my $markdown-doc = "poem.md";
my $pod-doc      = "poem.rakudoc";
$pod-doc = from-markdown $markdown-doc, :to("pod");
```

The second step is Rakupod to PDF, but that step can be further broken down into two major paths:

  * Transform Rakupod to PDF directly

  * Transform Rakupod to PostScript

    * Transform PostScript to PDF (ps2pdf)

Santa's IT group decided, given the current state of Raku modules, one of the easiest ways is to use David Warring's modules `Pod::Lite` and the very new module `Pod::To:PDF::Lite` for the direct transformation. That module has encapsulated the huge, low-level collection of PDF utility routines into an easier-to-use interface to get typesetting quality output. (Note David is actively improving the module so keep an eye out for updates.)

But that route has a bump in the road: `PDF::Lite` requires the user to provide the `$=pod` object (technically it is the root node of a Raku tree-like sructure). That is easy if you're calling it inside a Raku program, but not if you're trying to access it from another program or module. Thus comes a new Raku module to the rescue. The clever algorithm that makes that possible is due to the Raku expert Vadim Belman (AKA @vrurg), and it has been extracted for easy use into a new module **RakupodObject**.

So, using those three modules, we get the following code:

```raku
use Pod::To::PDF::Lite;
use Pod::Lite;
use RakupodObject;
my $pod-object = rakupod2object $pod-doc;
```

IT used the module in its wrapper program and added some convenience input options. Raku is used World-wide so they allowed for various paper sizes and provide settings for US Letter and A4. Finally, they provided some other capabilities by customizing the `PDF::Lite` object after the base document was created:

  * Combine multiple documents into a single one

  * Provide a cover and a title for the unified document

  * Provide a unified set of page numbers for the unified document

```raku

```

Finally, a prettier version of PDF is produced. More features could be added with more detailed, but more complex, processing with other `PDF::*` modules, but that project is for another day--Santa's archivist Elves are happy for now!

And the product is a present from Santa to all the Raku-using folks around the world: the two-part article from Tony O'Dell (AKA @tony-o) for creating an Apache website with Jonathon's Raku `Cro` libraries! (See the original posts at [https://deathbykeystroke.com/articles/20220224-building-a-cro-app-part-1.html](Part1) and [https://deathbykeystroke.com/articles/20220923-building-a-cro-app-part-b.html](Part2).)

Santa's Epilogue
----------------

Don't forget the "reason for the season:" ✝

As I always end these jottings, in the words of Charles Dickens' Tiny Tim, "**may God bless Us , Every one!**" [1]

Footnotes
---------

1. *A Christmas Carol*, a short story by Charles Dickens (1812-1870), a well-known and popular Victorian author whose many works include *The Pickwick Papers*, *Oliver Twist*, *David Copperfield*, *Bleak House*, *Great Expectations*, and *A Tale of Two Cities*.

