#!/usr/bin/env python3
"""Normalize Hammerspoon keyboard layout *.lua files to canonical ASCII format.

Modes:
  --fix-format       (default) only adjust column geometry to [17, 32, 47, 51]
  --insert-missing   additionally insert ASCII rows for active chords lacking docs
  --project          additionally write the machine's shortcuts (macos_shortcuts/shortcuts.toml)
                     into the tables as ⚙ / ◆ lines, replacing the ones written before
                     (docs/keyboard/projection.py); hand-written lines are never touched

Canonical row geometry:
    --          ⇪a   │      ←       │ A    Ф    Α  │ ✓ │       Rider — …
    ^^               ^               ^               ^   ^
    0    chord:17    │  kar:14       │  bir:14       │ G3│ desc verbatim
                     17              32              47  51

Idempotent: running twice produces no diff.

Usage:
  python3 normalize.py                       # all files, fix format only
  python3 normalize.py --insert-missing      # also insert missing ASCII rows
  python3 normalize.py --project             # also refresh the ⚙ / ◆ lines from shortcuts.toml
  python3 normalize.py --files a.lua b.lua   # specific files
  python3 normalize.py --check               # exit 1 if any file would change
"""
import argparse
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(HERE))

from labels import get_label, FN_LABELS
from config import FKEY_MAPPING, MOD_DISPLAY, KEY_DISPLAY
from app_constants import resolve
import projection

LAYOUT_DIR = os.path.normpath(os.path.join(
    HERE, "..", "..", "..", "hammerspoon", "Spoons", "HotKeys.spoon", "layout", "60%"))

# Canonical column positions for │ / ┬ / ┼ / ┴
COL = [17, 32, 47, 51]
# Cell widths (between separators): [chord, kar, bir, g, desc]
W_CHORD, W_KAR, W_BIR, W_G = 15, 14, 14, 3  # chord cell = 17 incl. "--"

# Stub files: pure modifier-key docs, skip normalization
STUB_FILES = {"shift.lua", "command.lua", "control.lua", "option.lua",
              "capslock.lua", "backslash.lua", "backspace.lua"}

# ─── line classification ────────────────────────────────────────────────────
SEP_DASH_BEFORE_CHORD = "—" * 8        # "--" + 8 dashes + " chord "
SEP_TAIL = "—" * 36                     # tail after "app — function "
SEP_ROW_TAIL = "—" * 46                 # tail of `┼` rows after last ┼
HEADER_LINE = (
    "--" + SEP_DASH_BEFORE_CHORD + " chord " + "┬"
    + "  karabiner   " + "┬"
    + " en | ru | el " + "┬"
    + " G " + "┬"
    + "—" * 11 + " app — function " + SEP_TAIL
)
FOOTER_LINE = (
    "--" + " " * (W_CHORD) + "┴"
    + " " * W_KAR + "┴"
    + " " * W_BIR + "┴"
    + " " * W_G + "┴"
)

# Regex for line types
HEADER_RE = re.compile(r"^--[—\- ]*chord\s+┬")
SEP_ROW_RE = re.compile(r"^--[\s—\-]*┼")
FOOTER_RE = re.compile(r"^--[\s—\-]*┴.*┴.*┴.*┴\s*$")

ACTIVE_RE = re.compile(
    r'^(\s*)\{\s*chord\s*=\s*"([^"]+)"\s*,\s*(app|fn)\s*=\s*"([^"]+)"'
)
CHORD_ROW_TOKEN_RE = re.compile(
    # `\s*` (not `\s+`): max-width 12-char chords leave no padding after `--`
    r"^--\s*([⇪⇧⌃⌥⌘⇥]*[a-zA-Z0-9~\-=\[\]\;\',./` ⎋↩␣←→↑↓]+(?:\s*→\s*\S+)?)\s+│"
)
F_CHORD_RE = re.compile(r"^[⇧⌃⌥⌘]*(F\d+|num\d+)$")

# ─── canonical modifier order ───────────────────────────────────────────────
_MOD_ORDER = {c: i for i, c in enumerate("⇪⇧⌃⌥⌘")}
_MOD_RUN = re.compile(r"[⇪⇧⌃⌥⌘]+")


def reorder_chord_mods(text):
    """Sort every run of modifier symbols into canonical ⇪⇧⌃⌥⌘ order.

    Applies to both halves of arrow-suffix annotations (`⌃⌥⌘⇧← → ⇧⌃F13` →
    `⇧⌃⌥⌘← → ⇧⌃F13`) and to any karabiner-column outputs (e.g. `⌘⇧←` → `⇧⌘←`).
    Idempotent.
    """
    if not text: return text
    return _MOD_RUN.sub(
        lambda m: "".join(sorted(m.group(0), key=lambda c: _MOD_ORDER[c])),
        text
    )


