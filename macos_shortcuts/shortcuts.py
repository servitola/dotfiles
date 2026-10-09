#!/usr/bin/env python3
"""Machine shortcut state, declared in `shortcuts.toml` next to this script.

Three kinds of store live outside the repo; this reads, compares and writes them:

  [[system]]  com.apple.symbolichotkeys → AppleSymbolicHotKeys, one row per numeric id
  [[app]]     an app's own global hotkey, in one of the formats below (`format`)
  [[menu]]    NSUserKeyEquivalents: a shortcut on any menu item, by its exact title

No OS API enumerates the global hotkeys apps register (RegisterEventHotKey and
event taps are both private to the process), so [[app]] knows only the stores
listed here, found by reading every installed app's preferences. `taps` shows
who is listening to the keyboard, which is the closest the OS gets.

App hotkey formats ([[app]] `format`, default `keyboardshortcuts`):
  keyboardshortcuts  sindresorhus/KeyboardShortcuts: `KeyboardShortcuts_<name>` = JSON
                     {carbonKeyCode, carbonModifiers}, or false/0 for none. Found in
                     any domain by `defaults find`. Writable.
  masshortcut        MASShortcut's dictionary transformer: {keyCode, modifierFlags}
                     with NSEvent flags (Itsycal). A cleared shortcut is an absent
                     key, which `apply` cannot write, so `none` is refused. Writable.
  carbon-dict        the same dict with Carbon flags (Day One, in a group container,
                     so it reads as sandboxed: unwritable).
  ice                Ice's `Hotkeys` dict: JSON data `[keyCode, modifiers]` in Ice's
                     own flag set, or `null`. READ-ONLY: this machine holds only
                     `null`s, so the non-null encoding comes from Ice's source, not
                     from a round-trip, and `apply` refuses it.
  services           pbs `NSServicesStatus` → `<service> → key_equivalent`, a menu
                     combo whose letter may be uppercase for ⇧. Covers Services and
                     Shortcuts.app shortcuts ("… - runShortcutAsService"). Writable:
                     the entry is rewritten whole, keeping its other fields.
Formats other than keyboardshortcuts only exist for the (domain, key) pairs in
REGISTRY; adding an app that uses a known format is one REGISTRY line.

Usage:
  shortcuts.py capture [--write]   print (or write) the TOML from this machine
  shortcuts.py check [--json]      ok / differs / missing / unwritable / absent per row, exit 1 unless all ok or absent
  shortcuts.py apply [--dry-run]   write the rows that differ
  shortcuts.py taps [--json]       list active CoreGraphics event taps (needs pyobjc via uvx)

Menu shortcuts (macOS "App Shortcuts"):
  * macOS binds a shortcut to ANY menu item by its exact title, even one the app
    never assigned a shortcut to. `item` is the title EXACTLY as shown, including
    a literal `…`. Only menu-bar items work, not context-menu-only ones.
  * `domain = "NSGlobalDomain"` is System Settings' "All Applications".
  * Stored as a combo: `@` Command, `$` Shift, `~` Option, `^` Control + the key
    character; special keys use unicode (Tab = \\U21e5, … = \\U2026). The TOML
    holds the chord instead and keycodes.py converts, so `~@e` and `@~e` are equal.
  * The Finder row is the reference entry: Finder is not sandboxed, and
    Go ▸ "Enclosing Folder in New Window" has no default shortcut, so ⌥⌘e on it
    proves the write path end to end without changing anything that matters.

Stores checked and NOT supported (see docs/keyboard-setup.md → Machine shortcuts):
Raycast (SQLCipher-encrypted settings DB), Zoom (encrypted DB), Discord (Electron
leveldb), AltTab (keeps defaults in code until changed), iTerm2 `GlobalKeyMap`
(in-app only), Karabiner and Hammerspoon (declared in this repo already).

Gotchas, learned the hard way:
  * Sandboxed / Mac App Store apps (Mail, Notes, TextEdit, Shottr, Maccy, …) keep
    their prefs in a TCC-protected ~/Library/Containers/<domain>, and a script
    CANNOT write there. `apply` never tries: set those by hand, once. Reading
    works, via `defaults export <domain> -` + plistlib, which is why every read
    here goes through export and never through the .plist file.
  * Listing an app in System Settings' "App Shortcuts" pane means writing
    com.apple.universalaccess `com.apple.custommenu.apps`, which is TCC-protected.
    It only affects what the GUI SHOWS; the shortcut fires regardless, so that
    write is best-effort.
  * Changes need `killall cfprefsd` and a relaunch of the target app; the app
    reads its key equivalents and global hotkeys once, at launch.
  * Symbolic hotkeys take effect after `activateSettings -u`, no logout needed.
    Their parameters are (ascii, key code, NSEvent flags); the flags carry fn on
    F-keys and arrows plus bits no chord names (numeric pad), so a row whose
    chord did not change is written back with its original parameters.
  * Ids are the identity and Apple does not document them; `name` is only a
    label from SYMBOLIC_HOTKEYS, "unknown" where nobody has pinned an id down.
"""
import argparse
import json
import os
import plistlib
import re
import shlex
import subprocess
import sys
import tomllib
from collections.abc import Callable
from xml.parsers.expat import ExpatError
from dataclasses import asdict, dataclass, field

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, os.path.join(ROOT, "docs", "keyboard"))

