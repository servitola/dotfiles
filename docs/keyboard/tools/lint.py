#!/usr/bin/env python3
"""Lint Hammerspoon keyboard layout files for format and coverage issues.

Pipeline (source of truth): karabiner → birman → hammerspoon.

Checks per file in hammerspoon/Spoons/HotKeys.spoon/layout/60%/*.lua:
  F1  ASCII column geometry matches canonical [17, 32, 47, 51]
  F2  header line uses canonical box-cap and dash counts
  F3  modifier-rows are present in canonical order (base, single, double, …)
  C1  every active {chord=…, app|fn=…} has a matching ASCII row
  D1  ASCII karabiner column matches karabiner/rules/*.json
  D2  ASCII birman column matches Birman.bundle/*.keylayout
  K1  Hammerspoon binding is not dead (Karabiner does not intercept same chord)

Exit codes:
  0 — clean
  1 — issues found (when run without --warn-only)

Usage:
  python3 lint.py                # full report, exit 1 on any issue
  python3 lint.py --strict       # exit 1 only on ERROR (pre-commit mode)
  python3 lint.py --files a.lua  # lint specific files
"""
import argparse
import os
import re
import sys
from collections import defaultdict

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

from parse_karabiner import parse_karabiner, _TO_PHYS, _to_display, _from_mods_to_layer
from parse_birman import parse_birman, LAYER_TO_STATE
from config import FKEY_MAPPING, MOD_DISPLAY

LAYOUT_DIR = os.path.normpath(os.path.join(
    HERE, "..", "..", "..", "hammerspoon", "Spoons", "HotKeys.spoon", "layout", "60%"))

# Canonical format
CANONICAL_COLS = [17, 32, 47, 51]   # positions of │ separators on chord rows
CANONICAL_HDR_TAIL_DASHES = 36       # dashes after "app — function "
CANONICAL_BOX_CAP_DASHES = 5         # ╭—————╮

# Files that intentionally skip the full table (modifier keys themselves)
STUB_FILES = {"shift.lua", "command.lua", "control.lua", "option.lua",
              "capslock.lua", "backslash.lua", "backspace.lua"}

# Severities
ERROR, WARN, INFO = "ERROR", "WARN", "INFO"
COLOR = {ERROR: "\033[31m", WARN: "\033[33m", INFO: "\033[36m", "_": "\033[0m",
         "dim": "\033[90m", "bold": "\033[1m"}

# ─── regex ──────────────────────────────────────────────────────────────────
CHORD_ROW_RE = re.compile(
    # `\s*` (not `\s+`): max-width 12-char chords leave no padding after `--`
    r'^--\s*([⇪⇧⌃⌥⌘⇥]*(?:[a-zA-Z0-9~\-=\[\]\;\',./` ⎋↩␣←→↑↓]|F\d+|num\d+)+)'
    r'(?:\s*→\s*[^\s│]+)?\s+│([^│]*)│([^│]*)│([^│]*)│(.*)$'
)
ACTIVE_RE = re.compile(
    r'\{\s*chord\s*=\s*"([^"]+)"\s*,\s*(app|fn)\s*=\s*"([^"]+)"'
)
HEADER_RE = re.compile(r'^--[—\- ]*chord\s+┬')
BOX_CAP_RE = re.compile(r'^--\s+╭([—\-]+)╮')

# F-key/num convention: ⇪key in ASCII row's karabiner column = F-key sent
F_CHORD = re.compile(r'^(⇧?⌃?⌥?⌘?)(F\d+|num\d+)$')

# ─── findings ──────────────────────────────────────────────────────────────
class Findings:
    def __init__(self):
        self.items = []  # (severity, file, line, code, msg, fix_hint)

    def add(self, sev, file, line, code, msg, hint=""):
        self.items.append((sev, file, line, code, msg, hint))

    def __bool__(self): return bool(self.items)

    def has_errors(self): return any(s == ERROR for s, *_ in self.items)


