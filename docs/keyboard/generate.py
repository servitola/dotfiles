#!/usr/bin/env python3
"""Generate keyboard shortcut SVGs from Hammerspoon Lua config."""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from parse_active import parse_active_entries
from parse_comments import parse_comment_entries, parse_full_entries
from parse_descriptions import parse_app_descriptions
from parse_brew import parse_brew_descriptions
from parse_birman import parse_birman
from parse_karabiner import parse_karabiner
from parse_rider import parse_rider
from classify import classify_entries, layer_name, layer_filename
from icons import extract_icons
from svg_keyboard import render
from svg_by_action import render as render_by_action
from config import MOD_ORDER, DEFAULT_APPS
from labels import FN_APP, get_label

out_dir = os.path.dirname(os.path.abspath(__file__))
active = parse_active_entries()
comments = parse_comment_entries()
descriptions = parse_app_descriptions()
full = parse_full_entries()
birman = parse_birman()
karabiner = parse_karabiner()
rider = parse_rider()
brew_descs = parse_brew_descriptions()
print(f"Birman: {len(birman)} keys | Karabiner: {len(karabiner)} | Rider: {len(rider)} shortcuts")
layers = classify_entries(active, comments)

# Add layers from full_entries/karabiner/rider that weren't in classify_entries
# and populate their keys dict so keyboard keys show as colored (not dim)
from classify import _parse_modifiers
from collections import Counter, defaultdict
_extra_keys = defaultdict(dict)  # {layer_mods: {phys_key: entry}}
for e in full:
    mods, key = _parse_modifiers(e["chord"])
    if e["karabiner"] or e["birman"] or e["descriptions"]:
        if key not in _extra_keys[mods]:
            label = e["karabiner"] or (e["birman"].split()[0] if e["birman"] else "")
            if label:
                _extra_keys[mods][key] = {"chord": e["chord"], "label": label,
                    "source_key": e["source_key"], "source_tag": "K" if e["karabiner"] else "B"}
for (lm, phys), display in karabiner.items():
    if phys not in _extra_keys[lm]:
        _extra_keys[lm][phys] = {"chord": "", "label": display, "source_key": phys, "source_tag": "K"}
for (lm, phys), entries in rider.items():
    if phys not in _extra_keys[lm]:
        _extra_keys[lm][phys] = {"chord": "", "label": entries[0][1], "source_key": phys, "source_tag": "K"}
for mods, keys_dict in _extra_keys.items():
    if mods not in layers and len(keys_dict) >= 3:
        layers[mods] = keys_dict
    elif mods in layers:
        # Fill gaps: add keys that classify_entries missed
        for k, v in keys_dict.items():
            if k not in layers[mods]:
                layers[mods][k] = v

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
app_names |= {app for e in full for app, _ in e.get("descriptions", []) if app} - {""}
app_names |= {"Shottr","Maccy","Mail","Warp","Safari","Raycast","Rider"}  # extra for tooltips
print(f"Extracting icons for {len(app_names)} apps...")
icon_map = extract_icons(app_names)
print(f"  Found {len(icon_map)} icons")

def sort_key(m):
    return (len(m), [MOD_ORDER.index(x) for x in MOD_ORDER if x in m])

for mods in sorted(layers.keys(), key=sort_key):
    svg = render(layer_name(mods), mods, layers[mods], icon_map, descriptions, brew_descs, full, birman, karabiner, rider)
    path = os.path.join(out_dir, layer_filename(mods))
    with open(path, "w", encoding="utf-8") as f:
        f.write(svg)
    print(f"  {layer_filename(mods)}: {len(layers[mods])} keys")

print(f"\nDone! Generated {len(layers)} layer diagrams.")

# By-action cheatsheet — bindings grouped by category, complement to per-layer
by_action_svg = render_by_action(active, icon_map)
path = os.path.join(out_dir, "by-action.svg")
with open(path, "w", encoding="utf-8") as f:
    f.write(by_action_svg)
print(f"  by-action.svg: bindings grouped by category")
