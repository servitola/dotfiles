"""Hyper layers: `karabiner/layers.toml` (tables + `[slots]`) + `layers.raw/` → rules 07–17.

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
BY_STEM = {stem: name for name, (stem, _) in LAYERS.items()}
_LAYER_MOD = {"shift": "shift", "command": "cmd", "option": "alt", "control": "ctrl"}
_HEADER = re.compile(r'^\s*\[layer\.([A-Za-z_]+)\]')
_KEY = re.compile(r'^\s*"?([A-Za-z0-9_]+)"?\s*=')


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
            where[(layer, m.group(1))] = n
    return where


def load(path=LAYERS_PATH):
    """Every table row in file order; a malformed row is a ValueError naming layer and key."""
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    data = tomllib.loads(text)
    where = _lines(text)
    unknown = (set(data) - {"layer", "slots"}) | (set(data.get("layer", {})) - set(LAYERS))
    if unknown:
        raise ValueError(f"{os.path.basename(path)}: unknown tables {sorted(unknown)}")
    rows = []
    for layer, table in data.get("layer", {}).items():
        for key, to in table.items():
            line = where.get((layer, key), 0)
            try:
                if key not in _TO_PHYS:
                    raise ValueError(f"`{key}` is not a Karabiner key_code")
                if not isinstance(to, str):
                    raise ValueError(f"value must be a string, got {to!r}")
                bridges.output_entry(to, key)
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


def manipulator(name, key_code, to):
    return {
        "from": {"key_code": key_code, "modifiers": {"mandatory": from_modifiers(name)}},
        "to": [bridges.output_entry(to, key_code)],
        "type": "basic",
    }


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


def build(rows=None, slots=None):
    """stem → the complete rule document, in the order table, slots, raw."""
    rows = load() if rows is None else rows
    slots = load_slots() if slots is None else slots
    stray = set(raw_stems()) - set(BY_STEM)
    if stray:
        raise ValueError(f"layers.raw/: {sorted(stray)} name no layer file")
    docs = {}
    for name, (stem, description) in LAYERS.items():
        manips = [manipulator(name, r.key, r.to) for r in rows if r.layer == name]
        manips += [manipulator(name, key, to) for key, to in slot_rows(name, rows, slots)]
        manips += load_raw(stem)
        _refuse_shadowed(stem, manips)
        docs[stem] = {"description": description, "manipulators": manips}
    return docs


def dumps(doc):
    return json.dumps(doc, indent=4, ensure_ascii=False) + "\n"
