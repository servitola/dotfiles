#!/usr/bin/env python3
"""Generate keyboard shortcut SVGs from Hammerspoon Lua config."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from parse_active import parse_active_entries
from parse_comments import parse_comment_entries
from classify import classify_entries, layer_name, layer_filename
from icons import extract_icons
from svg_keyboard import render
from config import MOD_ORDER

out_dir = os.path.dirname(os.path.abspath(__file__))

active = parse_active_entries()
comments = parse_comment_entries()
app_names = {e["app"] for e in active if "app" in e}
print(f"Extracting icons for {len(app_names)} apps...")
icon_map = extract_icons(app_names)
print(f"  Found {len(icon_map)} icons")
layers = classify_entries(active, comments)

# Sort layers: fewer modifiers first, then alphabetically
def sort_key(mods):
    return (len(mods), [MOD_ORDER.index(m) for m in MOD_ORDER if m in mods])

for mods in sorted(layers.keys(), key=sort_key):
    name = layer_name(mods)
    fname = layer_filename(mods)
    svg = render(name, mods, layers[mods], icon_map)
    path = os.path.join(out_dir, fname)
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"  {fname}: {len(layers[mods])} keys")

print(f"\nDone! Generated {len(layers)} layer diagrams.")
