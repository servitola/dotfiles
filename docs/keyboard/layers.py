"""`karabiner/layers.toml` (tables + `[slots]`) + `layers.raw/` → rules 07–17 (Hyper) and the `PLAIN` layers.

One table per layer; key = Karabiner `key_code` of the pressed key, value = the
glyph text `bridges.output_entry` understands. `[slots]` maps a letter to its
F-key; every layer without its own entry for that letter sends the slot with the
layer's left modifiers.
"""
import glob
import json
import os
import re
import tomllib
from dataclasses import dataclass, field

import bridges
from parse_karabiner import _HYPER, _TO_PHYS

KARABINER = os.path.join(bridges.ROOT, "karabiner")
LAYERS_PATH = os.path.join(KARABINER, "layers.toml")
RAW_DIR = os.path.join(KARABINER, "layers.raw")

# name → (rule stem, description); the descriptions are the titles Karabiner shows.
LAYERS = {
    "hyper": ("07-hyper-only", "Hyper Layer (only)"),
    "hyper_shift": ("08-hyper-shift", "Hyper Layer (shift)"),
    "hyper_command": ("09-hyper-command", "Hyper Layer (command)"),
    "hyper_option": ("10-hyper-option", "Hyper Layer (option)"),
    "hyper_control": ("11-hyper-control", "Hyper Layer (control)"),
    "hyper_shift_command": ("12-hyper-shift-command", "Hyper Layer (shift-command)"),
    "hyper_shift_option": ("13-hyper-shift-option", "Hyper Layer (shift-option)"),
    "hyper_shift_control": ("14-hyper-shift-control", "Hyper Layer (shift-control)"),
    "hyper_command_option": ("15-hyper-command-option", "Hyper Layer (command-option)"),
    "hyper_command_control": ("16-hyper-command-control", "Hyper Layer (command-control)"),
    "hyper_option_control": ("17-hyper-option-control", "Hyper Layer (option-control)"),
}
@dataclass(frozen=True)
class Plain:
    """A layer held by something other than Hyper. It takes no [slots].

    `chords`: every row names its own modifiers (`"⌥⇧q"`), so the table is a list
    of chords rather than a layer. Tables sharing a `stem` are written to that
    rule in the order they stand here.
    """
    stem: str
    description: str
    modifiers: dict | None = None
    conditions: tuple = ()
    chords: bool = False


_KEYBOARD_ON = ({"name": "keyboard_disabled", "type": "variable_unless", "value": 1},)
PLAIN = {
    "tab": Plain("01-tab-modifier", "TAB as a POWERFUL MODIFIER LAYER",
                 conditions=({"name": "tab_modifier", "type": "variable_if", "value": 1},)),
    "grave": Plain("05-grave-to-escape", "Grave Accent to Escape", chords=True),
    "misc": Plain("18-hyper-misc", "Left-modifier chords and the F-row", chords=True),
    "f_row": Plain("18-hyper-misc", "Left-modifier chords and the F-row", conditions=_KEYBOARD_ON, chords=True),
    "right_cmd": Plain("22-custom-right-cmd", "Custom Right Command",
                       modifiers={"mandatory": ["right_command"]}),
    "left_all": Plain("27-left-all-hide",
                      "Focus Modes: All Left Modifiers + W A S D → the same modifiers + arrows (Hammerspoon binds the arrows)",
                      modifiers={"mandatory": ["left_command", "left_control", "left_option", "left_shift"]}),
    "fn": Plain("30-fn-layer-mirror",
                "fn layer: left half of each row reaches the right half (1-6 -> 7 8 9 0 - = / qwerty -> uiop [ ] / asdfg -> jkl ; ' / zxcvb -> nm , . / / h -> backslash, the one key the rows leave over)",
                modifiers={"mandatory": ["fn"], "optional": ["any"]}),
}
# Rules no table can say; everything else in rules/ must come from layers.toml.
HAND_WRITTEN = ("00-keyboard-lock", "04-caps-lock-hyper", "26-right-option-space-punto",
                "29-mouse-ugreen-hold-to-browser", "32-swap-sides")
BY_STEM = {stem: name for name, (stem, _) in LAYERS.items()}
_LAYER_MOD = {"shift": "shift", "command": "cmd", "option": "alt", "control": "ctrl"}
_HEADER = re.compile(r'^\s*\[layer\.([A-Za-z0-9_]+)\]')
_KEY = re.compile(r'^\s*(?:"([^"]+)"|([A-Za-z0-9_]+))\s*=')
_CHORD = re.compile(r'^([⇪⇧⌃⌥⌘]*)(?:\(([⇧⌃⌥⌘]+)\))?([a-z0-9_]+)$')
# Keys a chord may be pressed on that have no row in the layout tables.
_CHORD_ONLY = {"escape"} | {f"f{n}" for n in range(1, 21)}
SHELL = "sh:"


