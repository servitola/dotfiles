"""Shortcuts the machine holds, projected into the per-key ASCII tables.

Sources: `macos_shortcuts/shortcuts.toml` and `jetbrains rider/keymap.xml` (both captured from
this Mac by `up`). Every shortcut becomes one description line in the table of the key it is
pressed on, marked in the G column so the line is known to be machine-owned:

    ⚙  an enabled macOS symbolic hotkey        `— system 52 dock.toggle_hiding`
    ◆  an app's global hotkey or a menu item   `Shottr — area`, `Music — Repeat All`
    ℝ  a Rider keymap customization            `Rider — Find Usages`

`normalize.py --project` writes these lines and replaces the ones it wrote before; lines
without a marker are hand-written and never touched. Lint rule P1 fails when the lines on
disk differ from `expected()`. A marker gets `!` when Hammerspoon binds the same chord in
that file (`ℝ!`, `◆!`): the shortcut is shadowed, see lint S4 / S5 and the `over` field.

Not projected (reported by `skipped()`): chords with 🌐 (no fn rows in the tables), F1–F12
(their files are placeholders Hammerspoon never loads) and keys without a table file.
"""
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
sys.path.insert(0, os.path.join(HERE, "..", "..", "macos_shortcuts"))

import bridges
import keycodes
import parse_karabiner
import rider
import shortcuts
import classify as _classify
from classify import _KM
import re as _re
_MOD_RANK = {c: i for i, c in enumerate("⇪⇧⌃⌥⌘")}


def _reorder(text):
    return _re.sub(r"[⇪⇧⌃⌥⌘]+", lambda m: "".join(sorted(m.group(0), key=_MOD_RANK.get)), text)
from config import BUTTON_FILES

MARKERS = {"system": "⚙", "app": "◆", "menu": "◆", "rider": rider.MARKER}
MARKER_CHARS = set(MARKERS.values())
STUB_FILES = {"shift", "command", "control", "option", "capslock", "backslash", "backspace"}

APP_NAMES = {
    "cc.ffitch.shottr": "Shottr",
    "org.p0deje.Maccy": "Maccy",
    "com.mowglii.ItsycalApp": "Itsycal",
    "com.openai.chat": "ChatGPT",
    "com.prakashjoshipax.VoiceInk": "VoiceInk",
    "theboringteam.boringnotch": "Boring Notch",
    "com.jordanbaird.Ice": "Ice",
    "com.apple.Music": "Music",
    "com.apple.finder": "Finder",
    "pbs": "Services",
    "com.googlecode.iterm2": "iTerm2",
    "com.apple.Terminal": "Terminal",
    shortcuts.DAY_ONE: "Day One",
}

_MOD_GLYPH = {"shift": "⇧", "ctrl": "⌃", "alt": "⌥", "cmd": "⌘"}
_MOD_ORDER = ("shift", "ctrl", "alt", "cmd")
_HYPER = frozenset(_MOD_ORDER)
_FILE_GLYPH = {"tilde": "~", "space": "␣", "left": "←", "right": "→", "up": "↑", "down": "↓",
               "tab": "⇥", "return": "↩"}


def app_name(domain):
    if domain in APP_NAMES:
        return APP_NAMES[domain]
    if domain == shortcuts.GLOBAL:
        return ""
    return domain.rsplit(".", 1)[-1].replace("App", "") or domain


def _service_label(name):
    """pbs stores `<bundle> - <menu title> - <selector>`; Shortcuts.app services have no bundle."""
    parts = [p.strip() for p in name.split(" - ")]
    if len(parts) != 3:
        return name
    owner, title, _ = parts
    if owner == "(null)":
        return f"Shortcuts.app {title[:8]}"
    return f"{title} ({app_name(owner)})"


def describe(row):
    if isinstance(row, shortcuts.System):
        return f"— system {row.id} {row.name}"
    if isinstance(row, shortcuts.App):
        label = _service_label(row.name) if row.domain == "pbs" else row.name
        return f"{app_name(row.domain)} — {label}"
    app = app_name(row.domain)
    return f"{app} — {row.item}" if app else f"— {row.item}"


def _passthrough_hyper():
    """Physical keys the Hyper layer leaves alone, so `⇪x` reaches macOS as `⇧⌃⌥⌘x`."""
    mapped = {phys for (mods, phys) in parse_karabiner.parse_karabiner() if mods == frozenset({"hyper"})}
    return {k for k in BUTTON_FILES if k not in mapped}


def place(keys, variants=None, passthrough=None):
    """(table file stem, chord text as the table spells it) for a canonical chord, or
    (None, reason) when the chord has no row to live on."""
    mods, key = keycodes.parse(keys)
    if "fn" in mods:
        return None, "🌐 chords have no table rows"
    if re.fullmatch(r"F(1[3-9]|20)", key):
        variants = variants if variants is not None else bridges.slot_variants()
        pressed = variants.get(keys)
        if pressed is None:
            return None, f"nothing emits {keys}"
        return pressed[-1], pressed
    if re.fullmatch(r"F\d+|num\d", key):
        return None, f"{key} has only a placeholder file"
    stem = _KM.get(key, key)
    if stem not in BUTTON_FILES or stem in STUB_FILES:
        return None, f"no table for key {key}"
    glyph = _FILE_GLYPH.get(stem, key)
    if mods == _HYPER:
        passthrough = passthrough if passthrough is not None else _passthrough_hyper()
        if stem in passthrough:
            return stem, "⇪" + glyph
    return stem, "".join(_MOD_GLYPH[m] for m in _MOD_ORDER if m in mods) + glyph


