#!/usr/bin/env python3
"""Generate keyboard shortcut SVGs from Hammerspoon Lua config."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from parse_active import parse_active_entries
from parse_comments import parse_comment_entries
from parse_descriptions import parse_app_descriptions
from parse_brew import parse_brew_descriptions
from classify import classify_entries, layer_name, layer_filename
from icons import extract_icons
from svg_keyboard import render
from config import MOD_ORDER, DEFAULT_APPS
from labels import FN_APP, get_label

out_dir = os.path.dirname(os.path.abspath(__file__))
active = parse_active_entries()
comments = parse_comment_entries()
descriptions = parse_app_descriptions()
brew_descs = parse_brew_descriptions()
layers = classify_entries(active, comments)

# Auto-detect default apps from Hyper layer
hyper = frozenset({"hyper"})
if hyper in layers:
    h = layers[hyper]
    if "b" in h: DEFAULT_APPS["_terminal"] = get_label(h["b"])
    if "v" in h: DEFAULT_APPS["_browser"] = h["v"].get("app", DEFAULT_APPS["_browser"])
    print(f"Defaults: terminal={DEFAULT_APPS['_terminal']}, browser={DEFAULT_APPS['_browser']}")

app_names = {e["app"] for e in active if "app" in e}
app_names |= {DEFAULT_APPS.get(v, v) for v in FN_APP.values()}
app_names |= {e.get("app_hint") for e in comments if "app_hint" in e} - {None}
app_names |= {"Shottr","Maccy","Mail","Warp","Safari","Raycast"}  # extra for detail tooltips
print(f"Extracting icons for {len(app_names)} apps...")
icon_map = extract_icons(app_names)
print(f"  Found {len(icon_map)} icons")

def sort_key(m):
    return (len(m), [MOD_ORDER.index(x) for x in MOD_ORDER if x in m])

for mods in sorted(layers.keys(), key=sort_key):
    svg = render(layer_name(mods), mods, layers[mods], icon_map, descriptions, brew_descs)
    path = os.path.join(out_dir, layer_filename(mods))
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"  {layer_filename(mods)}: {len(layers[mods])} keys")

print(f"\nDone! Generated {len(layers)} layer diagrams.")