@dataclass(frozen=True)
class Row:
    layer: str
    key: str
    to: str
    line: int = field(default=0, compare=False)


def from_modifiers(name):
    """Karabiner `from.modifiers.mandatory` of a layer, sorted."""
    return sorted(_HYPER | {f"left_{part}" for part in name.split("_")[1:]})


def layer_mods(name):
    """The layer as the modifier set `bridges.parse_from` returns."""
    return frozenset({"hyper"} | {_LAYER_MOD[part] for part in name.split("_")[1:]})


def _lines(text):
    where, layer = {}, None
    for n, line in enumerate(text.splitlines(), 1):
        if m := _HEADER.match(line):
            layer = m.group(1)
        elif layer and (m := _KEY.match(line)):
            where[(layer, m.group(1) or m.group(2))] = n
    return where


def load(path=LAYERS_PATH, tables=LAYERS):
    """Every row of the `tables` layers in file order; a malformed row is a ValueError naming layer and key."""
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    data = tomllib.loads(text)
    where = _lines(text)
    unknown = (set(data) - {"layer", "slots"}) | (set(data.get("layer", {})) - set(LAYERS) - set(PLAIN))
    if unknown:
        raise ValueError(f"{os.path.basename(path)}: unknown tables {sorted(unknown)}")
    rows = []
    for layer, table in data.get("layer", {}).items():
        if layer not in tables:
            continue
        for key, to in table.items():
            line = where.get((layer, key), 0)
            try:
                chords = layer in PLAIN and PLAIN[layer].chords
                code = chord_from(key)["key_code"] if chords else key
                if code not in _TO_PHYS and not (chords and code in _CHORD_ONLY):
                    raise ValueError(f"`{code}` is not a Karabiner key_code")
                if not isinstance(to, str):
                    raise ValueError(f"value must be a string, got {to!r}")
                outputs(to, code)
            except ValueError as e:
                raise ValueError(f"{os.path.basename(path)}:{line} layer {layer}, key {key}: {e}") from None
            rows.append(Row(layer, key, to, line))
    return rows


def key_code_of(phys):
    """Physical key id → the key_code a manipulator's `from` uses for it."""
    codes = [c for c, p in _TO_PHYS.items() if p == phys and c != "non_us_backslash"]
    if len(codes) != 1:
        raise ValueError(f"no single key_code for physical key `{phys}`")
    return codes[0]


def load_slots(path=LAYERS_PATH):
    """`[slots]` as {key_code: F-key}, in file order."""
    with open(path, "rb") as fh:
        slots = tomllib.load(fh).get("slots", {})
    name = os.path.basename(path)
    for key, base in slots.items():
        if key not in _TO_PHYS or not key.isalpha() or len(key) != 1:
            raise ValueError(f"{name} [slots]: `{key}` is not a letter key_code")
        if base not in bridges.SLOT_BASES:
            raise ValueError(f"{name} [slots] {key}: `{base}` is not one of F13–F20")
    taken = list(slots.values())
    dup = sorted({b for b in taken if taken.count(b) > 1})
    if dup:
        raise ValueError(f"{name} [slots]: {dup} assigned to more than one letter")
    return dict(slots)


def slot_rows(name, rows, slots):
    """(key_code, `to` text) of every slot letter layer `name` does not map itself, in slot order.

    Mapping it itself means a table row or a `layers.raw/` manipulator.
    """
    own = {r.key for r in rows if r.layer == name}
    own |= {m["from"].get("key_code") for m in load_raw(LAYERS[name][0])}
    mods = bridges._mods_text(layer_mods(name) - {"hyper"})
    return [(key, mods + base) for key, base in slots.items() if key not in own]


def raw_path(stem):
    return os.path.join(RAW_DIR, f"{stem}.json")


def load_raw(stem):
    path = raw_path(stem)
    if not os.path.exists(path):
        return []
    with open(path, encoding="utf-8") as fh:
        manips = json.load(fh)
    if not isinstance(manips, list):
        raise ValueError(f"{path}: expected a JSON list of manipulators")
    return manips


def raw_stems():
    return sorted(os.path.splitext(os.path.basename(p))[0] for p in glob.glob(os.path.join(RAW_DIR, "*.json")))


