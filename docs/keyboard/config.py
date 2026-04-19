"""Constants: button files, modifier symbols, F-key mapping, rendering."""
import os

LAYOUT_DIR = os.path.join(os.path.dirname(__file__),
    "..", "..", "hammerspoon", "Spoons", "Hotkeys.spoon", "layout", "60%")

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

# Karabiner F-key remaps: (physical_key, implicit_modifiers)
FKEY_MAPPING = {
    "F17": ("r", frozenset({"hyper"})),
    "F19": ("v", frozenset({"hyper"})),
    "F20": ("z", frozenset({"hyper"})),
    "F14": ("b", frozenset({"hyper", "shift"})),
    "F15": ("f", frozenset({"hyper", "shift"})),
    "F16": ("h", frozenset({"hyper", "shift"})),
    "F18": ("t", frozenset({"hyper", "shift"})),
}
FKEY_TO_PHYSICAL = {k: v[0] for k, v in FKEY_MAPPING.items()}

# Map modifier names to physical key_ids for highlighting
MOD_TO_KEYS = {
    "hyper": {"capslock"}, "shift": {"shift", "shift_r"},
    "ctrl": {"ctrl"}, "alt": {"opt", "opt_r"}, "cmd": {"cmd", "cmd_r"},
    "tab_mod": {"tab"},
}

MOD_ORDER = ["hyper", "shift", "ctrl", "alt", "cmd", "tab_mod"]
MOD_DISPLAY = {"hyper": "\u21ea", "shift": "\u21e7", "ctrl": "\u2303",
               "alt": "\u2325", "cmd": "\u2318", "tab_mod": "\u21e5"}

# Default apps for icon resolution (edit when you change default terminal/browser)
DEFAULT_APPS = {"_terminal": "Warp", "_browser": "Firefox"}
MIN_LAYER_ENTRIES = 3
KEY_UNIT = 54
KEY_HEIGHT = 48
KEY_GAP = 4
KEY_RADIUS = 6