import keycodes

TOML_PATH = os.path.join(HERE, "shortcuts.toml")

SYMBOLIC_DOMAIN = "com.apple.symbolichotkeys"
SYMBOLIC_KEY = "AppleSymbolicHotKeys"
APP_PREFIX = "KeyboardShortcuts_"
MENU_KEY = "NSUserKeyEquivalents"
GLOBAL = "NSGlobalDomain"
UNIVERSAL_ACCESS = "com.apple.universalaccess"
CUSTOM_MENU_APPS = "com.apple.custommenu.apps"
ACTIVATE_SETTINGS = ("/System/Library/PrivateFrameworks/SystemAdministration.framework"
                     "/Resources/activateSettings")
NONE = "none"

SYMBOLIC_HOTKEYS = {
    7: "focus.menu_bar", 8: "focus.dock", 9: "focus.window", 10: "focus.toolbar",
    11: "focus.floating_window", 12: "keyboard_access.toggle", 13: "focus.tab_mode",
    15: "zoom.toggle", 17: "zoom.in", 19: "zoom.out", 21: "display.invert_colors",
    23: "zoom.smoothing", 25: "display.contrast_up", 26: "display.contrast_down",
    27: "focus.next_window",
    28: "screenshot.screen", 29: "screenshot.screen_clipboard",
    30: "screenshot.area", 31: "screenshot.area_clipboard",
    32: "mission_control", 33: "mission_control.app_windows", 36: "mission_control.show_desktop",
    52: "dock.toggle_hiding", 53: "display.brightness_down", 54: "display.brightness_up",
    57: "focus.status_menus", 59: "voiceover.toggle",
    60: "input_source.previous", 61: "input_source.next",
    64: "spotlight", 65: "spotlight.finder_search", 70: "dictionary.lookup",
    79: "spaces.left", 80: "spaces.left.alt", 81: "spaces.right", 82: "spaces.right.alt",
    98: "help_menu",
    **{117 + n: f"spaces.desktop_{n}" for n in range(1, 10)},
    160: "launchpad", 162: "accessibility.controls", 163: "notification_center",
    164: "do_not_disturb", 184: "screenshot.options", 190: "quick_note", 222: "stage_manager",
    237: "window.fill", 238: "window.center", 239: "window.restore",
}

FIELDS = {"system": ("id", "name", "enabled", "keys"),
          "app": ("domain", "name", "format", "keys"),
          "menu": ("domain", "item", "keys")}
OPTIONAL = {"app": {"format"}}

HEADER = """\
# Shortcut state outside the repo, declared. `shortcuts.py capture` writes this
# file from the running machine; `check` diffs; `apply` pushes it back.
# Chords: ⇧⌃⌥⌘ + key glyph, 🌐 = fn/Globe (docs/keyboard/keycodes.py).
# [[system]] com.apple.symbolichotkeys, id is the identity, name only a label;
#            keys = "" when the entry holds no key.
# [[app]]    an app's global hotkey; format says how it is stored (shortcuts.py
#            docstring); keys = "none" when unset.
# [[menu]]   NSUserKeyEquivalents; item is the menu title exactly as shown.
"""


