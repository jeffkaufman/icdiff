#!/bin/bash

# Usage: ./test.sh [--regold] [test-name] [python-version]
# Example:
#   Run all tests:
#     ./test.sh python3
#   Regold all tests:
#     ./test.sh --regold python3
#   Run one test:
#     ./test.sh tests/gold-45-sas-h-nb.txt python3
#   Regold one test:
#     ./test.sh --regold tests/gold-45-sas-h-nb.txt python3

if [ "$#" -gt 1 -a "$1" = "--regold" ]; then
  REGOLD=true
  shift
else
  REGOLD=false
fi

TEST_NAME=all
if [ "$#" -gt 1 ]; then
  TEST_NAME=$1
  shift
fi

if [ "$#" != 1 ]; then
  echo "Usage: '$0 [--regold] [test-name] python[23]'"
  exit 1
fi

PYTHON="$1"
ICDIFF="icdiff"

if [ ! -z "$INSTALLED" ]; then
  INVOCATION="$ICDIFF"
else
  INVOCATION="$PYTHON $ICDIFF"
fi

function fail() {
  echo "FAIL"
  exit 1
}

function check_gold() {
  local gold=tests/$1
  shift

  if [ $TEST_NAME != "all" -a $TEST_NAME != $gold ]; then
    return
  fi

  echo "    check_gold $gold matches $@"
  local tmp=/tmp/icdiff.output
  $INVOCATION "$@" &> $tmp

  if $REGOLD; then
    if [ -e $gold ] && diff $tmp $gold > /dev/null; then
      echo "Did not need to regold $gold"
    else
      cat $tmp
      read -p "Is this correct? y/n > " -n 1 -r
      echo
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv $tmp $gold
        echo "Regolded $gold."
      else
        echo "Did not regold $gold."
      fi
    fi
    return
  fi

  if ! diff $gold $tmp; then
    echo "Got: ($tmp)"
    cat $tmp
    echo "Expected: ($gold)"
    cat $gold
    fail
  fi
}

FIRST_TIME_CHECK_GIT_DIFF=true
function check_git_diff() {
  local gitdiff=tests/$1
  shift

  echo "    check_gitdiff $gitdiff matches git icdiff $@"
  # Check when using icdiff in git
  if $FIRST_TIME_CHECK_GIT_DIFF; then
    FIRST_TIME_CHECK_GIT_DIFF=false
    # Set default args when first time check git diff
    yes | git difftool --extcmd icdiff > /dev/null
    git config --global icdiff.options '--cols=80'
    export PATH=$PATH:"$(pwd)"
  fi
  local tmp=/tmp/git-icdiff.output
  git icdiff $1 $2 &> $tmp
  if ! diff $tmp $gitdiff; then
    echo "Got: ($tmp)"
    cat $tmp
    echo "Expected: ($gitdiff)"
    fail
  fi
}