def rows_with_keys(machine_rows=None):
    rows = machine_rows or shortcuts.load()
    out = [r for r in rows["system"] if r.enabled and r.keys]
    out += [r for r in rows["app"] if r.keys != shortcuts.NONE]
    out += rows["menu"]
    return out


def expected(machine_rows=None):
    """{file stem: {chord text: [(marker, description), …]}}, descriptions sorted."""
    variants = bridges.slot_variants()
    passthrough = _passthrough_hyper()
    files = {}
    for row in rows_with_keys(machine_rows):
        stem, chord = place(row.keys, variants, passthrough)
        if stem is None:
            continue
        kind = "system" if isinstance(row, shortcuts.System) else "app" if isinstance(row, shortcuts.App) else "menu"
        files.setdefault(stem, {}).setdefault(chord, []).append((MARKERS[kind], describe(row)))
    for keys, texts in rider.expected().items():
        stem, chord = place(keys, variants, passthrough)
        if stem is None:
            continue
        files.setdefault(stem, {}).setdefault(chord, []).extend((MARKERS["rider"], t) for t in texts)
    for chords in files.values():
        for chord in chords:
            chords[chord] = sorted(set(chords[chord]), key=lambda t: (t[0] != "⚙", t[0] != "◆", t[1]))
    return files


def skipped(machine_rows=None):
    """[(keys, reason)] for the shortcuts `expected()` leaves out."""
    variants = bridges.slot_variants()
    passthrough = _passthrough_hyper()
    out = []
    for row in rows_with_keys(machine_rows):
        stem, reason = place(row.keys, variants, passthrough)
        if stem is None:
            out.append((row.keys, f"{shortcuts.ident(row)}: {reason}"))
    for keys, texts in rider.expected().items():
        stem, reason = place(keys, variants, passthrough)
        if stem is None:
            out.append((keys, f"{', '.join(texts)}: {reason}"))
    for action_id, ks in sorted(set(rider.skipped())):
        out.append((ks, f"Rider {action_id}: no chord glyph for that key"))
    return out


def received(chord_text):
    """The chord macOS gets when the table's chord is pressed: a slot letter becomes its
    emitted F-key, a Hyper- or Tab-layer key its layer output (`⇪1` → `F1`, `⇥a` → `⌘l`), a plain
    `⇪x` the four modifiers; None when the grammar does not know the chord."""
    emitted = {v: k for k, v in bridges.slot_variants().items()}
    if chord_text in emitted:
        return emitted[chord_text]
    try:
        mods, phys = _classify._parse_modifiers(chord_text)
    except Exception:
        mods, phys = None, None
    if mods and ("hyper" in mods or "tab_mod" in mods):
        out = parse_karabiner.parse_karabiner().get((mods, phys))
        if out and out != "passthrough":
            try:
                return keycodes.canonical(_reorder(out))
            except ValueError:
                return None
    try:
        return keycodes.canonical(chord_text)
    except ValueError:
        return None


def flag_conflicts(expected_for_file, actives, rider_effective=None, names=None):
    """`expected()[stem]` with `!` on the marker of every line whose chord Hammerspoon binds
    in this file, plus an `ℝ!` line for each Rider *default* a binding without ⇪ shadows
    (defaults are otherwise not projected; `rider_effective` is `rider.effective()`, None
    without Rider.app). Same shape: {chord: [(marker, desc)]}."""
    bound = {}
    for a in actives:
        try:
            bound[keycodes.canonical(a["chord"])] = a["chord"]
        except ValueError:
            pass
    out = {}
    for chord, descs in expected_for_file.items():
        hit = received(chord) in bound
        out[chord] = [(g + "!" if hit else g, d) for g, d in descs]
    variants = bridges.slot_variants()
    for canonical, chord in bound.items():
        if chord.startswith("⇪") or not rider_effective or canonical not in rider_effective:
            continue
        row = out.setdefault(variants.get(chord, chord), [])
        have = {d for _, d in row}
        for action_id in rider_effective[canonical]:
            text = f"{rider.APP_LABEL} — {rider.label(action_id, names or {})}"
            if text not in have:
                row.append((rider.MARKER + "!", text))
                have.add(text)
    return out


_ROW = re.compile(r"^--(?P<chord>[^│]*)│[^│]*│[^│]*│(?P<g>[^│]*)│\s?(?P<desc>.*?)\s*$")


def marked_lines(lines):
    """[(line number, chord text, marker, description)] for every machine-owned line, a
    continuation line taking the chord of the row above it."""
    out, chord = [], None
    for i, line in enumerate(lines):
        m = _ROW.match(line.rstrip("\n"))
        if not m:
            if not line.lstrip().startswith("--"):
                chord = None
            continue
        text = m.group("chord").strip()
        if text:
            chord = text
        g = m.group("g").strip()
        if g.rstrip("!") in MARKER_CHARS and chord:
            out.append((i + 1, chord, g, m.group("desc").strip()))
    return out