@dataclass(frozen=True)
class System:
    id: int
    name: str
    enabled: bool
    keys: str
    line: int = field(default=0, compare=False)


@dataclass(frozen=True)
class App:
    domain: str
    name: str
    keys: str
    format: str = "keyboardshortcuts"
    line: int = field(default=0, compare=False)


@dataclass(frozen=True)
class Menu:
    domain: str
    item: str
    keys: str
    line: int = field(default=0, compare=False)


KINDS = {"system": System, "app": App, "menu": Menu}


class Machine:
    """The live macOS preferences. Tests pass an object with the same methods."""

    def export(self, domain):
        """The domain's prefs; {} with a warning when it cannot be read, so one bad domain
        does not hide every other row from capture and check."""
        proc = subprocess.run(["defaults", "export", os.path.expanduser(domain), "-"], capture_output=True)
        try:
            if proc.returncode != 0:
                raise ValueError(proc.stderr.decode("utf-8", "replace").strip() or f"exit {proc.returncode}")
            return plistlib.loads(proc.stdout) if proc.stdout.strip() else {}
        except (ValueError, ExpatError) as e:
            print(f"warning: skipping '{domain}', defaults export failed: {e}", file=sys.stderr)
            return {}

    def find(self, word):
        out = subprocess.run(["defaults", "find", word], capture_output=True, text=True).stdout
        names = re.findall(r"^Found \d+ keys in domain '(.+)': \{$", out, re.M)
        return sorted({GLOBAL if n == "Apple Global Domain" else n for n in names})

    def sandboxed(self, domain):
        if "/Group Containers/" in domain:
            return True
        return domain != GLOBAL and os.path.isdir(os.path.expanduser(f"~/Library/Containers/{domain}"))

    def write(self, args):
        args = [os.path.expanduser(args[0]), *args[1:]]
        return subprocess.run(["defaults", "write", *args], capture_output=True).returncode == 0

    def run(self, argv):
        subprocess.run(argv, capture_output=True)

    def taps(self):
        """(raw tap dicts, {pid: process name}). pyobjc comes from uvx so this module
        stays importable, and testable, on a bare python."""
        out = subprocess.run(["uvx", "--quiet", "--with", "pyobjc-framework-Quartz", "python", "-c", TAP_LISTER],
                             capture_output=True, text=True, check=True).stdout
        raw = json.loads(out)
        pids = {t[k] for t in raw for k in ("tappingProcess", "processBeingTapped")}
        names = {}
        for line in subprocess.run(["ps", "-axo", "pid=,comm="], capture_output=True, text=True).stdout.splitlines():
            pid, _, comm = line.strip().partition(" ")
            if int(pid) in pids:
                names[pid] = os.path.basename(comm.strip())
        return raw, names



def _symbolic_table(machine):
    return machine.export(SYMBOLIC_DOMAIN).get(SYMBOLIC_KEY, {})


def _symbolic_keys(entry):
    value = entry.get("value", {})
    params = value.get("parameters")
    # A "modifier" hotkey fires on a bare modifier and holds [flags, mask], no key:
    # a fresh Tahoe ships Do Not Disturb (164) as one, bound to ⌃.
    if value.get("type") == "modifier":
        return keycodes.render({m for m, bit in keycodes.NS.items() if params[0] & bit}, "")
    return keycodes.symbolic_to_chord(params) if params else ""


def _app_keys(value):
    """`none` is stored as `false` by the KeyboardShortcuts library; older writes left `0`."""
    if value is False or type(value) is int and value == 0:
        return NONE
    if isinstance(value, str):
        data = json.loads(value)
        return keycodes.carbon_to_chord(data["carbonKeyCode"], data["carbonModifiers"])
    raise ValueError(f"KeyboardShortcuts value {value!r} is neither false/0 nor a JSON string")


def _keyboardshortcuts_value(keys, _live):
    if keys == NONE:
        return False
    code, flags = keycodes.chord_to_carbon(keys)
    return json.dumps({"carbonKeyCode": code, "carbonModifiers": flags}, separators=(",", ":"))


def _dict_format(to_chord, to_flags):
    def decode(raw):
        return to_chord(raw["keyCode"], raw["modifierFlags"])

    def encode(keys, _live):
        if keys == NONE:
            return None
        code, flags = to_flags(keys)
        return {"keyCode": code, "modifierFlags": flags}
    return decode, encode


