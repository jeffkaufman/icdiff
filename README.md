# Icdiff

Improved colored diff

![screenshot](http://www.jefftk.com/icdiff-css-demo.png)

## Installation

Download the [latest](https://github.com/jeffkaufman/icdiff/releases) `icdiff` binary and put it on your PATH.

Alternatively, install with pip:
```
  pip install git+https://github.com/jeffkaufman/icdiff.git
```

It can be also installed using [AUR](https://aur.archlinux.org/packages/icdiff/)
```
  yay -S icdiff
```
It can be also installed using [Nix](https://nixos.org/nix/)

```
  nix-env -i icdiff
```

## Usage

```sh
icdiff [options] left_file right_file
```

Show differences between files in a two column view.

### Options
```
  --version             show program's version number and exit
  -h, --help            show this help message and exit
  --cols=COLS           specify the width of the screen. Autodetection is Unix
                        only
  --encoding=ENCODING   specify the file encoding; defaults to utf8
  -E MATCHER, --exclude-lines=MATCHER
                        Do not diff lines that match this regex. Not
                        compatible with the 'line-numbers' option
  --head=HEAD           consider only the first N lines of each file
  -H, --highlight       color by changing the background color instead of the
                        foreground color.  Very fast, ugly, displays all
                        changes
  -L LABELS, --label=LABELS
                        override file labels with arbitrary tags. Use twice,
                        one for each file
  -N, --line-numbers    generate output with line numbers. Not compatible with
                        the 'exclude-lines' option.
  --no-bold             use non-bold colors; recommended for solarized
  --no-headers          don't label the left and right sides with their file
                        names
  --output-encoding=OUTPUT_ENCODING
                        specify the output encoding; defaults to utf8
  -r, --recursive       recursively compare subdirectories
  -s, --report-identical-files
                        report when two files are the same
  --show-all-spaces     color all non-matching whitespace including that which
                        is not needed for drawing the eye to changes.  Slow,
                        ugly, displays all changes
  --tabsize=TABSIZE     tab stop spacing
  -t, --truncate        truncate long lines instead of wrapping them
  -u, --patch           generate patch. This is always true, and only exists
                        for compatibility
  -U NUM, --unified=NUM, --numlines=NUM
                        how many lines of context to print; can't be combined
                        with --whole-file
  -W, --whole-file      show the whole file instead of just changed lines and
                        context
  --strip-trailing-cr   strip any trailing carriage return at the end of an
                        input line
  --color-map=COLOR_MAP
                        choose which colors are used for which items. Default
                        is --color-map='add:green_bold,change:yellow_bold,desc
                        ription:blue,meta:magenta,separator:blue,subtract:red_
                        bold'.  You don't have to override all of them:
                        '--color-map=separator:white,description:cyan
```

## Using with Git

To see what it looks like, try:

```sh
git difftool --extcmd icdiff
```

To install this as a tool you can use with Git, copy
`git-icdiff` into your PATH and run:

```sh
git icdiff
```

You can configure `git-icdiff` in Git's config:

```
git config --global icdiff.options '--highlight --line-numbers'
```

## Using with subversion

To try it out, run:

```sh
svn diff --diff-cmd icdiff
```

## Using with Mercurial

Add the following to your `~/.hgrc`:

```sh
[extensions]
extdiff=

[extdiff]
cmd.icdiff=icdiff
opts.icdiff=--recursive --line-numbers
```

Or check more [in-depth setup instructions](http://ianobermiller.com/blog/2016/07/14/side-by-side-diffs-for-mercurial-hg-icdiff-revisited/).

## Setting up a dev environment

Create a virtualenv and install the dev dependencies.
This is not needed for normal usage.

```sh
virtualenv venv
source venv/bin/activate
pip install -r requirements-dev.txt
```

## Running tests

```sh
./test.sh python3
```

## Making a release

* Update ChangeLog with all the changes since the last release
* Update `__version__` in `icdiff`
* Run tests, make sure they pass
* `git commit -a -m "release ${version}"`
* `git push`
* `git tag release-${version}`
* `git push origin release-${version}`
* `prepare-release.sh ${prev-version} ${version}`
* `python3 -m twine upload icdiff-${version}.tar.gz --user "__token__" --password "$TOKEN"`

## License

This file is derived from `difflib.HtmlDiff` which is under [license](http://www.python.org/download/releases/2.6.2/license/).
I release my changes here under the same license.  This is GPL compatible.
