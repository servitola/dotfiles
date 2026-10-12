"""`karabiner/layers.toml` + `karabiner/hand/` → the rules of karabiner.json.

One table per layer; key = Karabiner `key_code` of the pressed key (a chord table
puts the modifiers in front of it), value = the glyph text `grammar.output_entry`
understands. `[slots]` maps a letter to its F-key; every Hyper layer without its
own entry for that letter sends the slot with the layer's left modifiers.
`hand/*.json` are whole rules no table can say, `hand/raw/<rule>.json` manipulators
appended to a generated rule. Nothing generated is kept on disk but karabiner.json.
"""
import glob
import json
import dataclasses
import functools
import os
import re
import tomllib
from dataclasses import dataclass, field

import grammar
from keys import HYPER as _HYPER, TO_PHYS as _TO_PHYS

KARABINER = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LAYERS_PATH = os.path.join(KARABINER, "layers.toml")
HAND_DIR = os.path.join(KARABINER, "hand")
RAW_DIR = os.path.join(HAND_DIR, "raw")
TEMPLATE_PATH = os.path.join(KARABINER, "karabiner-template.json")
OUTPUT_PATH = os.path.join(KARABINER, "karabiner.json")

META = ("rule", "title", "mandatory", "optional", "when", "unless")
_RULE = re.compile(r"^\d\d-[a-z0-9-]+$")
_MODIFIERS = {f"{side}_{mod}" for side in ("left", "right") for mod in ("shift", "control", "option", "command")} | {"fn"}


@dataclass(frozen=True)
class Table:
    """What a `[layer.<name>]` table says about itself: its rule and what its rows are pressed with.

    `hyper`: named `hyper` / `hyper_<mods>`, held with Caps Lock, takes [slots].
    `chords`: no modifiers of its own, so every row names them in its key (`"⌥⇧q"`).
    """
    stem: str
    description: str
    hyper: bool = False
    modifiers: dict | None = None
    conditions: tuple = ()

    @property
    def chords(self):
        return not self.hyper and not self.modifiers


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
    """The layer as the modifier set `grammar.parse_from` returns."""
    return frozenset({"hyper"} | {_LAYER_MOD[part] for part in name.split("_")[1:]})


def _lines(text):
    where, layer = {}, None
    for n, line in enumerate(text.splitlines(), 1):
        if m := _HEADER.match(line):
            layer = m.group(1)
        elif layer and (m := _KEY.match(line)):
            where[(layer, m.group(1) or m.group(2))] = n
    return where


def _strings(raw, key, allowed):
    value = raw.get(key, [])
    if not isinstance(value, list) or not set(value) <= allowed:
        raise ValueError(f"`{key}` must be a list of Karabiner modifier names, got {value!r}")
    return value


def _table(name, raw):
    stem = raw.get("rule")
    if not isinstance(stem, str) or not _RULE.match(stem):
        raise ValueError(f'needs rule = "NN-name", got {stem!r}')
    hyper = name.split("_")[0] == "hyper"
    held = [k for k in META[2:] if k in raw]
    if hyper:
        parts = name.split("_")[1:]
        if len(set(parts)) != len(parts) or not set(parts) <= set(_LAYER_MOD):
            raise ValueError(f"a Hyper table is named hyper or hyper_<{'|'.join(_LAYER_MOD)}>…")
        if held:
            raise ValueError(f"a Hyper table is held with Caps Lock and its name; drop {held}")
    modifiers = {k: _strings(raw, k, _MODIFIERS | ({"any"} if k == "optional" else set()))
                 for k in ("mandatory", "optional") if k in raw}
    conditions = []
    for key, kind in (("when", "variable_if"), ("unless", "variable_unless")):
        if key in raw:
            if not isinstance(raw[key], str):
                raise ValueError(f"`{key}` must be the name of a Karabiner variable")
            conditions.append({"name": raw[key], "type": kind, "value": 1})
    return Table(stem, raw.get("title"), hyper, modifiers or None, tuple(conditions))


