color_codes = {
    "red":     '\033[0;31m',
    "green":   '\033[0;32m',
    "yellow":  '\033[0;33m',
    "blue":    '\033[0;34m',
    "magenta": '\033[0;35m',
    "cyan":    '\033[0;36m',
    "none":    '\033[m',
    "red_bold":     '\033[1;31m',
    "green_bold":   '\033[1;32m',
    "yellow_bold":  '\033[1;33m',
    "blue_bold":    '\033[1;34m',
    "magenta_bold": '\033[1;35m',
    "cyan_bold":    '\033[1;36m',
}


def simple_colorize(s, chosen_color):
    return "%s%s%s" % (color_codes[chosen_color], s, color_codes["none"])
