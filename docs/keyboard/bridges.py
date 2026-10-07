"""Bridges: physical chords Karabiner turns into a key only Hammerspoon binds.

Two kinds. Slots: `[slots]` in `karabiner/layers.toml` gives eight Hyper letters
an F-key each, and the generated layers send every modifier variant of the
letter as the same variant of its F-key (`slot_variants`). Exceptions: gestures
no chord can express, on the top keypad row (`EXCEPTIONS`). The chord grammar
(`parse_from`, `parse_to`, `output_entry`) is shared with the layer generator.
"""
import glob
import json
import os
import re
from dataclasses import dataclass

from parse_karabiner import _CONSUMER_SYM, _HYPER, _KEY_SYM, _TO_PHYS, _from_mods_to_layer

ROOT = os.path.normpath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
RULES_DIR = os.path.join(ROOT, "karabiner", "rules")

SLOT_BASES = [f"F{n}" for n in range(13, 21)]
KEYPAD_BASES = [f"num{n}" for n in range(10)]
TO_MODS = ("shift", "ctrl", "alt", "cmd")
FROM_MODS = ("hyper",) + TO_MODS
# Codes outside the formula: emitted key → (physical chords, rule). Punto's ⌥ is the right one.
EXCEPTIONS = {
    "num8": (("⌃⌥ad", "⌃⌥←→"), "32-swap-sides"),
    "num9": (("⌥␣",), "26-right-option-space-punto"),
}

_BRIDGE_KEY_CODE = re.compile(r"^(?:f(1[3-9]|20)|keypad_(\d))$")
_MOUSE = re.compile(r"^mouse\.button\d+(?:\.hold)?$")


@dataclass(frozen=True)
class Bridge:
    from_chord: str
    to: str
    rule: str
    side: str | None = None


def _glyphs():
    # Imported late: config builds FKEY_MAPPING from this module at import time,
    # after it has defined the glyph tables read here.
    from config import BUTTON_FILES, KEY_DISPLAY, MOD_DISPLAY
    return MOD_DISPLAY, KEY_DISPLAY, BUTTON_FILES


def _mods_text(mods):
    mod_display = _glyphs()[0]
    return "".join(mod_display[m] for m in FROM_MODS if m in mods)


def _split_mods(chord, allowed):
    """Leading modifier glyphs → frozenset of names, or None if out of order."""
    mod_display = _glyphs()[0]
    by_glyph = {mod_display[m]: m for m in allowed}
    i = 0
    while i < len(chord) and chord[i] in by_glyph:
        i += 1
    names = [by_glyph[c] for c in chord[:i]]
    if names != [m for m in allowed if m in names]:
        return None, chord[i:]
    return frozenset(names), chord[i:]


def parse_from(chord):
    """`⇪⇧h` → (frozenset({"hyper", "shift"}), ("h",)); simultaneous keys give two ids.

    Mouse rows have no keyboard key: (frozenset(), ()).
    """
    if _MOUSE.match(chord):
        return frozenset(), ()
    _, key_display, button_files = _glyphs()
    keys_by_glyph = {g: k for k, g in key_display.items()}
    keys_by_glyph.update({k: k for k in button_files if len(k) == 1})
    mods, rest = _split_mods(chord, FROM_MODS)
    if mods is None:
        raise ValueError(f"modifiers of `{chord}` are not in ⇪⇧⌃⌥⌘ order")
    if not 1 <= len(rest) <= 2 or any(c not in keys_by_glyph for c in rest):
        raise ValueError(f"`{chord}` is not a modifier prefix plus one or two key glyphs")
    return mods, tuple(keys_by_glyph[c] for c in rest)


PASSTHROUGH = "passthrough"
# _CONSUMER_SYM mixes both Karabiner fields and gives some glyphs two names; these
# are the ones rules 07–17 send, each in the field Karabiner expects it in.
_MEDIA_OUT = {
    "vk_consumer_previous": "key_code", "vk_consumer_next": "key_code",
    "illumination_increment": "key_code", "illumination_decrement": "key_code",
    "play_or_pause": "consumer_key_code",
    "volume_increment": "consumer_key_code", "volume_decrement": "consumer_key_code",
}
_LEFT = {"shift": "left_shift", "ctrl": "left_control", "alt": "left_option", "cmd": "left_command"}
_UNSIDED = {"shift": "shift", "control": "ctrl", "option": "alt", "command": "cmd"}


def _output_tokens():
    """Output token → (Karabiner field, name). Built once, checked for collisions."""
    if _output_tokens.cache is not None:
        return _output_tokens.cache
    key_display = _glyphs()[1]
    table = {}

    def put(token, value):
        if table.setdefault(token, value) != value:
            raise AssertionError(f"output token `{token}` means both {table[token]} and {value}")

    for c in "abcdefghijklmnopqrstuvwxyz0123456789":
        put(c, ("key_code", c))
    for n in range(1, 21):
        put(f"F{n}", ("key_code", f"f{n}"))
    for n in range(10):
        put(f"num{n}", ("key_code", f"keypad_{n}"))
    # non_us_backslash shares the `~` key with grave_accent_and_tilde; rules only
    # ever send it back unchanged, which `passthrough` expresses unambiguously.
    for code, phys in _TO_PHYS.items():
        if phys in key_display and phys != "tilde":
            put(key_display[phys], ("key_code", code))
    for code, glyph in _KEY_SYM.items():
        if code != "non_us_backslash":
            put(glyph, ("key_code", code))
    for name, field in _MEDIA_OUT.items():
        put(_CONSUMER_SYM[name].replace(" ", ""), (field, name))
    _output_tokens.cache = table
    return table


