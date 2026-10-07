"""Chord glyphs ↔ the encodings macOS stores shortcuts in.

A chord is modifier glyphs in `⇧⌃⌥⌘` order plus one key glyph (`⇧⌘4`, `⌃F2`,
`⌥⌘␣`). Navigation keys are `↖` Home, `↘` End, `PgUp`, `PgDn`, `⌦` forward
delete. Four stores read it differently:

- virtual key codes: `kVK_*` from Carbon's Events.h, ANSI layout;
- Carbon modifier flags (the `KeyboardShortcuts` library's `carbonModifiers`);
- `NSEvent` modifier flags (`com.apple.symbolichotkeys` parameters, MASShortcut);
- Ice's own `Modifiers` option set (⌃ 1, ⌥ 2, ⇧ 4, ⌘ 8);
- `NSUserKeyEquivalents` combos (`@$~^` + the key character), also used by
  Services, which may spell ⇧ as an uppercase letter instead of `$`.

`🌐` is the Globe/fn modifier. Only symbolic hotkeys can hold it, and it is
written only on keys that do not carry it implicitly: macOS sets the fn bit on
every F-key, arrow and navigation key by itself (`⌃F2` is stored with it), so
on those keys the bit says nothing and `🌐` would not round-trip.
"""

MOD_ORDER = ("fn", "shift", "ctrl", "alt", "cmd")
MOD_GLYPH = {"fn": "🌐", "shift": "⇧", "ctrl": "⌃", "alt": "⌥", "cmd": "⌘"}
HYPER = "⇪"
HYPER_MODS = frozenset({"shift", "ctrl", "alt", "cmd"})

CARBON = {"cmd": 256, "shift": 512, "alt": 2048, "ctrl": 4096}
ICE = {"ctrl": 1, "alt": 2, "shift": 4, "cmd": 8}
NS = {"shift": 131072, "ctrl": 262144, "alt": 524288, "cmd": 1048576, "fn": 8388608}
MENU = {"cmd": "@", "shift": "$", "alt": "~", "ctrl": "^"}
MENU_ORDER = ("ctrl", "alt", "shift", "cmd")
NO_KEY = 65535

_LETTERS = dict(zip("asdfhgzxcvbqwerytuiopljkmn", (0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16,
                                                    17, 32, 34, 31, 35, 37, 38, 40, 46, 45)))
_DIGITS = dict(zip("1234567890", (18, 19, 20, 21, 23, 22, 26, 28, 25, 29)))
_PUNCT = {"=": 24, "-": 27, "]": 30, "[": 33, "'": 39, ";": 41, "\\": 42, ",": 43, "/": 44,
          ".": 47, "`": 50}
_FKEYS = dict(zip((f"F{n}" for n in range(1, 21)),
                  (122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111,
                   105, 107, 113, 106, 64, 79, 80, 90)))
_KEYPAD = dict(zip((f"num{n}" for n in range(10)), (82, 83, 84, 85, 86, 87, 88, 89, 91, 92)))
_NAV = {"←": 123, "→": 124, "↓": 125, "↑": 126, "PgUp": 116, "PgDn": 121, "↖": 115, "↘": 119,
        "⌦": 117}
_OTHER = {"␣": 49, "⇥": 48, "↩": 36, "⌫": 51, "⎋": 53}

KEYCODE = {**_LETTERS, **_DIGITS, **_PUNCT, **_FKEYS, **_KEYPAD, **_NAV, **_OTHER}
GLYPH = {code: glyph for glyph, code in KEYCODE.items()}
IMPLICIT_FN = frozenset(_FKEYS) | frozenset(_NAV)
# The layout tables draw the grave key as `~`; in a menu combo `~` is Option.
ALIASES = {"~": "`"}

_PRINTABLE = {**{c: c for c in (*_LETTERS, *_DIGITS, *_PUNCT)}, "␣": " "}
# NSEvent's private-use function-key characters (NSF1FunctionKey = U+F704, …).
_MENU_FKEY = {f"F{n}": chr(0xF704 + n - 1) for n in range(1, 21)}
_MENU_SPECIAL = {"←": "←", "→": "→", "↓": "↓", "↑": "↑", "⇥": "⇥", "↩": "↩", "⌫": "⌫", "⎋": "⎋",
                 "⌦": "⌦", "PgUp": "⇞", "PgDn": "⇟", "↖": "↖", "↘": "↘"}
MENU_CHAR = {**_PRINTABLE, **_MENU_FKEY, **_MENU_SPECIAL}
_MENU_ARROWS_NS = {"\uf700": "↑", "\uf701": "↓", "\uf702": "←", "\uf703": "→"}
MENU_KEY = {**{ch: g for g, ch in MENU_CHAR.items()}, **_MENU_ARROWS_NS}