check_gold gold-recursive.txt       --recursive tests/{a,b} --cols=80
check_gold gold-exclude.txt         --exclude-lines '^#|  pad' tests/input-4-cr.txt tests/input-4-partial-cr.txt --cols=80
check_gold gold-dir.txt             tests/{a,b} --cols=80
check_gold gold-12.txt              tests/input-{1,2}.txt --cols=80
check_gold gold-3.txt               tests/input-{3,3}.txt
check_gold gold-45.txt              tests/input-{4,5}.txt --cols=80
check_gold gold-45-95.txt           tests/input-{4,5}.txt --cols=95
check_gold gold-45-sas.txt          tests/input-{4,5}.txt --cols=80 --show-all-spaces
check_gold gold-45-h.txt            tests/input-{4,5}.txt --cols=80 --highlight
check_gold gold-45-nb.txt           tests/input-{4,5}.txt --cols=80 --no-bold
check_gold gold-45-sas-h.txt        tests/input-{4,5}.txt --cols=80 --show-all-spaces --highlight
check_gold gold-45-sas-h-nb.txt     tests/input-{4,5}.txt --cols=80 --show-all-spaces --highlight --no-bold
check_gold gold-45-h-nb.txt         tests/input-{4,5}.txt --cols=80 --highlight --no-bold
check_gold gold-45-ln.txt           tests/input-{4,5}.txt --cols=80 --line-numbers
check_gold gold-45-ln-color.txt     tests/input-{4,5}.txt --cols=80 --line-numbers --color-map='line-numbers:cyan'
check_gold gold-45-nh.txt           tests/input-{4,5}.txt --cols=80 --no-headers
check_gold gold-45-h3.txt           tests/input-{4,5}.txt --cols=80 --head=3
check_gold gold-45-l.txt            tests/input-{4,5}.txt --cols=80 -L left
check_gold gold-45-lr.txt           tests/input-{4,5}.txt --cols=80 -L left -L right
check_gold gold-45-lbrb.txt         tests/input-{4,5}.txt --cols=80 -L "L {basename}" -L "R {basename}"
check_gold gold-45-pipe.txt         tests/input-4.txt <(cat tests/input-5.txt) --cols=80 --no-headers
check_gold gold-4dn.txt             tests/input-4.txt /dev/null --cols=80 -L left -L right
check_gold gold-dn5.txt             /dev/null tests/input-5.txt --cols=80 -L left -L right
check_gold gold-67.txt              tests/input-{6,7}.txt --cols=80
check_gold gold-67-wf.txt           tests/input-{6,7}.txt --cols=80 --whole-file
check_gold gold-67-ln.txt           tests/input-{6,7}.txt --cols=80 --line-numbers
check_gold gold-67-u3.txt           tests/input-{6,7}.txt --cols=80 -U 3
check_gold gold-tabs-default.txt    tests/input-{8,9}.txt --cols=80
check_gold gold-tabs-4.txt          tests/input-{8,9}.txt --cols=80 --tabsize=4
check_gold gold-file-not-found.txt  tests/input-4.txt nonexistent_file
check_gold gold-strip-cr-off.txt    tests/input-4.txt tests/input-4-cr.txt --cols=80
check_gold gold-strip-cr-on.txt     tests/input-4.txt tests/input-4-cr.txt --cols=80 --strip-trailing-cr
check_gold gold-no-cr-indent        tests/input-4-cr.txt tests/input-4-partial-cr.txt --cols=80
check_gold gold-hide-cr-if-dos      tests/input-4-cr.txt tests/input-5-cr.txt --cols=80
check_gold gold-12-subcolors.txt    tests/input-{1,2}.txt --cols=80 --color-map='change:magenta,description:cyan_bold'
check_gold gold-subcolors-bad-color tests/input-{1,2}.txt --cols=80 --color-map='change:mageta,description:cyan_bold'
check_gold gold-subcolors-bad-cat tests/input-{1,2}.txt --cols=80 --color-map='chnge:magenta,description:cyan_bold'
check_gold gold-subcolors-bad-fmt tests/input-{1,2}.txt --cols=80 --color-map='change:magenta:gold,description:cyan_bold'
check_gold gold-bad-encoding.txt tests/input-{1,2}.txt --encoding=nonexistend_encoding
check_git_diff gitdiff-only-newlines.txt 4e86205629~1 4e86205629

# Testing pipe behavior doesn't fit well with the check_gold system
$INVOCATION tests/input-{4,5}.txt 2>/tmp/icdiff-pipe-error-output | head -n 1
if [ -s /tmp/icdiff-pipe-error-output ]; then
  echo 'emitting errors on early pipe closure'
  fail
fi

VERSION=$($INVOCATION --version | awk '{print $NF}')
if [ "$VERSION" != $(head -n 1 ChangeLog) ]; then
  echo "Version mismatch between ChangeLog and icdiff source."
  fail
fi

if ! command -v 'flake8' >/dev/null 2>&1; then
  echo 'Could not find flake8. Ensure flake8 is installed and on your $PATH.'
  if [ -z "$VIRTUAL_ENV" ]; then
    echo 'It appears you have have forgotten to activate your virtualenv.'
  fi
  echo 'See README.md for details on setting up your environment.'
  fail
fi

echo 'Running flake8 linter...'
if ! flake8 icdiff; then
  fail
fi

if ! $REGOLD; then
  echo PASS
fi
