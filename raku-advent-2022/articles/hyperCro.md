# `.hyper` and `Cro`
## or How (not) to pound your production server

(and to bring on the wrath of the Ops)

## the problem

So, suppose you have:

1. a lot (half a million) records in a `.csv` file, to be entered in your database;
2. a database only accessible via a not-controlled-by-you API;
3. said API takes a little bit more than half a second per record;
4. some consistency checks must be done before sending the records to the API; but
5. the API is a "black box" and it may be more strict than your basic consistency checks;
6. tight schedule (obviously)

## the solution

### the prototype: `Text::CSV` and `HTTP::UserAgent`

So, taking half a second per record just in the HTTP round-trip is **bad**, very bad (34 hours for the processing of the whole dataset).

```raku
sub read-csv(IO() $file) {
  gather {
    my $f = $file.open: :r :!chomp;
    with Text::CSV.new {
      .header: $f, munge-column-names => { S:g /\W+//.samemark('x').lc };
      while my $row = .getline-hr: $f { take $row }
    }
  }
}

sub csv-to-yaml(@line --> Str) 
  # secret sauce
  my %obj = do { ... };
  to-yaml %obj
}

sub server-put($_) {
  # HTTP::UserAgent
}

sub MAIN(Str $input) {
  my @r = lazy read-csv $input;
  server-login;
  server-put csv-to-json $_ for @r
}
```

### `.hyper`ize it

Let's try to make things move faster...

```raku
sub MAIN(Str $input) {
  my @r = lazy read-csv $input;
  server-login;
  react {
    whenever supply {
        .emit for @r.hyper(:8degree, :16batch)
          .map(&csv-to-yaml)
      } {
        server-post $_
    }
  }  
}
```

Yeah, but HTTP::UserAgent does not paralelyze very nicely...

### `Cro::HTTP` to the rescue

```raku
sub server-login() {
  my Lock \l .= new;
  our $cro;
  l.protect: {
    my $c = Cro::HTTP::Client.new:
      base-uri => SERVER-URL,
      content-type => JSON,
      user-agent => 'honking/2022.2.1',
      timeout => %(
        connection => 240,
        headers => 480,
      ),
      cookie-jar => Cro::HTTP::Client::CookieJar.new,
      ;
    await $c.post: "{SERVER-URI}/{SESSION-PATH}", body => CREDENTIALS
    $cro = $c
  }
  $cro
}

sub server-post($data) {
  our $cro;
  my $r = await $cro.post: "{SERVER-URI}/{DATA-PATH}", body => $data;
  await $r.body
}
```

Nice, but I ran the thing on a testing database and... oh, no... lots of `503`s and eventually a `401` and the connection was lost. 

```raku
constant NUMBER-OF-RETRIES = 3; # YMMV
constant COOLING-OFF-PERIOD = 2; # this is plenty to stall this thread

sub server-post($data) {
  our $cro;
  do {
    my $r = await $cro.post: "{SERVER-URI}/{DATA-PATH}", body => $data;
    my $count = NUMBER-OF-RETRIES;
    while $count-- and $r.status == 503|401 {
      sleep COOLING-OFF-PERIOD;
      server-login if $r.status == 401;
      $r = await $cro.post: "{SERVER-URI}/{DATA-PATH}", body => $data;
    }
    await $r.body
  }
}
```

Oh, it ran *almost* to the end of the data (and it's **fast**), but... we are getting some `409`s for some records where our `csv-to-json` is not smart enough, we can ignore those records. **And** some timeouts.

```raku
sub format-error(X::Cro::HTTP::Error $_) {
  my $status-line = .response.Str.lines.first;
  my $resp-body = do { await .response.body-blob }.decode;
  my $req-method = .request.method;
  my $req-target = .request.target;
  my $req-body = do { await .request.body-blob }.decode;
  "ERROR $status-line WITH $resp-body FOR $req-method $req-target WITH $req-body"
}

sub server-post($data) {
  our $cro;
  do {
    my $r = await $cro.post: "{SERVER-URI}/{DATA-PATH}", body => $data;
    my $count = NUMBER-OF-RETRIES;
    while $count-- and $r.status == 503|401 {
      sleep COOLING-OFF-PERIOD;
      server-login if $r.status == 401;
      $r = await $cro.post: "{SERVER-URI}/{DATA-PATH}", body => $data;
    }
    await $r.body
  }
  
  CATCH {
    when X::Cro::HTTP::Client::Timeout {
      note 'got a timeout, cooling off for a little bit more';
      sleep 5 * COOLING-OFF-PERIOD;
      server-login
    }
    when X::Cro::HTTP::Error {
      note format-error $_
    }
  }
}
```

## the result

So, now the whole process goes smoothly and finishes in 20 minutes, *circa* **100x** faster.

Import the data in production... similar results. The process is ongoing, 15 minutes in, the Ops comes (in person):

> **Why** is the server load triple the normal and the number of `5xx` is thru the roof?

>> just five more minutes, check the ticket XXX, closing it now...

> (uninteligbile noises)

And this is the story of how to import half a million records, that would take two whole days to be imported, in twentysome minutes. The whole ticket took less than a day's work, start to finish.