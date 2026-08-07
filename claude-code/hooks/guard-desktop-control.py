#!/usr/bin/env python3
"""PreToolUse(Bash) — policy gate for commands that drive the desktop itself:
window geometry, synthetic input, display arrangement, Hammerspoon.

**Every rule below currently says "allow", so this hook blocks nothing.** It is
installed inert on purpose: the rule table is the point, not the policy. Flip an
action to "ask" or "deny" when you decide that class of command should stop.

    allow   pass through, silently (also useful as a carve-out placed *above* a
            broader deny — first match wins, so a narrow allow beats it)
    ask     the user gets a confirmation prompt
    deny    refused outright, the agent is told why and cannot retry

Rules are matched against each shell segment separately, after env-assignments
and wrappers (sudo/rtk/env/...) are stripped. A segment whose first token is a
read-only command is skipped entirely, so `grep -rn "set bounds" hammerspoon/`
and `cat window_focus_sets.lua` are searches, not window moves.

Six matching styles are demonstrated, and they compose within one rule:

    binary       exact command name                     -> cliclick
    subcommand   positional tokens after the binary     -> yabai -m window
    args         regex over the arguments only          -> hs -c '<lua>'
    segment      regex over the whole segment           -> osascript ... keystroke
    cwd          regex over the working directory       -> only inside ~/projects/x
    unless       regex that exempts an otherwise-matched segment (the carve-out)

Fails open — a broken guard must never wedge the session.
"""

import json
import os
import re
import shlex
import sys

SEPARATORS = set("();<>|&`") | {"||", "&&", ";;", ">>", "<<"}

WRAPPERS = {"sudo", "doas", "command", "builtin", "exec", "nohup", "time",
            "nice", "env", "stdbuf", "xargs", "caffeinate", "rtk", "proxy"}

READ_ONLY = {"grep", "rg", "ag", "cat", "bat", "head", "tail", "less", "more",
             "ls", "find", "fd", "wc", "diff", "jq", "echo", "printf", "awk",
             "sed", "cut", "sort", "uniq", "file", "stat", "tree"}

ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z_0-9]*=")

# Ordered; first match wins. Narrow carve-outs go above the broad rules they
# punch through.
RULES = [
    {
        "name": "hammerspoon-reload",
        "action": "allow",
        "binary": "hs",
        "args": r"hs\.reload\(\)|hs\.console|hs\.inspect",
        "reason": "Перезагрузка и интроспекция конфига — своя же разработка Spoon'ов.",
    },
    {
        "name": "hammerspoon-arbitrary-lua",
        "action": "allow",
        "binary": "hs",
        "subcommand": ("-c",),
        "unless": r"hs\.reload\(\)",
        "reason": (
            "`hs -c` выполняет произвольный Lua с правами Hammerspoon — "
            "это обход любого другого правила здесь."
        ),
    },
    {
        "name": "synthetic-input",
        "action": "allow",
        "binary": "cliclick",
        "reason": "Синтетические клики и нажатия в чужих приложениях.",
    },
    {
        "name": "applescript-synthetic-input",
        "action": "allow",
        "segment": r"osascript.*\b(keystroke|key code|click at|click UI element)\b",
        "reason": "AppleScript печатает или кликает за тебя в чужом окне.",
    },
    {
        "name": "applescript-window-geometry",
        "action": "allow",
        "segment": r"osascript.*\bset (bounds|position|size) of\b",
        "reason": "AppleScript двигает или ресайзит окна.",
    },
    {
        "name": "yabai-window-ops",
        "action": "allow",
        "binary": "yabai",
        "subcommand": ("-m", "window"),
        "reason": "yabai переставляет окна.",
    },
    {
        "name": "display-arrangement",
        "action": "allow",
        "binary": "displayplacer",
        "reason": "Перестройка физического расположения мониторов.",
    },
    {
        "name": "spaces-and-dock-defaults",
        "action": "allow",
        "segment": r"defaults\s+write\s+com\.apple\.(spaces|dock|WindowManager)\b",
        "reason": "Правка системных настроек Spaces / Dock / Stage Manager.",
    },
    {
        "name": "hammerspoon-config-writes-outside-dotfiles",
        "action": "allow",
        "binary": "hs",
        "cwd": r"^(?!/Users/[^/]+/projects/dotfiles)",
        "reason": "Hammerspoon дёргают из чужого репозитория, а не из dotfiles.",
    },
]


def lex(command):
    lexer = shlex.shlex(command, posix=True, punctuation_chars="();<>|&`")
    lexer.whitespace_split = True
    return list(lexer)


def segments(tokens):
    current = []
    for token in tokens:
        if token in SEPARATORS:
            if current:
                yield current
            current = []
        else:
            current.append(token)
    if current:
        yield current


def strip_prefix(segment):
    index = 0
    while index < len(segment):
        token = segment[index]
        if ASSIGNMENT.match(token) or os.path.basename(token) in WRAPPERS:
            index += 1
        else:
            break
    return segment[index:]


def matches(rule, segment, cwd):
    binary = os.path.basename(segment[0])
    args = segment[1:]
    chunk = " ".join(segment)

    if "binary" in rule and binary != rule["binary"]:
        return False
    if "subcommand" in rule:
        head = tuple(args[:len(rule["subcommand"])])
        if head != rule["subcommand"]:
            return False
    if "args" in rule and not re.search(rule["args"], " ".join(args)):
        return False
    if "segment" in rule and not re.search(rule["segment"], chunk):
        return False
    if "cwd" in rule and not re.search(rule["cwd"], cwd or ""):
        return False
    if "unless" in rule and re.search(rule["unless"], chunk):
        return False
    return True


def verdict(command, cwd):
    """(decision, reason) for the first non-allow match, else None."""
    try:
        tokens = lex(command)
    except ValueError:
        return None

    for segment in segments(tokens):
        segment = strip_prefix(segment)
        if not segment or os.path.basename(segment[0]) in READ_ONLY:
            continue
        for rule in RULES:
            if not matches(rule, segment, cwd):
                continue
            if rule["action"] == "allow":
                break
            return rule["action"], f"[{rule['name']}] {rule['reason']}"
    return None


def main():
    payload = json.load(sys.stdin)
    if payload.get("tool_name") != "Bash":
        return
    result = verdict(
        payload.get("tool_input", {}).get("command", ""),
        payload.get("cwd", ""),
    )
    if not result:
        return
    decision, reason = result
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": decision,
            "permissionDecisionReason": reason,
        }
    }, ensure_ascii=False))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"guard-desktop-control hook error: {exc}", file=sys.stderr)
    sys.exit(0)