def _ice_keys(raw):
    combo = json.loads(raw)
    return NONE if combo is None else keycodes.ice_to_chord(*combo)


def _services_keys(entry):
    combo = entry.get("key_equivalent")
    return keycodes.services_combo_to_chord(combo) if combo else NONE


def _services_value(keys, live):
    entry = {k: v for k, v in (live or {}).items() if k != "key_equivalent"}
    if keys != NONE:
        entry["key_equivalent"] = keycodes.chord_to_menu_combo(keys)
    return entry


@dataclass(frozen=True)
class Format:
    """`encode(keys, live raw value)` gives the value to store, None when it cannot be
    stored; a format without `encode` is read-only."""
    decode: Callable
    validate: Callable
    encode: Callable | None = None
    absent_is_none: bool = False
    holds_key: Callable = lambda raw: True


_MAS_DECODE, _MAS_ENCODE = _dict_format(keycodes.ns_to_chord, keycodes.chord_to_ns)
_CARBON_DECODE, _CARBON_ENCODE = _dict_format(keycodes.carbon_to_chord, keycodes.chord_to_carbon)
FORMATS = {
    "keyboardshortcuts": Format(_app_keys, keycodes.chord_to_carbon, _keyboardshortcuts_value),
    "masshortcut": Format(_MAS_DECODE, keycodes.chord_to_ns, _MAS_ENCODE, absent_is_none=True),
    "carbon-dict": Format(_CARBON_DECODE, keycodes.chord_to_carbon, _CARBON_ENCODE, absent_is_none=True),
    "ice": Format(_ice_keys, keycodes.chord_to_ice),
    "services": Format(_services_keys, keycodes.chord_to_menu_combo, _services_value,
                       holds_key=lambda entry: bool(entry.get("key_equivalent"))),
}
DEFAULT_FORMAT = "keyboardshortcuts"


@dataclass(frozen=True)
class Slot:
    """Where one app keeps its hotkeys: `key` is a single top-level key, `parent` a dict
    holding one hotkey per entry, `prefix` a family of top-level keys."""
    domain: str
    format: str
    app: str
    how: str
    key: str | None = None
    parent: str | None = None
    prefix: str = ""

    def container(self, prefs):
        return prefs.get(self.parent, {}) if self.parent else prefs

    def items(self, prefs):
        holds_key = FORMATS[self.format].holds_key
        for k, raw in self.container(prefs).items():
            if (self.key is None or k == self.key) and k.startswith(self.prefix) and holds_key(raw):
                yield k[len(self.prefix):], raw

    def get(self, prefs, name):
        return self.container(prefs).get(self.prefix + name)


DAY_ONE = "~/Library/Group Containers/5U8NS4GX82.dayoneapp2/Library/Preferences/5U8NS4GX82.dayoneapp2"
REGISTRY = (
    Slot("com.mowglii.ItsycalApp", "masshortcut", "Itsycal", "Itsycal ▸ Settings ▸ Keyboard shortcut",
         key="GlobalShortcut"),
    Slot(DAY_ONE, "carbon-dict", "Day One", "Day One ▸ Settings ▸ General ▸ global shortcut",
         key="DOMenuEntryGlobalShortcut"),
    Slot("com.jordanbaird.Ice", "ice", "Ice", "Ice ▸ Settings ▸ Hotkeys", parent="Hotkeys"),
    Slot("pbs", "services", "Services", "System Settings ▸ Keyboard ▸ Keyboard Shortcuts ▸ Services "
         "(a Shortcuts.app shortcut: its Details ▸ Add Keyboard Shortcut)", parent="NSServicesStatus"),
)
PBS_UPDATE = ("/System/Library/CoreServices/pbs", "-update")


def _keyboardshortcuts_slot(domain):
    return Slot(domain, DEFAULT_FORMAT, domain, "the app's own settings", prefix=APP_PREFIX)


def slot_for(row):
    if row.format == DEFAULT_FORMAT:
        return _keyboardshortcuts_slot(row.domain)
    for slot in REGISTRY:
        if (slot.domain, slot.format) == (row.domain, row.format):
            return slot
    raise ValueError(f"no REGISTRY entry stores format \"{row.format}\" in {row.domain}")


