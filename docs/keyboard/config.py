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

# Karabiner F-key/numpad remaps: full_chord_string → (source_physical_key, mod_set).
#
# Convention:
#   • `⇪` (hyper) = all four RIGHT modifiers, produced by Caps Lock remap
#   • Other modifiers (⇧⌃⌥⌘) without `⇪` = LEFT-hand side modifiers
#     (intentional, since the layout is optimized for left-hand operation).
#
# Two routing patterns produce F-keys / numpad codes:
#   (1) Hyper-combo: right_*4 + optional left_<mod> + key  (`⇪key`, `⇪⇧key`, `⇪⌃key`, ...)
#   (2) Left cluster: left_<mods> + key  (no `⇪`, written as `⌃⌥⌘key`, `⇧⌃⌥⌘key`, ...)
#
# Lookup is by the FULL active-chord string (including any modifier prefix on the F-key),
# because different prefixes can map to different physical keys (e.g. `⇧F13` ≠ `⇧` + `F13`).
FKEY_MAPPING = {
    # ── Hyper-only (right_*4 + key) ──
    "F17": ("r", frozenset({"hyper"})),
    "F19": ("v", frozenset({"hyper"})),
    "F20": ("z", frozenset({"hyper"})),
    # ── Hyper + left_shift + key (`⇪⇧key`) ──
    "F14": ("b", frozenset({"hyper", "shift"})),
    "F15": ("f", frozenset({"hyper", "shift"})),
    "F16": ("h", frozenset({"hyper", "shift"})),
    "F18": ("t", frozenset({"hyper", "shift"})),
    "num0": ("space", frozenset({"hyper", "shift"})),
    # ── Hyper + left_ctrl + left_cmd + key (`⇪⌃⌘key`) ──
    "num2": ("q", frozenset({"hyper", "ctrl", "cmd"})),
    # ── Left cluster: 3 left mods (ctrl+opt+cmd, no shift) + key (`⌃⌥⌘key`) ──
    "F13": ("h", frozenset({"ctrl", "alt", "cmd"})),
    # ── Left cluster: all 4 left mods + key (`⇧⌃⌥⌘key`) ──
    "num1":   ("h",     frozenset({"shift", "ctrl", "alt", "cmd"})),
    "⇧F13":   ("down",  frozenset({"shift", "ctrl", "alt", "cmd"})),
    "⌃F13":   ("up",    frozenset({"shift", "ctrl", "alt", "cmd"})),
    "⇧⌃F13":  ("left",  frozenset({"shift", "ctrl", "alt", "cmd"})),
    "⌃⌥F13":  ("right", frozenset({"shift", "ctrl", "alt", "cmd"})),
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

# Physical key id \u2192 display glyph (used when rendering source chords like
# `\u21e7\u2303\u2325\u2318\u2193` from a karabiner-output active chord like `\u21e7F13`).
KEY_DISPLAY = {
    "down": "\u2193", "up": "\u2191", "left": "\u2190", "right": "\u2192",
    "tab": "\u21e5", "tilde": "~", "space": "\u2423", "return": "\u21a9",
    "backspace": "\u232b", "comma": ",", "period": ".", "semicolon": ";",
    "apostrophe": "'", "slash": "/", "bracketleft": "[",
    "bracketright": "]", "backslash": "\\", "minus": "-", "equal": "=",
}

# Default apps for icon resolution (edit when you change default terminal/browser)
DEFAULT_APPS = {"_terminal": "Warp", "_browser": "Firefox"}
MIN_LAYER_ENTRIES = 3
KEY_UNIT = 54
KEY_HEIGHT = 48
KEY_GAP = 4
KEY_RADIUS = 6
