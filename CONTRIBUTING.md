# Contributing to the annual Perl 6 Advent

## Background

See current and previous Advent article entries
[here](https://perl6advent.wordpress.com/).

## Instructions

1. Get a Perl 6 Wordpress account from an admin on IRC #perl6
   (jmerelo, timotimo, moritz, ...).

2. Choose one or more empty day slots in the
   [Christmas 2019 schedule](perl6advent-2019/schedule).

3. Write your article using Github markdown.  **Note that it is
   recommended to have each paragraph in the markdown source file
   collapsed into one long line before using one of the html converter
   tools listed in the next step.  That is necessary in order to get
   the html formatting correct (Wordpress doesn't remove newlines
   inside html text content)**.

4. Convert the file to Wordpress html format using one of the two
   tools here (see para 3. for an important note before using one of
   these tools):

   * Perl 6 module Acme::Advent::Highlighter [may get errors]

   * [tools/p6advent-md2html.p6](tools/p6advent-md2html.p6) Execute it
     without an argument to see instructions.

5. Insert the converted file into Wordpress.

6. Schedule the article to be published at 00:01 (as configured on the
   Wordpress site) on its scheduled date.

**For detailed *Wordpress* instructions see
  [this](https://codex.wordpress.org/Posts#Best_Practices_For_Posting)
  article.**
