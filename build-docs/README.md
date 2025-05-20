# quickemu-docs

Build environment for Quickemu project documentation

[![CodeFactor](https://www.codefactor.io/repository/github/philclifford/quickemu-docs/badge/main)](https://www.codefactor.io/repository/github/philclifford/quickemu-docs/overview/main)

This is aimed at being a submodule for generating and placing
documentation and manual pages.

It consists of a `Makefile` that calls a script (`build_manuals`) which generates the [README](../README.md)
and the contents of [../docs](../docs)

> [!NOTE]  
>Since much of the [README](../README.md) has been redirected to the wiki it no longer contains dynamic version-dependant content.

It is likely that it can be removed from this process shortly, if indeed this sub-project has a future at all. Ideally CI/CD can also maintain
any wiki content and keeping the man pages in step can be transferred to CI.  For now everything is regenerated, but probably only docs need
submitting and README checking for local edits and changes

It does this by using a set of parts according to the recipe build in the `build_manuals` script. To update the 3 manual pages, the markdown sources and
the main project README.md edit or add to the parts, paying
attention to ordering and inclusion of new parts in appropriate recipes, then run `make clean;make`.  This
will generate parts of the documentation by running the software itself to ensure consistency and current alignment.
The Makefile here can also be used (with sudo) to install the man pages and or the software.

The parts list currently consists of:

``` text
##  Tops and tails
quickemu.1-01-head.md
quickemu_conf.1-00-hdr.md
quickemu_conf.1-05-footer.md
quickget.1-00-header.md
quickget.1-09-footer.md
README-00-hdr.md
quickemu.1-30-Footers.md

# The Seed parts for generation with `cog`

XXquickemu.1-08-OtherOperatingSystems01.md  
XXquickemu.1-14-AllquickemuOptions-02coggged.md

# The static parts
quickemu.1-02-options.md
quickemu.1-03-examples.md
quickemu.1-04-intro.md
quickemu.1-05-features01.md
quickemu.1-06a-GUI.md
quickemu.1-06-requirements.md
quickemu.1-07-Ubuntus00.md
quickemu.1-07-Ubuntus01.md
quickemu.1-08-OtherOperatingSystems01.md
quickemu.1-09-othermanualguests.md
quickemu.1-10-macOSguests.md
quickemu.1-11-Windowsguests.md
quickemu.1-15-UsageNotes.md
quickemu.1-20-References.md

README-00-hdr.md
README-01-Intro.md
README-02-Features.md
README-03-Quickstart.md
README-04-Documentation.md
README-05-Contribution.md
README-06-Install.md

README-135-accessibility.md
README-135-confoptions.md

## No longer / not yet in use

quickemu_conf.1-01-spiceheadless.md
quickemu.1-13-OtherGuests01.md 
README-06-Install.md
README-135-accessibility.md

## README list

README-01-Intro.md
README-02-Features.md
README-03-Quickstart.md
README-04-Documentation.md
README-05-Contribution.md

## quickget list

quickget.1-00-header.md 
quickemu.1-07-Ubuntus00.md 
quickemu.1-07-Ubuntus01.md 
quickemu.1-07-Ubuntus02-generated.md 
quickemu.1-08-OtherOperatingSystems01.md
quickemu.1-08-OtherOperatingSystems02-generated.md 
quickemu.1-09-othermanualguests.md 
quickemu.1-10-macOSguests.md 
quickemu.1-11-Windowsguests.md 
quickget.1-09-footer.md

## quickemu list

quickemu.1-01-head.md
quickemu.1-02-options.md
quickemu.1-03-examples.md
quickemu.1-04-intro.md
quickemu.1-05-features01.md
quickemu.1-06-requirements.md
quickemu.1-06a-GUI.md
quickemu.1-07-Ubuntus00.md
quickemu.1-07-Ubuntus01.md
quickemu.1-07-Ubuntus02-generated.md
quickemu.1-08-OtherOperatingSystems01.md
quickemu.1-08-OtherOperatingSystems02-generated.md
quickemu.1-09-othermanualguests.md
quickemu.1-10-macOSguests.md
quickemu.1-11-Windowsguests.md
quickemu.1-14-AllquickemuOptions-02coggged.md
quickemu.1-15-UsageNotes.md
quickemu.1-20-References.md
quickemu.1-30-Footers.md

## quickemu_conf list

quickemu_conf.1-00-hdr.md
README-135-confoptions.md
quickemu_conf.1-05-footer.md


```

The process requires

* a recent version of `pandoc`
  * ( which you can obtain with `deb-get install pandoc` - if you have  [`deb-get`](https://github.com/wimpysworld/deb-get) )
* `cog` (install with `pip3 install cogapp`)

## Building the docs

You will need this submodule checked out appropriately under a clone of the `quickemu` repo.  The build uses `../quickemu` for the most part, so will build docs
based on the the position in this submodule but consistent with the version of software in the parent directory. `cog` updates are designed to happen within the
parent repo (so they can happen in GitHub too ), so the Makefile will enforce a symlink to appear here pointing to `../quickemu`

The general flow of the build is:

``` shell

# in the `quickemu` clone
git pull -r --no-recurse-submodules # or checkout <branch> ...
cd build_docs
# this will be detatched at the commit in the parent
# usually this is not what you want but is needed for repeatability
# Generally you will want to
git checkout main # or relevant branch or 
make clean
make

```

This should result in a perfect and consistent set of markdown docs and `man` pages in `../docs/` and also the matching `../README.md`
It is essential to check and preview the generated assets before
committing them or installing them since mistakes are easy, helpful software sometimes is too helpful, and `pandoc`, `cog` and github markdown sometimes choose
to fight rather than cooperate so small edits or patches may be needed to achieve satisfactory outcomes.

Once satisfied, you can optionally `install` the `man` pages so generated (and even the versions of the executables ) with

`sudo make  install_{docs|bins}`
or
`sudo make install`

and/or if the parent is checked out on a branch for submiting or updating a PR upstream, then

``` shell
cd ..
git add docs/quick*
## optionally now also
#git add  README.md 
git commit
git push
```
