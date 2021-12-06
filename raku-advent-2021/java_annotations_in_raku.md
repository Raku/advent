## Java Annotations in Raku

Today, a little about the fact that the new is better absorbed through the already known. It so happened that I write for $dayjob in Java, so I will come from this side. Java 1.5 introduces an interesting syntactic form - [annotations](https://docs.oracle.com/javase/tutorial/java/annotations/). It looks something like this:

```java
/**
 * @deprecated use #getId() method instead
 */
@Override
public String getName() {
  return "stub";
}
```

The example shows an annotation [`@Deprecated`](https://docs.oracle.com/javase/8/docs/api/java/lang/Deprecated.html) that causes the runtime to print a warning to the console every time the `getName` method is used. In addition, explanatory information has been added to the Javadoc.

In general, annotations in Java are a mechanism for adding some metadata to classes, objects, types, etc., which can be used later at the stage of compilation, execution, or static analysis of the code. With the help of them, for example, it is possible to implement a code decoupling strategy - so that some program components work together with others, without having a rigid connection. This strategy builds the on idea of [Inversion of Control](https://en.wikipedia.org/wiki/Inversion_of_control) and is the core of the [Spring library](https://spring.io).

But that's enough Java. What is similar to the annotation engine in Raku? Raku has [`Traits`](https://docs.raku.org/language/traits), a syntax that can be used to mark classes and objects. These labels are processed during compilation of the program. Depending on the wishes of the programmer, the effect of such processing can have an impact on the course of program execution.

For example, consider a similar annotation to the `@Deprecated` construct from the Raku spec:

```raku
sub get-name(--> Str) is DEPRECATED('get-id() method') {
  'stub'
}
```

[`is DEPRECATED`](https://docs.raku.org/type/Routine#trait_is_DEPRECATED) there is a trait. An argument can provide an alternative to the deprecated code. After the program finishes, during the execution of which the `get-name` function was called, a message will be displayed indicating where and how many times the obsolete code was executed:

```
Saw 1 occurrence of deprecated code.
======================================================================
Sub get-name (from GLOBAL) seen at:
  ~ / advent.raku, line 13
Please use get-id() method instead.
----------------------------------------------------------------------
Please contact the author to have these occurrences of deprecated code
adapted, so that this message will disappear!
```

### Obsolete

`is DEPRECATED` is a trait from the standard library. To understand how it works, let's try to write our analogue under the name `obsolete`. First, let's define the storage of the collected information - a class that stores and updates the number of function calls and is able to display a report:

```raku
class ObsoleteTraitData {
  has $.routine-name is required;
  has $.user-hint;
  has $!execution-amount = 0;
  method executed() { $!execution-amount++ }
  method report() {
    return unless $!execution-amount;
    note "Obsolete routine $!routine-name is executed $!execution-amount times.";
    note $_ with $!user-hint;
  }
}
```

Now we declare a test trait - this is an ordinary multifunction with a name `trait_mod:<is>` and two arguments: the first is what the trait will be applied to (in our case, this is a `Routine`), the second is the name:

```raku
say 'run-time';
multi trait_mod:<is>(Routine $r, :$obsolete!) {
  say 'compile-time'
}
sub get-name(--> Str) is obsolete {
  'stub'
}
say get-name;
# Output: compil-time
#         run-time
#         stub
```

The most important thing to understand about traits is that their functions are executed at compile time, not at program execution. This can be clearly seen from the output of the code above. Let's remember what we want to achieve - a report on the execution of obsolete code before the program terminates. We can obtain this information only during the execution. To affect compile-time execution, the trait must modify the function in some way. In our case, you can add via the function [phaser](https://docs.raku.org/language/phasers) [`ENTER`](https://docs.raku.org/language/phasers#ENTER). This is a special block that is executed before the first statement of the function is executed. That is, we make the function `get-name` looks something like this:

```raku
sub get-name(--> Str) {
  ENTER { $obsolete-trait-data.executed }
  'stub'
}
```

We cannot touch the code of the function itself, but we can do the necessary manipulations during compilation. We take the function name, a possible hint for the user, create a new type object `ObsoleteTraitData`, put it in the local associative variable `%obsolete-trait-data` and add the necessary phaser:

```raku
my ObsoleteTraitData %obsolete-trait-data;

multi trait_mod:<is>(Routine $r, :$obsolete!) {
  my $routine-name = $r.name;
  my $user-hint = $obsolete ~~ Str ?? $obsolete !! Any;
  %obsolete-trait-data{$routine-name} = ObsoleteTraitData.new(:$routine-name, :$user-hint);
  $r.add_phaser('ENTER', -> {
    %obsolete-trait-data{$routine-name}.executed;
  });
}
```

Now, when the function `get-name` is executed, the `ObsoleteTraitData` object will update its state. Thus, we influenced the program execution flow during compilation. It remains only to display the report. To do this, we will add another phaser [`END`](https://docs.raku.org/language/phasers#END) to the main code. Its block is executed just before the end of the program. Thus, we get the following picture:

```raku
class ObsoleteTraitData { #`(described above) }

my ObsoleteTraitData %obsolete-trait-data;

END { .report for %obsolete-trait-data.values }

multi trait_mod:<is>(Routine $r, :$obsolete!) { #`(described above) }

sub get-name(--> Str) is obsolete ('Please use get-id() instead.') {
  'stub'
}
sub another-obsolete() is obsolete {}

get-name();
another-obsolete();
get-name();

# Output:
# Obsolete routine get-name is executed 2 times.
# Please use get-id() instead.
# Obsolete routine another-obsolete is executed 1 times.
```

### Override

Another commonly used annotation in Java is [`@Override`](https://docs.oracle.com/javase/8/docs/api/java/lang/Override.html) on a class method. The case where it does not override a super-class method is considered a compilation error. It will not be difficult to make a similar trait - we will not have to go beyond the compilation stage. We declare a trait with a name `override` that applies only to methods:

```raku
multi trait_mod:<is>(Method $m, :$override!) {
```

We check that the method is a member of the class, otherwise we exit:

```raku
  return unless $m.package.HOW ~~ Metamodel::ClassHOW;
```

We check that the class of the owner of the method has parents. To do this, we will use the meta-method [`^mro`](https://docs.raku.org/routine/mro), which will return a list of all parent classes, including itself, `Any` and `Mu` (we will filter them from consideration):

```raku
  my $class = $m.package;
  my $method-point = $class.^name ~ '::' ~ $m.name;
  my @parents = $class.^mro[1 ..^ *-2];
  die "is override trait cannot be used without parent class $method-point." unless @parents;
```

We go through all the parents and their methods in search of one that matches in name and [signature](https://docs.raku.org/type/Signature). Comparing method signatures is not a very trivial task, and here we will hide its implementation behind a function `check-signature-eq`:

```raku
  for @parents -> $parent {
    for $parent.^methods -> $parent-method {
      return if $parent-method.name eq $m.name &&
        check-signature-eq($parent-method.signature, $m.signature)
    }
  }
```

If the parents did not find the required method, they will return an error:

```raku
  die "$method-point does not override any parent methods.";
}
```

As a result, we get the following:

```raku
multi trait_mod:<is>(Method $m, :$override!) { #`(described above) }

class A {
  method from-a(:$r) {}
}

class B is A {
  method from-a($r) is override { # missed a colon
    say 'from-b'
  }
}

# Output: B::from-a does not override any parent methods.
# Exit code: 1
```

### Suppress

We have already managed to implement the logic of the Java annotations `@Deprecated` and `@Override`. Let's try to implement the logic of [`@SuppressWarnings`](https://docs.oracle.com/javase/8/docs/api/java/lang/SuppressWarnings.html). This annotation applies to the function and suppresses its warning messages. Also, you can specify which warnings will be suppressed.

In Raku, warnings can be displayed using a function [`warn`](https://docs.raku.org/routine/warn). It throws a special exception, which is printed to the error stream, and the execution process resumes where it was. You can catch such an exception using a special phaser [`CONTROL`](https://docs.raku.org/language/phasers#CONTROL). That is, as in the case with `@Deprecated`, we need to modify the function by adding the desired phaser. Let's try something new and use the function [wrapper](https://docs.raku.org/language/functions#index-entry-dispatch_wrapped_routines) instead of `add_phaser`. How does it work? We are replacing one function with another that can call the original (by the routine [`callsame`](https://docs.raku.org/language/functions#index-entry-dispatch_callsame)) at its discretion . Inside this function, we will insert a phaser `CONTROL`, which will mimic the standard behavior, but not for suppressed warnings:

```raku
multi trait_mod:<is>(Routine $b, :$suppress-warnings) {
  my $regex = $suppress-warnings ~~ Str ?? / <$suppress-warnings> / !! Any;
  $b.wrap(sub with-control(|c) {
    callsame;
    CONTROL {
      when CX::Warn {
        .note if $regex.defined && $_.message !~~ $regex;
        .resume
      }
    }
  });
}

sub work-in-progress() is suppress-warnings('todo') {
  warn 'important warn';
  warn 'todo warn';
}

work-in-progress()
# Output:
# important warn
#   in sub work-in-progress at ~/trait-supress.raku line 15
```

### Serialize

All that remains is to discuss user-defined annotations. As I said above, Java annotations are a way to attach some meta information to a class or object. Thereafter, at compile time, or more often at runtime, the annotated objects are checked to see if they have the information they need. In Raku, [roles](https://docs.raku.org/language/objects#Roles) are great for this. Consider the problem of adding the simplest serialization system to a class. Let's write a class and mark it up our future trait:

```raku
class Person is serialize-name('Passport') {
  has $.first;
  has $.second is serialize-name('Second name');
  has $.third is serialize-name('Honorific');
}
```

You can see that trait `serialize-name` applies to both the class itself and its attributes.

The trait for the attribute looks like this:

```raku
role SerialisableAttribute {
  has $.serialize-name;
}

multi trait_mod:<is>(Attribute $a, :$serialize-name!) {
  $a does SerialisableAttribute(:$serialize-name);
}
```

Above, the trait adds a new `SerialisableAttribute` role to the attribute. This role itself injects a new attribute into the attribute :) The value of the new trait attribute is passed through its argument.

The trait for the class looks like this:

```raku
role SerialisableClass[$name] {
  method serialize() {
    say $name, '| ', self.^name;
    say .serialize-name, '<-', .get_value(self)
      for self.^attributes(:local) .grep(*.^can('serialize-name'));
  }
}

multi trait_mod:<is>(Mu:U $c, :$serialize-name!) {
  return unless $c.HOW ~~ Metamodel::ClassHOW;
  $c.^add_role(SerialisableClass[$serialize-name]);
}
```

Above, you can see that trait checks that it applies exactly to the class and adds a special role `SerialisableClass`. This role adds a new method `serialize` to the class that implements all the serialization logic. In particular, it filters the list of all class attributes based on the presence of a method `serialize-name`.

If we run all this, we get:

```raku
Person.new(:first<John>, :second<Hancock>, :third<Mr>).serialize();
# Output:
# Passport | Person
# Second name <- Hancock
# Honorific <- Mr
```

### Conclusion

As we can see, traits are a pretty powerful tool, but like everything in the Raku world, it can be used in very different ways. For example, in Java, when declaring their annotation, the programmer must indicate to what stage its action extends (only at the code level, until the end of compilation, or until the end of the application). You can also specify whether the annotation will be inherited by child classes, and whether it can be specified multiple times. On the other hand, traits in Raku give the programmer complete freedom of action. You now have the knowledge to write your own IoC/DI system like Java Spring Core using Raku traits.
