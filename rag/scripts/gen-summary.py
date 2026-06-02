#!/usr/bin/env python3
"""gen-summary — deterministic SUMMARY.md generator for "dark" dirs.

For directories that ingest into RAG but lack a narrative file, this tool
produces a compact `SUMMARY.md` that aggregates per-file metadata into a
single browsable index. The aggregate file then carries enough signal to
surface in vector + FTS retrieval where individual short files don't.

Modes (one per parsing strategy — explicit, no auto-detection):

  karabiner-rules   parse Karabiner JSON: description + first manipulator
  md-frontmatter    parse Markdown YAML frontmatter (name/description/...)
  hotkeys-layout    parse HotKeys.spoon Lua per-key files (chord = "..." {app|fn|sendKey})
  python-docstring  parse Python module + def docstrings

Usage:
  ./gen-summary.py karabiner-rules ~/projects/dotfiles/karabiner/rules
  ./gen-summary.py md-frontmatter  ~/projects/dotfiles/claude-code/agents
  ./gen-summary.py md-frontmatter  ~/projects/dotfiles/claude-code/commands
  ./gen-summary.py hotkeys-layout  ~/projects/dotfiles/hammerspoon/Spoons/HotKeys.spoon/layout/extra
  ./gen-summary.py python-docstring ~/projects/dotfiles/rag/scripts

Writes <dir>/SUMMARY.md. Idempotent — re-run after changes to refresh.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# Mode: karabiner-rules
# ---------------------------------------------------------------------------

def _summarize_manipulator(m: dict) -> str:
    """Compact one-line description of a Karabiner manipulator."""
    fr = m.get("from", {})
    src_key = fr.get("key_code") or fr.get("simultaneous", [{}])[0].get("key_code", "?")
    src_mods = ((fr.get("modifiers") or {}).get("mandatory") or [])
    src = f"{'+'.join(src_mods + [src_key])}" if src_mods else src_key

    to = m.get("to") or []
    if to and isinstance(to, list):
        first = to[0]
        dst_key = first.get("key_code") or first.get("shell_command") or first.get("set_variable", {}).get("name", "?")
        dst_mods = first.get("modifiers") or []
        dst = f"{'+'.join(dst_mods + [dst_key])}" if dst_mods else dst_key
    else:
        dst = "?"
    return f"`{src}` → `{dst}`"


def gen_karabiner_rules(directory: Path) -> str:
    files = sorted(p for p in directory.glob("*.json") if p.name != "SUMMARY.json")
    lines = [
        "# Karabiner rules — quick index",
        "",
        "Auto-generated from `*.json` files in this directory. Each rule defines",
        "a Karabiner-Elements layer or remap, listed below in load order.",
        "",
        "Symbols in the action column come straight from the rule's `from` and",
        "`to` clauses — modifiers prefixed (e.g. `right_command+a`), no symbolic",
        "rendering. For full docs see [docs/keyboard-setup.md](../../docs/keyboard-setup.md).",
        "",
        "| File | Description | First mapping |",
        "|---|---|---|",
    ]
    for path in files:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as exc:
            print(f"WARN: skip {path.name}: {exc}", file=sys.stderr)
            continue
        desc = (data.get("description") or "").strip().replace("\n", " ").replace("|", "\\|")
        manips = data.get("manipulators") or []
        first = _summarize_manipulator(manips[0]) if manips else "(no manipulators)"
        lines.append(f"| [{path.name}]({path.name}) | {desc} | {first} |")
    lines.append("")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Mode: md-frontmatter
# ---------------------------------------------------------------------------

FRONTMATTER_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)


def _parse_yaml_lite(block: str) -> dict[str, str]:
    """Tiny YAML parser supporting `key: value`, `key: |\\n  multiline`, comments.

    We don't bring PyYAML — these frontmatters are simple and stable.
    """
    out: dict[str, str] = {}
    lines = block.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            i += 1
            continue
        if ":" not in stripped:
            i += 1
            continue
        key, _, val = stripped.partition(":")
        key = key.strip()
        val = val.strip()
        if val == "|" or val == "|-" or val == ">":
            # Block scalar: collect indented lines until dedent.
            collected = []
            i += 1
            while i < len(lines):
                nxt = lines[i]
                if nxt and not nxt.startswith((" ", "\t")):
                    break
                collected.append(nxt.strip())
                i += 1
            out[key] = " ".join(c for c in collected if c)
        else:
            out[key] = val.strip().strip('"').strip("'")
            i += 1
    return out


def gen_md_frontmatter(directory: Path) -> str:
    files = sorted(p for p in directory.glob("*.md") if p.name not in {"SUMMARY.md", "README.md", "CLAUDE.md", "AGENTS.md"})
    rows: list[tuple[str, str, str, str]] = []  # (name, desc, color/extra, file)
    for path in files:
        text = path.read_text(encoding="utf-8")
        m = FRONTMATTER_RE.match(text)
        if not m:
            rows.append((path.stem, "(no frontmatter)", "", path.name))
            continue
        meta = _parse_yaml_lite(m.group(1))
        name = meta.get("name") or path.stem
        desc = meta.get("description") or "(no description)"
        # Trim long descriptions
        if len(desc) > 200:
            desc = desc[:197] + "…"
        desc = desc.replace("|", "\\|").replace("\n", " ")
        # Auxiliary column: model/color/argument-hint, whichever is present.
        extras = []
        for key in ("model", "color", "argument-hint", "tools"):
            if key in meta and meta[key]:
                extras.append(f"`{key}={meta[key]}`")
        rows.append((name, desc, " ".join(extras), path.name))

    title = directory.name
    lines = [
        f"# {title} — overview",
        "",
        f"Auto-generated index of `*.md` files in this directory. Each entry is",
        f"an agent / command / skill / template definition with YAML frontmatter.",
        "",
        "| Name | Description | Meta | File |",
        "|---|---|---|---|",
    ]
    for name, desc, extras, fname in rows:
        lines.append(f"| **{name}** | {desc} | {extras} | [{fname}]({fname}) |")
    lines.append("")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Mode: hotkeys-layout (re-uses logic from layout/60% generator)
# ---------------------------------------------------------------------------

CHORD_RE = re.compile(
    r'\{\s*chord\s*=\s*"([^"]+)"\s*,\s*'
    r'(?:'
    r'app\s*=\s*"([^"]+)"|'
    r'fn\s*=\s*"([^"]+)"|'
    r'sendKey\s*=\s*"([^"]+)"'
    r')'
    r'(?:[^}]*window_default_position\s*=\s*"([^"]+)")?'
    r'[^}]*\}',
    re.DOTALL,
)

MOD_PRETTY = {"⇪": "Hyper", "⌘": "Cmd", "⌥": "Alt", "⌃": "Ctrl", "⇧": "Shift"}
KEY_PRETTY = {
    "apostrophe": "'", "backslash": "\\", "bracketleft": "[",
    "bracketright": "]", "comma": ",", "equal": "=",
    "minus": "-", "period": ".", "semicolon": ";", "slash": "/",
}


def _parse_chord(chord: str) -> tuple[list[str], str]:
    mods = [name for sym, name in MOD_PRETTY.items() if sym in chord]
    rest = chord
    for sym in MOD_PRETTY:
        rest = rest.replace(sym, "")
    return mods, rest


def gen_hotkeys_layout(directory: Path) -> str:
    files = sorted(directory.glob("*.lua"), key=lambda p: (
        0 if p.stem.isdigit() else (1 if len(p.stem) == 1 else 2),
        p.stem,
    ))
    rows: list[tuple[str, str, str, str]] = []
    for path in files:
        text = path.read_text(encoding="utf-8")
        n = path.stem
        label = KEY_PRETTY.get(n, n).upper() if len(n) == 1 else KEY_PRETTY.get(n, n)
        for m in CHORD_RE.finditer(text):
            chord, app, fn, sk, pos = m.groups()
            mods, rest = _parse_chord(chord)
            chord_pretty = "+".join(mods + [rest.upper() if len(rest) == 1 else rest]).strip("+")
            if app:
                target = f"app **{app}**"
            elif fn:
                target = f"fn `{fn}`"
            elif sk:
                target = f"send `{sk!r}`"
            else:
                target = "?"
            if pos:
                target += f" (window: {pos})"
            rows.append((label, chord_pretty, target, path.name))

    title = directory.name
    lines = [
        f"# {title} — chord overview",
        "",
        "Auto-generated from `*.lua` files in this directory. Each file holds",
        "chord definitions for one physical key; this file aggregates them so a",
        "search for a specific binding finds the action without diving into",
        "individual files.",
        "",
        "Symbols: `⇪` Hyper · `⌘` Cmd · `⌥` Alt · `⌃` Ctrl · `⇧` Shift.",
        "",
        "| Key | Chord | Action | Source |",
        "|---|---|---|---|",
    ]
    if rows:
        for key, chord, target, src in rows:
            lines.append(f"| `{key}` | `{chord}` | {target} | [{src}]({src}) |")
    else:
        lines.append("| (no active chord definitions in this directory) | | | |")
    lines.append("")
    lines.append("## Per-key files")
    lines.append("")
    for path in files:
        n = path.stem
        label = KEY_PRETTY.get(n, n).upper() if len(n) == 1 else KEY_PRETTY.get(n, n)
        n_chords = sum(1 for _ in CHORD_RE.finditer(path.read_text(encoding="utf-8")))
        suffix = f" — {n_chords} chord{'s' if n_chords != 1 else ''}" if n_chords else " — _(no active chords)_"
        lines.append(f"- **`{label}`** — [{path.name}]({path.name}){suffix}")
    lines.append("")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# Mode: python-docstring
# ---------------------------------------------------------------------------

PY_DOCSTRING_RE = re.compile(r'^\s*(?:"""|\'\'\')\s*([^\n]+)', re.MULTILINE)


