"""Physical 60% ANSI keyboard geometry: rows with (display, width_units, key_id)."""

ROWS = [
    [("~", 1, "tilde"), ("1", 1, "1"), ("2", 1, "2"), ("3", 1, "3"), ("4", 1, "4"),
     ("5", 1, "5"), ("6", 1, "6"), ("7", 1, "7"), ("8", 1, "8"), ("9", 1, "9"),
     ("0", 1, "0"), ("-", 1, "minus"), ("=", 1, "equal"), ("\u232b", 2, "backspace")],

    [("\u21e5", 1.5, "tab"), ("Q", 1, "q"), ("W", 1, "w"), ("E", 1, "e"), ("R", 1, "r"),
     ("T", 1, "t"), ("Y", 1, "y"), ("U", 1, "u"), ("I", 1, "i"), ("O", 1, "o"),
     ("P", 1, "p"), ("[", 1, "bracketleft"), ("]", 1, "bracketright"),
     ("\\", 1.5, "backslash")],

    [("\u21ea", 1.75, "capslock"), ("A", 1, "a"), ("S", 1, "s"), ("D", 1, "d"),
     ("F", 1, "f"), ("G", 1, "g"), ("H", 1, "h"), ("J", 1, "j"), ("K", 1, "k"),
     ("L", 1, "l"), (";", 1, "semicolon"), ("'", 1, "apostrophe"),
     ("\u21a9", 2.25, "return")],

    [("\u21e7", 2.25, "shift"), ("Z", 1, "z"), ("X", 1, "x"), ("C", 1, "c"),
     ("V", 1, "v"), ("B", 1, "b"), ("N", 1, "n"), ("M", 1, "m"),
     (",", 1, "comma"), (".", 1, "period"), ("/", 1, "slash"),
     ("\u21e7", 2.75, "shift_r")],

    [("\u2303", 1.25, "ctrl"), ("\u2325", 1.25, "opt"), ("\u2318", 1.25, "cmd"),
     ("", 6.25, "space"), ("\u2318", 1.25, "cmd_r"), ("\u2325", 1.25, "opt_r"),
     ("\u2190", 1, "left"), ("\u2191\u2193", 1, "updown"), ("\u2192", 1, "right")],
]

# Map key_id used in ROWS to the key_id used in button files / chord parsing
KEY_ALIASES = {
    "shift_r": "shift", "cmd_r": "cmd", "opt_r": "opt",
    "updown": "up",  # up/down share a column
}


def get_key_id(row_key_id):
    """Resolve aliases to canonical key id for entry lookup."""
    return KEY_ALIASES.get(row_key_id, row_key_id)
