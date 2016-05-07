#!/usr/bin/env python

""" icdiff.py

Author: Jeff Kaufman, derived from difflib.HtmlDiff

License: This code is usable under the same open terms as the rest of
         python.  See: http://www.python.org/psf/license/

Copyright (c) 2001, 2002, 2003, 2004, 2005, 2006 Python Software Foundation; All Rights Reserved

"""

import os
import re
import sys
import filecmp
import unicodedata
import codecs
from icdiff.consolediff import ConsoleDiff
from icdiff.colorize import simple_colorize


def codec_print(s, options):
    s = "%s\n" % s
    if hasattr(sys.stdout, "buffer"):
        sys.stdout.buffer.write(s.encode(options.output_encoding))
    else:
        sys.stdout.write(s.encode(options.output_encoding))


def diff(options, a, b):
    def print_meta(s):
        codec_print(simple_colorize(s, "magenta"), options)

    if os.path.isfile(a) and os.path.isfile(b):
        if not filecmp.cmp(a, b, shallow=False):
            diff_files(options, a, b)

    elif os.path.isdir(a) and os.path.isdir(b):
        a_contents = set(os.listdir(a))
        b_contents = set(os.listdir(b))

        for child in sorted(a_contents.union(b_contents)):
            if child not in b_contents:
                print_meta("Only in %s: %s" % (a, child))
            elif child not in a_contents:
                print_meta("Only in %s: %s" % (b, child))
            elif options.recursive:
                diff(options,
                     os.path.join(a, child),
                     os.path.join(b, child))
    elif os.path.isdir(a) and os.path.isfile(b):
        print_meta("File %s is a directory while %s is a file" % (a, b))

    elif os.path.isfile(a) and os.path.isdir(b):
        print_meta("File %s is a file while %s is a directory" % (a, b))


def read_file(fname, options):
    try:
        with codecs.open(fname, encoding=options.encoding, mode="rb") as inf:
            return inf.readlines()
    except UnicodeDecodeError as e:
        codec_print(
            "error: file '%s' not valid with encoding '%s': <%s> at %s-%s." %
            (fname, options.encoding, e.reason, e.start, e.end), options)
        raise


def diff_files(options, a, b):
    if options.labels:
        if len(options.labels) == 2:
            headers = options.labels
        else:
            codec_print("error: to use arbitrary file labels, "
                        "specify -L twice.", options)
            return
    else:
        headers = a, b
    if options.no_headers:
        headers = None, None

    head = int(options.head)

    assert not os.path.isdir(a)
    assert not os.path.isdir(b)

    try:
        lines_a = read_file(a, options)
        lines_b = read_file(b, options)
    except UnicodeDecodeError:
        return

    if head != 0:
        lines_a = lines_a[:head]
        lines_b = lines_b[:head]

    cd = ConsoleDiff(cols=int(options.cols),
                     show_all_spaces=options.show_all_spaces,
                     highlight=options.highlight,
                     no_bold=options.no_bold,
                     line_numbers=options.line_numbers,
                     tabsize=int(options.tabsize))
    for line in cd.make_table(
            lines_a, lines_b, headers[0], headers[1],
            context=(not options.whole_file),
            numlines=int(options.unified)):
        codec_print(line, options)
        sys.stdout.flush()

if __name__ == "__main__":
    try:
        start()
    except KeyboardInterrupt:
        pass
    except IOError as e:
        if e.errno == errno.EPIPE:
            pass
        else:
            raise