@functools.lru_cache(maxsize=None)
def _read(path):
    """(parsed TOML, {(layer, key): line}, {layer: Table}) of a layers file."""
    with open(path, encoding="utf-8") as fh:
        text = fh.read()
    data = tomllib.loads(text)
    name = os.path.basename(path)
    unknown = set(data) - {"layer", "slots"}
    if unknown:
        raise ValueError(f"{name}: unknown tables {sorted(unknown)}")
    found = {}
    for layer, raw in data.get("layer", {}).items():
        try:
            found[layer] = _table(layer, raw)
        except ValueError as e:
            raise ValueError(f"{name} [layer.{layer}]: {e}") from None
    titles = {}
    for layer, table in found.items():
        if table.description is not None:
            if titles.setdefault(table.stem, table.description) != table.description:
                raise ValueError(f"{name} [layer.{layer}]: rule {table.stem} already has another title")
    for layer, table in found.items():
        if table.stem not in titles:
            raise ValueError(f"{name} [layer.{layer}]: rule {table.stem} has no title")
        if table.hyper and [t.stem for t in found.values()].count(table.stem) > 1:
            raise ValueError(f"{name} [layer.{layer}]: a Hyper table cannot share rule {table.stem}")
        found[layer] = dataclasses.replace(table, description=titles[table.stem])
    return data, _lines(text), found


def tables(path=LAYERS_PATH):
    """{layer name: Table} in file order."""
    return _read(path)[2]


def __getattr__(name):
    """`LAYERS` (Hyper: name → (rule, title)), `PLAIN` (the others: name → Table), `BY_STEM` (Hyper rule → name)."""
    if name == "LAYERS":
        return {n: (t.stem, t.description) for n, t in tables().items() if t.hyper}
    if name == "PLAIN":
        return {n: t for n, t in tables().items() if not t.hyper}
    if name == "BY_STEM":
        return {t.stem: n for n, t in tables().items() if t.hyper}
    raise AttributeError(name)


def load(path=LAYERS_PATH, hyper=True):
    """Every row of the Hyper tables (or of the others) in file order; a malformed row is a ValueError naming layer and key."""
    data, where, found = _read(path)
    rows = []
    for layer, table in data.get("layer", {}).items():
        if found[layer].hyper != hyper:
            continue
        for key, to in table.items():
            if key in META:
                continue
            line = where.get((layer, key), 0)
            try:
                chords = found[layer].chords
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
        if base not in grammar.SLOT_BASES:
            raise ValueError(f"{name} [slots] {key}: `{base}` is not one of F13–F20")
    taken = list(slots.values())
    dup = sorted({b for b in taken if taken.count(b) > 1})
    if dup:
        raise ValueError(f"{name} [slots]: {dup} assigned to more than one letter")
    return dict(slots)


def slot_rows(name, rows, slots):
    """(key_code, `to` text) of every slot letter layer `name` does not map itself, in slot order.

    Mapping it itself means a table row or a `hand/raw/` manipulator.
    """
    own = {r.key for r in rows if r.layer == name}
    own |= {m["from"].get("key_code") for m in load_raw(tables()[name].stem)}
    mods = grammar._mods_text(layer_mods(name) - {"hyper"})
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
    order = ("hyper",) + grammar.TO_MODS
    held, rest = grammar._split_mods(m.group(1), order) if m else (None, "")
    optional, rest2 = grammar._split_mods(m.group(2) or "", grammar.TO_MODS) if m else (None, "")
    if held is None or optional is None or rest or rest2:
        raise ValueError(f"`{chord}` is not ⇪⇧⌃⌥⌘ (in that order), optional ones in brackets, plus a key_code")
    frm = {"key_code": m.group(3)}
    mandatory = sorted((_HYPER if "hyper" in held else set()) | {grammar._LEFT[x] for x in held - {"hyper"}})
    if mandatory:
        frm["modifiers"] = {"mandatory": mandatory}
    if optional:
        frm.setdefault("modifiers", {})["optional"] = sorted(grammar._LEFT[x] for x in optional)
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
    return [grammar.output_entry(part, key_code) for part in to.split()]