_output_tokens.cache = None


def parse_to(to):
    """`⇧⌃F13` → (frozenset({"shift", "ctrl"}), "F13").

    The key part is any output token (`↑`, `F1`, `a`, `Vol↑`, `passthrough`, …);
    `⇪` stands for the four right modifiers.
    """
    mods, base = _split_mods(to, FROM_MODS)
    if mods is None or (base not in _output_tokens() and base != PASSTHROUGH):
        raise ValueError(f"`{to}` is not ⇪⇧⌃⌥⌘ (in that order) plus one output key")
    return mods, base


def output_entry(to, from_key_code):
    """Glyph text → the Karabiner `to` entry; `passthrough` resends `from_key_code`."""
    mods, base = parse_to(to)
    field, name = ("key_code", from_key_code) if base == PASSTHROUGH else _output_tokens()[base]
    entry = {field: name}
    names = sorted((_HYPER if "hyper" in mods else set()) | {_LEFT[m] for m in mods - {"hyper"}})
    if names:
        if field != "key_code":
            raise ValueError(f"`{to}`: {name} is a consumer key and takes no modifiers")
        entry["modifiers"] = names
    return entry


def render_output(entry, from_key_code):
    """Inverse of `output_entry`, or None when the entry is not one plain key."""
    if set(entry) - {"key_code", "consumer_key_code", "modifiers"}:
        return None
    raw = set(entry.get("modifiers", []))
    mods = set()
    if _HYPER <= raw:
        mods.add("hyper")
        raw -= _HYPER
    for m in raw:
        side, _, bare = m.rpartition("_")
        if side not in ("", "left") or bare not in _UNSIDED:
            return None
        mods.add(_UNSIDED[bare])
    if entry.get("key_code") == from_key_code:
        base = PASSTHROUGH
    else:
        field = "key_code" if "key_code" in entry else "consumer_key_code"
        by_value = {v: t for t, v in _output_tokens().items()}
        base = by_value.get((field, entry.get(field)))
        if base is None:
            return None
    return _mods_text(mods) + base


def slot_variants(rows=None, slots=None):
    """Every key the Hyper layers emit for a slot letter: `to` text → physical chord.

    `⇪v` → `F16`, `⇪⌘v` → `⌘F16`, …; a layer that maps the letter itself
    (`⇪⌘f` → `⌘o`) has no variant for it.
    """
    import layers
    rows = layers.load() if rows is None else rows
    slots = layers.load_slots() if slots is None else slots
    out = {}
    for name in layers.LAYERS:
        for key, to in layers.slot_rows(name, rows, slots):
            out[to] = _mods_text(layers.layer_mods(name)) + _TO_PHYS[key]
    return out


def fkey_mapping(slots=None):
    """`to → (physical key id, modifier set)` for the SVG/lint tools.

    Bare slots only: consumers resolve `⌘F16` by stripping `⌘`, looking up `F16`
    and adding `⌘` back. Exceptions join when their chord is a single key.
    """
    import layers
    slots = layers.load_slots() if slots is None else slots
    mapping = {base: (_TO_PHYS[key], frozenset({"hyper"})) for key, base in slots.items()}
    for to, (chords, _) in EXCEPTIONS.items():
        mods, keys = parse_from(chords[0])
        if len(chords) == 1 and len(keys) == 1:
            mapping[to] = (keys[0], mods)
    return mapping


def _manipulators(path):
    with open(path, encoding="utf-8") as fh:
        data = json.load(fh)
    manips = list(data.get("manipulators", []))
    for rule in data.get("rules", []):
        manips.extend(rule.get("manipulators", []))
    return manips


def _render_to(entry):
    m = _BRIDGE_KEY_CODE.match(entry.get("key_code", ""))
    if not m:
        return None
    base = f"F{m.group(1)}" if m.group(1) else f"num{m.group(2)}"
    mods = _from_mods_to_layer(entry.get("modifiers", []))
    return _mods_text(mods) + base


def _render_from(fr, via, path):
    _, key_display, _ = _glyphs()
    if "pointing_button" in fr:
        return f"mouse.{fr['pointing_button']}" + (".hold" if via == "to_if_held_down" else ""), None
    mandatory = set(fr.get("modifiers", {}).get("mandatory", []))
    plain = mandatory - _HYPER if _HYPER <= mandatory else mandatory
    side = "right" if any(m.startswith("right_") for m in plain) else None
    codes = [s["key_code"] for s in fr["simultaneous"]] if "simultaneous" in fr else [fr["key_code"]]
    unknown = [c for c in codes if c not in _TO_PHYS]
    if unknown:
        raise ValueError(f"{os.path.basename(path)}: no physical key for {unknown}")
    keys = "".join(key_display.get(_TO_PHYS[c], _TO_PHYS[c]) for c in codes)
    return _mods_text(_from_mods_to_layer(mandatory)) + keys, side


def from_rules(rules_dir=RULES_DIR):
    """Every manipulator whose `to` or `to_if_held_down` emits F13–F20 or a keypad digit."""
    rows = []
    for path in sorted(glob.glob(os.path.join(rules_dir, "*.json"))):
        rule = os.path.splitext(os.path.basename(path))[0]
        for m in _manipulators(path):
            for via in ("to", "to_if_held_down"):
                for entry in m.get(via, []):
                    to = _render_to(entry)
                    if to:
                        chord, side = _render_from(m["from"], via, path)
                        rows.append(Bridge(chord, to, rule, side))
    return rows
