#!/usr/bin/env python3
"""Exercises guard-bash.py: which commands are guarded, and what each session mode gets.

Every command below is one that was actually run on 2026-09-24 while republishing
three repositories, plus the harmless look-alikes that must stay silent.
"""

import importlib.util
import os
import pathlib
import sys
import tempfile

spec = importlib.util.spec_from_file_location(
    "guard", pathlib.Path(__file__).with_name("guard-bash.py"))
guard = importlib.util.module_from_spec(spec)
spec.loader.exec_module(guard)
guard.shell_table = lambda: ({}, {})
guard.APPROVED_LOG = os.path.join(tempfile.mkdtemp(), "approved.log")

BOT = True
TERMINAL = False

# (command, mode, expected decision or None)
CASES = [
    ("gh repo delete servitola/homebrew-tap --yes", BOT, "deny"),
    ("gh repo delete servitola/homebrew-tap --yes", TERMINAL, "ask"),
    ("gh release delete v2026.09.24 -R servitola/yt-dlp-puzzle-movies --yes --cleanup-tag", BOT, "deny"),
    ("gh repo edit servitola/yt-dlp-puzzle-movies --visibility public --accept-visibility-change-consequences", BOT, "deny"),
    ("git push -q --force origin main", BOT, "deny"),
    ("git push -q --force-with-lease origin main", BOT, "deny"),
    ("git push origin +main", BOT, "deny"),
    ("git push -q origin :refs/tags/v2026.09.24.4", BOT, "deny"),
    ("git push --delete origin v1", BOT, "deny"),
    ("git -C ~/projects/homebrew-tap push --mirror origin", BOT, "deny"),
    ("git filter-repo --force --path-rename .gitea/:.github/", BOT, "deny"),
    ("gh api -X DELETE repos/servitola/x", BOT, "deny"),
    ("cd ~/projects/x && git tag -d v1 && git push origin :refs/tags/v1", BOT, "deny"),
    ("gh repo delete servitola/x --yes", TERMINAL, "ask"),

    ("OWNER_APPROVED=1 gh repo delete servitola/x --yes", BOT, None),
    ("OWNER_APPROVED=1 gh repo delete servitola/x --yes", TERMINAL, "ask"),
    ("echo OWNER_APPROVED=1; gh repo delete servitola/x --yes", BOT, "deny"),

    ("git push -q origin main", BOT, "ask"),
    ("git push -q origin main", TERMINAL, "ask"),
    ("gh release create v1 -R a/b x.zip", BOT, "ask"),
    ("gh repo create servitola/x --public", BOT, "ask"),
    ("gh repo edit servitola/x --add-topic cli", BOT, None),

    ("git push --dry-run --force origin main", BOT, "deny"),
    ("git push --dry-run origin main", BOT, None),
    ("gh release view v1 -R a/b", BOT, None),
    ("gh repo view servitola/x", BOT, None),
    ("git log --oneline --grep filter-repo", BOT, None),
    ("git commit -m 'explain gh repo delete'", BOT, None),
    ("gh api repos/servitola/x", BOT, None),
]


def decision_for(command, mode):
    hit = guard.guarded(command)
    decision = hit and guard.decide(*hit, command, mode)
    return decision[0] if decision else None


def run():
    failures = []
    for command, mode, expected in CASES:
        got = decision_for(command, mode)
        if got != expected:
            failures.append(f"{command!r} [{mode}]: expected {expected}, got {got}")
    if not os.path.exists(guard.APPROVED_LOG):
        failures.append("an approved destructive command was not logged")

    for failure in failures:
        print(f"FAIL {failure}")
    print(f"{len(CASES) - len(failures)}/{len(CASES)} passed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(run())