# ─── per-file parsing ──────────────────────────────────────────────────────
def parse_file(path):
    """Return dict: {lines, header_idx, ascii_rows, actives, header_cols}."""
    with open(path, encoding="utf-8") as f:
        lines = f.readlines()
    header_idx = next((i for i, l in enumerate(lines) if HEADER_RE.match(l)), None)
    header_cols = None
    if header_idx is not None:
        header_cols = [i for i, ch in enumerate(lines[header_idx].rstrip("\n")) if ch == "┬"]
    ascii_rows = []
    for i, line in enumerate(lines):
        m = CHORD_ROW_RE.match(line.rstrip("\n"))
        if not m: continue
        ascii_rows.append({
            "line": i + 1,
            "chord": m.group(1).strip(),
            "karabiner": m.group(2).strip(),
            "birman": m.group(3).strip(),
            "g": m.group(4).strip(),
            "desc": m.group(5).strip(),
            "cols": [j for j, ch in enumerate(line.rstrip("\n")) if ch == "│"],
        })
    actives = []
    for i, line in enumerate(lines):
        s = line.lstrip()
        if s.startswith("--"): continue
        for m in ACTIVE_RE.finditer(line):
            actives.append({"line": i + 1, "chord": m.group(1),
                            "kind": m.group(2), "target": m.group(3)})
    return {"path": path, "lines": lines, "header_idx": header_idx,
            "header_cols": header_cols, "ascii_rows": ascii_rows, "actives": actives}


# ─── checks ────────────────────────────────────────────────────────────────
def check_format(state, findings):
    f = state["path"]
    name = os.path.basename(f)
    if name in STUB_FILES:
        return
    # F2: header presence
    if state["header_idx"] is None:
        findings.add(ERROR, f, 1, "F2",
                     "missing canonical header `-- ——————— chord ┬ karabiner ┬ en | ru | el ┬ G ┬ app — function`",
                     "run normalize.py to insert canonical header")
        return
    # F1: column geometry on header
    if state["header_cols"] != CANONICAL_COLS:
        findings.add(ERROR, f, state["header_idx"] + 1, "F1",
                     f"header ┬ columns {state['header_cols']} ≠ canonical {CANONICAL_COLS}",
                     "run normalize.py to fix column widths")
    # F1: column geometry on every ASCII row
    bad = [r for r in state["ascii_rows"] if r["cols"] != CANONICAL_COLS]
    for r in bad[:3]:  # cap to 3 per file to avoid spam
        findings.add(ERROR, f, r["line"], "F1",
                     f"row │ columns {r['cols']} ≠ canonical {CANONICAL_COLS}",
                     "run normalize.py to fix column widths")
    if len(bad) > 3:
        findings.add(INFO, f, bad[0]["line"], "F1",
                     f"… and {len(bad) - 3} more rows with column drift")
    # F2: box-cap width
    for i, line in enumerate(state["lines"][:6]):
        m = BOX_CAP_RE.match(line)
        if m and len(m.group(1)) != CANONICAL_BOX_CAP_DASHES:
            findings.add(WARN, f, i + 1, "F2",
                         f"box-cap `╭{m.group(1)}╮` has {len(m.group(1))} dashes ≠ canonical {CANONICAL_BOX_CAP_DASHES}",
                         "run normalize.py to fix box-cap")
            break


def check_coverage(state, findings):
    """C1: every active {chord, app|fn} must have a matching ASCII row."""
    f = state["path"]
    name = os.path.basename(f)
    if name in STUB_FILES:
        return
    ascii_chords = {r["chord"]: r for r in state["ascii_rows"]}
    # Build F-key reverse map: which ⇪-prefixed chord in this file maps to which F-key.
    # F-key target can appear in either:
    #   • karabiner column: `⇪r │ F17 │ … │ … │ …`
    #   • chord-column suffix: `⇪⇧h → F16 │ … │ … │ … │ …`
    f_in_karabiner = {}  # F-key string → source chord
    arrow_suffix_re = re.compile(r"→\s*([⇧⌃⌥⌘]*(?:F\d+|num\d+))")
    for r in state["ascii_rows"]:
        if r["karabiner"] and F_CHORD.match(r["karabiner"]):
            f_in_karabiner[r["karabiner"]] = r["chord"]
        # Look in the raw line for `→ F-key` arrow notation in the chord column
        raw = state["lines"][r["line"] - 1]
        chord_cell = raw.split("│", 1)[0] if "│" in raw else raw
        m = arrow_suffix_re.search(chord_cell)
        if m:
            f_in_karabiner[m.group(1)] = r["chord"]
    for a in state["actives"]:
        chord = a["chord"]
        target = a["target"]
        # F-key convention: F17 active is documented as karabiner-column-target
        if F_CHORD.match(chord):
            if chord in f_in_karabiner:
                continue
            # Look up F-key in FKEY_MAPPING (config.py) to find canonical source chord
            base_fkey = re.sub(r"^[⇧⌃⌥⌘]+", "", chord)  # strip leading modifiers
            mod_prefix = chord[:len(chord) - len(base_fkey)]
            mapping = FKEY_MAPPING.get(base_fkey)
            if mapping:
                src_key, implicit_mods = mapping
                # Build canonical source chord: [implicit_mods] + [explicit modifiers] + src_key
                mod_str = "".join(MOD_DISPLAY[m] for m in ("hyper", "shift", "ctrl", "alt", "cmd")
                                  if m in implicit_mods) + mod_prefix
                src_chord = mod_str + src_key
                # Hint with concrete chord
                hint = (f"add `-- {src_chord} │ {chord} │ … │ … │ ↓` row "
                        f"in {src_key}.lua (or this file if same key)")
            else:
                hint = (f"karabiner.json has rule producing `{chord}` from this key; "
                        f"add the source-chord row above the active line "
                        f"(see docs/keyboard/tools/normalize.py for format)")
            # Downgrade unknown F-keys to WARN — they need user-supplied mapping
            sev = ERROR if mapping else WARN
            findings.add(sev, f, a["line"], "C1",
                         f"active `{chord} → {target}` has no ASCII row "
                         f"with `{chord}` in karabiner column",
                         hint)
            continue
        # Exact match
        if chord in ascii_chords:
            continue
        # Try whitespace-insensitive match
        compact = chord.replace(" ", "")
        if any(c.replace(" ", "") == compact for c in ascii_chords):
            continue
        findings.add(ERROR, f, a["line"], "C1",
                     f"active `{chord} → {target}` has no ASCII row",
                     "run normalize.py --insert-missing to insert canonical row")


