#!/usr/bin/env python3
"""Rider's keymap as a source for the key tables.

  python3 docs/keyboard/rider.py capture    copy Rider's active keymap into `jetbrains rider/keymap.xml`
  python3 docs/keyboard/rider.py apply      copy the repo keymap back into Rider (Rider must be closed:
                                            it reads keymaps at launch and rewrites the file on exit)
  python3 docs/keyboard/rider.py            print what the tables get from it (ℝ lines) and what is skipped

The repo copy holds only what the owner changed against the parent keymap (that is how
JetBrains stores a keymap): every `<action>` in it is a customization, an empty one a
removed default. Those are the lines projected into the tables, marked `ℝ`. The parent
chain (`Mac OS X 10.5+` → `$default`) lives inside Rider.app and is read only for the
effective keymap, which lint S5 uses to find Rider actions a Hammerspoon chord takes away;
without Rider installed that check is skipped.
"""
import codecs
import glob
import os
import re
import sys
import xml.etree.ElementTree as ET
import zipfile

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

import keycodes

ROOT = os.path.normpath(os.path.join(HERE, "..", ".."))
KEYMAP = os.path.join(ROOT, "jetbrains rider", "keymap.xml")
JETBRAINS = os.path.expanduser("~/Library/Application Support/JetBrains")
APP = os.path.expanduser("~/Applications/Rider.app")
PLATFORM_JAR = os.path.join(APP, "Contents", "lib", "intellij.platform.ide.impl.jar")
BUNDLE_JARS = {PLATFORM_JAR: "messages/ActionsBundle.properties",
               os.path.join(APP, "Contents", "lib", "intellij.rider.jar"): "messages/RiderActionsBundle.properties"}
MARKER = "ℝ"
APP_LABEL = "Rider"

_MODS = {"shift": "shift", "ctrl": "ctrl", "control": "ctrl", "alt": "alt", "meta": "cmd"}
_KEYS = {
    "space": "␣", "escape": "⎋", "tab": "⇥", "enter": "↩", "back_space": "⌫", "delete": "⌦",
    "up": "↑", "down": "↓", "left": "←", "right": "→", "page_up": "PgUp", "page_down": "PgDn",
    "home": "↖", "end": "↘", "period": ".", "comma": ",", "slash": "/", "semicolon": ";",
    "quote": "'", "open_bracket": "[", "close_bracket": "]", "minus": "-", "equals": "=",
    "back_quote": "`", "back_slash": "\\",
}


# `$default` is written for Windows; on a Mac the IDE wraps it (MacOSDefaultKeymap) and swaps
# Ctrl and Meta, so `control D` there is ⌘D. Child keymaps (Mac OS X 10.5+, the owner's) are literal.
_MAC_DEFAULT_SWAP = {"ctrl": "cmd", "cmd": "ctrl"}


def keystroke_to_chord(text, mac_default=False):
    """`shift ctrl s` → `⇧⌃s`; None for keys the chord grammar has no glyph for (numpad
    operators, Insert, the context-menu key). `mac_default` applies the `$default` swap."""
    mods, key = set(), None
    for tok in text.lower().split():
        if tok in _MODS:
            m = _MODS[tok]
            mods.add(_MAC_DEFAULT_SWAP.get(m, m) if mac_default else m)
        elif tok == "altgraph":
            mods.add("alt")
        else:
            key = tok
    if key is None:
        return None
    if re.fullmatch(r"f\d+", key):
        key = key.upper()
    elif re.fullmatch(r"numpad\d", key):
        key = "num" + key[-1]
    else:
        key = _KEYS.get(key, key)
    if key not in keycodes.KEYCODE:
        return None
    return keycodes.render(frozenset(mods), key)


def _actions(root):
    """{action id: [(first chord, second chord or None), …]}, an empty list for a removed action."""
    out = {}
    swap = root.get("name") == "$default"
    for action in root.findall("action"):
        strokes = []
        for ks in action.findall("keyboard-shortcut"):
            first = keystroke_to_chord(ks.get("first-keystroke", ""), swap)
            second = ks.get("second-keystroke")
            strokes.append((first, keystroke_to_chord(second, swap) if second else None))
        out[action.get("id")] = strokes
    return out


def overrides(path=KEYMAP):
    """(parent keymap name, {action id: shortcuts}) from the repo copy."""
    root = ET.parse(path).getroot()
    return root.get("parent"), _actions(root)


def _humanize(action_id):
    name = action_id.lstrip("$").rsplit(".", 1)[-1]
    return re.sub(r"(?<=[a-z0-9])(?=[A-Z])|(?<=[A-Z])(?=[A-Z][a-z])", " ", name)


