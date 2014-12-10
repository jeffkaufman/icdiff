# Icdiff

Improved colored diff

## Installation

Put `icdiff` on your PATH.

##Usage

```sh
icdiff [options] left_file right_file
```

Show differences between files in a two column view.

### Options
```
  --version             show program's version number and exit
  -h, --help           show this help message and exit
  -u, --patch           generate patch. This is always true, and only exists
                        for compatibility
  --cols=COLS          specify the width of the screen. Autodetection is Unix
                       only
  --head=HEAD          consider only the first N lines of each file
  --highlight          color by changing the background color instead of the
                       foreground color.  Very fast, ugly, displays all
                       changes
  --line-numbers       generate output with line numbers
  --no-bold            use non-bold colors; recommended for with solarized
  --no-headers         don't label the left and right sides with their file
                       names
  -U NUM, --unified=NUM
                        how many lines of context to print; can't be combined
                        with --whole-file
  --recursive          recursively compare subdirectories
  --show-all-spaces    color all non-matching whitespace including that which
                       is not needed for drawing the eye to changes.  Slow,
                       ugly, displays all changes
  --whole-file         show the whole file instead of just changed lines and
                       context
  -L LABELS, --label=LABELS
                        override file labels with arbitrary tags. Use twice,
                        one for each file
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


## License

This file is derived from `difflib.HtmlDiff` which is under the [license](http://www.python.org/download/releases/2.6.2/license/).
I release my changes here under the same license.  This is GPL compatible.