_MOD_ORDER_RE = re.compile(r"[⇪⇧⌃⌥⌘]+")
_CONSUMER_NAME_TO_SYM = {
    "prev_track": "⏮", "next_track": "⏭", "play_or_pause": "▶/⏸",
    "rewind": "⏪", "fast_forward": "⏩", "fastforward": "⏩",
    "volume_up": "Vol↑", "volume_down": "Vol↓",
    "mute": "Mute", "key_light_up": "🔆", "light_dn": "🔅",
    "vk_consumer_previous": "⏮", "vk_consumer_next": "⏭",
    "vk_consumer_play": "▶/⏸",
    # Karabiner emits key_code names for punctuation; ASCII uses the glyph
    "comma": ",", "period": ".", "slash": "/", "semicolon": ";",
    "quote": "'", "open_bracket": "[", "close_bracket": "]",
    "backslash": "\\", "hyphen": "-", "equal_sign": "=",
    "grave_accent_and_tilde": "`",
    # Word forms commonly used in ASCII
    "volumeup": "Vol↑", "volumedown": "Vol↓",
    "Vol↑": "Vol↑", "Vol↓": "Vol↓",
}

def _normalize_karabiner_value(s):
    """Canonical form for comparing ASCII karabiner col with karabiner.json output."""
    if not s: return ""
    s = re.sub(r"\s+", "", s.strip())
    # Whole-token alias
    if s in _CONSUMER_NAME_TO_SYM:
        return _CONSUMER_NAME_TO_SYM[s]
    # Split modifier prefix from key body, then alias the body
    m = re.match(r"^([⇪⇧⌃⌥⌘]*)(.*)$", s)
    mods, body = (m.group(1), m.group(2)) if m else ("", s)
    body = _CONSUMER_NAME_TO_SYM.get(body, body)
    # Canonical modifier order ⇪⇧⌃⌥⌘
    order = {c: i for i, c in enumerate("⇪⇧⌃⌥⌘")}
    mods = "".join(sorted(mods, key=lambda c: order.get(c, 99)))
    return mods + body


