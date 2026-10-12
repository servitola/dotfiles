#!/usr/bin/env python3
"""where.py <chord> — everything the four sources know about one chord.

  python3 docs/keyboard/tools/where.py ⇪g        a pressed chord
  python3 docs/keyboard/tools/where.py ⌘F16      what Karabiner emits (traced back to ⇪⌘v)
  python3 docs/keyboard/tools/where.py ⇧⌘4 --json

Sections: what Karabiner does with the press (karabiner/rules/*.json, generated 07–17
included), what Hammerspoon binds (HotKeys layout files, Punto), what macOS and the apps
hold on the same chord (macos_shortcuts/shortcuts.toml), and what the key types in
en / ru / el (Apple's layouts, BirmanLayer on right ⌥).
"""
import argparse
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.dirname(HERE))
sys.path.insert(0, os.path.join(os.path.dirname(HERE), "..", "..", "macos_shortcuts"))

import bridges
import classify
import keycodes
import layers
import lint
import normalize
import parse_birman
import parse_karabiner
import shortcuts
import app_constants

RULES_DIR = bridges.RULES_DIR
HYPER_SET = {"right_command", "right_control", "right_option", "right_shift"}
PUNTO = os.path.join(lint.HAMMERSPOON_DIR, "punto_switcher.lua")


def _mods_of(mandatory):
    """Karabiner mandatory modifiers → the layout's modifier names; None when the set
    is one the layout grammar cannot spell (a lone right_command, say)."""
    rest = set(mandatory)
    mods = set()
    if HYPER_SET <= rest:
        mods.add("hyper")
        rest -= HYPER_SET
    for m in list(rest):
        base = m.removeprefix("left_").removeprefix("right_")
        name = {"command": "cmd", "control": "ctrl", "option": "alt", "shift": "shift", "fn": "fn"}.get(base)
        if name is None:
            return None
        mods.add(name)
    return frozenset(mods)


def _side(mandatory):
    sides = {m.split("_")[0] for m in mandatory if m.startswith(("left_", "right_"))} - (
        {"right"} if HYPER_SET <= set(mandatory) else set())
    return sides.pop() if len(sides) == 1 else None


def _to_text(to):
    words = []
    for t in to:
        text = parse_karabiner._to_display(t)
        text = re.sub(r"keypad_(\d)", r"num\1", text)
        if text and text != "vk_none":
            words.append(normalize.reorder_chord_mods(text))
    return " ".join(words)


def _conditions(m):
    notes = []
    for c in m.get("conditions", []):
        if c.get("type", "").startswith("frontmost_application"):
            apps = [b for b in c.get("bundle_identifiers", [])]
            notes.append(("only in " if c["type"].endswith("_if") else "except in ") + ", ".join(apps))
        elif c.get("type") == "variable_if" and c.get("name") != "tab_modifier":
            notes.append(f"while {c.get('name')} = {c.get('value')}")
    return notes


def karabiner(mods, phys):
    """Manipulators whose `from` is this physical chord, in rule order (first wins)."""
    try:
        code = layers.key_code_of(phys)
    except ValueError:
        code = phys
    want = frozenset(mods) - {"tab_mod"}
    tab = "tab_mod" in mods
    hits = []
    for path in sorted(glob.glob(os.path.join(RULES_DIR, "*.json"))):
        with open(path, encoding="utf-8") as fh:
            rule = json.load(fh)
        for m in rule.get("manipulators", []):
            fr = m.get("from", {})
            keys = [fr["key_code"]] if "key_code" in fr else [s.get("key_code") for s in fr.get("simultaneous", [])]
            if code not in keys:
                continue
            got = _mods_of(fr.get("modifiers", {}).get("mandatory", []))
            held_tab = any(c.get("name") == "tab_modifier" and c.get("value") == 1 for c in m.get("conditions", []))
            if got != want or held_tab != tab:
                continue
            to = m.get("to") or m.get("to_if_held_down") or []
            hits.append({
                "rule": os.path.basename(path).removesuffix(".json"),
                "with": [k for k in keys if k != code],
                "to": _to_text(to),
                "held": "to_if_held_down" in m and "to" not in m,
                "side": _side(fr.get("modifiers", {}).get("mandatory", [])),
                "notes": _conditions(m),
            })
    return hits


def hammerspoon(chords):
    """Layout entries bound to any of `chords` (the emitted and the pressed spelling)."""
    hits = []
    for path in sorted(glob.glob(os.path.join(lint.LAYOUT_DIR, "*.lua"))):
        parsed = lint.parse_file(path)
        desc = {r["chord"]: r["desc"].strip() for r in parsed["ascii_rows"] if r["desc"].strip() not in ("", "↓")}
        for a in parsed["actives"]:
            if normalize.reorder_chord_mods(a["chord"]) in chords:
                target = a["target"]
                if a["kind"] == "app" and target.startswith("@"):
                    target = f"{app_constants.resolve(target)} ({target})"
                hits.append({"file": os.path.basename(path), "line": a["line"], "chord": a["chord"],
                             "kind": a["kind"], "target": target,
                             "desc": next((desc[c] for c in chords if c in desc), "")})
    if "num9" in chords and os.path.exists(PUNTO):
        hits.append({"file": "punto_switcher.lua", "line": None, "chord": "num9", "kind": "fn",
                     "target": "punto (right ⌥␣, Karabiner rule 26)", "desc": ""})
    return hits


