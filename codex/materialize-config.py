#!/usr/bin/env python3
"""Materialize ~/.codex/config.toml as a REAL file — never a symlink into the
dotfiles repo.

Codex persists machine-local runtime state directly into config.toml:
project-trust ([projects.*]), plus [notice], [marketplaces.*], [plugins.*] and
[tui.*]. When config.toml is symlinked into the repo, every trust write lands in
the working tree and gets committed. So we keep config.toml a real local file:
the authored head comes from the repo, Codex's managed tail is preserved locally,
and ephemeral project-trust blocks (anything not under $HOME/projects) are
dropped so the registry stops accumulating temp dirs.

    materialize-config.py <authored_src> <live_dst> <home>

Idempotent: re-running re-syncs the authored head and keeps real project trust.
"""
import os
import re
import sys

# Top-level tables Codex writes at runtime (authored tables never start with these).
MANAGED_RE = re.compile(r'^\[(projects|notice|marketplaces|plugins|tui)[.\]]')
PROJECT_RE = re.compile(r'^\[projects\."(.*)"\]\s*$')


def read(path):
    real = os.path.realpath(path)
    if os.path.exists(real):
        with open(real, encoding='utf-8') as f:
            return f.read()
    return ''


def split_head(text):
    """Split into (authored_head, managed_tail) at the first managed table."""
    lines = text.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if MANAGED_RE.match(line):
            return ''.join(lines[:i]), ''.join(lines[i:])
    return text, ''


def blocks(tail):
    """Yield TOML blocks: a header line plus its body up to the next header."""
    cur = []
    for line in tail.splitlines(keepends=True):
        if line.startswith('[') and cur:
            yield ''.join(cur)
            cur = []
        cur.append(line)
    if cur:
        yield ''.join(cur)


def keep_block(block, projects_prefix):
    header = block.splitlines()[0] if block.strip() else ''
    m = PROJECT_RE.match(header)
    if not m:
        return True  # non-projects managed block (notice/marketplaces/…): keep
    return m.group(1).startswith(projects_prefix)  # real project trust only


def main():
    authored_src, live_dst, home = sys.argv[1], sys.argv[2], sys.argv[3]
    head, _ = split_head(read(authored_src))
    _, tail = split_head(read(live_dst))
    prefix = os.path.join(home, 'projects') + os.sep

    kept = ''.join(b for b in blocks(tail) if keep_block(b, prefix))
    head = head.rstrip('\n')
    result = head + '\n' if not kept.strip() else head + '\n\n' + kept.lstrip('\n')
    if not result.endswith('\n'):
        result += '\n'

    # Keep the repo's authored file pristine (head only). No-op once clean, so
    # never clobbers an intentional authored edit and never churns git.
    clean_head = head + '\n'
    if read(authored_src) != clean_head:
        with open(os.path.realpath(authored_src), 'w', encoding='utf-8') as f:
            f.write(clean_head)

    # Replace live_dst with a real file (drop any symlink first).
    if os.path.islink(live_dst):
        os.unlink(live_dst)
    elif os.path.exists(live_dst) and read(live_dst) == result:
        return  # already correct
    os.makedirs(os.path.dirname(live_dst), exist_ok=True)
    with open(live_dst, 'w', encoding='utf-8') as f:
        f.write(result)


if __name__ == '__main__':
    main()