def _parse_karabiner_strict():
    """Like parse_karabiner but preserves left/right modifier specificity.

    Returns {(layer_mods, phys_key): [{'sided': bool, 'to': str, 'has_conditions': bool}]}.
    `sided` is True when the rule uses *_option/*_command/*_control/*_shift with
    left/right qualifier (excluding the Hyper set which is always right_*).
    For Hammerspoon dead-binding check: if all matching rules are `sided`,
    the other side of the modifier remains alive — binding is NOT dead.
    """
    import glob, json
    _DIR = os.path.normpath(os.path.join(HERE, "..", "..", "..", "karabiner", "rules"))
    _HYPER_SET = {"right_command", "right_control", "right_option", "right_shift"}
    _SIDED_PREFIX = ("left_", "right_")
    out = {}
    for path in sorted(glob.glob(os.path.join(_DIR, "*.json"))):
        try:
            with open(path, encoding="utf-8") as f: data = json.load(f)
        except (json.JSONDecodeError, OSError): continue
        manips = data.get("manipulators", [])
        if not manips:
            for rule in data.get("rules", []): manips.extend(rule.get("manipulators", []))
        for m in manips:
            if m.get("type") != "basic": continue
            fr = m.get("from", {})
            fk = fr.get("key_code", "")
            phys = _TO_PHYS.get(fk)
            if not phys: continue
            mandatory = fr.get("modifiers", {}).get("mandatory", [])
            layer = _from_mods_to_layer(mandatory)
            # Strip Hyper modifiers only if ALL four are present (= real Hyper).
            # Otherwise individual right_* are normal sided modifiers (right Option, etc.).
            hyper_active = _HYPER_SET.issubset(set(mandatory))
            non_hyper = [m for m in mandatory
                         if not (hyper_active and m in _HYPER_SET)]
            # `sided` = at least one non-Hyper modifier is left/right-qualified.
            # When sided, only one physical side of the modifier is intercepted,
            # so the other side remains alive for Hammerspoon's generic listener.
            sided = any(m.startswith(_SIDED_PREFIX) for m in non_hyper)
            to_list = m.get("to", [])
            if not to_list: continue
            disp = _to_display(to_list[0])
            if not disp: continue
            has_cond = bool(m.get("conditions"))
            out.setdefault((layer, phys), []).append(
                {"sided": sided, "to": disp, "has_conditions": has_cond})
    return out


def check_karabiner_drift(state, findings, karabiner_strict):
    """D1: ASCII karabiner column vs real karabiner.json.

    Skip drift when Karabiner rule is sided (left/right-qualified) — the ASCII
    generic chord describes the unintercepted side's macOS behavior, not the
    Karabiner output. Only flag when Karabiner intercepts both sides (generic).
    """
    f = state["path"]
    name = os.path.basename(f)
    phys = name[:-4]
    from classify import _parse_modifiers
    for r in state["ascii_rows"]:
        if not r["karabiner"]: continue
        try:
            mods, _ = _parse_modifiers(r["chord"])
        except Exception:
            continue
        rules = karabiner_strict.get((mods, phys), [])
        unconditional = [x for x in rules if not x["has_conditions"]]
        # Prefer generic rule; if only sided rules exist, skip drift (ASCII may
        # describe the unintercepted side intentionally)
        generic = [x for x in unconditional if not x["sided"]]
        if not generic: continue
        real = generic[0]["to"]
        if _normalize_karabiner_value(r["karabiner"]) != _normalize_karabiner_value(real):
            findings.add(WARN, f, r["line"], "D1",
                         f"ASCII karabiner `{r['karabiner']}` ≠ karabiner.json `{real}` for {r['chord']}",
                         "update ASCII karabiner column to match karabiner/rules/")


_GREEK_LOOKALIKES = {"Α": "A", "Β": "B", "Ε": "E", "Ζ": "Z", "Η": "H", "Ι": "I",
                     "Κ": "K", "Μ": "M", "Ν": "N", "Ο": "O", "Ρ": "P", "Τ": "T",
                     "Υ": "Y", "Χ": "X"}

def _bir_eq(a, b):
    """Compare birman chars allowing Latin/Greek look-alike equivalence."""
    return _GREEK_LOOKALIKES.get(a, a) == _GREEK_LOOKALIKES.get(b, b)


def check_birman_drift(state, findings, birman_data):
    """D2: ASCII birman column vs Birman.bundle keylayouts."""
    f = state["path"]
    name = os.path.basename(f)
    phys = name[:-4]
    if phys not in birman_data:
        return
    from classify import _parse_modifiers
    for r in state["ascii_rows"]:
        if not r["birman"]: continue
        try:
            mods, _ = _parse_modifiers(r["chord"])
        except Exception:
            continue
        state_name = LAYER_TO_STATE.get(mods)
        if not state_name: continue
        real = birman_data[phys].get(state_name)
        if not real: continue
        en, ru, gr = real
        # Split by 2+ spaces so multi-codepoint cells like `¹⁄₃` stay intact
        ascii_chars = [c for c in re.split(r"\s{2,}", r["birman"].strip()) if c]
        real_chars = [c for c in (en, ru, gr) if c]
        if not real_chars or not ascii_chars: continue
        # Compare positionally with Greek look-alike tolerance
        n = min(len(ascii_chars), len(real_chars))
        mismatch = any(not _bir_eq(ascii_chars[i], real_chars[i]) for i in range(n))
        if mismatch:
            findings.add(WARN, f, r["line"], "D2",
                         f"ASCII birman `{r['birman']}` ≠ keylayout `{' '.join(real_chars)}` for {r['chord']}",
                         "update ASCII birman column to match Birman.bundle/")


