While Raku regex and tokens are meant to work on data structures (such as parsing and validating file types), they can help us to better understand malware. Malware, as any other legit binary, have some signatures within. Some “file signatures” are widely used to blacklist those specific samples (the hashes), but the problem is that blacklisting hashes is not safe enough. Sometimes, the very same kind of malware could be slightly different in small details, and have many different samples related. In this case, apart from relying on dynamic detection (monitoring devices and alerting the user when something seems to be acting suspiciously), genes are also investigated.

Malware genes are pieces of the reversed code (such as strings) that are commonly seen in most or all the samples of a malware family. This sort of genes help researchers identify the malware family and contextualize the attacks , since this is relevant not only to try to put an end to the threat by executing the proper counterfeits in time, but also helps profiling and framing threat actors in some cases. 

Generally, these genes are also useful to look for malware families among a unknown group of samples. A common tool for this is “YARA”.  YARA is a tool used by researchers to create some rules and basic logic to try to find genes across samples. The structure of how YARA works can also be approached using Raku grammars, providing an alternative that might be useful when the YARA logic is not enough for the regex rules in specific cases. In order to test this idea, I created “CuBu” (curious butterfly), a tool similar to YARA which takes advantage of Raku elements to look for malware genes. For testing out the tool I designed a script to look for Sparkling Goblin genes. Sparkling Goblin is an APT (advanced persistent threat) that I happened to investigate a few months ago. While working on a YARA rule, I found out the following gene was commonly seen in some of their malware:

```
InterfaceSpeedTester9Calc
```

So I created a token in Raku using that gene:

```
my token gen1 {'InterfaceSpeedTester9Calc'}
```

Now created a regex with it:

```
my regex sparkling_goblin {<gen1>}
```

And parsed a file line by line trying to look for the gene:

```
my $c = 1;
    for "$fo/$fi".IO.lines -> $line {
        # If the line contains the gene, print it
         if $line ~~ &sparkling_goblin {say "Sparkling Goblin found: "; say $line; say "in line $c"; say "in file $fi"; say " "; }
         #if $line ~~ &sparkling2 {say "Sparkling Goblin complex regex found: "; say $line; say "in line $c"; say " "; }

         $c++;
    }
```

In the code above, the file is parsed in a given folder ($fo) and file ($fi) and when the gene is found it prints the name of the file and the line. In this case there are too many steps for a single gene, but let’s check then using another regex from different tokens. Let’s say we also want to check for gene:

```
ScheduledCtrl9UpdateJobERK
```

So in this case we can create another token:

```
my token gen2 {'ScheduledCtrl9UpdateJobERK'}
```

And change the regex so it checks for one or the other:

```
my regex sparkling2 {
    [
       <gen1>|<gen2>
    ]
    }
```

And we can keep going with yet another gene:

```
my token gen3 {'ScanHardwareInfoPSt'}
```

And add it in the regex:

```
my regex sparkling2 {
    [
       <gen1>|<gen2>|<gen3>
    ]
    }
```


Now let’s say that the first gene is only suspicious when seen in the end of a line, but the second and third genes are suspicious always. We then should use the regex `<gen1>$`  included in our logic.


```
my regex sparkling2 {
    [
       <gen1>$|<gen2>|<gen3>
    ]
    }
```

This is becoming interesting and more specific. If we wanted to check for a line which ends with the first gene, or starts with the second gene we would do:

```
my regex sparkling2 {
    [
       <gen1>$|^<gen2>
    ]
    }
```

And if we want to look for a line which is specifically the third gene without anything else or any of the other genes inside the strings:


```
my regex sparkling2 {
    [
       <gen1>|<gen2>|^<gen3>$
    ]
    }
```

And so on. Once you know your malware you can create more and more refined regex to work with them. You can create more than one regex to look for different specific things. This is how the whole code for the last option would look like:

```
sub MAIN (Str :$fi = '', Str :$fo = '') {
    # some genes in the binary

    my token gen1 {'InterfaceSpeedTester9Calc'}
    my token gen2 {'ScheduledCtrl9UpdateJobERK'}
    my token gen3 {'ScanHardwareInfoPSt'}

    my regex sparkling2 {
        [
           <gen1>|<gen2>|^<gen3>$
        ]
     }

    my $c = 1;
    for "$fo/$fi".IO.lines -> $line {
        if $line ~~ &sparkling2 {say "Sparkling Goblin complex regex found: "; say $line; say "in line $c"; say "in file $fi"; say " "; }
    
    $c++;
  }
}    
```

In my tool, CuBu, I used this raku (compiled with rakudo) inside a bash script using Zenity for a simple user friendly GUI that asks for the folder and the raku script and creates a CSV and a raw file with the results. It iterates every single file of the folder:

```
#!/bin/sh

zenity --forms --title="New analysis" \
	--text="Enter configuration:" \
	--separator="," \
	--add-entry="Folder" \
	--add-entry="Threat name" >> threat.csv

case $? in
    0)
        echo "Configuration set"
	name=$(csvtool col 2-2 threat.csv)
	mv threat.csv* "$name.csv"

	folder2=$(csvtool col 1-1 $name.csv)
	;;
    1)
        echo "Nothing configured."
	;;
    -1)
        echo "An unexpected error has occurred."
	;;
esac

zenity --question \
--text="You are going to check samples in folder $folder2 in order to look for $name. Is that okay?"
if [ $? ]; then
	echo "Starting analysis: "

touch results_$name

	for i in "$folder2"/*; do
		rakudo $name.raku --fi="$i" --fo=. >> results_$name
	done

	zenity --info \
	--text="Info saved in results_$name"
else
	echo "okay! bye!"
fi

```















