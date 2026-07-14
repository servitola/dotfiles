#!/usr/bin/env python3
"""Pre-commit gate: keep every source file small.

Small files force single-purpose modules that connect through explicit imports.
Runs as a pre-commit hook (paths as argv) or standalone over a tree (``--walk .``).
Smarter than a flat ``wc -l``: code files cap at --limit (default 100), tests at
--test-limit (default 300), generated/vendored files are skipped, and a per-file
``project-init: allow-long`` marker in the first lines grants an exemption. Blank
lines and ``#``/``//`` comment lines are not counted — the cap targets logic.

Hardening an existing repo? Use the ratchet: ``--write-baseline FILE`` records every
current violation, then ``--baseline FILE`` lets those files stay put but blocks them
from growing while brand-new files get the full cap. Shrink the baseline over time.
"""

from __future__ import annotations

import argparse
import fnmatch
import os
import sys
from pathlib import Path

HEAD_LINES = 3
LINE_COMMENTS = ("#", "//")
SKIP_DIRS = {".git", "node_modules", ".venv", "dist", "build"}

# Machine-produced or third-party files — never our maintainability concern.
SKIP_GLOBS = ["*.g.cs", "*.designer.cs", "*.generated.*", "*.pb.go", "*_pb2.py",
              "*.min.js", "*.min.css", "*.d.ts", "*.lock", "*.svg", "*.snap",
              "*/migrations/*", "*/vendor/*"]  # fmt: skip
TEST_GLOBS = ["test/*", "tests/*", "*/tests/*", "*/test/*", "*_test.py", "*_test.go",
              "test_*.py", "*.test.ts", "*.test.tsx", "*.test.js", "*.spec.ts",
              "*.spec.tsx", "*Test.kt", "*Tests.kt", "*Test.cs", "*Tests.cs",
              "*Tests.swift", "*Spec.swift"]  # fmt: skip


def matches(path: str, globs: list[str]) -> bool:
    return any(fnmatch.fnmatch(path, g) for g in globs)


def significant_lines(path: str) -> tuple[int, bool]:
    """Return (count of logic lines, whether an allow-long marker appears up top)."""
    count = 0
    allow = False
    try:
        with Path(path).open(encoding="utf-8", errors="ignore") as handle:
            for i, raw in enumerate(handle):
                if i < HEAD_LINES and "project-init: allow-long" in raw:
                    allow = True
                stripped = raw.strip()
                if stripped and not stripped.startswith(LINE_COMMENTS):
                    count += 1
    except OSError:
        return 0, False
    return count, allow


def walk(root: str) -> list[str]:
    out: list[str] = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        out.extend(str(Path(dirpath) / name) for name in filenames)
    return out


def cap_for(path: str, limit: int, test_limit: int) -> int:
    return test_limit if matches(path, TEST_GLOBS) else limit


def load_baseline(path: str | None) -> dict[str, int]:
    if not path or not Path(path).exists():
        return {}
    pairs = (ln.split("\t", 1) for ln in Path(path).read_text().splitlines() if "\t" in ln)
    return {name: int(count) for count, name in pairs}


def check(path: str, cap: int, baseline: dict[str, int]) -> tuple[str, int, int] | None:
    if matches(path, SKIP_GLOBS):
        return None
    count, allow = significant_lines(path)
    if count == 0 or allow:
        return None
    ceiling = max(cap, baseline.get(path, 0))  # baselined files may sit high but not grow
    return None if count <= ceiling else (path, count, cap)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description="File-length gate for source files.")
    parser.add_argument("--limit", type=int, default=100, help="max logic lines for code")
    parser.add_argument("--test-limit", type=int, default=300, help="max logic lines for tests")
    parser.add_argument("--walk", metavar="DIR", action="append", default=[],
                        help="scan a directory tree, not argv paths (repeatable)")  # fmt: skip
    parser.add_argument("--baseline", help="grandfather files in this baseline at their size")
    parser.add_argument("--write-baseline", metavar="FILE", help="record violations, then exit")
    parser.add_argument("paths", nargs="*", help="files to check (as passed by pre-commit)")
    args = parser.parse_args(argv)

    paths = [p for d in args.walk for p in walk(d)] if args.walk else args.paths
    if args.write_baseline:
        found = (check(p, cap_for(p, args.limit, args.test_limit), {}) for p in paths)
        rows = sorted((c, p) for p, c, _ in filter(None, found))
        Path(args.write_baseline).write_text("".join(f"{c}\t{p}\n" for c, p in rows))
        return 0

    baseline = load_baseline(args.baseline)
    checked = (check(p, cap_for(p, args.limit, args.test_limit), baseline) for p in paths)
    violations = [v for v in checked if v]
    for path, count, cap in violations:
        sys.stderr.write(
            f"{path}: {count} lines of logic > {cap} — split into smaller modules "
            f"(or add a `project-init: allow-long` marker if truly irreducible)\n"
        )
    return 1 if violations else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