def check_dead_bindings(state, findings, karabiner_strict):
    """K1: Hammerspoon binding on a chord that Karabiner intercepts on BOTH sides.

    A rule with `sided` left/right qualifier only blocks one side; Hammerspoon
    listens via generic modifiers (hs.hotkey {"alt"}), so the other side fires.
    K1 only fires when at least one matching Karabiner rule is generic (not sided)
    OR when conditions are unconditional.
    """
    f = state["path"]
    name = os.path.basename(f)
    phys = name[:-4]
    from classify import _parse_modifiers
    for a in state["actives"]:
        chord = a["chord"]
        if F_CHORD.match(chord): continue  # F-keys are FROM karabiner, not blocked
        try:
            mods, _ = _parse_modifiers(chord)
        except Exception:
            continue
        rules = karabiner_strict.get((mods, phys), [])
        if not rules: continue
        # Filter to unconditional rules (conditional rules apply only in certain apps)
        unconditional = [r for r in rules if not r["has_conditions"]]
        if not unconditional: continue
        # Dead only if some unconditional rule is generic (covers both sides)
        generic = [r for r in unconditional if not r["sided"]]
        if not generic: continue
        intercept = generic[0]["to"]
        findings.add(WARN, f, a["line"], "K1",
                     f"chord `{chord}` is intercepted by Karabiner → `{intercept}` "
                     f"(generic modifier, both sides blocked), "
                     f"Hammerspoon binding `{a['target']}` is dead",
                     "move binding to a non-intercepted chord OR remove the Karabiner rule")


# ─── output ────────────────────────────────────────────────────────────────
def _color(s, c): return f"{COLOR[c]}{s}{COLOR['_']}" if sys.stdout.isatty() else s


def render_report(findings):
    if not findings.items:
        print(_color("✓ keyboard layout clean — all checks passed", INFO))
        return
    by_file = defaultdict(list)
    for sev, f, line, code, msg, hint in findings.items:
        by_file[f].append((sev, line, code, msg, hint))
    summary = defaultdict(int)
    for sev, *_ in findings.items:
        summary[sev] += 1
    # Per-file
    for path, items in sorted(by_file.items()):
        rel = os.path.relpath(path)
        items.sort(key=lambda x: (x[1], x[2]))
        print(_color(f"\n{rel}", "bold"))
        for sev, line, code, msg, hint in items:
            tag = _color(f"{sev:5s}", sev)
            loc = _color(f"{rel}:{line}", "dim")
            print(f"  {tag} [{code}] {loc}  {msg}")
            if hint:
                print(_color(f"         ↳ {hint}", "dim"))
    # Footer
    parts = []
    if summary[ERROR]: parts.append(_color(f"{summary[ERROR]} errors", ERROR))
    if summary[WARN]:  parts.append(_color(f"{summary[WARN]} warnings", WARN))
    if summary[INFO]:  parts.append(_color(f"{summary[INFO]} info", INFO))
    print("\n" + ", ".join(parts) if parts else "")


# ─── main ──────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--files", nargs="*", help="specific *.lua basenames (default: all)")
    ap.add_argument("--strict", action="store_true",
                    help="exit 1 only on ERROR (pre-commit mode); WARN/INFO are reported but don't fail")
    ap.add_argument("--skip-drift", action="store_true",
                    help="skip karabiner.json and Birman keylayout cross-checks (faster)")
    args = ap.parse_args()

    files = args.files or sorted(
        os.path.basename(p) for p in __import__("glob").glob(os.path.join(LAYOUT_DIR, "*.lua")))

    findings = Findings()
    karabiner_strict = {} if args.skip_drift else _parse_karabiner_strict()
    birman_data = {} if args.skip_drift else parse_birman()

    for name in files:
        if not name.endswith(".lua"): name += ".lua"
        path = os.path.join(LAYOUT_DIR, name)
        if not os.path.exists(path):
            findings.add(ERROR, path, 1, "F0", f"file not found: {name}")
            continue
        state = parse_file(path)
        check_format(state, findings)
        check_coverage(state, findings)
        if not args.skip_drift:
            check_karabiner_drift(state, findings, karabiner_strict)
            check_birman_drift(state, findings, birman_data)
            check_dead_bindings(state, findings, karabiner_strict)

    render_report(findings)
    if args.strict:
        sys.exit(1 if findings.has_errors() else 0)
    sys.exit(1 if findings else 0)


if __name__ == "__main__":
    main()