def _live_app(prefs, row):
    """(raw value, chord) as the machine holds it; (None, None) when nothing is stored."""
    fmt = FORMATS[row.format]
    raw = slot_for(row).get(prefs, row.name)
    if raw is None:
        return None, NONE if fmt.absent_is_none else None
    return raw, fmt.decode(raw)


def capture(machine):
    """Every row the machine has, sorted so an unchanged machine re-captures identically."""
    system = [System(int(i), SYMBOLIC_HOTKEYS.get(int(i), "unknown"), bool(e.get("enabled")),
                     _symbolic_keys(e))
              for i, e in _symbolic_table(machine).items()]
    apps = []
    for slot in [*map(_keyboardshortcuts_slot, machine.find(APP_PREFIX)), *REGISTRY]:
        decode = FORMATS[slot.format].decode
        apps += [App(slot.domain, name, decode(raw), slot.format)
                 for name, raw in slot.items(machine.export(slot.domain))]
    menu_domains = {GLOBAL, *machine.find(MENU_KEY),
                    *machine.export(UNIVERSAL_ACCESS).get(CUSTOM_MENU_APPS, [])}
    menus = [Menu(d, item, keycodes.menu_combo_to_chord(combo))
             for d in menu_domains
             for item, combo in machine.export(d).get(MENU_KEY, {}).items()]
    return {"system": sorted(system, key=lambda r: r.id),
            "app": sorted(apps, key=lambda r: (r.domain, r.name)),
            "menu": sorted(menus, key=lambda r: (r.domain, r.item))}



def _toml_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, int):
        return str(v)
    return json.dumps(v, ensure_ascii=False)


def render(rows):
    out = [HEADER]
    for kind in FIELDS:
        for r in rows[kind]:
            out.append(f"[[{kind}]]")
            out += [f"{f} = {_toml_value(getattr(r, f))}" for f in FIELDS[kind]]
            out.append("")
    return "\n".join(out)


def _check_row(kind, entry):
    if kind == "app":
        if entry.get("format", DEFAULT_FORMAT) not in FORMATS:
            raise ValueError(f"format = \"{entry['format']}\" is not one of {', '.join(FORMATS)}")
        slot_for(App(entry["domain"], entry["name"], entry["keys"], entry.get("format", DEFAULT_FORMAT)))
    keys = entry["keys"]
    if kind == "system" and keys == "" or kind == "app" and keys == NONE:
        return
    if keycodes.canonical(keys) != keys:
        raise ValueError(f"keys = \"{keys}\" is not canonical, write \"{keycodes.canonical(keys)}\"")
    if kind == "app":
        FORMATS[entry.get("format", DEFAULT_FORMAT)].validate(keys)
    elif kind == "menu":
        keycodes.chord_to_menu_combo(keys)


def load(path=TOML_PATH):
    with open(path, "rb") as fh:
        text = fh.read().decode("utf-8")
    data = tomllib.loads(text)
    unknown = set(data) - set(FIELDS)
    if unknown:
        raise ValueError(f"{os.path.basename(path)}: unknown tables {sorted(unknown)}")
    rows = {}
    for kind, fields in FIELDS.items():
        lines = [i + 1 for i, t in enumerate(text.splitlines()) if t.strip() == f"[[{kind}]]"]
        rows[kind] = []
        for entry, line in zip(data.get(kind, []), lines):
            where = f"{os.path.basename(path)} line {line}"
            optional = OPTIONAL.get(kind, set())
            if not set(fields) - optional <= set(entry) <= set(fields):
                raise ValueError(f"{where}: [[{kind}]] needs exactly {', '.join(fields)}"
                                 + (f" ({', '.join(sorted(optional))} optional)" if optional else ""))
            try:
                _check_row(kind, entry)
            except ValueError as e:
                raise ValueError(f"{where}: {e}") from None
            rows[kind].append(KINDS[kind](**entry, line=line))
        idents = [ident(r) for r in rows[kind]]
        dupes = {i for i in idents if idents.count(i) > 1}
        if dupes:
            raise ValueError(f"{os.path.basename(path)}: [[{kind}]] declared twice: {sorted(dupes)}")
    return rows


