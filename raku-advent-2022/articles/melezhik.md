# SparrowCI pipelines for everything

New year is a fun time when the whole family gets together by a table and eat holiday dinner.

Let me introduce some fun and young member of a Raku family - a guy named SparrowCI - super flexible and fun to use CI service.

To find SparrowCI lad - go to https://ci.sparrowhub.io web site and get your login using GitHub credentials:

![login](https://raw.githubusercontent.com/melezhik/advent/master/images/sparrowci/login.jpeg)

# Pipelines of fun

SparrowCI provides you with some DSL to built a CI for your Raku modules. 

For none devops people CI means "continuous integration" - a process allowing to test your code in some centralized 
service and share results with others.

Let's create some new year gift module and then build it:

```bash
mkdir SparrowBird
cd SparrowBird
git init 
cat << HERE > META6.json
{
  "authors" : [
    "Alexey Melezhik"
  ],
  "description" : "Sparrow::Bird",
  "license" : "Artistic-2.0",
  "name" : "Sparrow Bird",
  "provides" : {
    "Sparrow::Bird" : "lib/Sparrow/Bird.rakumod"
  },
  "version" : "0.0.1"
}
HERE

mkdir -p lib/Sparrow

cat << HERE > lib/Sparrow/Bird.rakumod
unit module Sparrow::Bird;
HERE


```

The SparrowCI guy is wrapping the gift into a new year paper:

```bash
cat << HERE > sparrow.yaml
tasks:
  -
    name: build-sparrow
    default: true
    language: Bash
    code: |
      set -e
      cd source/
      zef install .
HERE
```

And finally let's commit everything to some git repo (aka send to Santa):

```bash
git add .
git commit -a -m "my sparrow bird module initial commit"

git remote add origin git@github.com:melezhik/sparrow-bird.git
git branch -M main
git push -u origin main
```

Once our module in the GitHub land (aka Lapland), let's register it in SparrowCI:

Go to "my repos", then add the repository you want to build - https://github.com/melezhik/sparrow-bird :

![add repo](https://raw.githubusercontent.com/melezhik/advent/master/images/sparrowci/add-repo.png)

# The Gift packaged 

Now it's time to see the very first new year gift wrapped in a holiday paper, 
please allow SparrowCI a minute do his job, as he is being very busy wrapping up other gifts.

Finally, we will [see](https://ci.sparrowhub.io/report/1849) something like this:

![report](https://raw.githubusercontent.com/melezhik/advent/master/images/sparrowci/report.jpeg)

Hurrah! Or gift packed and ready to be sent by Santa.

# That is it?

Well, this is a small new year story not pretending to be a boring technical stuff. But as the title says - SparrowCI pipelines _for everything_, 
not just for building Raku modules ...

Thus, check out https://ci.sparrowhub.io to see all fun SparrowCI features. 

And ... happy holidays!