def machine(chords):
    rows = shortcuts.load()
    keys = set()
    for c in chords:
        try:
            keys.add(keycodes.canonical(c))
        except ValueError:
            pass
    out = []
    for r in rows["system"]:
        if r.keys in keys:
            out.append({"kind": "system", "id": r.id, "name": r.name, "enabled": r.enabled, "keys": r.keys})
    for r in rows["app"]:
        if r.keys in keys:
            out.append({"kind": "app", "domain": r.domain, "name": r.name, "keys": r.keys})
    for r in rows["menu"]:
        if r.keys in keys:
            out.append({"kind": "menu", "domain": r.domain, "item": r.item, "keys": r.keys})
    return sorted(keys), out


def _rewrites(hit):
    """A manipulator that takes the press away before any app or layout sees it."""
    return not hit["with"] and not hit["notes"] and not hit["held"]


def typing(mods, phys, karab):
    table = parse_birman.parse_birman().get(phys)
    if table is None:
        return None
    state = parse_birman.LAYER_TO_STATE.get(frozenset(mods) & {"shift", "alt"})
    if frozenset(mods) - {"shift", "alt"}:
        return {"state": None, "why": "a shortcut, types nothing", "layers": table}
    taken = [h for h in karab if _rewrites(h)]
    if taken and ("alt" not in mods or taken[0]["side"] != "left"):
        return {"state": None, "why": f"Karabiner rule {taken[0]['rule']} takes the press first", "layers": table}
    return {"state": state, "why": None, "layers": table}


def resolve(chord):
    fn = re.fullmatch(r"fn\s*(\S.*)", chord.strip())
    chord = normalize.reorder_chord_mods((fn.group(1) if fn else chord).strip())
    variants = bridges.slot_variants()
    pressed, emitted = chord, chord
    if lint.BRIDGE_CHORD.match(chord):
        if chord in variants:
            pressed = variants[chord]
        elif chord in bridges.EXCEPTIONS:
            pressed = " / ".join(bridges.EXCEPTIONS[chord][0])
    mods, phys = classify._parse_modifiers(pressed if " / " not in pressed else chord)
    if fn:
        mods |= {"fn"}
    karab = karabiner(mods, phys) if " / " not in pressed else [
        {"rule": bridges.EXCEPTIONS[chord][1], "with": [], "to": chord, "held": False, "side": None, "notes": []}]
    taken = [h for h in karab if _rewrites(h)]
    if emitted == pressed and taken:
        emitted = taken[0]["to"] or pressed
    chords = {emitted, pressed, chord}
    keys, rows = machine(chords)
    return {
        "chord": ("fn " if fn else "") + chord, "pressed": ("fn " if fn else "") + pressed, "emitted": emitted, "phys": phys,
        "mods": sorted(mods),
        "karabiner": karab,
        "hammerspoon": hammerspoon(chords),
        "macos": {"as_received": keys, "rows": rows},
        "types": typing(mods, phys, karab),
    }


def _ch(c):
    return c if c and c != "" else "·"


def render(info):
    out = [f"{info['chord']}"]
    if info["pressed"] != info["chord"]:
        out.append(f"  pressed as   {info['pressed']}")
    if info["emitted"] != info["pressed"]:
        out.append(f"  reaches apps as   {info['emitted']}")
    out.append("")
    out.append("Karabiner")
    if not info["karabiner"]:
        out.append("  passes through untouched")
    for k in info["karabiner"]:
        extra = (" + " + " ".join(k["with"]) if k["with"] else "") + (" (held)" if k["held"] else "")
        extra += f" ({k['side']} modifier only)" if k["side"] else ""
        note = f"   [{'; '.join(k['notes'])}]" if k["notes"] else ""
        out.append(f"  {k['rule']}{extra}  →  {k['to'] or '(nothing)'}{note}")
    out.append("")
    out.append("Hammerspoon" + ("  (left ⌥ only: right ⌥ is the Birman layer)"
                                if set(info["mods"]) <= {"alt", "shift"} and "alt" in info["mods"] else ""))
    if not info["hammerspoon"]:
        out.append("  nothing bound")
    for h in info["hammerspoon"]:
        where = f"{h['file']}:{h['line']}" if h["line"] else h["file"]
        desc = f"   — {h['desc']}" if h["desc"] else ""
        out.append(f"  {where}  {h['chord']}  {h['kind']} {h['target']}{desc}")
    out.append("")
    out.append("macOS and apps  (" + ", ".join(info["macos"]["as_received"]) + ")")
    if not info["macos"]["rows"]:
        out.append("  free: no system, app or menu row")
    for r in info["macos"]["rows"]:
        if r["kind"] == "system":
            state = "enabled" if r["enabled"] else "disabled"
            out.append(f"  system {r['id']} {r['name']}  {state}")
        elif r["kind"] == "app":
            out.append(f"  app {r['domain']}  {r['name']}")
        else:
            out.append(f"  menu {r['domain']}  “{r['item']}”")
    out.append("")
    t = info["types"]
    if t:
        rows = {"base": "plain", "shift": "⇧", "option": "right ⌥", "shift_option": "⇧ right ⌥"}
        head = "Types" + (f"  (this chord: {rows[t['state']]})" if t["state"] else f"  ({t['why']})")
        out.append(head)
        for state, label in rows.items():
            en, ru, el = (_ch(c) for c in t["layers"][state])
            mark = " ←" if state == t["state"] else ""
            out.append(f"  {label:10} {en}  {ru}  {el}{mark}")
        out.append("  left ⌥ keeps Apple's own ⌥ layer")
    return "\n".join(out)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("chord")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args(argv)
    info = resolve(args.chord)
    print(json.dumps(info, ensure_ascii=False, indent=2) if args.json else render(info))
    return 0


if __name__ == "__main__":
    sys.exit(main())