def ident(row):
    if isinstance(row, System):
        return f"system {row.id} ({row.name})"
    if isinstance(row, App):
        return f"app {row.domain} {row.name}"
    return f"menu {row.domain} “{row.item}”"



@dataclass
class Result:
    row: object
    status: str
    live: str | None = None
    live_value: object = None


def _describe_system(enabled, keys):
    return f"{'enabled' if enabled else 'disabled'} {keys or '(no key)'}"


def check(rows, machine):
    """(results, undeclared symbolic ids). Reads only."""
    results = []
    table = _symbolic_table(machine)
    for r in rows["system"]:
        entry = table.get(str(r.id))
        if entry is None:
            results.append(Result(r, "missing"))
            continue
        live = (bool(entry.get("enabled")), _symbolic_keys(entry))
        ok = live == (r.enabled, r.keys)
        results.append(Result(r, "ok" if ok else "differs", _describe_system(*live), entry))
    exports = {}
    for r in rows["app"] + rows["menu"]:
        prefs = exports.setdefault(r.domain, machine.export(r.domain))
        if isinstance(r, App):
            value, live = _live_app(prefs, r)
        else:
            value = prefs.get(MENU_KEY, {}).get(r.item)
            live = None if value is None else keycodes.menu_combo_to_chord(value)
        if live == r.keys:
            results.append(Result(r, "ok", live, value))
        elif machine.sandboxed(r.domain):
            # No prefs at all: the app was never installed here, nothing to set by hand yet.
            results.append(Result(r, "unwritable" if prefs else "absent", live, value))
        else:
            results.append(Result(r, "missing" if live is None else "differs", live, value))
    declared = {r.id for r in rows["system"]}
    undeclared = sorted(int(i) for i in table if int(i) not in declared)
    return results, undeclared


def _line(res):
    live = "" if res.status == "ok" or res.live is None else f" (live: {res.live})"
    return f"{res.status:10} {ident(res.row)} → {_declared(res.row)}{live}"


def _declared(row):
    if isinstance(row, System):
        return _describe_system(row.enabled, row.keys)
    return row.keys



def _symbolic_entry(row, live_entry):
    entry = {"enabled": row.enabled}
    live_value = (live_entry or {}).get("value")
    if live_value and _symbolic_keys(live_entry) == row.keys:
        entry["value"] = live_value
    elif row.keys:
        entry["value"] = {"parameters": keycodes.chord_to_symbolic(row.keys), "type": "standard"}
    return entry


def _plist_fragment(value):
    xml = plistlib.dumps(value).decode("utf-8")
    body = xml[xml.index("<plist version=\"1.0\">") + len("<plist version=\"1.0\">"):xml.rindex("</plist>")]
    return re.sub(r">\s+<", "><", body.strip())


def _plist_key(name):
    """`defaults -dict-add` parses the key as a plist, so a bare `(null) - … - runShortcutAsService`
    reads as an unterminated array and the write fails; a quoted string is stored unquoted."""
    return '"' + name.replace("\\", "\\\\").replace('"', '\\"') + '"'


def write_args(res):
    """The `defaults write` arguments that bring the machine to `res.row`."""
    r = res.row
    if isinstance(r, System):
        return [SYMBOLIC_DOMAIN, SYMBOLIC_KEY, "-dict-add", str(r.id),
                _plist_fragment(_symbolic_entry(r, res.live_value))]
    if isinstance(r, App):
        slot = slot_for(r)
        value = FORMATS[r.format].encode(r.keys, res.live_value)
        if slot.parent:
            return [r.domain, slot.parent, "-dict-add", _plist_key(r.name), _plist_fragment(value)]
        key = slot.prefix + r.name
        if isinstance(value, bool):
            return [r.domain, key, "-bool", "true" if value else "false"]
        if isinstance(value, str):
            return [r.domain, key, "-string", value]
        return [r.domain, key, _plist_fragment(value)]
    return [r.domain, MENU_KEY, "-dict-add", _plist_key(r.item), keycodes.chord_to_menu_combo(r.keys)]


