#!/usr/bin/env perl6
use v6;
use LWP::Simple;

# from the original script from Zoffix, November 2017

#| Converts a github gist to Advent calender format
#| Works best when the text paragraphs are one line,
multi sub MAIN(
    Str $gist-url,          #= URL of gist to download and modifiy
    Str $out='advent.html'  #= Filename to write output to (defaults to "advent.html")
) {
    $out.IO.spurt(get-html($gist-url));

    say "See output file '$out'";
}

sub get-html($gist-url) {
    return LWP::Simple.get($gist-url)
    .comb(/'<article' <-[>]>+ '>' <(.+?)> '</article>'/)
    .subst(:g, 'class="pl-c"',   'style="color: #999;"')
    .subst(:g, 'class="pl-c1"',  'style="color: #449;"')
    .subst(:g, 'class="pl-k"',   'style="color: blue;"')
    .subst(:g, 'class="pl-pds"', 'style="font-weight: bold;"')
    .subst(:g, 'class="pl-s"',   'style="color: #994;"')
    .subst(:g, 'class="pl-smi"', 'style="color: #440;"')
    .subst(:g,
        '<pre>',
        '<pre style="font-size: 14px; font-family: monospace">'
    );
}