# ─── canonical row builder ──────────────────────────────────────────────────
def _center(text, width):
    """Pad text to width, centered. Left-bias for odd remainders (matches existing files)."""
    text = text or ""
    pad = width - len(text)
    if pad <= 0:
        return text
    left = pad // 2
    return " " * left + text + " " * (pad - left)


def build_chord_row(chord, karabiner="", birman="", g="", desc=""):
    """Build a canonical ASCII chord row.

    Chord cell is 17 chars wide ("--" + 15). For chords ≤ 12 chars, right-align
    with 3 trailing spaces. Longer chords (e.g. arrow-suffix annotations like
    `⌃⌥⌘⇧← → ⇧⌃F13` = 13 chars) shrink trailing spaces to fit, keeping ≥ 1.
    """
    chord_text = chord.strip()
    if len(chord_text) <= 12:
        chord_cell = "--" + chord_text.rjust(12) + "   "
    else:
        trailing = max(1, 15 - len(chord_text))
        chord_cell = "--" + chord_text + " " * trailing
    kar_cell = _center(karabiner.strip(), W_KAR)
    bir_cell = _center(birman.strip(), W_BIR)
    g_cell = _center(g.strip(), W_G)
    desc_tail = desc.rstrip()
    if desc_tail and not desc_tail.startswith(" "):
        desc_tail = " " + desc_tail
    return f"{chord_cell}│{kar_cell}│{bir_cell}│{g_cell}│{desc_tail}".rstrip() + "\n"


def build_continuation_row(g="", desc=""):
    chord_cell = "--" + " " * W_CHORD
    desc_tail = desc.rstrip()
    if desc_tail and not desc_tail.startswith(" "):
        desc_tail = " " + desc_tail
    return f"{chord_cell}│{_center('', W_KAR)}│{_center('', W_BIR)}│{_center(g, W_G)}│{desc_tail}".rstrip() + "\n"


def build_sep_row():
    return ("--" + "—" * W_CHORD + "┼"
            + "—" * W_KAR + "┼"
            + "—" * W_BIR + "┼"
            + "—" * W_G + "┼"
            + SEP_ROW_TAIL + "\n")


def build_header():   return HEADER_LINE + "\n"
def build_footer():   return FOOTER_LINE + "\n"


# ─── parsing & normalization ────────────────────────────────────────────────
def _split_row(line):
    """Split a chord row on │. Return (cells, ok) where ok = exactly 4 separators."""
    cells = line.rstrip("\n").split("│")
    return cells, len(cells) == 5


def normalize_line(line):
    """Return canonical form of a single line.

    Lines we transform:
      • header → canonical HEADER_LINE
      • ┼-separator → canonical sep row
      • ┴-footer → canonical footer
      • chord row (4 │) → canonical chord row (cells centered/padded)
      • continuation row (no chord, has │) → re-pad to canonical column widths
    Other lines (active {}, blank, return-table, custom comments) pass through.
    """
    stripped = line.rstrip("\n")
    # Header
    if HEADER_RE.match(stripped):
        return build_header()
    # Sub-separator ┼
    if SEP_ROW_RE.match(stripped):
        return build_sep_row()
    # Footer ┴
    if FOOTER_RE.match(stripped):
        return build_footer()
    # Chord row or continuation: must start with "--" and contain 4 │
    cells, ok = _split_row(stripped)
    if ok and stripped.startswith("--"):
        # cells[0] always starts with "--…" before first │
        # Extract chord text from cells[0] (may be blank for continuation rows)
        chord_text = reorder_chord_mods(cells[0][2:].strip())
        karabiner = reorder_chord_mods(cells[1].strip())
        birman = cells[2].strip()
        g = cells[3].strip()
        # cells[4] = trailing desc; preserve leading space prefix loosely
        desc = cells[4]
        if chord_text:
            return build_chord_row(chord_text, karabiner, birman, g, desc)
        # Continuation row (no chord, empty cells 0-3, only desc)
        chord_cell = "--" + " " * W_CHORD  # 2 + 15 = 17 chars total
        kar_cell = _center(karabiner, W_KAR)
        bir_cell = _center(birman, W_BIR)
        g_cell = _center(g, W_G)
        desc_tail = desc.rstrip()
        if desc_tail and not desc_tail.startswith(" "):
            desc_tail = " " + desc_tail
        return f"{chord_cell}│{kar_cell}│{bir_cell}│{g_cell}│{desc_tail}".rstrip() + "\n"
    return line


def _default_desc_for_active(target, kind):
    """Generate description text for an inserted ASCII row from active binding."""
    if kind == "app":
        return resolve(target) or target
    return FN_LABELS.get(target, target)


