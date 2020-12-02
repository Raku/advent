# Rudolph on Raku

## Finding a way home to the North pole with Physics::Navigation

So, Rudolph has been worried about getting Santa and the other reindeer back home to the North Pole after an exhausting flight to visit all the (well-behaved) Children on the Globe.

He has heard a rumour that the North Pole keeps moving due to the precession of molten iron at the Earth's core and that every year it creeps around a bit with relation to Santa's workshop, which lies at the True North Pole.

Luckily he has been on a navigation skills course and has learned about how to specify a position on the globe using a combination of Latitude and Longitude. However, these seem all of a muddle as they are alike and yet different. What Rudi needs is a way to structure his navigation to ensure that he does not mix them up. Even better, he is good friends with Larry and knows that he can trust the Raku [type system](https://docs.raku.org/language/typesystem) to get him home. In fact, Raku has a lot of ways to make the life of a reindeer|developer better, find out more at https://www.raku.org.

Let's see how he does it:

```
use Physics::Unit;
use Physics::Measure;

class NavAngle is Angle {
  has Unit  $.units is rw where *.name eq '°';
	
  multi method new( Str:D $s ) {
    my ($decimal, $compass) = NavAngle.defn-extract( $s );
    my $type;
    given $compass {
      when <N S>.any   { $type = 'Latitude' }
      when <E W>.any   { $type = 'Longitude' }
      when <M T H>.any { $type = 'Bearing' }
      default          { nextsame }
    }
    ::($type).new( value => $nominal, compass => $compass );
  }
  
  method defn-extract( NavAngle:U: Str:D $s ) {
    #handle degrees-minutes-seconds <°> is U+00B0 <′> is U+2032 <″> is U+2033
    unless $s ~~ /(\d*)\°(\d*)\′?(\d*)\″?\w*(<[NSEWMTH]>)/ { return 0 };
    my $deg where 0 <= * < 360 = $0 % 360;
    my $min where 0 <= * <  60 = $1 // 0;
    my $sec where 0 <= * <  60 = $2 // 0;
    my $decimal = ( ($deg * 3600) + ($min * 60) + $sec ) / 3600;
    my $compass = ~$3;

    say "NA extracting «$s»: value is $deg°$min′$sec″, compass is $compass" if $db;
    return($decimal, $compass)
  }
  
  method Str {
    my ( $deg, $min ) = self.dms( :no-secs ); 
    $deg = sprintf( "%03d", $deg );
    qq{$deg° $.compass}
  }
}
#real code at https://github.com/p6steve/raku-Physics-Navigation (work in progress)
```
So Rudi has created a NavAngle class that inherits the Angle class provided by [Physics::Unit](https://github.com/p6steve/raku-Physics-Unit) by writing 'NavAngle is Angle' and created some general methods that 'know' that <N S> are Latitude and <E W> are Longitude. There's also the notion of <M T H> for Bearing (more on that later). Here y9ou can see that Raku has a very flexible [switch](https://docs.raku.org/language/control#index-entry-switch_(given)) that uses 'given-when-default' keywords to specify control flow.
	
This new class 'has' one attribute defined - $.units. The Raku $. [twigil](https://docs.raku.org/language/classtut#index-entry-twigils_accessors) indicates that this is a public attribute and automatically provides accessor get and set methods with no need for extra code. So when you to set the value, the 'where' [constraint](https://docs.raku.org/type/Signature#index-entry-Constraint) checks that $.units.name eq '°'. That way we enforce that our NavAngle objects are specified in degrees '°' and prevent the use of other available Angle units such as radians or grads.

Having attended the Greenland Grammar school, he knows that the Raku [regex](https://docs.raku.org/language/regexes) capability and [unicode](https://docs.raku.org/language/unicode) support can make short work of degrees, minutes and seconds. Value constraints will stop him from flying off at 451 degrees.

A couple of other nice Raku capabilities are shown here (i) the '::($type)' syntax allows types to be handled as variables and acted on programmatically, (ii) the parameter capture '( Str:D $s )' checks the type and defined-ness of fucntion parameters and (iii) the '= $1 // 0' combination tests for defined-ness and assigns a default value. Rudolph is happy to see that all these tools sit nicely together in a comprehensible language syntax.

## Latitude and Longitude
Now the basics are in place, Rudolph can easily define the Latitude and Longitude child classes using [inheritance](https://docs.raku.org/language/classtut#index-entry-classes__inheritance):
```
class Latitude is NavAngle {
	has Real  $.value is rw where 0 <= * <= 90; 
	has Str   $.compass is rw where <N S>.any;
}
class Longitude is NavAngle {
	has Real  $.value is rw where 0 <= * <= 180; 
	has Str   $.compass is rw where <E W>.any;
}
```
The constraints are adjusted - now the children have their own $.value and $.compass attributes - to reflect the different value limits of each child class. The <N S> brackets are equivalent to ('N', 'S') - they are quicker to type since you do not have to use [quotes](https://docs.raku.org/routine/%3C%20%3E) around every word.

Rudolph can set his Latitude position by creating a new instance of the Latitude class with the standard Raku constructor:
```my $lat = Latitude.new( value => 45, compass => <N> ); say ~$lat; #OUTPUT 43° N```

But this is quite long winded and he is impatient to get home. Great news, he can create a Raku [custom operator](https://docs.raku.org/language/optut) to let him easily specify and initialise new instances from a quoted string. In this case, he decides to use a unicode pisces 'emoji' - ♓️ ...
```
multi infix:<♓️> ( Any:U $left is rw, Str:D $right ) {
    $left = NavAngle.new( $right );
}
```
Now he can quickly hoof in his coordinates:
```
my $lat  ♓️ <55°30′30″S>; say ~$lat;   #OUTPUT 55°30.5 S
my $long ♓️ <45°W>;       say ~$long;  #OUTPUT 45° W
```

## Magnetic vs. True North

Now he knows where he is, Rudolph can set a course to steer home to the North Pole. But wait, how can he adjust for the difference between Magnetic north on his Compass and True North, his destination?

Rudolph has another trick up his (antler) sleeve:
```
class CompassAdjustment { ... }

our $variation = 0;			#optional variation (Compass-Adjustment)
our $deviation = 0;			#optional deviation (Compass-Adjustment)

#| Bearing embodies the identity 'M = T + Vw', so...
#| Magnetic = True + Variation-West [+ Deviation-West]
class Bearing is NavAngle is export {
	has Real  $.value is rw where 0 <= * <= 360; 
	has Str   $.compass where <M T>.any;

	method M {
		if $.compass eq <M> { return( self ) } 
		else { return( self + ( $variation + $deviation ) ) }
	}
	method T {
		if $.compass eq <T> { return( self ) } 
		else { return( self - ( $variation + $deviation ) ) }
	}

   sub check-same( $l, $r ) {
	if $r ~~ CompassAdjustment { 
		return 
	}
        if ! $l.compass eq $r.compass {
            die "Cannot combine Bearings of different Types!"
        }    
    }  
    method add( $r is rw ) {
        my $l = self;
        check-same( $l, $r );
        $l.value += $r.value;
 	$l.compass( $r.compass );
        return $l
    }    
    method subtract( $r is rw ) {
        my $l = self;
        check-same( $l, $r );
        $l.value -= $r.value; 
	$l.compass( $r.compass );
        return $l
    }
}

class CompassAdjustment is Bearing is export {
	has Real  $.value is rw where -180 <= * <= 180; 

	multi method compass {						#get compass
		given $.value {
			when * >= 0 { return <W>, 0 }
			when * < 0  { return <E>, 1 }
		}
	}
	multi method compass( Str $compass ) {				#set compass
		given $compass {
			when <W>   { }		#no-op
			when <E>   { $.value = -$.value }
			default    { die "Compass-Adjustment must be <W E>.any" }
		}
	}
}
```
Now, after setting the compass variation, Rudolph can enter in their magnetic compass reading and get back the  Bearing to True North.
```
$Physics::Navigation::variation = CompassAdjustment.new( value => 7, compass => <W> );

my $bear ♓️ <43°30′30″M>; say ~$bear;   #OUTPUT 43°30.5 M
say ~$bear.T;				#OUTPUT 43°37.5 T
```
Santa can even steer (H=Helm) by doing addition/subtraction of the course change Bearing since +/- are already overidden for Physics::Measure objects - that's one benefit of these weird ♓️ unicode operators ... they act as a warning that language mutations are active in these code regions.

And should Santa be bringing home a sleigh full unwanted ferrous Christmas presents (bikes, climbing frames, Meccano sets and so on), then this can be accommodated with the ```$Physics::Navigation::deviation``` setting.

And finally Santa, Rudolph and the other reindeer can rest their weary bones around the glowing fire at home after a long night's work!

Merry Christmas to one and all (and any)
p6steve.   (p6 is pronounced "Physics")