def chord_from(chord):
    """`⌥(⇧)a` → the Karabiner `from`: ⌥ mandatory, ⇧ optional, left-sided; `⇪` is the four right modifiers."""
    m = _CHORD.match(chord)
    order = ("hyper",) + bridges.TO_MODS
    held, rest = bridges._split_mods(m.group(1), order) if m else (None, "")
    optional, rest2 = bridges._split_mods(m.group(2) or "", bridges.TO_MODS) if m else (None, "")
    if held is None or optional is None or rest or rest2:
        raise ValueError(f"`{chord}` is not ⇪⇧⌃⌥⌘ (in that order), optional ones in brackets, plus a key_code")
    frm = {"key_code": m.group(3)}
    mandatory = sorted((_HYPER if "hyper" in held else set()) | {bridges._LEFT[x] for x in held - {"hyper"}})
    if mandatory:
        frm["modifiers"] = {"mandatory": mandatory}
    if optional:
        frm.setdefault("modifiers", {})["optional"] = sorted(bridges._LEFT[x] for x in optional)
    return frm


def outputs(to, key_code):
    """The `to` list of a table value: `sh: command`, one output, or several separated by spaces, sent in order."""
    if to.startswith(SHELL):
        command = to[len(SHELL):].strip()
        if not command:
            raise ValueError("`sh:` needs a command")
        return [{"shell_command": command}]
    if not to.split():
        raise ValueError("value is empty")
    return [bridges.output_entry(part, key_code) for part in to.split()]


def manipulator(name, key, to):
    plain = PLAIN.get(name)
    frm = chord_from(key) if plain and plain.chords else {"key_code": key}
    if plain is None:
        frm["modifiers"] = {"mandatory": from_modifiers(name)}
    elif plain.modifiers:
        frm["modifiers"] = plain.modifiers
    m = {"conditions": list(plain.conditions)} if plain and plain.conditions else {}
    return {**m, "from": frm, "to": outputs(to, frm["key_code"]), "type": "basic"}


def representable(m, name):
    """The table text for manipulator `m` in layer `name`, or None if only raw JSON can hold it."""
    plain = (set(m) == {"from", "to", "type"} and m["type"] == "basic"
             and set(m["from"]) == {"key_code", "modifiers"}
             and set(m["from"]["modifiers"]) == {"mandatory"}
             and sorted(m["from"]["modifiers"]["mandatory"]) == from_modifiers(name)
             and len(m["to"]) == 1)
    return bridges.render_output(m["to"][0], m["from"]["key_code"]) if plain else None


def _refuse_shadowed(stem, manips):
    seen = set()
    for m in manips:
        frm = json.dumps({**m["from"], "modifiers": {k: sorted(v) for k, v in m["from"].get("modifiers", {}).items()}},
                         sort_keys=True)
        if frm in seen:
            raise ValueError(f"{stem}: `{m['from'].get('key_code')}` is mapped more than once "
                             "(layers.toml, layers.raw); Karabiner would use only the first")
        seen.add(frm)


def build(rows=None, slots=None, plain=None):
    """stem → the complete rule document, in the order table, slots, raw; `PLAIN` layers take no slots."""
    rows = load() if rows is None else rows
    slots = load_slots() if slots is None else slots
    stray = set(raw_stems()) - set(BY_STEM) - {p.stem for p in PLAIN.values()}
    if stray:
        raise ValueError(f"layers.raw/: {sorted(stray)} name no layer file")
    docs = {}
    for name, (stem, description) in LAYERS.items():
        manips = [manipulator(name, r.key, r.to) for r in rows if r.layer == name]
        manips += [manipulator(name, key, to) for key, to in slot_rows(name, rows, slots)]
        manips += load_raw(stem)
        _refuse_shadowed(stem, manips)
        docs[stem] = {"description": description, "manipulators": manips}
    plain_rows = load(tables=PLAIN) if plain is None else plain
    for name, p in PLAIN.items():
        doc = docs.setdefault(p.stem, {"description": p.description, "manipulators": []})
        doc["manipulators"] += [manipulator(name, r.key, r.to) for r in plain_rows if r.layer == name]
    for stem in sorted({p.stem for p in PLAIN.values()}):
        docs[stem]["manipulators"] += load_raw(stem)
        _refuse_shadowed(stem, docs[stem]["manipulators"])
    return docs


def dumps(doc):
    return json.dumps(doc, indent=4, ensure_ascii=False) + "\n"