def _source_chord_for_fkey(fkey):
    """Build canonical chord text (e.g., `⇧⌃⌥⌘↓`) from FKEY_MAPPING entry.

    Returns (chord_text, source_key) or (None, None) if F-key is unknown.
    """
    if fkey not in FKEY_MAPPING:
        return None, None
    src_key, src_mods = FKEY_MAPPING[fkey]
    order = ("hyper", "shift", "ctrl", "alt", "cmd")
    mods_str = "".join(MOD_DISPLAY[m] for m in order if m in src_mods)
    key_str = KEY_DISPLAY.get(src_key, src_key)
    return mods_str + key_str, src_key


_ARROW_SUFFIX_RE = re.compile(r"→\s*([⇧⌃⌥⌘]*(?:F\d+|num\d+))")


def insert_missing_rows(lines, ascii_chords, ascii_f_keys, actives):
    """Insert ASCII rows immediately before active lines whose chord lacks docs.

    Two cases:
      • F-key/num active (e.g. `chord="num1"`): look up source chord via
        `FKEY_MAPPING`, insert row `source_chord │ F-key │ … │ … │ ↓`.
        Skipped if F-key already appears in some ASCII row's karabiner column
        or as `→ F-key` arrow-suffix on the chord cell.
      • Regular chord: insert row `chord │ … │ … │ … │ label`.

    Returns (new_lines, inserted_count).
    """
    inserts = []  # (line_idx_0based, ascii_row_str)
    for a in actives:
        chord = a["chord"]
        if F_CHORD_RE.match(chord):
            if chord in ascii_f_keys:
                continue  # already documented (karabiner column or arrow suffix)
            src_chord, _ = _source_chord_for_fkey(chord)
            if not src_chord:
                continue  # unknown F-key — leave as a linter warning
            row = build_chord_row(src_chord, karabiner=chord, desc="↓")
            inserts.append((a["line"] - 1, row))
            continue
        compact = chord.replace(" ", "")
        if chord in ascii_chords or any(c.replace(" ", "") == compact for c in ascii_chords):
            continue
        desc = _default_desc_for_active(a["target"], a["kind"])
        row = build_chord_row(chord, desc=desc)
        inserts.append((a["line"] - 1, row))
    if not inserts:
        return lines, 0
    inserts.sort(key=lambda x: -x[0])
    new_lines = list(lines)
    for idx, row in inserts:
        new_lines.insert(idx, row)
    return new_lines, len(inserts)


# ─── projection of the machine's shortcuts ──────────────────────────────────
_CHORD_TEXT_RE = re.compile(r"^--([^│]*)│([^│]*)│([^│]*)│([^│]*)│")


def _chord_of(line):
    """Chord text of a table row, "" for a continuation row, None for any other line."""
    m = _CHORD_TEXT_RE.match(line.rstrip("\n"))
    if not m:
        return None
    return re.sub(r"\s*→.*$", "", m.group(1)).strip()


def _sort_key(chord):
    m = re.match(r"^([⇪⇧⌃⌥⌘]*)", chord)
    mods = m.group(1)
    return (len(mods), [_MOD_ORDER[c] for c in mods])


def _without_projected(lines):
    """Drop every ⚙ / ◆ line; a hand-written continuation left under a dropped chord row
    becomes that chord's row, so nothing hand-written is lost."""
    out, orphan_chord = [], None
    for line in lines:
        chord = _chord_of(line)
        if chord is None:
            out.append(line)
            orphan_chord = None
            continue
        m = _CHORD_TEXT_RE.match(line)
        g = m.group(4).strip()
        if g in projection.MARKER_CHARS:
            if chord:
                orphan_chord = chord
            continue
        if chord == "" and orphan_chord:
            line = build_chord_row(orphan_chord, desc=line.split("│", 4)[4])
        orphan_chord = None
        out.append(line)
    return out


def _insert_at(lines, chord, rows):
    """Place a new chord row (plus its continuation rows) in modifier order: before the
    first row of the same group that sorts after it, else before the next group's
    separator, else before the footer."""
    key = _sort_key(chord)
    for i, line in enumerate(lines):
        c = _chord_of(line)
        if not c:
            continue
        other = _sort_key(c)
        if other <= key:
            continue
        if other[0] == key[0]:
            return lines[:i] + rows + lines[i:]
        j = i
        while j > 0 and SEP_ROW_RE.match(lines[j - 1].rstrip("\n")):
            j -= 1
        return lines[:j] + rows + lines[j:]
    for i, line in enumerate(lines):
        if FOOTER_RE.match(line.rstrip("\n")):
            return lines[:i] + rows + lines[i:]
    return lines + rows