def _module_docstring(text: str) -> str:
    """Return the first triple-quoted string in the module (single line summary)."""
    # Skip shebang and any blank/comment lines.
    lines = text.splitlines()
    i = 0
    while i < len(lines) and (
        lines[i].startswith("#") or
        lines[i].startswith("from __future__") or
        not lines[i].strip()
    ):
        i += 1
    rest = "\n".join(lines[i:])
    rest = rest.lstrip()
    if rest.startswith('"""') or rest.startswith("'''"):
        delim = rest[:3]
        end = rest.find(delim, 3)
        if end != -1:
            doc = rest[3:end].strip()
            # First line only.
            first = doc.split("\n", 1)[0].strip()
            return first
    return "(no module docstring)"


PY_DEF_RE = re.compile(r"^def\s+([a-zA-Z_][\w]*)\s*\(", re.MULTILINE)


def gen_python_docstring(directory: Path) -> str:
    files = sorted(p for p in directory.glob("*.py") if not p.name.startswith("_"))
    lines = [
        f"# {directory.name} — Python scripts overview",
        "",
        "Auto-generated. Each file's module docstring (first line) and top-level",
        "functions are listed below for quick orientation.",
        "",
        "| Script | Purpose | Top-level functions |",
        "|---|---|---|",
    ]
    for path in files:
        text = path.read_text(encoding="utf-8")
        doc = _module_docstring(text).replace("|", "\\|")
        defs = PY_DEF_RE.findall(text)
        # Filter helpers
        defs_public = [d for d in defs if not d.startswith("_")][:8]
        defs_str = ", ".join(f"`{d}()`" for d in defs_public) if defs_public else "_(no public)_"
        lines.append(f"| [{path.name}]({path.name}) | {doc} | {defs_str} |")
    lines.append("")
    return "\n".join(lines) + "\n"


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

MODES = {
    "karabiner-rules": gen_karabiner_rules,
    "md-frontmatter": gen_md_frontmatter,
    "hotkeys-layout": gen_hotkeys_layout,
    "python-docstring": gen_python_docstring,
}


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    p.add_argument("mode", choices=list(MODES.keys()))
    p.add_argument("directory", type=Path)
    p.add_argument("-o", "--output", type=Path, default=None,
                   help="Override output file (default: <directory>/SUMMARY.md).")
    args = p.parse_args()

    if not args.directory.is_dir():
        print(f"error: {args.directory} is not a directory", file=sys.stderr)
        return 2

    md = MODES[args.mode](args.directory.resolve())
    out = args.output or (args.directory / "SUMMARY.md")
    out.write_text(md, encoding="utf-8")
    print(f"wrote {out} ({out.stat().st_size} bytes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
