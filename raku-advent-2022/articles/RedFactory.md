# RedFactory

Recently I had the experience of playing with Ruby and its tools. One of the tools I liked to learn about was `factory_bot`.

`factory_bot`as its documentation says is:

> a framework and DSL for defining and using factories - less error-prone, more explicit, and all-around easier to work with than fixtures.

Instead of having a static collection of rows on your test database that's hard to remember while you are writing/reading the tests you just dynamicaly create your needed rows inside your test setting only the columns you need to test, much more explicity.

I like that concept. Factories being more explicit than fixtures makes it much simpler to read and understand tests. Wouldn’t that be great to have something like that for Raku? So now we do! 😄

`Red` is an ORM for Raku and now there is `RedFactory`, a factory for `Red`!

With `RedFactory`you can pre-configure some factories to each of your models setting default values for its attributes. For configuring a factory you use the `factory` function, it receives the factory name, the model this factory should be using as a named parameter and a block that will receive as only parameter a `Factory` object to be configured.

```raku
factory “post”, :model(Post), {
  ...
}
```

That factory object will have the same attributes your model has. And those attributes will be used to set the default values.

```raku
factory “post”, :model(Post), {
   .title = "my post title";
   .body  = "my post body";
}
```

And now, if you use your “post” factory without passing any additional argument (`factory-create "post"`) it will return a new Post object where title will be “my post title” and its body will be “my post body”.  But if you are testing something that need a specific title you can override it on your factory call: `factory-create "post", :title("my specific title")`and it will use that.

But where is it creating that? It’s using your pre-defined `$*RED-DB`or a `red-defaults`. But you would have to create the table by yourself. RedFactory has a tool for helping you with that, you can just do:

```raku
my $*RED-DB = factory-db;
```

And that will set a `Red`to use an in-memory `SQLite`as database and automatically create the needed tables to you. Another option would be using `factory-run`that accepts a block that receives `RedFactory`as only parameter (that has smaller versions of the `factory-...` functions as methods. So:

```red
my $*RED-DB = factory-db;
my $post = factory-create "post";
...
```

can also be done like:

```raku
factory-run {
   my $post = .create: "post";
   ...
}
```

The factory attributes can also receive a block to make the value dynamic, for example:

```raku
factory "post", :model(Post), {
    .title = {
        "Post title { .counter-by-model }"
    }
    .body  = -> $_, :$title-repetition = 3 {
        (.title ~ "\n") x $title-repetition
    }
}
```

That could generate:

```raku
factory-run {
   .create: "post";
   # Post.new: :title("Post title 1"), :body("Post title 1\nPost title 1\nPost title 1\n")
   .create: "post";
   # Post.new: :title("Post title 2"), :body("Post title 2\nPost title 2\nPost title 2\n")
   .create: "post", :title<aaa>;
   # Post.new: :title("aaa"), :body("aaa\naaa\naaa")
   .create: "post", :title<a>, :PARS{ :5title-repetition };
   # Post.new: :title("a"), :body("a\na\na\na\na\n")
}
```

Being `PARS` all arguments you want to pass to your factory that’s not an model, for example to express how many times to repeat the title to create the body.

If you want a factory that has some differences from another one, you can specialise that. For example:

```raku
factory "post", :model(Post), {
    .title = {
        "Post title { .counter-by-model }"
    }
    .body  = -> $_, :$title-repetition = 3 {
        (.title ~ "\n") x $title-repetition
    }
    
    factory "post-with-long-title", {
       .title x= 20
    }
}
```

In that case, `post-with-long-title` will use
the outside factory's default, (for example
"Post title 42") and repeat it 20 times as 
that factory's title default value.

There is also the option of creating traits
for handling other options, for example if we
add a Instant attribute for representing when/if
a post was archived:

```raku
factory "post", :model(Post), {
    .title = {
        "Post title { .counter-by-model }"
    }
    .body  = -> $_, :$title-repetition = 3 {
        (.title ~ "\n") x $title-repetition
    }

    trait "archived", {
      .archived = now
    }
}
```

You still can set the archived value passing
It as a named argument for the factory's create.
But using traits is a good option because using it
The users don't "need to know" how the archiving
works, they just needs a archived post and the
trait prepare it for them. And that logic could
involve many more attributes that only one.

And you can use that like:

```raku
factory-run {
  .create: "post", "archived"
}
```

`.create` and `factory-create` inserts the created objects into the database
but if you just wants the object and not to include that on the database
you should use `.manufacture` and `factory-manufacture`. And using those methods
make it possible to use RedFactory as a factory of any Raku class.

For helping, getting help or anything else, RedFactory is here: https://github.com/FCO/RedFactory
