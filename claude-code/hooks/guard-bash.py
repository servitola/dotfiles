#!/usr/bin/env python3
"""PreToolUse(Bash) policy gate — the only FAIL-CLOSED hook in this setup.

Enforces the hard rules from claude-code/CLAUDE.md at the harness level,
so they hold even if the model loses them after context compaction:

  ask   scutil --nc start/stop, AmneziaWG/wg-quick   (VPN only on a direct ask)
  deny  sudo rm                                       (root deletes go to the user as `! sudo \\rm ...`)
  deny  rm -rf on /, ~, $HOME                         (home/root wipe)
  ask   git push, gh pr create/merge, glab mr create/merge
        ("explicit go-ahead" becomes a literal confirmation prompt)
  ask   rm -rf <absolute path> outside /tmp, /private/tmp, /private/var/folders

Anything else passes through untouched (exit 0, no output) — the rtk
rewriter and normal permission flow are unaffected. On internal error the
hook answers "ask" (fail-closed), so a broken guard surfaces immediately
instead of silently waving commands through.
"""

import json
import re
import sys

SAFE_RM_PREFIXES = (
    "/tmp/",
    "/private/tmp/",
    "/private/var/folders/",
)

HOME = "/Users/servitola"


def decision(kind: str, reason: str) -> None:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": kind,
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def rm_flags_and_targets(segment: str):
    tokens = segment.split()
    flags, targets = set(), []
    for tok in tokens[1:]:
        if tok.startswith("--"):
            flags.add(tok[2:])
        elif tok.startswith("-") and len(tok) > 1:
            flags.update(tok[1:])
        else:
            targets.append(tok)
    return flags, targets


def check_rm(command: str):
    # Per pipeline/chain segment: only segments that invoke rm/\rm directly.
    for segment in re.split(r"(?:\|\||&&|;|\|)", command):
        segment = segment.strip().lstrip("\\")
        if not re.match(r"rm\s", segment):
            continue
        flags, targets = rm_flags_and_targets(segment)
        recursive = bool({"r", "R", "recursive"} & flags)
        forced = bool({"f", "force"} & flags)
        if not (recursive and forced):
            continue
        for t in targets:
            t = t.strip("'\"")
            expanded = t.replace("~", HOME).replace("$HOME", HOME).rstrip("/")
            if expanded in ("", "/") or expanded == HOME:
                decision("deny", f"rm -rf on '{t}' — refusing a root/home wipe.")
            if t.startswith(("/", "~", "$HOME")) and not expanded.startswith(SAFE_RM_PREFIXES):
                decision("ask", f"rm -rf on absolute path '{t}' — confirm this recursive delete.")


def check(command: str):
    if re.search(r"scutil\s+--nc\s+(start|stop)\b", command) or \
       re.search(r"\b(amneziawg|awg-client|wg-quick)\b", command, re.IGNORECASE):
        decision("ask", "VPN control — confirm (CLAUDE.md: only on a direct ask from the user).")

    if re.search(r"\bsudo\s+(\\?rm|trash)\b", command):
        decision("deny", "No sudo deletes from the agent (CLAUDE.md hard rule). "
                         "Give the user a `! sudo \\rm ...` line to run themselves.")

    if re.search(r"\bgit\b[^|;&]*\bpush\b", command):
        decision("ask", "git push leaves the machine — confirm (CLAUDE.md: push only on explicit go-ahead).")

    if re.search(r"\bgh\s+pr\s+(create|merge)\b", command) or \
       re.search(r"\bglab\s+mr\s+(create|merge)\b", command):
        decision("ask", "Creating/merging a PR/MR is outward-facing — confirm (CLAUDE.md hard rule).")

    check_rm(command)


def main():
    payload = json.load(sys.stdin)
    if payload.get("tool_name") != "Bash":
        sys.exit(0)
    command = payload.get("tool_input", {}).get("command", "")
    check(command)
    sys.exit(0)  # passthrough


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # fail-closed: a broken guard must be visible, not silent
        decision("ask", f"guard-bash hook error ({exc.__class__.__name__}: {exc}) — command not vetted, confirm manually.")
