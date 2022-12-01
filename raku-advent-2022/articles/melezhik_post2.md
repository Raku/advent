# SparrowCI pipelines cascades of fun


Remember the young in the [previous](https://raku-advent.blog/2022/12/01/day-1-sparrowci-pipelins-for-everything/) SparrowCI story? We have not finished with him yet ...

Because New Year time is coming and brings us a lot of fun, or we can say cascades of fun ...

So, our awesome SparrowCI pipelines plumber guy is busy with sending [the gift](https://github.com/melezhik/rakudist-teddy-bear) to his nephew:

`sparrow.yaml`:

```yaml
tasks:
  -
    name: zef-build
    language: Bash
    default: true
    code: |
      set -e
      cd source/
      zef install --deps-only --/test .
      zef test .
```

Once a gift is [packed](https://ci.sparrowhub.io/report/1919) and ready, there is one little thing that is left.

\- And that is - to send the gift to Santa, to His wonderful [(~~LAP~~|Raku)land](https://raku.land)

So, SparrowCI guy gets quickly to it, and he knows what to do (did not I tell you ,
he is very knowledgeable? :-), creating a small, nifty script to publish things to 
Santa's land:

`.sparrow/publish.yaml`

```yaml
image:
  - melezhik/sparrow:debian

secrets:
  - FEZ_TOKEN
tasks:
  - name: fez-upload
    default: true
    language: Raku
    init: |
      if config()<tasks><git-commit><state><comment> ~~ /'Happy New Year'/ {
        run_task "upload"
      }
    subtasks:
    -
      name: upload
      language: Bash
      code: |
        set -e
        cat << HERE > ~/.fez-config.json
          {"groups":[],"un":"melezhik","key":"$FEZ_TOKEN"}
        HERE
        cd source/
        zef install --/test fez
        head Changes
        tom --clean
        fez upload
    depends:
      -
        name: git-commit
  - name: git-commit
    plugin: git-commit-data
    config:
      dir: source
```

Didn't you notice, SparrowCI lad needs to tell Santa's his (-fez-token-) secret to do so, 
but don't worry! - Santa knows how to keep secrets!

![secret](https://raw.githubusercontent.com/melezhik/advent/master/images/sparrowci/secret.png)

Finally, SparrowCI plumber [ties](https://github.com/melezhik/rakudist-teddy-bear/blob/0023787d0c0b6c7c7ac9e62e7b56b3be2ace35f3/sparrow.yaml#L12) 
"package" and "publish" things together and we have **CASCADING PIPELINES of FUN**

`sparrow.yaml`:

```yaml
# ...
followup_job: .sparrow/publish.yaml
```

And, here we are, ready to share some gifts:


```bash
git commit -m "Happy New Year" -a
git push
```

Remember, what should we say to Santa, once we see him? Yes - Happy New Year!

This "magic" commit phrase will open door in Santa's shop 
and [deliver](https://ci.sparrowhub.io/report/1930) the package straight to it!

![publish](https://raw.githubusercontent.com/melezhik/advent/master/images/sparrowci/fez-upload.jpeg)

# That is it?

Yes and ... no - you can read all that _technical_ stuff in more boring, none holiday manner on
[SparrowCI](https://ci.sparrowhub.io) site, but don't forget - SparrowCI is FUN.
