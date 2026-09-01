#!/usr/bin/env python3
"""Inject a keylog marker into every remapped manipulator of a built karabiner.json.

Runs from build.sh on the generated file, never on rules/*.json — the rule files
stay readable and reviewable, the markers exist only in what Karabiner loads.

Recovering the physical chord from the output alone works for 55% of the rules;
the rest collide (⌘← comes from ⇪⌘a, ⇪⌘k, ⇪⌘, and ⇪⌘x alike). The marker closes
that gap by having Karabiner state what it actually matched.
"""
import json, os, sys

HELPER = os.path.join(os.path.dirname(os.path.abspath(__file__)), "helper", "keylog")

MOD = {"right_command": "hyper", "right_control": "hyper", "right_option": "hyper",
       "right_shift": "hyper", "left_shift": "lshift", "left_control": "lctrl",
       "left_option": "lopt", "left_command": "lcmd", "shift": "shift",
       "control": "lctrl", "option": "lopt", "command": "lcmd", "fn": "fn"}

MODIFIER_KEYS = {"left_shift", "right_shift", "left_control", "right_control",
                 "left_option", "right_option", "left_command", "right_command",
                 "fn", "caps_lock"}


def is_infrastructure(to):
    """A manipulator that produces a modifier is the ground others stand on.

    Instrumenting Caps→Hyper broke every chord on the machine: the marker sits in
    the same `to` as a lazy modifier, and the modifier stopped reaching the key
    pressed after it. These build the layer rather than remap a key, so they
    answer nothing about which key a finger hit — skipping them costs no data.
    """
    for t in to:
        if not isinstance(t, dict):
            continue
        if t.get("lazy") or t.get("set_variable") or t.get("key_code") in MODIFIER_KEYS:
            return True
    return False


def label(mods, key):
    """ASCII only: the label is passed through /bin/sh, so no quotes or symbols."""
    seen, out = set(), []
    for m in sorted(mods or []):
        n = MOD.get(m, m)
        if n not in seen:
            seen.add(n)
            out.append(n)
    return "+".join(out + [str(key)])


def describe_to(to):
    parts = []
    for t in to:
        if not isinstance(t, dict):
            continue
        k = t.get("key_code") or t.get("consumer_key_code") or t.get("pointing_button")
        if k and k != "vk_none":
            parts.append(label(t.get("modifiers"), k))
        elif t.get("shell_command"):
            parts.append("shell")
    return ",".join(parts) or "none"


def main():
    path = sys.argv[1]
    with open(path) as fh:
        cfg = json.load(fh)

    if not os.access(HELPER, os.X_OK):
        sys.exit(f"instrument: helper not built: {HELPER}")

    count = skipped = 0
    for rule in cfg["profiles"][0]["complex_modifications"]["rules"]:
        for m in rule.get("manipulators", []):
            if m.get("type") != "basic":
                continue
            to = m.get("to")
            if not isinstance(to, list) or not to:
                continue
            if any(isinstance(t, dict) and t.get("shell_command", "").startswith(HELPER)
                   for t in to):
                continue
            if is_infrastructure(to):
                skipped += 1
                continue
            src = m.get("from", {})
            key = (src.get("key_code") or src.get("consumer_key_code")
                   or src.get("pointing_button"))
            if not key:
                continue
            chord = label(src.get("modifiers", {}).get("mandatory"), key)
            # first, not last: Karabiner repeats only the final `to` event while a
            # key is held. Appending the marker made it the last one, which killed
            # auto-repeat everywhere — holding ⇪1 stopped ramping the brightness.
            # Being non-last also means the marker never forks per repeat.
            to.insert(0, {"shell_command": f"{HELPER} '{chord}' '{describe_to(to)}'"})
            count += 1

    with open(path, "w") as fh:
        json.dump(cfg, fh, indent=4, ensure_ascii=False)
        fh.write("\n")
    print(f"instrumented {count} manipulators, skipped {skipped} modifier-producing")


if __name__ == "__main__":
    main()
