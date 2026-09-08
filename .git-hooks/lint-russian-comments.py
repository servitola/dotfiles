#!/usr/bin/env python3
"""Fail the commit when a comment is written in Russian.

Prose only. Cyrillic that is data has to survive: the `ru` column of the keyboard
layout tables, paths under ~/projects/serho_topics/, Telegram message texts,
dictation dictionaries, test fixtures. So a line counts as a violation only when
the Cyrillic sits inside something this script is confident is a comment.
"""
import re
import sys

CYRILLIC = re.compile(r"[А-Яа-яЁё]")
# Prose, not a stray letter: a range label like `А-Я → а-я` is not Russian writing.
CYRILLIC_WORD = re.compile(r"[А-Яа-яЁё]{3,}")
# A comment is allowed to quote Russian data — a voice phrase, a window title, a path.
QUOTED = re.compile(r"«[^»]*»|\"[^\"]*\"|'[^']*'|`[^`]*`")
# A quote that runs onto the next line leaves an opener behind: everything after it
# is data too, otherwise a wrapped list of Russian book titles reads as prose.
DANGLING_QUOTE = re.compile(r"[«\"'`].*$")
CLOSERS = {"«": "»", '"': '"', "'": "'", "`": "`"}
# Paths are data wherever they appear: ~/projects/serho_topics/греческий-язык/
PATH_TOKEN = re.compile(r"\S*/\S*")

# Suffix -> comment markers. A file type absent here is never checked: no marker,
# no way to tell a comment from a string.
MARKERS = {
    ".lua": ("--",),
    ".sh": ("#",), ".zsh": ("#",), ".bash": ("#",),
    ".py": ("#",),
    ".js": ("//",), ".ts": ("//",), ".mjs": ("//",),
    ".c": ("//",), ".h": ("//",), ".swift": ("//",),
    ".applescript": ("--",),
    ".toml": ("#",), ".yaml": ("#",), ".yml": ("#",),
    ".conf": ("#",), ".cfg": ("#",),
}


def comment_start(line, markers):
    """Index where a comment begins, or None.

    A marker at the start of the line is always a comment. A trailing one counts
    only when the quotes before it are balanced — otherwise `echo "тест # раз"`
    would read as a comment and every printed Russian string would fail the hook.
    """
    stripped = line.lstrip()
    for mark in markers:
        if stripped.startswith(mark):
            return len(line) - len(stripped)
    for mark in markers:
        idx = line.find(mark)
        if idx <= 0:
            continue
        head = line[:idx]
        if head.count('"') % 2 == 0 and head.count("'") % 2 == 0:
            return idx
    return None


def is_layout_table_row(line):
    """Keyboard layout tables carry Cyrillic in their third column by design."""
    if "│" not in line:
        return False
    columns = line.split("│")
    if len(columns) < 4:
        return False
    return not any(CYRILLIC.search(c) for i, c in enumerate(columns) if i != 2)


def violations(path):
    markers = next((m for ext, m in MARKERS.items() if path.endswith(ext)), None)
    if not markers:
        return []
    try:
        lines = open(path, encoding="utf-8").read().split("\n")
    except (OSError, UnicodeDecodeError):
        return []

    found = []
    open_quote = None
    for number, line in enumerate(lines, 1):
        start = comment_start(line, markers)
        if start is None:
            open_quote = None
            continue

        prose = line[start:]
        # A quote opened on an earlier comment line still runs: everything up to its
        # closer is data, not prose. Without this, a wrapped list of Russian book
        # titles reads as Russian writing on its second line.
        if open_quote:
            closer = CLOSERS[open_quote]
            end = prose.find(closer)
            if end < 0:
                continue
            prose = prose[end + 1:]
            open_quote = None

        prose = QUOTED.sub("", prose)
        dangling = next((c for c in "«\"'`" if c in prose), None)
        if dangling:
            open_quote = dangling
            prose = DANGLING_QUOTE.sub("", prose)
        prose = PATH_TOKEN.sub("", prose)

        if not is_layout_table_row(line) and CYRILLIC_WORD.search(prose):
            found.append((number, line.strip()))
    return found


def main():
    failed = False
    for path in sys.argv[1:]:
        for number, text in violations(path):
            if not failed:
                print("Comments in this repo are English-only (see AGENTS.md).")
                failed = True
            print(f"  {path}:{number}  {text[:100]}")
    if failed:
        print("\nCyrillic that is data — layout columns, paths, message texts, fixtures —")
        print("belongs in strings, not in a comment. Move it or translate the comment.")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
