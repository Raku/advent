#!/usr/bin/env raku


multi sub MAIN() {

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
  
  my $filename = "report.html";
  given open $filename, :w {
     write-document($_, %data);
     .close
  }
}

sub get-issues($repo) {

  my @cmd-line = << gh issue list -R $repo --search "sort:updated-desc" --limit 50 --state "all" >>;  
  my Proc $proc = run @cmd-line, :out;
  
  my @lines = $proc.out.lines;
  
  my @data;
  
  for @lines -> $line {
    my @fields = $line.split("\t");
    my %issue = %(
      id         => @fields[0].Int,
      status     => @fields[1],
      summary    => @fields[2], 
      tags       => @fields[3], 
      updated-at => DateTime.new(@fields[4])
    );
    @data.push(%issue);
    # ignore any parsing errors and continue looping
    CATCH { next } 
  }

  return @data;
}

sub write-document(IO::Handle $h, %data) {

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
  
  # Template one section for each repo
  for %data.kv -> $repo, @issues {

    spurt $h, qq:to/END/;
    <section>
        <h1>{$repo}</h1>
        <details open>
        <summary>Most recent issues (show/hide)</summary>
    END
    
    # Template issues for this section
    for @issues -> %issue {
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
  
    spurt $h, q:to/END/;
            </details>
        </section>
        <hr/>
    END
  }

  # End of HTML document
  spurt $h, q:to/END/;
      </body>
  </html>
  END
}


