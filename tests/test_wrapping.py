import os
import runpy
import subprocess
import sys
import tempfile
import unittest


ICDIFF = os.path.join(os.path.dirname(os.path.dirname(__file__)), "icdiff")
ConsoleDiff = runpy.run_path(ICDIFF)["ConsoleDiff"]


class WrappingTests(unittest.TestCase):
    def test_narrow_automatic_columns_make_progress(self):
        for cols, line_numbers in (
            (2, False),
            (3, False),
            (18, True),
            (19, True),
        ):
            for text in ("abcdef", "a日本b"):
                with self.subTest(
                    cols=cols, line_numbers=line_numbers, text=text
                ):
                    diff = ConsoleDiff(cols=cols, line_numbers=line_numbers)
                    display_len = diff._display_len
                    calls = [0]

                    def bounded_display_len(value):
                        calls[0] += 1
                        if calls[0] > 100:
                            self.fail("line wrapping did not make progress")
                        return display_len(value)

                    diff._display_len = bounded_display_len
                    lines = []
                    diff._split_line(lines, 1, text)
                    self.assertEqual("".join(part for _, part in lines), text)
                    self.assertTrue(all(part for _, part in lines))

    def test_explicit_zero_still_disables_wrapping(self):
        diff = ConsoleDiff(cols=2, wrapcolumn=0)
        lines = list(diff.make_table(["abcdef\n"], ["uvwxyz\n"]))
        self.assertTrue(any("abcdef" in line for line in lines))
        self.assertEqual(diff._wrapcolumn, 0)

    def test_narrow_cli_finishes(self):
        with tempfile.TemporaryDirectory() as directory:
            left = os.path.join(directory, "left.txt")
            right = os.path.join(directory, "right.txt")
            with open(left, "w") as stream:
                stream.write("abc\n")
            with open(right, "w") as stream:
                stream.write("xyz\n")
            for options in (("--cols=2",), ("--cols=19", "--line-numbers")):
                with self.subTest(options=options):
                    process = subprocess.Popen(
                        [sys.executable, ICDIFF, "--no-headers", left, right]
                        + list(options),
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE,
                    )
                    try:
                        stdout, stderr = process.communicate(timeout=3)
                    except subprocess.TimeoutExpired:
                        process.kill()
                        process.communicate()
                        raise
                    self.assertEqual(process.returncode, 1, stderr)
                    self.assertIn(b"a", stdout)
                    self.assertIn(b"x", stdout)
                    self.assertEqual(stderr, b"")


if __name__ == "__main__":
    unittest.main()