def action_names():
    """{action id: menu text} from Rider's resource bundles; {} without Rider."""
    names = {}
    for jar, member in BUNDLE_JARS.items():
        if not os.path.exists(jar):
            continue
        with zipfile.ZipFile(jar) as z:
            text = z.read(member).decode("latin-1")
        for m in re.finditer(r"^action\.(.+?)\.text=(.*)$", text, re.M):
            value = codecs.decode(m.group(2).strip(), "unicode_escape")
            # The ellipsis stays: it is what tells `Debug…` (choose a configuration) from `Debug`.
            names[m.group(1)] = re.sub(r"_(?=\w)", "", value).replace("...", "…").strip()
    return names


def label(action_id, names):
    return names.get(action_id) or _humanize(action_id)


def expected(path=KEYMAP, names=None):
    """{canonical first chord: [description]} for the customizations in the repo copy."""
    if not os.path.exists(path):
        return {}
    names = action_names() if names is None else names
    out = {}
    for action_id, strokes in overrides(path)[1].items():
        for first, second in strokes:
            if first is None:
                continue
            text = f"{APP_LABEL} — {label(action_id, names)}" + (f" (then {second})" if second else "")
            out.setdefault(first, []).append(text)
    return out


def skipped(path=KEYMAP):
    """[(action id, keystroke text)] the chord grammar cannot spell."""
    if not os.path.exists(path):
        return []
    root = ET.parse(path).getroot()
    return [(a.get("id"), ks.get("first-keystroke"))
            for a in root.findall("action") for ks in a.findall("keyboard-shortcut")
            if keystroke_to_chord(ks.get("first-keystroke", "")) is None]


def _parent_chain(name):
    """Keymap roots from the jar, child first, up to `$default`."""
    chain = []
    with zipfile.ZipFile(PLATFORM_JAR) as z:
        while name:
            root = ET.fromstring(z.read(f"keymaps/{name}.xml"))
            chain.append(root)
            name = root.get("parent")
    return chain


def effective(path=KEYMAP):
    """{canonical first chord: [action id]} after the whole parent chain, or None when
    Rider.app (the parent keymaps) is not here."""
    if not (os.path.exists(path) and os.path.exists(PLATFORM_JAR)):
        return None
    parent, own = overrides(path)
    layers = [_actions(r) for r in reversed(_parent_chain(parent))] + [own]
    actions = {}
    for layer in layers:
        actions.update(layer)
    out = {}
    for action_id, strokes in actions.items():
        for first, _ in strokes:
            if first is not None:
                out.setdefault(first, []).append(action_id)
    return out


def active_keymap_path():
    """The keymap file Rider uses now, from the newest Rider config directory."""
    dirs = sorted(glob.glob(os.path.join(JETBRAINS, "Rider*")), key=os.path.getmtime, reverse=True)
    for d in dirs:
        setting = os.path.join(d, "options", "mac", "keymap.xml")
        if not os.path.exists(setting):
            continue
        name = ET.parse(setting).getroot().find("component/active_keymap").get("name")
        path = os.path.join(d, "keymaps", f"{name}.xml")
        if os.path.exists(path):
            return path
    return None


def capture():
    src = active_keymap_path()
    if src is None:
        print("rider: no active custom keymap on this Mac, keeping the repo copy", file=sys.stderr)
        return 0
    with open(src, encoding="utf-8") as fh:
        text = fh.read()
    os.makedirs(os.path.dirname(KEYMAP), exist_ok=True)
    with open(KEYMAP, "w", encoding="utf-8") as fh:
        fh.write(text)
    print(f"wrote {os.path.relpath(KEYMAP, ROOT)} from {src}")
    return 0


def apply():
    import subprocess
    if subprocess.run(["pgrep", "-f", "Rider.app/Contents/MacOS"], capture_output=True).returncode == 0:
        sys.exit("rider: quit Rider first — it rewrites its keymap file on exit, which would undo this")
    dst = active_keymap_path()
    if dst is None:
        sys.exit("rider: no Rider config directory with an active custom keymap here")
    with open(KEYMAP, encoding="utf-8") as fh:
        text = fh.read()
    name = ET.fromstring(text).get("name")
    if os.path.basename(dst) != f"{name}.xml":
        sys.exit(f"rider: the repo keymap is named {name!r}, Rider's active one is {os.path.basename(dst)!r}")
    with open(dst, "w", encoding="utf-8") as fh:
        fh.write(text)
    print(f"wrote {dst}; start Rider to pick it up")
    return 0


def main(argv=None):
    argv = sys.argv[1:] if argv is None else argv
    if argv == ["capture"]:
        return capture()
    if argv == ["apply"]:
        return apply()
    for chord, texts in sorted(expected().items()):
        for t in texts:
            print(f"{chord:10} {t}")
    for action_id, ks in skipped():
        print(f"not projected: {action_id} `{ks}`", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
