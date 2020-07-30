## RFC 5, by  Michael J. Mathews: Multiline comments

This is the first [RFC](https://raku.org/archive/rfc/5.html) proposed related to documentation. It asks for a common feature in most of the modern programming languages: multiline comments.

The problem of not having multi-line comments is quite obvious: if you need to comment a large chunk of code, you need to manually insert a `#` symbol at the beginning of every line (in `Raku`). This can be incredibly tedious if you do not have, for instance, a text editor to do this with a shortcut or similar. This practice is very common in large code bases. For that reason, Michael refers to `C++` and `Java` as

> popular languages that were designed from the outset as being useful for large projects, implementing both single line and multiline comments

In those languages you can type comments as follows:

~~~c++
// single line of code

/*
 Several lines of code
*/
~~~

But, in addition, in `Java` you have a special *multiline comment syntax* [^1] for writing documentation:

~~~java
/**
* Here you can write the doc!
*
*/
~~~

A lot of people proposed `POD` as a solution to this problem, but Michael lists some inconvenients:

- "it's not intuitive": given that `POD` is only used by `Perl`, people coming from different languages will face some struggles learning an entire new syntax.

  From my point of view, this not as big a problem since `POD6` syntax is quite simple and it's well [documented](https://docs.raku.org/language/pod). In addition, it is quite intuitive for newcomers: if you want a header, you use `=head1`, if you want italics, you use `I<>` and so on.

- "it's not documentation": this one is still true. The main problem is that when you want to comment a big chunk of code, that's probably not documentation, so using `=begin pod ... =end pod` it's a little weird.

- "it doesn't encourage consistency": another problem of `POD` is that you can use arbitrary terms in its syntax:

  ~~~raku
  =begin ARBITRARYTEXT
  ...
  =end ARBITRARYTEXT
  ~~~

  While this behavior gives us a lot freedom, it also complicates consistency across different projects and users.

After some discussion, `Perl` chose `POD` for implementing multiline comments. Nonetheless, Michael proposal was taken into account and `Raku` supports multiline comments similar to those of `C++` and `Java`, but with a slightly different syntax:

~~~raku
#`[
Raku is a large-project-friendly
language too!
]
say ":D";
~~~

And as a curiosity, `Raku` has *embedded comments*, that is:

~~~raku
if #`( embedded comment ) True {
    say "Raku is awesome";
}
~~~

In the end, as a modern, 100-year language, `Raku` gives you more than one way to do it, so choose whatever fits you best!

[^1]: It's not really a multiline comment because you also need to type the _*_ symbol at the beginning of every line.