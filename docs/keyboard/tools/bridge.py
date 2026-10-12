#!/usr/bin/env python3
"""Bridge slots: which F13–F20 / num0–num9 code each Hyper letter or gesture uses.

Every slot letter emits one code per Hyper layer (`⇪⌘v` → `⌘F16`); a row shows
the physical chord and what the layout binds on it (`·` = free variant).

Usage:
  python3 bridge.py            # slot table, exceptions, free keypad codes
  python3 bridge.py --json     # the same as JSON
"""
import argparse
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

import bridges
import grammar
import layers
from config import LAYOUT_DIR

ACTIVE = re.compile(r'^\{\s*chord\s*=\s*"([^"]+)"\s*,\s*(?:app|fn)\s*=\s*"([^"]+)"')


def layout_bindings():
    """Active chord → (target, file) over every layout file."""
    out = {}
    for path in sorted(glob.glob(os.path.join(LAYOUT_DIR, "*.lua"))):
        with open(path, encoding="utf-8") as fh:
            for line in fh:
                if m := ACTIVE.match(line.strip()):
                    out[m.group(1)] = (m.group(2), os.path.basename(path))
    return out


def table():
    slots = layers.load_slots()
    variants = bridges.slot_variants(slots=slots)
    bound = layout_bindings()
    extra = [b for b in bridges.from_rules() if b.rule not in layers.BY_STEM and b.to not in bridges.EXCEPTIONS]

    def row(to, chords):
        target, where = bound.get(to, (None, None))
        return {"code": to, "from": chords, "binds": target, "file": where}

    out = {"slots": [], "exceptions": [], "free": []}
    for key, base in slots.items():
        rows = [row(to, [chord]) for to, chord in variants.items() if grammar.parse_to(to)[1] == base]
        rows += [row(b.to, [b.from_chord]) for b in extra if grammar.parse_to(b.to)[1] == base]
        out["slots"].append({"letter": key, "slot": base, "variants": rows})
    for to, (chords, rule) in bridges.EXCEPTIONS.items():
        out["exceptions"].append({**row(to, list(chords)), "rule": rule})
    used = set(slots.values()) | set(bridges.EXCEPTIONS)
    out["free"] = [c for c in grammar.SLOT_BASES + bridges.KEYPAD_BASES if c not in used]
    return out


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--json", action="store_true", help="machine-readable output")
    args = ap.parse_args()
    t = table()
    if args.json:
        print(json.dumps(t, ensure_ascii=False, indent=1))
        return
    for s in t["slots"]:
        print(f"{s['slot']}  ⇪{s['letter']}")
        for r in s["variants"]:
            print(f"  {r['code']:<8}{', '.join(r['from']):<20}{r['binds'] or '·'}")
    print("exceptions")
    for r in t["exceptions"]:
        print(f"  {r['code']:<8}{', '.join(r['from']):<20}{r['binds'] or '·'}  ({r['rule']})")
    print(f"free: {' '.join(t['free']) or '—'}")


if __name__ == "__main__":
    main()
