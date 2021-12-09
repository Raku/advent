# Contributing to the annual Raku Advent calendar

## Background

See current and previous Advent article entries
[here](https://perl6advent.wordpress.com/) and [here](https://rakuadventcalendar.wordpress.com).

## Instructions

1. Get a Raku Wordpress account from an admin on IRC #raku or #raku-dev
   (jmerelo, timotimo, moritz, tbrowder ...).

2. Write your article using Github markdown.  **Note that it is
   recommended to have each paragraph in the markdown source file
   collapsed into one long line before using one of the html converter
   tools listed in the next step.  That is necessary in order to get
   the html formatting correct (Wordpress doesn't remove newlines
   inside html text content)**.

3. Convert the file to Wordpress html format using one of the two
   tools here (see para 2 for an important note before using one of
   these tools):

   * Raku module Acme::Advent::Highlighter

   * [tools/p6advent-md2html.p6](tools/p6advent-md2html.p6) Execute it
     without an argument to see instructions.

4. Insert the converted file into Wordpress.

5. When your article is ready for publication, you can announce it
   on the IRC \#raku channel and someone with the proper credentials
   will schedule its live publication at the proper time.

**For detailed *Wordpress* instructions see
  [this](https://wordpress.org/support/article/writing-posts)
  article.**