def refusal(row):
    """Why `apply` will not write this [[app]] row, or None."""
    if not isinstance(row, App):
        return None
    slot, fmt = slot_for(row), FORMATS[row.format]
    if fmt.encode is None:
        return f"{slot.app} stores it as `{row.format}`, read-only here; set it in {slot.how}"
    if row.keys == NONE and fmt.absent_is_none:
        return f"{slot.app} clears it by deleting the key, which apply does not do; clear it in {slot.how}"
    return None


def apply(rows, machine, dry_run=False, say=print):
    """Write every row that differs. Returns False when a write failed."""
    results, _ = check(rows, machine)
    todo = [res for res in results if res.status != "ok"]
    if not todo:
        say("nothing to do")
        return True
    wrote_system, wrote_prefs, wrote_services, relaunch, menu_apps, failed = False, False, False, set(), set(), False
    for res in todo:
        r = res.row
        if res.status == "unwritable":
            say(f"skip       {ident(r)} → {_declared(r)}: {r.domain} is sandboxed, set it by hand")
            continue
        if res.status == "absent":
            say(f"skip       {ident(r)} → {_declared(r)}: app not installed")
            continue
        why = refusal(r)
        if why:
            say(f"refuse     {ident(r)} → {_declared(r)}: {why}")
            continue
        args = write_args(res)
        if dry_run:
            say("would run  " + shlex.join(["defaults", "write", *args]))
            continue
        if not machine.write(args):
            say(f"✗ could not write '{r.domain if not isinstance(r, System) else SYMBOLIC_DOMAIN}' "
                "(sandboxed/TCC-protected — set it by hand)")
            failed = True
            continue
        say(f"✓ {ident(r)} → {_declared(r)}" + (f" (was {res.live})" if res.live else ""))
        if isinstance(r, System):
            wrote_system = True
            continue
        wrote_prefs = True
        if isinstance(r, App) and r.format == "services":
            wrote_services = True
        elif r.domain != GLOBAL:
            relaunch.add(r.domain)
            if isinstance(r, Menu):
                menu_apps.add(r.domain)
    if dry_run:
        return True
    if wrote_system:
        machine.run([ACTIVATE_SETTINGS, "-u"])
    registered = machine.export(UNIVERSAL_ACCESS).get(CUSTOM_MENU_APPS, [])
    for app in sorted(menu_apps - set(registered)):
        if not machine.write([UNIVERSAL_ACCESS, CUSTOM_MENU_APPS, "-array-add", app]):
            say(f"  (note: '{app}' not registered in Settings GUI — TCC; shortcut still works)")
    if wrote_prefs:
        machine.run(["killall", "cfprefsd"])
    if wrote_services:
        machine.run(list(PBS_UPDATE))
    if relaunch:
        say("Relaunch these apps to pick up changes: " + " ".join(sorted(relaunch)))
    return not failed



TAP_FIELDS = ("eventTapID", "tapPoint", "options", "eventsOfInterest", "tappingProcess", "processBeingTapped",
              "enabled", "minUsecLatency", "avgUsecLatency", "maxUsecLatency")
# The first call must already pass a capacity: asked with 0, it reports 0 taps.
TAP_LISTER = f"""
import json, Quartz
_, taps, n = Quartz.CGGetEventTapList(1024, None, None)
print(json.dumps([{{f: getattr(t, f) for f in {TAP_FIELDS!r}}} for t in taps[:n]]))
"""
# CGEventType, plus the NSEventType values a tap mask can also name.
EVENT_TYPES = {
    1: "leftMouseDown", 2: "leftMouseUp", 3: "rightMouseDown", 4: "rightMouseUp", 5: "mouseMoved",
    6: "leftMouseDragged", 7: "rightMouseDragged", 8: "mouseEntered", 9: "mouseExited",
    10: "keyDown", 11: "keyUp", 12: "flagsChanged", 13: "appKitDefined", 14: "systemDefined",
    15: "applicationDefined", 16: "periodic", 17: "cursorUpdate", 18: "rotate", 19: "beginGesture",
    20: "endGesture", 22: "scrollWheel", 23: "tabletPointer", 24: "tabletProximity",
    25: "otherMouseDown", 26: "otherMouseUp", 27: "otherMouseDragged", 29: "gesture", 30: "magnify",
    31: "swipe", 32: "smartMagnify", 33: "quickLook", 34: "pressure", 37: "directTouch", 38: "changeMode",
}
TAP_POINTS = {0: "hid", 1: "session", 2: "annotated"}
ALL_EVENTS = (1 << 64) - 1


