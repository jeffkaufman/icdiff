# Icdiff

Improved colored diff

![screenshot](http://www.jefftk.com/icdiff-css-demo.png)

## Installation

Download the [latest](https://github.com/jeffkaufman/icdiff/releases) `icdiff` binary and put it on your PATH.

Install with pip from PyPI
```
  pip install icdiff
```

Alternatively, install with pip from github:
```
  pip install git+https://github.com/jeffkaufman/icdiff.git
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
  --head=HEAD           consider only the first N lines of each file
  -H, --highlight       color by changing the background color instead of the
                        foreground color.  Very fast, ugly, displays all
                        changes
  -L LABELS, --label=LABELS
                        override file labels with arbitrary tags. Use twice,
                        one for each file
  -N, --line-numbers    generate output with line numbers
  --no-bold             use non-bold colors; recommended for with solarized
  --no-headers          don't label the left and right sides with their file
                        names
  --output-encoding=OUTPUT_ENCODING
                        specify the output encoding; defaults to utf8
  --recursive           recursively compare subdirectories
  --show-all-spaces     color all non-matching whitespace including that which
                        is not needed for drawing the eye to changes.  Slow,
                        ugly, displays all changes
  --tabsize=TABSIZE     tab stop spacing
  -u, --patch           generate patch. This is always true, and only exists
                        for compatibility
  -U NUM, --unified=NUM, --numlines=NUM
                        how many lines of context to print; can't be combined
                        with --whole-file
  -W, --whole-file      show the whole file instead of just changed lines and
                        context
```


## Using with git

To see what it looks like, try:

```sh
git difftool --extcmd icdiff
```

To install this as a tool you can use with git, copy
`git-icdiff` onto your path and run:

```sh
git icdiff
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

## Running tests

```sh
./test.sh python2
./test.sh python3
```

## License

This file is derived from `difflib.HtmlDiff` which is under the [license](http://www.python.org/download/releases/2.6.2/license/).
I release my changes here under the same license.  This is GPL compatible.
