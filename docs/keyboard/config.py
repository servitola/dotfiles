"""Constants: button files, modifier symbols, F-key mapping, rendering."""
import os

LAYOUT_DIR = os.path.join(os.path.dirname(__file__),
    "..", "..", "hammerspoon", "Spoons", "HotKeys.spoon", "layout", "60%")

BUTTON_FILES = [
    "tilde", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0",
    "minus", "equal", "backspace", "tab",
    "q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
    "bracketleft", "bracketright", "return", "capslock",
    "a", "s", "d", "f", "g", "h", "j", "k", "l",
    "semicolon", "apostrophe", "backslash", "shift",
    "z", "x", "c", "v", "b", "n", "m",
    "period", "comma", "slash", "space",
    "left", "up", "down", "right",
]

MODIFIER_SYMBOLS = {"⇪": "hyper", "⇧": "shift", "⌃": "ctrl", "⌥": "alt", "⌘": "cmd"}

# Map modifier names to physical key_ids for highlighting
MOD_TO_KEYS = {
    "hyper": {"capslock"}, "shift": {"shift", "shift_r"},
    "ctrl": {"ctrl"}, "alt": {"opt", "opt_r"}, "cmd": {"cmd", "cmd_r"},
    "tab_mod": {"tab"},
    "fn": set(),  # the 60% board drawn here has no fn key
}

MOD_ORDER = ["hyper", "shift", "ctrl", "alt", "cmd", "tab_mod", "fn"]
MOD_DISPLAY = {"hyper": "\u21ea", "shift": "\u21e7", "ctrl": "\u2303",
               "alt": "\u2325", "cmd": "\u2318", "tab_mod": "\u21e5", "fn": "fn "}

# Physical key id \u2192 display glyph (used when rendering source chords like
# `\u21e7\u2303\u2325\u2318\u2193` from a karabiner-output active chord like `\u21e7F13`).
KEY_DISPLAY = {
    "down": "\u2193", "up": "\u2191", "left": "\u2190", "right": "\u2192",
    "tab": "\u21e5", "tilde": "~", "space": "\u2423", "return": "\u21a9",
    "backspace": "\u232b", "comma": ",", "period": ".", "semicolon": ";",
    "apostrophe": "'", "slash": "/", "bracketleft": "[",
    "bracketright": "]", "backslash": "\\", "minus": "-", "equal": "=",
}

# Active chord (`F16`, `num9`) → (source physical key, modifier set), from `[slots]` in
# karabiner/layers.toml. Assigned after KEY_DISPLAY/MOD_DISPLAY: bridges reads them.
import bridges
FKEY_MAPPING = bridges.fkey_mapping()
FKEY_TO_PHYSICAL = {k: v[0] for k, v in FKEY_MAPPING.items()}

# Default apps for icon resolution (edit when you change default terminal/browser)
DEFAULT_APPS = {"_terminal": "Zap", "_browser": "Firefox"}
MIN_LAYER_ENTRIES = 3
KEY_UNIT = 54
KEY_HEIGHT = 48
KEY_GAP = 4
KEY_RADIUS = 6