def event_names(mask):
    if mask == ALL_EVENTS:
        return ["all"]
    return [EVENT_TYPES.get(bit, f"type{bit}") for bit in range(64) if mask >> bit & 1]


def decode_taps(raw, names):
    """One dict per tap, `warnings` filled in: an active (filtering) tap that is disabled
    stalls nothing but also sees nothing — macOS turns a tap off when its callback times
    out; and one process holding several active taps on the same mask usually means a
    leaked re-registration."""
    rows = []
    for t in raw:
        pid, target = t["tappingProcess"], t["processBeingTapped"]
        rows.append({
            "id": t["eventTapID"], "pid": pid, "process": names.get(str(pid), "?"),
            "point": f"pid {target} ({names.get(str(target), '?')})" if target else TAP_POINTS.get(
                t["tapPoint"], str(t["tapPoint"])),
            "active": t["options"] == 0, "enabled": bool(t["enabled"]),
            "mask": t["eventsOfInterest"], "events": event_names(t["eventsOfInterest"]),
            "latency_usec": [t["minUsecLatency"], t["avgUsecLatency"], t["maxUsecLatency"]],
            "warnings": [],
        })
    active = [r for r in rows if r["active"]]
    for r in active:
        twins = sum(1 for o in active if (o["pid"], o["mask"]) == (r["pid"], r["mask"]))
        if twins > 1:
            r["warnings"].append(f"{twins} active taps with this mask in one process")
        if not r["enabled"]:
            r["warnings"].append("active tap is disabled (callback timeout, or its owner turned it off)")
    return rows


def _tap_line(r):
    lat = "/".join(f"{v:.0f}" for v in r["latency_usec"])
    line = (f"{r['pid']:>6} {r['process'][:24]:24} {r['point']:9} {'active' if r['active'] else 'listen':6} "
            f"{'on ' if r['enabled'] else 'OFF'} {','.join(r['events'])} [µs {lat}]")
    return line + "".join(f"\n{'':7}! {w}" for w in r["warnings"])


def main(argv=None, machine=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    sub.add_parser("capture").add_argument("--write", action="store_true")
    sub.add_parser("check").add_argument("--json", action="store_true")
    sub.add_parser("apply").add_argument("--dry-run", action="store_true")
    sub.add_parser("taps").add_argument("--json", action="store_true")
    args = ap.parse_args(argv)
    machine = machine or Machine()

    if args.cmd == "taps":
        rows = decode_taps(*machine.taps())
        if args.json:
            print(json.dumps(rows, ensure_ascii=False, indent=2))
        else:
            print(f"{'pid':>6} {'process':24} {'point':9} {'mode':6} {'en'} events [µs min/avg/max]")
            for r in sorted(rows, key=lambda r: (r["process"], r["id"])):
                print(_tap_line(r))
        return 0

    if args.cmd == "capture":
        text = render(capture(machine))
        if args.write:
            with open(TOML_PATH, "w", encoding="utf-8") as fh:
                fh.write(text)
            print(f"wrote {os.path.relpath(TOML_PATH, ROOT)}")
        else:
            print(text, end="")
        return 0

    rows = load()
    if args.cmd == "apply":
        return 0 if apply(rows, machine, dry_run=args.dry_run) else 1

    results, undeclared = check(rows, machine)
    if args.json:
        print(json.dumps({"results": [{"kind": type(r.row).__name__.lower(),
                                       "row": {k: v for k, v in asdict(r.row).items() if k != "line"},
                                       "status": r.status, "live": r.live} for r in results],
                          "undeclared_system_ids": undeclared}, ensure_ascii=False, indent=2))
    else:
        for res in results:
            if res.status != "ok":
                print(_line(res))
        for i in undeclared:
            print(f"warning    system {i} is on this machine but not declared (new macOS feature?)")
        counts = {}
        for res in results:
            counts[res.status] = counts.get(res.status, 0) + 1
        print(", ".join(f"{n} {s}" for s, n in sorted(counts.items())))
    return 0 if all(r.status in ("ok", "absent") for r in results) else 1


if __name__ == "__main__":
    sys.exit(main())