def parse(keys):
    """`⇧⌘4` → (frozenset({"shift", "cmd"}), "4"). `⇪` expands to ⇧⌃⌥⌘."""
    mods, rest = set(), keys
    if rest.startswith(HYPER):
        mods |= HYPER_MODS
        rest = rest[len(HYPER):]
    by_glyph = {g: m for m, g in MOD_GLYPH.items()}
    seen = []
    while rest and rest[0] in by_glyph:
        seen.append(by_glyph[rest[0]])
        rest = rest[1:]
    if seen != [m for m in MOD_ORDER if m in seen]:
        raise ValueError(f"modifiers of `{keys}` are not in {''.join(MOD_GLYPH.values())} order")
    mods |= set(seen)
    key = ALIASES.get(rest, rest)
    if key not in KEYCODE:
        raise ValueError(f"`{rest}` in `{keys}` has no key code")
    if "fn" in mods and key in IMPLICIT_FN:
        raise ValueError(f"`{keys}`: {key} always carries fn, drop the 🌐")
    return frozenset(mods), key


def render(mods, key):
    return "".join(MOD_GLYPH[m] for m in MOD_ORDER if m in mods) + key


def canonical(keys):
    return render(*parse(keys))


def _chord_to_flags(keys, space, what):
    mods, key = parse(keys)
    if "fn" in mods and "fn" not in space:
        raise ValueError(f"`{keys}`: {what} flags have no fn modifier")
    return KEYCODE[key], sum(space[m] for m in mods)


def _flags_to_chord(keycode, flags, space, what):
    mods = {m for m, bit in space.items() if flags & bit}
    unknown = flags & ~sum(space.values())
    if unknown or keycode not in GLYPH:
        raise ValueError(f"{what} ({keycode}, {flags}) has no chord")
    return render(mods, GLYPH[keycode])


def chord_to_carbon(keys):
    return _chord_to_flags(keys, CARBON, "Carbon")


def carbon_to_chord(keycode, flags):
    return _flags_to_chord(keycode, flags, CARBON, "Carbon")


def chord_to_ice(keys):
    return _chord_to_flags(keys, ICE, "Ice")


def ice_to_chord(keycode, flags):
    return _flags_to_chord(keycode, flags, ICE, "Ice")


def chord_to_ns(keys):
    """(keycode, NSEvent flags) as MASShortcut stores them: no implicit fn bit."""
    mods, key = parse(keys)
    return KEYCODE[key], sum(NS[m] for m in mods)


def ns_to_chord(keycode, flags):
    """Bits outside ⇧⌃⌥⌘🌐 (caps lock, numeric pad, …) are ignored, as for symbolic hotkeys."""
    return symbolic_to_chord([NO_KEY, keycode, flags]) if keycode != NO_KEY else ""


def chord_to_symbolic(keys):
    """[ascii, keycode, NSEvent flags]; `""` is the no-key triple."""
    if keys == "":
        return [NO_KEY, NO_KEY, 0]
    mods, key = parse(keys)
    if key in IMPLICIT_FN:
        mods = mods | {"fn"}
    ascii_code = ord(_PRINTABLE[key]) if key in _PRINTABLE else NO_KEY
    return [ascii_code, KEYCODE[key], sum(NS[m] for m in mods)]


def symbolic_to_chord(params):
    """Inverse of `chord_to_symbolic`. Bits it does not know (numeric pad, …) are ignored."""
    _, keycode, flags = params
    if keycode == NO_KEY:
        return ""
    if keycode not in GLYPH:
        raise ValueError(f"symbolic hotkey key code {keycode} has no glyph")
    key = GLYPH[keycode]
    mods = {m for m, bit in NS.items() if flags & bit}
    if key in IMPLICIT_FN:
        mods.discard("fn")
    return render(mods, key)


def chord_to_menu_combo(keys):
    mods, key = parse(keys)
    if "fn" in mods or key not in MENU_CHAR:
        raise ValueError(f"`{keys}` cannot be a menu key equivalent")
    return "".join(MENU[m] for m in MENU_ORDER if m in mods) + MENU_CHAR[key]


def menu_combo_to_chord(combo):
    by_char = {c: m for m, c in MENU.items()}
    mods, i = set(), 0
    while i < len(combo) - 1 and combo[i] in by_char:
        mods.add(by_char[combo[i]])
        i += 1
    rest = combo[i:]
    if rest not in MENU_KEY:
        raise ValueError(f"menu combo `{combo}`: `{rest}` is not a known key")
    return render(mods, MENU_KEY[rest])


def services_combo_to_chord(combo):
    """A Services `key_equivalent`: a menu combo whose letter may be uppercase for ⇧."""
    if combo[-1:].isalpha() and combo[-1].isupper():
        mods = combo[:-1]
        combo = mods + ("" if "$" in mods else "$") + combo[-1].lower()
    return menu_combo_to_chord(combo)
