# Contributing to the annual Raku Advent calendar

## Background

See current and previous Advent article entries
[here](https://perl6advent.wordpress.com/) and [here](https://raku-advent.blog).

## Instructions

1. Get a Raku Wordpress account from an admin on IRC #raku or #raku-dev
   (jmerelo, timotimo, moritz, tbrowder ...).

2. Write your article using Github Markdown.  **Note that it is
   recommended to have each paragraph in the markdown source file
   collapsed into one long line before using one of the html converter
   tools listed in the next step.  That is necessary in order to get
   the html formatting correct (Wordpress doesn't remove newlines
   inside html text content)**.

   * An easier way is to write the article in Raku Pod, then transform
     it to Markdown by using Raku's built-in converter.
     A great advantage of this method is multiple lines in
     paragraphs are collapsed into single lines automatically.

     ~~~
     $ raku --doc=Markdown my-article.pod > my-article.md
     ~~~ 

3. Convert the file to Wordpress html format using one of the two
   tools here (see para 2 for an important note before using one of
   these tools). The first method is currently the easiest
   to use and gives much better results.

   * Raku module **Acme::Advent::Highlighter** See intructions at its
     repository [here](https://github.com/raku-community-modules/Acme-Advent-Highlighter).
     Note the html output has two embedded html comments telling the
     user where to delete lines before inserting the remainder into
     Wordpress.

   * [tools/raku-advent-md2html.raku](tools/raku-advent-md2html.raku) Execute it
     without an argument to see instructions.

4. Insert the converted file into Wordpress.

5. When your article is ready for publication, you can announce it
   on the IRC \#raku channel and someone with the proper credentials
   will schedule its live publication at the proper time.

**For detailed *Wordpress* instructions see
  [this](https://wordpress.org/support/article/writing-posts)
  article.**
