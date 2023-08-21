#!/usr/bin/env python3

""" icdiff.py

Author: Jeff Kaufman, derived from difflib.HtmlDiff

License: This code is usable under the same open terms as the rest of
         python.  See: http://www.python.org/psf/license/

Copyright (c) 2001, 2002, 2003, 2004, 2005, 2006 Python Software Foundation;
All Rights Reserved

Based on Python's difflib.HtmlDiff,
with changes to provide console output instead of html output.  """

import os
import stat
import sys
import errno
import difflib
from optparse import Option, OptionParser
import re
import filecmp
import unicodedata
import codecs
import fnmatch

__version__ = "2.0.7"

# Exit code constants
EXIT_CODE_SUCCESS = 0
EXIT_CODE_DIFF = 1
EXIT_CODE_ERROR = 2

color_codes = {
    "black": "\033[0;30m",
    "red": "\033[0;31m",
    "green": "\033[0;32m",
    "yellow": "\033[0;33m",
    "blue": "\033[0;34m",
    "magenta": "\033[0;35m",
    "cyan": "\033[0;36m",
    "white": "\033[0;37m",
    "none": "\033[m",
    "black_bold": "\033[1;30m",
    "red_bold": "\033[1;31m",
    "green_bold": "\033[1;32m",
    "yellow_bold": "\033[1;33m",
    "blue_bold": "\033[1;34m",
    "magenta_bold": "\033[1;35m",
    "cyan_bold": "\033[1;36m",
    "white_bold": "\033[1;37m",
}


color_mapping = {
    "add": "green_bold",
    "subtract": "red_bold",
    "change": "yellow_bold",
    "separator": "blue",
    "description": "blue",
    "permissions": "yellow",
    "meta": "magenta",
    "line-numbers": "white",
}


