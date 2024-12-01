= Generating an HTML Dashboard With Vanilla Raku =

The goal of this post is to demonstrate some Raku features by accomplishing
something useful in about 100 lines of Raku. We're going to avoid using
libraries, and instead use only what's available to us in the core language.

Our task requires wrapping the GitHub CLI and generating an HTML dashboard.
We'll query the recently updated issues for some core Raku repositories,
parse the CLI's output into structured data, and write out templated HTML
to a file.

Along the way, we'll learn about

* Running a subprocess and capturing it's output
* Opening and writing to files
* String substitution
* Raku's quoting constructs

Raku is a powerful language with lots of syntax, so we will try to proceed
slowly, explaining each part of our script as we go. We will provide links 
to the official documentation where appropriate.

The repos we will be concerned with are

* https://github.com/raku/doc-website[raku/doc-website] - tools that generate HTML, CSS, and JavaScript
  for https://docs.raku.org[docs.raku.org], the official docs website 
* https://github.com/raku/doc[raku/doc] - content for the docs website 
* https://github.com/moarvm/moarvm[moarvm/moarvm] - virtual machine in C that Rakudo targets
* https://github.com/rakudo/rakudo[rakudo/rakudo] - flagship Raku implementation
* https://github.com/raku/nqp[raku/nqp] - the "not quite perl" intermediate representations

Let's get started.

=== Part 1: Calling Another Program ===

The command line utility we'll use is the GitHub CLI.

The GitHub CLI can fetch up to 1000 issues at a time with a command
like the following. 

----
gh issue list -R raku/doc-website --state closed,open --search 'sort:updated-desc'
----

We're only going to concern ourselves with 50, and sort
them by recently updated. We include the closed as well as the open issues,
because an issue being recently closed is important information for Raku
contributors.

The only argument we need to parameterize is `-R`. We have 5 repos we'll need to 
pass to `-R`, so lets make an array.

[source,raku]
----
my @repos = <<
  raku/doc-website
  raku/doc
  moarvm/moarvm
  rakudo/rakudo
  raku/nqp
>>;
----

Next, let's loop through that array and shell out to gh with the https://docs.raku.org/routine/run[run builtin subroutine].

[source,raku]
----
for @repos -> $repo {
  say "getting issues for $repo";
  run("gh", "issue", "list", "-R", "$repo", "--search", "sort:updated-desc", 
      "--limit", "50", "--state", "all");
}
----

This would be enough if we wanted to run this script locally and look at the
output in our own terminal, but we.


=== Part 2: Program Structure ===

To keep our script organized, we'll break it up into functions, or _subroutines_
as Raku calls them. For now we're going to leave some details out and focus on the
program's structure.

We'll start by defining `sub MAIN()`, a special subroutine that specifies the
entrypoint to our program. Yes, it's all caps.

[source,raku]
----
#!/usr/bin/env raku

sub MAIN() {
  # program starts here...
}
----

We can define another function `get-issues` that takes a repo name as a
parameter. We'll be calling this inside a loop. This function will call
`gh`, parse its output, and return structured data.

[source,raku]
----
sub get-issues($repo) {
  # encapsulate calling gh and parsing output
}
----

Finally, we'll create a `write-document` function that accepts an open
file handle and a hash of all the data we've gathered into memory.

[source,raku]
----
sub write-document($h, %data) {
  # Iterate our data and write it to a file handle
}
----

So far, I've avoided specifying types on either parameters or return
values. Raku allows gradual typing, and enforces types with a mix of
compile-time and run-time checks. We'll add some types later.


=== Part 3: Capturing Output ===

Let's explore the implementation of the `get-issues` function. We need
to capture the output of `gh`. Previously we shelled out like this.

[source,raku]
----
run("gh", "issue", "list", "-R", "$repo", "--search", "sort:updated-desc", 
    "--limit", "50", "--state", "all");
----

That dumps output to our terminal. Let's clean this up and capture the output.

[source,raku]
----
my @cmd-line = << gh issue list -R $repo --search "sort:updated-desc" --limit 50 --state "all" >>;  
my Proc $proc = run @cmd-line, :out;
----

Our `@cmd-line` variable uses the `<< >>` array style, which will still let us
interpolate `$repo`, but use space-separated elements.

Furthermore, we pass the `:out` symbolic parameter to `run`, which captures
the process' stdout.

And we also add the builtin class `Proc` as a type annotation. This is
for you, dear reader, to reinforce the fact that the `run` subroutine
returns a `Proc`.

Now it's time to do something with the output. The default output of 
`gh issue list` is newline-delimited. The `lines` method transforms our
output into an array of strings. One line of output for each issue.

[,raku]
----
my @lines = $proc.out.lines;
----

Each line of output looks like this.

----
4536	OPEN	Run and Edit examples	docs, wishlist	2024-12-01T00:04:33Z
----

Conveniently, the output is tab-delimited. 

Let's put it all together and finish our `get-issues` function.

[source,raku]
----
sub get-issues($repo) {

  my @cmd-line = << gh issue list -R $repo --search "sort:updated-desc" --limit 50 --state "all" >>;  
  my Proc $proc = run @cmd-line, :out;
  
  my @lines = $proc.out.lines;
  
  my @issues;
  
  for @lines -> $line {
    my @fields = $line.split("\t");
    my %issue = (
      id         => @fields[0].Int,
      status     => @fields[1],
      summary    => @fields[2], 
      tags       => @fields[3], 
      updated-at => DateTime.new(@fields[4])
    );
    @issues.push(%issue)
    # ignore any parsing errors and continue looping
    CATCH { next } 
  }

  return @issues;
}
----

