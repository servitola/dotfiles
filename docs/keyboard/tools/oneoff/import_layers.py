#!/usr/bin/env python3
"""One-off: karabiner/rules/07…17 → karabiner/layers.toml + karabiner/layers.raw/.

Kept for the record of how the table was produced; nothing runs it. Bridge
manipulators are skipped (bridge.lock.toml owns them); anything that is not one
plain key or consumer key goes to layers.raw/ verbatim. A second manipulator for
the same key in the same layer is dead (Karabiner takes the first) and is dropped.
"""
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(os.path.dirname(HERE)))

import bridges
import layers

HEADER = """\
# Hyper layers → karabiner/rules/07…17. Regenerate with gen_layers.py (build.sh does).
# Key = Karabiner key_code. Value = what the chord sends: [⇪⇧⌃⌥⌘]key-glyph,
# `F1`…`F20`, `PgUp`/`PgDn`, consumer symbols (⏮ ⏭ ▶/⏸ Vol↑ Vol↓ 🔆 🔅),
# or [⇧⌃⌥⌘]passthrough (send the pressed key again, without the layer modifiers).
# ⇪ in a value is the four right modifiers, other glyphs are left ones.
# Bridge rows (F13–F20/keypad) live in bridge.lock.toml, never here; manipulators
# the table cannot express live in layers.raw/<rule>.json.
"""
BARE = re.compile(r"^[A-Za-z_][A-Za-z0-9_-]*$")


def split(name, manips):
    """→ (table rows [(key_code, text)], raw manipulators)."""
    stem = layers.LAYERS[name][0]
    rows, raw, seen = [], [], set()
    for m in manips:
        if any(bridges._render_to(e) for e in m.get("to", [])):
            continue
        text = layers.representable(m, name)
        if text is None:
            raw.append(m)
            continue
        key = m["from"]["key_code"]
        if key in seen:
            # Karabiner stops at the first manipulator whose `from` matches: this one never fires.
            print(f"{stem}: dropped shadowed {key} → {text}")
            continue
        seen.add(key)
        rows.append((key, text))
    return rows, raw


def main():
    out = [HEADER]
    os.makedirs(layers.RAW_DIR, exist_ok=True)
    for name, (stem, _) in layers.LAYERS.items():
        with open(os.path.join(bridges.RULES_DIR, f"{stem}.json"), encoding="utf-8") as fh:
            rows, raw = split(name, json.load(fh)["manipulators"])
        glyphs = bridges._mods_text(layers.layer_mods(name))
        out.append(f"\n[layer.{name}]  # {glyphs} → {stem}\n")
        for key, text in rows:
            k = key if BARE.match(key) else json.dumps(key)
            out.append(f"{k} = {json.dumps(text, ensure_ascii=False)}\n")
        if raw:
            with open(layers.raw_path(stem), "w", encoding="utf-8") as fh:
                fh.write(json.dumps(raw, indent=4, ensure_ascii=False) + "\n")
            print(f"{stem}: {len(raw)} raw")
    with open(layers.LAYERS_PATH, "w", encoding="utf-8") as fh:
        fh.write("".join(out))


if __name__ == "__main__":
    main()