def project_lines(lines, expected):
    """Rewrite the ⚙ / ◆ lines of one file from `expected` ({chord: [(marker, desc)]})."""
    lines = _without_projected(lines)
    for chord, descs in sorted(expected.items(), key=lambda kv: _sort_key(kv[0])):
        cont = [build_continuation_row(g, d) for g, d in descs]
        idx = next((i for i, l in enumerate(lines) if _chord_of(l) == chord), None)
        if idx is None:
            g, d = descs[0]
            lines = _insert_at(lines, chord, [build_chord_row(chord, g=g, desc=d), *cont[1:]])
            continue
        end = idx + 1
        while end < len(lines) and _chord_of(lines[end]) == "":
            end += 1
        lines = lines[:end] + cont + lines[end:]
    return lines


# ─── per-file pipeline ──────────────────────────────────────────────────────
def normalize_file(path, insert_missing=False, project=None):
    """Return (new_content, changed, inserted_count). `project` is the expected
    projection for this file ({chord: [(marker, desc)]}, {} to clear it), or None."""
    with open(path, encoding="utf-8") as f:
        original = f.read()
    name = os.path.basename(path)
    if name in STUB_FILES:
        return original, False, 0

    lines = original.splitlines(keepends=True)
    # Pass 1: per-line format normalization
    new_lines = [normalize_line(l) for l in lines]
    inserted = 0
    if insert_missing:
        # Re-scan for ASCII chords + F-key/num documentation + actives
        ascii_chords = set()
        ascii_f_keys = set()
        for l in new_lines:
            m = CHORD_ROW_TOKEN_RE.match(l)
            if not m: continue
            chord_token = m.group(1).strip()
            ascii_chords.add(re.sub(r"\s+→\s+.*$", "", chord_token).strip())
            # F-key referenced via `→ F-key` arrow suffix on chord cell
            arrow_m = _ARROW_SUFFIX_RE.search(chord_token)
            if arrow_m:
                ascii_f_keys.add(arrow_m.group(1))
            # F-key referenced in karabiner column (between │…│)
            cells = l.rstrip("\n").split("│")
            if len(cells) >= 2:
                kar = cells[1].strip()
                if F_CHORD_RE.match(kar):
                    ascii_f_keys.add(kar)
        actives = []
        for i, l in enumerate(new_lines):
            m = ACTIVE_RE.match(l)
            if m:
                actives.append({"line": i + 1, "chord": m.group(2),
                                "kind": m.group(3), "target": m.group(4)})
        new_lines, inserted = insert_missing_rows(
            new_lines, ascii_chords, ascii_f_keys, actives)
    if project is not None:
        new_lines = project_lines(new_lines, project)

    new_content = "".join(new_lines)
    return new_content, (new_content != original), inserted


# ─── main ──────────────────────────────────────────────────────────────────
def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                  formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--files", nargs="*", help="specific *.lua basenames (default: all)")
    ap.add_argument("--insert-missing", action="store_true",
                    help="insert ASCII rows for active chords lacking docs")
    ap.add_argument("--project", action="store_true",
                    help="refresh the ⚙ / ◆ lines from macos_shortcuts/shortcuts.toml")
    ap.add_argument("--check", action="store_true",
                    help="don't write; exit 1 if any file would change (CI mode)")
    args = ap.parse_args()
    expected = projection.expected() if args.project else None

    import glob
    files = args.files or sorted(
        os.path.basename(p) for p in glob.glob(os.path.join(LAYOUT_DIR, "*.lua")))

    changed_files = []
    total_inserted = 0
    for name in files:
        if not name.endswith(".lua"): name += ".lua"
        path = os.path.join(LAYOUT_DIR, name)
        if not os.path.exists(path):
            print(f"  skip (not found): {name}", file=sys.stderr)
            continue
        project = None if expected is None else expected.get(name.removesuffix(".lua"), {})
        new_content, changed, inserted = normalize_file(path, args.insert_missing, project)
        if changed:
            changed_files.append((name, inserted))
            if not args.check:
                with open(path, "w", encoding="utf-8") as f:
                    f.write(new_content)
            total_inserted += inserted

    if args.check:
        if changed_files:
            print(f"would change {len(changed_files)} files:")
            for n, ins in changed_files:
                tag = f" (+{ins} rows)" if ins else ""
                print(f"  {n}{tag}")
            sys.exit(1)
        print("all files canonical")
        sys.exit(0)

    if changed_files:
        for n, ins in changed_files:
            tag = f" +{ins} rows" if ins else ""
            print(f"  {n}{tag}")
        print(f"\nnormalized {len(changed_files)} files"
              + (f", inserted {total_inserted} ASCII rows" if total_inserted else ""))
    else:
        print("all files already canonical")
    if args.project:
        for row, why in projection.skipped():
            print(f"  not projected: {row.keys} ({why})", file=sys.stderr)


if __name__ == "__main__":
    main()