To summarize, we shell out to `gh issue list`, loop through all the output,
and accumulate the data into an array of hashes. See the https://docs.raku.org/type/Hash[Hash]
documentation for all the wonderful ways to build and manipulate hashes.

For good measure, we've coerced `id` into an `Int`
(with an `.Int` method call) and parsed the `updated-at` date string into 
the builtin https://docs.raku.org/type/DateTime[DateTime type] (with the `new`
class constructor).

Back in our `MAIN`, we can make use of our fully-implemented `get-issues` routine.
For each $repo, we add to our `%data` object. 

[,raku]
----
my @repos = <<
  raku/doc-website
  raku/doc
  moarvm/moarvm
  rakudo/rakudo
  raku/nqp
>>;

my %data;

for @repos -> $repo {
   my @issues = get-issues($repo);
   %data{$repo} = @issues;
}
----

Our `%data` hash ends up with the keys being the repo name, and the associated
value is the array of issues for that repo.


=== Part 4: Rendering an HTML File ===

We have our data. Let's template it as HTML and write it to a file.

There are many ways to open a file in Raku, but they're all going
to give you back https://docs.raku.org/type/IO/Handle[an `IO::Handle` object].

For no particular reason, we'll use the https://docs.raku.org/type/independent-routines#sub_open[standalone builtin `open`].
The `:w` symbol here will open the file for writing, and truncate the
file if it already exists.

[,raku]
----
my $filename = "report.html";
my $fh = open $filename, :w;
write-document($fh, %data)
$fh.close;
----

Actually, on second thought, let's spice things up. We can do the same thing but 
use https://docs.raku.org/syntax/given[given], which lets us avoid naming our
file handle, and instead access it as the https://docs.raku.org/language/variables#The_$__variable[topic variable $_]. 

[,raku]
----
given open $filename, :w {
   write-document($_, %data);
   .close
}
----

All that's left to do is implement `write-document`.

The responsibility of our `write-document` routine is to write html to a
file, and there are several ways of writing to a file. We will use
the standalone https://docs.raku.org/type/independent-routines#sub_spurt[spurt routine].
The first argument to `spurt` will be our `IO::Handle` to the open
file, and the second argument will be strings, our fragments of
templated HTML.

Since the start of our HTML document is a fairly long string, we can
use https://docs.raku.org/language/quoting[HEREDOC style quoting].
The various quoting constructs that Raku provides give us much
of the power of string templating languages without requiring
and additional libraries.

[,raku]
----
# document start
spurt $h, q:to/END/;
<!DOCTYPE html>
<html lang="en">
<head>
    <title>Issues in Raku core</title>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <meta name="robots" content="noindex">
    <link rel="stylesheet" href="https://envs.net/~coleman/css/style.css"/>
    <link rel="stylesheet" href="https://envs.net/css/fork-awesome.min.css"/>
</head>
<body id="body" class="dark-mode">
END
----

Everything between `q:to/END` and the closing `END` is treated as a single
string argument to `spurt`. We used the `q:to` form since we didn't need 
to interpolate any variables.

When we _do_ need to interpolate variables, we can use the `qq:to` form and
wrap our variables in curly brackets.

Let's loop through our nested `%data` hash to fill out the templated middlep
part of our HTML document. We'll see `qq:to` and data interplolation in action.

[,raku]
----
for %data.kv -> $repo, @issues {
  spurt $h, qq:to/END/;
  <section>
      <h1>{$repo}</h1>
      <details open>
      <summary>Most recent issues (show/hide)</summary>
  END
  
  for @issues -> %issue {
    # destructure values from %issue
    my ($issue-number, $summary, $status) = %issue<id summary status>; 
   
    # HTML escape (minimal)
    # & becomes &amp;
    # < becomes &lt;
    # > becomes &gt;
    $summary.=subst(/ '&' /, '&amp;'):g;
    $summary.=subst(/ '<' /, '&lt;'):g;
    $summary.=subst(/ '>' /, '&gt;'):g;

    spurt $h, qq:to/END/;
        <div class="issue-container">
            <div class="issue-id"><a href="https://github.com/{$repo}/issues/{$issue-number}">{$issue-number}</a></div>
            <div class="issue-summary">{$summary}</div>
            <div class="issue-status">{$status}</div>
        </div>
    END
  } 

  # Section end
  spurt $h, q:to/END/;
          </details>
      </section>
      <hr/>
  END
}
----

We also did a little bit of HTML escaping on the `$summary` string. Note that 
the `.=` is an in-place modification of the `$summary` string, 
using https://docs.raku.org/type/Str#method_subst[method call assignment].
Every `Str` has a `subst` method, and we're just calling that and assigning
to ourselves in one go. The reason we need to do that is to escape some
characters that will frequently appear in issue summaries, but are bad news
for rendering to HTML. This isn't a totally injection-safe solution, but it's
good enough for our purposes.

Finally we can end our `write-document` routine with closing tags.

[,raku]
----
# footer
spurt $h, q:to/END/;
    </body>
</html>
END
----

== Conclusion ==

I've published the results at https://envs.net/~coleman/raku/report.html

To keep something like this up to date, we will need to use `cron`, systemd timers,
or some other scheduler, but that's beyond our scope here.