class ConsoleDiff(object):
    """Console colored side by side comparison with change highlights.

    Based on difflib.HtmlDiff

    This class can be used to create a text-mode table showing a side

    by side, line by line comparison of text with inter-line and
    intra-line change highlights in ansi color escape sequences as
    intra-line change highlights in ansi color escape sequences as
    read by xterm.  The table can be generated in either full or
    contextual difference mode.

    To generate the table, call make_table.

    Usage is the almost the same as HtmlDiff except only make_table is
    implemented and the file can be invoked on the command line.
    Run::

      python icdiff.py --help

    for command line usage information.

    """

    def __init__(
        self,
        tabsize=8,
        wrapcolumn=None,
        linejunk=None,
        charjunk=difflib.IS_CHARACTER_JUNK,
        cols=80,
        line_numbers=False,
        show_all_spaces=False,
        show_no_spaces=False,
        highlight=False,
        truncate=False,
        strip_trailing_cr=False,
    ):
        """ConsoleDiff instance initializer

        Arguments:
        tabsize -- tab stop spacing, defaults to 8.
        wrapcolumn -- column number where lines are broken and wrapped,
            defaults to None where lines are not wrapped.
        linejunk, charjunk -- keyword arguments passed into ndiff() (used by
            ConsoleDiff() to generate the side by side differences).  See
            ndiff() documentation for argument default values and descriptions.
        """

        self._tabsize = tabsize
        self.line_numbers = line_numbers
        self.cols = cols
        self.show_all_spaces = show_all_spaces
        self.show_no_spaces = show_no_spaces
        self.highlight = highlight
        self.strip_trailing_cr = strip_trailing_cr
        self.truncate = truncate

        if wrapcolumn is None:
            if not line_numbers:
                wrapcolumn = self.cols // 2 - 2
            else:
                wrapcolumn = self.cols // 2 - 10

        self._wrapcolumn = wrapcolumn
        self._linejunk = linejunk
        self._charjunk = charjunk

    def _tab_newline_replace(self, fromlines, tolines):
        """Returns from/to line lists with tabs expanded and newlines removed.

        Instead of tab characters being replaced by the number of spaces
        needed to fill in to the next tab stop, this function will fill
        the space with tab characters.  This is done so that the difference
        algorithms can identify changes in a file when tabs are replaced by
        spaces and vice versa.  At the end of the table generation, the tab
        characters will be replaced with a space.
        """

        def expand_tabs(line):
            # hide real spaces
            line = line.replace(" ", "\0")
            # expand tabs into spaces
            line = line.expandtabs(self._tabsize)
            # replace spaces from expanded tabs back into tab characters
            # (we'll replace them with markup after we do differencing)
            line = line.replace(" ", "\t")
            return line.replace("\0", " ").rstrip("\n")

        fromlines = [expand_tabs(line) for line in fromlines]
        tolines = [expand_tabs(line) for line in tolines]
        return fromlines, tolines

    def _strip_trailing_cr(self, lines):
        """Remove windows return carriage"""
        lines = [line.rstrip("\r") for line in lines]
        return lines

    def _all_cr_nl(self, lines):
        """Whether a file is entirely \r\n line endings"""
        return all(line.endswith("\r") for line in lines)

    def _display_len(self, s):
        # Handle wide characters like Chinese.
        def width(c):
            if isinstance(c, type("")) and unicodedata.east_asian_width(c) in [
                "F",
                "W",
            ]:
                return 2
            elif c == "\r":
                return 2
            return 1

        return sum(width(c) for c in s)

    def _split_line(self, data_list, line_num, text):
        """Builds list of text lines by splitting text lines at wrap point

        This function will determine if the input text line needs to be
        wrapped (split) into separate lines.  If so, the first wrap point
        will be determined and the first line appended to the output
        text line list.  This function is used recursively to handle
        the second part of the split line to further split it.
        """

        while True:
            # if blank line or context separator, just add it to the output
            # list
            if not line_num:
                data_list.append((line_num, text))
                return

            # if line text doesn't need wrapping, just add it to the output
            # list
            if (
                self._display_len(text) - (text.count("\0") * 3)
                <= self._wrapcolumn
            ):
                data_list.append((line_num, text))
                return

            # scan text looking for the wrap point, keeping track if the wrap
            # point is inside markers
            i = 0
            n = 0
            mark = ""
            while n < self._wrapcolumn and i < len(text):
                if text[i] == "\0":
                    i += 1
                    mark = text[i]
                    i += 1
                elif text[i] == "\1":
                    i += 1
                    mark = ""
                else:
                    n += self._display_len(text[i])
                    i += 1

            # wrap point is inside text, break it up into separate lines
            line1 = text[:i]
            line2 = text[i:]

            # if wrap point is inside markers, place end marker at end of first
            # line and start marker at beginning of second line because each
            # line will have its own table tag markup around it.
            if mark:
                line1 = line1 + "\1"
                line2 = "\0" + mark + line2

            # tack on first line onto the output list
            data_list.append((line_num, line1))

            # use this routine again to wrap the remaining text
            # unless truncate is set
            if self.truncate:
                return
            line_num = ">"
            text = line2

    def _line_wrapper(self, diffs):
        """Returns iterator that splits (wraps) mdiff text lines"""

        # pull from/to data and flags from mdiff iterator
        for fromdata, todata, flag in diffs:
            # check for context separators and pass them through
            if flag is None:
                yield fromdata, todata, flag
                continue
            (fromline, fromtext), (toline, totext) = fromdata, todata
            # for each from/to line split it at the wrap column to form
            # list of text lines.
            fromlist, tolist = [], []
            self._split_line(fromlist, fromline, fromtext)
            self._split_line(tolist, toline, totext)
            # yield from/to line in pairs inserting blank lines as
            # necessary when one side has more wrapped lines
            while fromlist or tolist:
                if fromlist:
                    fromdata = fromlist.pop(0)
                else:
                    fromdata = ("", " ")
                if tolist:
                    todata = tolist.pop(0)
                else:
                    todata = ("", " ")
                yield fromdata, todata, flag

    def _collect_lines(self, diffs):
        """Collects mdiff output into separate lists

        Before storing the mdiff from/to data into a list, it is converted
        into a single line of text with console markup.
        """

        # pull from/to data and flags from mdiff style iterator
        for fromdata, todata, flag in diffs:
            if (fromdata, todata, flag) == (None, None, None):
                yield None
            else:
                yield (
                    self._format_line(*fromdata),
                    self._format_line(*todata),
                )

    def _format_line(self, linenum, text):
        text = text.rstrip()
        if not self.line_numbers:
            return text
        return self._add_line_numbers(linenum, text)

    def _add_line_numbers(self, linenum, text):
        try:
            lid = "%d" % linenum
        except TypeError:
            # handle blank lines where linenum is '>' or ''
            lid = ""
            return text
        return "%s %s" % (
            self._rpad(simple_colorize(str(lid), "line-numbers"), 8),
            text,
        )

    def _real_len(self, s):
        s_len = 0
        in_esc = False
        prev = " "
        for c in replace_all(
            {"\0+": "", "\0-": "", "\0^": "", "\1": "", "\t": " "}, s
        ):
            if in_esc:
                if c == "m":
                    in_esc = False
            else:
                if c == "[" and prev == "\033":
                    in_esc = True
                    s_len -= 1  # we counted prev when we shouldn't have
                else:
                    s_len += self._display_len(c)
            prev = c

        return s_len

    def _rpad(self, s, field_width):
        return self._pad(s, field_width) + s

    def _pad(self, s, field_width):
        return " " * (field_width - self._real_len(s))

    def _lpad(self, s, field_width):
        return s + self._pad(s, field_width)

    def make_table(
        self,
        fromlines,
        tolines,
        fromdesc="",
        todesc="",
        fromperms=None,
        toperms=None,
        context=False,
        numlines=5,
    ):
        """Generates table of side by side comparison with change highlights

        Arguments:
        fromlines -- list of "from" lines
        tolines -- list of "to" lines
        fromdesc -- "from" file column header string
        todesc -- "to" file column header string
        fromperms -- "from" file permissions
        toperms -- "to" file permissions
        context -- set to True for contextual differences (defaults to False
            which shows full differences).
        numlines -- number of context lines.  When context is set True,
            controls number of lines displayed before and after the change.
            When context is False, controls the number of lines to place
            the "next" link anchors before the next change (so click of
            "next" link jumps to just before the change).
        """
        if context:
            context_lines = numlines
        else:
            context_lines = None

        # change tabs to spaces before it gets more difficult after we insert
        # markup
        fromlines, tolines = self._tab_newline_replace(fromlines, tolines)

        if self.strip_trailing_cr or (
            self._all_cr_nl(fromlines) and self._all_cr_nl(tolines)
        ):
            fromlines = self._strip_trailing_cr(fromlines)
            tolines = self._strip_trailing_cr(tolines)

        # create diffs iterator which generates side by side from/to data
        diffs = difflib._mdiff(
            fromlines,
            tolines,
            context_lines,
            linejunk=self._linejunk,
            charjunk=self._charjunk,
        )

        # set up iterator to wrap lines that exceed desired width
        if self._wrapcolumn:
            diffs = self._line_wrapper(diffs)
        diffs = self._collect_lines(diffs)

        for left, right in self._generate_table(
            fromdesc, todesc, fromperms, toperms, diffs
        ):
            yield self.colorize(
                "%s %s"
                % (
                    self._lpad(left, self.cols // 2 - 1),
                    self._lpad(right, self.cols // 2 - 1),
                )
            )

    def _generate_table(self, fromdesc, todesc, fromperms, toperms, diffs):
        if fromdesc or todesc:
            yield (
                simple_colorize(fromdesc, "description"),
                simple_colorize(todesc, "description"),
            )

        if fromperms != toperms:
            yield (
                simple_colorize(
                    f"{stat.filemode(fromperms)} ({fromperms:o})",
                    "permissions",
                ),
                simple_colorize(
                    f"{stat.filemode(toperms)} ({toperms:o})", "permissions"
                ),
            )

        for i, line in enumerate(diffs):
            if line is None:
                # mdiff yields None on separator lines; skip the bogus ones
                # generated for the first line
                if i > 0:
                    yield (
                        simple_colorize("---", "separator"),
                        simple_colorize("---", "separator"),
                    )
            else:
                yield line

    def colorize(self, s):
        def background(color):
            return replace_all(
                {"\033[1;": "\033[7;1;", "\033[0;": "\033[7;"}, color
            )

        C_ADD = color_codes[color_mapping["add"]]
        C_SUB = color_codes[color_mapping["subtract"]]
        C_CHG = color_codes[color_mapping["change"]]

        if self.highlight:
            C_ADD, C_SUB, C_CHG = (
                background(C_ADD),
                background(C_SUB),
                background(C_CHG),
            )

        C_NONE = color_codes["none"]
        colors = (C_ADD, C_SUB, C_CHG, C_NONE)

        s = replace_all(
            {
                "\0+": C_ADD,
                "\0-": C_SUB,
                "\0^": C_CHG,
                "\1": C_NONE,
                "\t": " ",
                "\r": "\\r",
            },
            s,
        )

        if self.highlight:
            return s

        if self.show_no_spaces:
            # Don't show whitespace even if it's a whitespace-only line.
            return re.sub(
                "\033\\[[01];3([01234567])m(\\s+)(\033\\[)",
                "\033[0;3\\1m\\2\\3",
                s,
            )

        elif not self.show_all_spaces:
            # If there's a change consisting entirely of whitespace,
            # don't color it.
            return re.sub(
                "\033\\[[01];3([01234567])m(\\s+)(\033\\[)",
                "\033[7;3\\1m\\2\\3",
                s,
            )

        def will_see_coloredspace(i, s):
            while i < len(s) and s[i].isspace():
                i += 1
            if i < len(s) and s[i] == "\033":
                return False
            return True

        n_s = []
        in_color = False
        seen_coloredspace = False
        for i, c in enumerate(s):
            if len(n_s) > 6 and n_s[-1] == "m":
                ns_end = "".join(n_s[-7:])
                for color in colors:
                    if ns_end.endswith(color):
                        if color != in_color:
                            seen_coloredspace = False
                        in_color = color
                if ns_end.endswith(C_NONE):
                    in_color = False

            if (
                c.isspace()
                and in_color
                and (
                    self.show_all_spaces
                    or not (seen_coloredspace or will_see_coloredspace(i, s))
                )
            ):
                n_s.extend([C_NONE, background(in_color), c, C_NONE, in_color])
            else:
                if in_color:
                    seen_coloredspace = True
                n_s.append(c)

        joined = "".join(n_s)

        return joined


def raw_colorize(s, color):
    return "%s%s%s" % (color_codes[color], s, color_codes["none"])


def simple_colorize(s, category):
    return raw_colorize(s, color_mapping[category])


def replace_all(replacements, string):
    for search, replace in replacements.items():
        string = string.replace(search, replace)
    return string


class MultipleOption(Option):
    ACTIONS = Option.ACTIONS + ("extend",)
    STORE_ACTIONS = Option.STORE_ACTIONS + ("extend",)
    TYPED_ACTIONS = Option.TYPED_ACTIONS + ("extend",)
    ALWAYS_TYPED_ACTIONS = Option.ALWAYS_TYPED_ACTIONS + ("extend",)

    def take_action(self, action, dest, opt, value, values, parser):
        if action == "extend":
            values.ensure_value(dest, []).append(value)
        else:
            Option.take_action(self, action, dest, opt, value, values, parser)


def create_option_parser():
    # If you change any of these, also update README.
    parser = OptionParser(
        usage="usage: %prog [options] left_file right_file",
        version="icdiff version %s" % __version__,
        description="Show differences between files in a " "two column view.",
        option_class=MultipleOption,
    )
    parser.add_option(
        "--cols",
        default=None,
        help="specify the width of the screen. Autodetection is " "Unix only",
    )
    parser.add_option(
        "--encoding",
        default="utf-8",
        help="specify the file encoding; defaults to utf8",
    )
    parser.add_option(
        "-E",
        "--exclude-lines",
        action="store",
        type="string",
        dest="matcher",
        help="Do not diff lines that match this regex. Not "
        "compatible with the 'line-numbers' option",
    )
    parser.add_option(
        "--head",
        default=0,
        help="consider only the first N lines of each file",
    )
    parser.add_option(
        "-H",
        "--highlight",
        default=False,
        action="store_true",
        help="color by changing the background color instead of "
        "the foreground color.  Very fast, ugly, displays all "
        "changes",
    )
    parser.add_option(
        "-L",
        "--label",
        action="extend",
        type="string",
        dest="labels",
        help="override file labels with arbitrary tags. "
        "Use twice, one for each file. You may include the "
        "formatting strings '{path}' and '{basename}'",
    )
    parser.add_option(
        "-N",
        "--line-numbers",
        default=False,
        action="store_true",
        help="generate output with line numbers. Not compatible "
        "with the 'exclude-lines' option.",
    )
    parser.add_option(
        "--no-bold",
        default=False,
        action="store_true",
        help="use non-bold colors; recommended for solarized",
    )
    parser.add_option(
        "--no-headers",
        default=False,
        action="store_true",
        help="don't label the left and right sides " "with their file names",
    )
    parser.add_option(
        "--output-encoding",
        default="utf-8",
        help="specify the output encoding; defaults to utf8",
    )
    parser.add_option(
        "-r",
        "--recursive",
        default=False,
        action="store_true",
        help="recursively compare subdirectories",
    )
    parser.add_option(
        "-s",
        "--report-identical-files",
        default=False,
        action="store_true",
        help="report when two files are the same",
    )
    parser.add_option(
        "--show-all-spaces",
        default=False,
        action="store_true",
        help="color all non-matching whitespace including "
        "that which is not needed for drawing the eye to "
        "changes.  Slow, ugly, displays all changes",
    )
    parser.add_option(
        "--show-no-spaces",
        default=False,
        action="store_true",
        help="don't color whitespace-only changes",
    )
    parser.add_option("--tabsize", default=8, help="tab stop spacing")
    parser.add_option(
        "-t",
        "--truncate",
        default=False,
        action="store_true",
        help="truncate long lines instead of wrapping them",
    )
    parser.add_option(
        "-u",
        "--patch",
        default=True,
        action="store_true",
        help="generate patch. This is always true, "
        "and only exists for compatibility",
    )
    parser.add_option(
        "-U",
        "--unified",
        "--numlines",
        default=5,
        metavar="NUM",
        help="how many lines of context to print; "
        "can't be combined with --whole-file",
    )
    parser.add_option(
        "-W",
        "--whole-file",
        default=False,
        action="store_true",
        help="show the whole file instead of just changed "
        "lines and context",
    )
    parser.add_option(
        "-P",
        "--permissions",
        default=False,
        action="store_true",
        help="compare the file permissions as well as the "
        "content of the file",
    )
    parser.add_option(
        "--strip-trailing-cr",
        default=False,
        action="store_true",
        help="strip any trailing carriage return at the end of "
        "an input line",
    )
    parser.add_option(
        "--color-map",
        default=None,
        help="choose which colors are used for which items. "
        "Default is --color-map='"
        + ",".join("%s:%s" % x for x in sorted(color_mapping.items()))
        + "'"
        ".  You don't have to override all of them: "
        "'--color-map=separator:white,description:cyan",
    )
    parser.add_option(
        "--is-git-diff",
        default=False,
        action="store_true",
        help="Show the real file name when displaying " "git-diff result",
    )
    parser.add_option(
        "-x",
        "--exclude",
        metavar="PAT",
        action="append",
        default=[],
        help="exclude files that match PAT",
    )
    return parser


def set_cols_option(options):
    if os.name == "nt":
        try:
            import struct
            from ctypes import windll, create_string_buffer

            fh = windll.kernel32.GetStdHandle(-12)  # stderr is -12
            csbi = create_string_buffer(22)
            windll.kernel32.GetConsoleScreenBufferInfo(fh, csbi)
            res = struct.unpack("hhhhHhhhhhh", csbi.raw)
            options.cols = res[7] - res[5] + 1  # right - left + 1
            return

        except Exception:
            pass

    else:

        def ioctl_GWINSZ(fd):
            try:
                import fcntl
                import termios
                import struct

                cr = struct.unpack(
                    "hh", fcntl.ioctl(fd, termios.TIOCGWINSZ, "1234")
                )
            except Exception:
                return None
            return cr

        cr = ioctl_GWINSZ(0) or ioctl_GWINSZ(1) or ioctl_GWINSZ(2)
        if cr and cr[1] > 0:
            options.cols = cr[1]
            return
    options.cols = 80


def validate_has_two_arguments(parser, args):
    if len(args) != 2:
        parser.print_help()
        sys.exit(EXIT_CODE_DIFF)


def start():
    diffs_found = False
    parser = create_option_parser()
    options, args = parser.parse_args()
    validate_has_two_arguments(parser, args)
    if not options.cols:
        set_cols_option(options)
    try:
        diffs_found = diff(options, *args)
    except KeyboardInterrupt:
        pass
    except IOError as e:
        if e.errno == errno.EPIPE:
            pass
        else:
            raise

    # Close stderr to prevent printing errors when icdiff is piped to
    # something that closes before icdiff is done writing
    #
    # See: https://stackoverflow.com/questions/26692284/...
    #      ...how-to-prevent-brokenpipeerror-when-doing-a-flush-in-python
    sys.stderr.close()
    sys.exit(EXIT_CODE_DIFF if diffs_found else EXIT_CODE_SUCCESS)


def codec_print(s, options):
    s = "%s\n" % s
    if hasattr(sys.stdout, "buffer"):
        sys.stdout.buffer.write(s.encode(options.output_encoding))
    else:
        sys.stdout.write(s.encode(options.output_encoding))


def cmp_perms(options, a, b):
    return not options.permissions or (
        os.lstat(a).st_mode == os.lstat(b).st_mode
    )


def should_be_excluded(name, pats):
    return any(fnmatch.fnmatchcase(name, pat) for pat in pats)


def diff(options, a, b):
    def print_meta(s):
        codec_print(simple_colorize(s, "meta"), options)

    # We start out and assume that no diffs have been found (so far)
    diffs_found = False

    # Don't use os.path.isfile; it returns False for file-like entities like
    # bash's process substitution (/dev/fd/N).
    is_a_file = not os.path.isdir(a)
    is_b_file = not os.path.isdir(b)

    if is_a_file and is_b_file:
        try:
            if not (
                filecmp.cmp(a, b, shallow=False) and cmp_perms(options, a, b)
            ):
                diffs_found = diffs_found | diff_files(options, a, b)
            elif options.report_identical_files:
                print("Files %s and %s are identical." % (a, b))
        except OSError as e:
            if e.errno == errno.ENOENT:
                print_meta("error: file '%s' was not found" % e.filename)
                sys.exit(EXIT_CODE_ERROR)
            else:
                raise (e)

    elif not is_a_file and not is_b_file:
        a_contents = set(os.listdir(a))
        b_contents = set(os.listdir(b))

        for child in sorted(a_contents.union(b_contents)):
            if should_be_excluded(child, options.exclude):
                continue
            if child not in b_contents:
                print_meta("Only in %s: %s" % (a, child))
            elif child not in a_contents:
                print_meta("Only in %s: %s" % (b, child))
            elif options.recursive:
                diffs_found = diffs_found | diff(
                    options, os.path.join(a, child), os.path.join(b, child)
                )
    elif not is_a_file and is_b_file:
        print_meta("File %s is a directory while %s is a file" % (a, b))
        diffs_found = True

    elif is_a_file and not is_b_file:
        print_meta("File %s is a file while %s is a directory" % (a, b))
        diffs_found = True

    return diffs_found


def read_file(fname, options):
    try:
        with codecs.open(fname, encoding=options.encoding, mode="rb") as inf:
            return inf.readlines()
    except UnicodeDecodeError as e:
        codec_print(
            "error: file '%s' not valid with encoding '%s': <%s> at %s-%s."
            % (fname, options.encoding, e.reason, e.start, e.end),
            options,
        )
        raise
    except LookupError:
        codec_print(
            "error: encoding '%s' was not found." % (options.encoding), options
        )
        sys.exit(EXIT_CODE_ERROR)


def format_label(path, label="{path}"):
    """Format a label using a file's path and basename.

    Example:
      For file `/foo/bar.py` and label "Yours: {basename}" -
      The output is "Yours: bar.py"
    """
    return label.format(path=path, basename=os.path.basename(path))


def diff_files(options, a, b):
    diff_found = False
    if options.is_git_diff is True:
        # Use $BASE as label when displaying git-diff result
        base = os.getenv("BASE")
        headers = [format_label(a, base), format_label(b, base)]
    else:
        if options.labels:
            if len(options.labels) == 2:
                headers = [
                    format_label(a, options.labels[0]),
                    format_label(b, options.labels[1]),
                ]
            else:
                codec_print(
                    "error: to use arbitrary file labels, "
                    "specify -L twice.",
                    options,
                )
                sys.exit(EXIT_CODE_ERROR)
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
        return diff_found

    if head != 0:
        lines_a = lines_a[:head]
        lines_b = lines_b[:head]

    if options.matcher:
        lines_a = [
            line_a
            for line_a in lines_a
            if not re.search(options.matcher, line_a)
        ]
        lines_b = [
            line_b
            for line_b in lines_b
            if not re.search(options.matcher, line_b)
        ]

    # Determine if a difference has been detected
    diff_found = lines_a != lines_b or not cmp_perms(options, a, b)

    if options.no_bold:
        for key in color_mapping:
            color_mapping[key] = color_mapping[key].replace("_bold", "")

    if options.color_map:
        command_for_errors = '--color-map="%s"' % (options.color_map)
        for mapping in options.color_map.split(","):
            category, color = mapping.split(":", 1)

            if category not in color_mapping:
                print(
                    "Invalid category '%s' in '%s'.  Valid categories are: %s."
                    % (
                        category,
                        command_for_errors,
                        ", ".join(sorted(color_mapping.keys())),
                    )
                )
                sys.exit(EXIT_CODE_ERROR)

            if color not in color_codes:
                print(
                    "Invalid color '%s' in '%s'.  Valid colors are: %s."
                    % (
                        color,
                        command_for_errors,
                        ", ".join(
                            [
                                raw_colorize(x, x)
                                for x in sorted(color_codes.keys())
                            ]
                        ),
                    )
                )
                sys.exit(EXIT_CODE_ERROR)

            color_mapping[category] = color

    if options.permissions:
        mode_a = os.lstat(a).st_mode
        mode_b = os.lstat(b).st_mode
    else:
        mode_a = None
        mode_b = None

    cd = ConsoleDiff(
        cols=int(options.cols),
        show_all_spaces=options.show_all_spaces,
        show_no_spaces=options.show_no_spaces,
        highlight=options.highlight,
        line_numbers=options.line_numbers,
        tabsize=int(options.tabsize),
        truncate=options.truncate,
        strip_trailing_cr=options.strip_trailing_cr,
    )
    for line in cd.make_table(
        lines_a,
        lines_b,
        headers[0],
        headers[1],
        mode_a,
        mode_b,
        context=(not options.whole_file),
        numlines=int(options.unified),
    ):
        codec_print(line, options)
        sys.stdout.flush()

    return diff_found


if __name__ == "__main__":
    start()
