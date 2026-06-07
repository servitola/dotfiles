#!/usr/bin/env python3
"""gen-dir-summary.py — generate a short role-level AGENTS.md for a directory.

The goal is a *durable* per-directory summary that boosts RAG retrieval and
orients agents, without polluting the tree with volatile detail. It describes
**purpose, key files & their roles, entry points, and relationships** — not
enumerable mutable content (no "contains 510 packages: …"). Short summaries of
invariants stay accurate across edits.

Staleness: a `struct_hash` of the directory's file/subdir *names* is embedded as
an HTML comment. Adding/removing/renaming a file changes the hash → the summary
is stale and gets regenerated with --stale-only. Editing a file's *contents*
does not (a role-level summary usually still holds).

Generation goes through the `claude` CLI (subscription auth) with the strongest
model — quality matters here, a wrong summary is worse than none.

Usage:
  gen-dir-summary.py homebrew litellm hammerspoon   # write if missing
  gen-dir-summary.py --preview homebrew             # print, don't write
  gen-dir-summary.py --stale-only <dirs...>         # regen only if struct changed
  gen-dir-summary.py --force <dirs...>              # always regenerate
  gen-dir-summary.py --model claude-opus-4-8 --budget 1.0 <dirs...>

Skips a directory that already has AGENTS.md unless --force/--stale-only.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

MARKER = "<!-- gen-dir-summary struct_hash:"  # frontmatter marker (HTML comment)
SKIP_NAMES = {".git", ".DS_Store", "node_modules", "__pycache__", ".venv"}
# Files we read a head of, in priority order, to give the model real context.
PREFERRED = ("README.md", "AGENTS.md", "CLAUDE.md", "Makefile", "install.sh",
             "config.yaml", "config.toml", "docker-compose.yml")
HEAD_CHARS = 500
MAX_HEAD_FILES = 8


def struct_hash(d: Path) -> str:
    """Hash of immediate file + subdir names (not contents) — structural signature."""
    names = sorted(p.name + ("/" if p.is_dir() else "")
                   for p in d.iterdir() if p.name not in SKIP_NAMES)
    return hashlib.sha1("\n".join(names).encode()).hexdigest()[:12]


def read_hash_from(agents: Path) -> str | None:
    if not agents.exists():
        return None
    m = re.search(re.escape(MARKER) + r"\s*([0-9a-f]{12})", agents.read_text(encoding="utf-8"))
    return m.group(1) if m else None


def build_context(d: Path) -> str:
    """Compact context: file/subdir listing + heads of a few key files."""
    entries = sorted(d.iterdir(), key=lambda p: (p.is_dir(), p.name))
    listing = []
    for p in entries:
        if p.name in SKIP_NAMES:
            continue
        listing.append(f"{p.name}/" if p.is_dir() else f"{p.name} ({p.stat().st_size}b)")
    # Heads of preferred files, then any other small text files until the cap.
    heads, used = [], 0
    ordered = [d / n for n in PREFERRED if (d / n).is_file()]
    ordered += [p for p in entries if p.is_file() and p not in ordered
                and p.suffix in (".sh", ".py", ".md", ".toml", ".yaml", ".yml", ".json", ".lua")]
    for p in ordered:
        if used >= MAX_HEAD_FILES:
            break
        try:
            txt = p.read_text(encoding="utf-8", errors="replace")[:HEAD_CHARS]
        except Exception:
            continue
        heads.append(f"--- {p.name} (head) ---\n{txt}")
        used += 1
    return f"Directory: {d}\n\nEntries:\n" + "\n".join(listing) + "\n\n" + "\n\n".join(heads)


PROMPT = """You are documenting one directory of a personal macOS dotfiles repo
so an AI retrieval system and coding agents can orient quickly.

Write a SHORT `AGENTS.md` (8-15 lines of markdown) for the directory below.
Rules:
- Describe DURABLE facts: the directory's purpose, what each key file/subdir is
  FOR (its role), the entry points, and how it relates to other parts of the
  repo. These should stay true across ordinary edits.
- Do NOT enumerate volatile content (no listing every package/setting/line).
- No preamble, no closing remarks. Start with `# <dirname> — <one-line purpose>`.
- Be concrete and specific to THIS directory; never generic boilerplate.
- Plain markdown, no code fences unless quoting one short command.

{context}"""


def generate(d: Path, model: str, budget: float) -> str | None:
    cmd = [
        "claude", "-p", "--model", model, "--output-format", "json",
        "--tools", "", "--no-session-persistence",
        "--max-budget-usd", f"{budget:.2f}",
        "--system-prompt",
        "You write terse, accurate technical documentation. Output only the requested markdown.",
    ]
    try:
        proc = subprocess.run(cmd, input=PROMPT.format(context=build_context(d)),
                              text=True, capture_output=True, timeout=180, cwd="/tmp")
    except subprocess.TimeoutExpired:
        return None
    if proc.returncode != 0 and not proc.stdout.strip():
        sys.stderr.write(proc.stderr[:300])
        return None
    try:
        data = json.loads(proc.stdout.strip().splitlines()[-1])
        text = data.get("result") or data.get("text") or ""
    except (json.JSONDecodeError, IndexError):
        text = proc.stdout.strip()
    text = text.strip()
    # Strip stray fences if the model wrapped the whole thing.
    text = re.sub(r"^```(?:markdown)?\s*\n?|\n?```\s*$", "", text).strip()
    return text or None


def write_agents(d: Path, body: str) -> None:
    h = struct_hash(d)
    content = f"{MARKER} {h} -->\n\n{body.rstrip()}\n"
    (d / "AGENTS.md").write_text(content, encoding="utf-8")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("dirs", nargs="+")
    ap.add_argument("--model", default="claude-opus-4-8")
    ap.add_argument("--budget", type=float, default=0.50, help="max USD per directory")
    ap.add_argument("--preview", action="store_true", help="print, don't write")
    ap.add_argument("--force", action="store_true", help="regenerate even if AGENTS.md exists")
    ap.add_argument("--stale-only", action="store_true",
                    help="regenerate only if the directory structure changed since last gen")
    args = ap.parse_args()

    for raw in args.dirs:
        d = Path(raw).expanduser().resolve()
        if not d.is_dir():
            print(f"skip (not a dir): {raw}", file=sys.stderr)
            continue
        agents = d / "AGENTS.md"

        if agents.exists() and not (args.force or args.preview):
            if args.stale_only:
                if read_hash_from(agents) == struct_hash(d):
                    print(f"fresh, skip: {raw}")
                    continue
                print(f"stale (structure changed), regenerating: {raw}")
            else:
                print(f"exists, skip: {raw}  (use --force / --stale-only / --preview)")
                continue

        print(f"generating ({args.model}): {raw} …", file=sys.stderr)
        body = generate(d, args.model, args.budget)
        if not body:
            print(f"FAILED to generate: {raw}", file=sys.stderr)
            continue
        if args.preview:
            print(f"\n===== {raw}/AGENTS.md (preview) =====\n{body}\n")
        else:
            write_agents(d, body)
            print(f"wrote {raw}/AGENTS.md (struct_hash {struct_hash(d)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
