"""Bridges: physical chords Karabiner turns into a key only Hammerspoon binds.

Two kinds. Slots: `[slots]` in `karabiner/layers.toml` gives eight Hyper letters
an F-key each, and the generated layers send every modifier variant of the
letter as the same variant of its F-key (`slot_variants`). Exceptions: gestures
no chord can express, on the top keypad row (`EXCEPTIONS`). The chord grammar
(`parse_to`, `output_entry`) is `karabiner/generator/grammar.py`.
"""
import re
from dataclasses import dataclass

from parse_karabiner import _HYPER, _TO_PHYS, _from_mods_to_layer
from grammar import FROM_MODS, _mods_text, _split_mods

KEYPAD_BASES = [f"num{n}" for n in range(10)]
# Codes outside the formula: emitted key → (physical chords, rule). Punto's ⌥ is the right one;
# ⇥ is the Tab layer (rule 01, held Tab sets a variable), the only way a Tab chord reaches Hammerspoon.
EXCEPTIONS = {
    "num1": (("⇥v",), "01-tab-modifier"),
    "num2": (("⇥f",), "01-tab-modifier"),
    "num3": (("⇥t",), "01-tab-modifier"),
    "num4": (("⌥4",), "18-hyper-misc"),
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


def _render_to(entry):
    m = _BRIDGE_KEY_CODE.match(entry.get("key_code", ""))
    if not m:
        return None
    base = f"F{m.group(1)}" if m.group(1) else f"num{m.group(2)}"
    mods = _from_mods_to_layer(entry.get("modifiers", []))
    return _mods_text(mods) + base


def _render_from(fr, via, rule, conditions=()):
    _, key_display, _ = _glyphs()
    tab = {"tab_mod"} if any(c.get("name") == "tab_modifier" and c.get("value") == 1 for c in conditions) else set()
    if "pointing_button" in fr:
        return f"mouse.{fr['pointing_button']}" + (".hold" if via == "to_if_held_down" else ""), None
    mandatory = set(fr.get("modifiers", {}).get("mandatory", []))
    plain = mandatory - _HYPER if _HYPER <= mandatory else mandatory
    side = "right" if any(m.startswith("right_") for m in plain) else None
    codes = [s["key_code"] for s in fr["simultaneous"]] if "simultaneous" in fr else [fr["key_code"]]
    unknown = [c for c in codes if c not in _TO_PHYS]
    if unknown:
        raise ValueError(f"{rule}: no physical key for {unknown}")
    keys = "".join(key_display.get(_TO_PHYS[c], _TO_PHYS[c]) for c in codes)
    return _mods_text(_from_mods_to_layer(mandatory) | tab) + keys, side


def from_rules(rules=None):
    """Every manipulator whose `to` or `to_if_held_down` emits F13–F20 or a keypad digit."""
    import layers
    rows = []
    for rule, doc in layers.all_rules() if rules is None else rules:
        for m in doc["manipulators"]:
            for via in ("to", "to_if_held_down"):
                for entry in m.get(via, []):
                    to = _render_to(entry)
                    if to:
                        chord, side = _render_from(m["from"], via, rule, m.get("conditions", ()))
                        rows.append(Bridge(chord, to, rule, side))
    return rows