def manipulator(name, key, to):
    table = tables()[name]
    frm = chord_from(key) if table.chords else {"key_code": key}
    if table.hyper:
        frm["modifiers"] = {"mandatory": from_modifiers(name)}
    elif table.modifiers:
        frm["modifiers"] = table.modifiers
    m = {"conditions": list(table.conditions)} if table.conditions else {}
    return {**m, "from": frm, "to": outputs(to, frm["key_code"]), "type": "basic"}


def representable(m, name):
    """The table text for manipulator `m` in layer `name`, or None if only raw JSON can hold it."""
    plain = (set(m) == {"from", "to", "type"} and m["type"] == "basic"
             and set(m["from"]) == {"key_code", "modifiers"}
             and set(m["from"]["modifiers"]) == {"mandatory"}
             and sorted(m["from"]["modifiers"]["mandatory"]) == from_modifiers(name)
             and len(m["to"]) == 1)
    return grammar.render_output(m["to"][0], m["from"]["key_code"]) if plain else None


def _refuse_shadowed(stem, manips):
    seen = set()
    for m in manips:
        frm = json.dumps({**m["from"], "modifiers": {k: sorted(v) for k, v in m["from"].get("modifiers", {}).items()}},
                         sort_keys=True)
        if frm in seen:
            raise ValueError(f"{stem}: `{m['from'].get('key_code')}` is mapped more than once "
                             "(layers.toml, hand/raw); Karabiner would use only the first")
        seen.add(frm)


def build(rows=None, slots=None, plain=None):
    """stem → the complete rule document: its tables in file order (a Hyper one followed by its slots), then raw."""
    rows = load() if rows is None else rows
    slots = load_slots() if slots is None else slots
    found = tables()
    stray = set(raw_stems()) - {t.stem for t in found.values()}
    if stray:
        raise ValueError(f"hand/raw/: {sorted(stray)} name no generated rule")
    plain_rows = load(hyper=False) if plain is None else plain
    docs = {}
    for name, table in found.items():
        doc = docs.setdefault(table.stem, {"description": table.description, "manipulators": []})
        doc["manipulators"] += [manipulator(name, r.key, r.to) for r in (rows if table.hyper else plain_rows)
                                if r.layer == name]
        if table.hyper:
            doc["manipulators"] += [manipulator(name, key, to) for key, to in slot_rows(name, rows, slots)]
    for stem, doc in docs.items():
        doc["manipulators"] += load_raw(stem)
        _refuse_shadowed(stem, doc["manipulators"])
    return docs


def hand_rules(hand_dir=None):
    """stem → rule document, for every whole rule written by hand."""
    docs = {}
    for path in sorted(glob.glob(os.path.join(hand_dir or HAND_DIR, "*.json"))):
        with open(path, encoding="utf-8") as fh:
            docs[os.path.splitext(os.path.basename(path))[0]] = json.load(fh)
    return docs


def all_rules():
    """[(stem, rule document)] in the order Karabiner tries them: by stem, generated and hand-written together."""
    generated, hand = build(), hand_rules()
    both = sorted(set(generated) & set(hand))
    if both:
        raise ValueError(f"{both} are both a table in layers.toml and a file in hand/")
    return sorted({**generated, **hand}.items())


def config(rules=None):
    """The complete karabiner.json: the template with the rules in place."""
    rules = all_rules() if rules is None else rules
    with open(TEMPLATE_PATH, encoding="utf-8") as fh:
        doc = json.load(fh)
    doc["profiles"][0]["complex_modifications"]["rules"] = [rule for _, rule in rules]
    return doc
