#!/usr/bin/env python3
"""PreToolUse(Bash) policy gate — one rule only.

  ask   commands that publish outward: `git push`, `gh pr create`,
        `docker push`, `npm publish`, ... ("explicit go-ahead" becomes a
        literal confirmation prompt)

The match is token-based, not substring-based: the command is lexed the
way a shell would, split on operators, stripped of env-assignments and
wrappers (sudo/rtk/env/...), and only the actual subcommand is checked.
So these pass through silently:

    git stash push          git log --grep push
    echo "git push"         git push --dry-run
    npm run publish         gh pr view --json push

Shell aliases are resolved too — the interactive shell that runs these
commands has `gp='git push'`, so a substring guard is trivially bypassed.
The alias table is dumped from the login shell and cached; unknown
aliases are simply not expanded.

Anything else passes through untouched (exit 0, no output) — the rtk
rewriter and normal permission flow are unaffected. Fails open on a
crash, and falls back to the old loose regex only when the command
cannot be lexed at all.
"""

import json
import os
import re
import shlex
import subprocess
import sys
import time

# Shell operators — each ends the current command segment.
SEPARATORS = set("();<>|&`") | {"||", "&&", ";;", ">>", "<<"}

# Prefixes that stand in front of the real command.
WRAPPERS = {"sudo", "doas", "command", "builtin", "exec", "nohup", "time",
            "nice", "ionice", "env", "stdbuf", "xargs", "caffeinate",
            "rtk", "proxy"}

# Options that consume the following token, per binary. Without these the
# option's value would be mistaken for a positional argument.
OPTS_WITH_ARG = {
    "git": {"-C", "-c", "--git-dir", "--work-tree", "--namespace",
            "--exec-path", "--config-env", "--super-prefix"},
    "docker": {"-c", "--context", "-H", "--host", "--log-level", "--config"},
    "podman": {"--connection", "--remote", "--url", "--log-level"},
    "gh": {"-R", "--repo", "--hostname"},
}

# Subcommand prefixes that hand code or artifacts to a remote.
PUBLISH_RULES = {
    "git": [("push",), ("send-pack",), ("send-email",),
            ("subtree", "push"), ("svn", "dcommit")],
    "gh": [("pr", "create"), ("pr", "merge"), ("pr", "ready"),
           ("release", "create"), ("release", "upload"),
           ("repo", "create"), ("gist", "create")],
    "glab": [("mr", "create"), ("mr", "merge"), ("release", "create")],
    "docker": [("push",)],
    "podman": [("push",)],
    "nerdctl": [("push",)],
    "helm": [("push",)],
    "npm": [("publish",)],
    "pnpm": [("publish",)],
    "yarn": [("publish",)],
    "bun": [("publish",)],
    "cargo": [("publish",)],
    "uv": [("publish",)],
    "poetry": [("publish",)],
    "twine": [("upload",)],
    "gem": [("push",)],
    "nuget": [("push",)],
    "dotnet": [("nuget", "push")],
}

# `gh api -X POST ...` creates PRs and releases straight through the API.
MUTATING_METHODS = {"POST", "PUT", "PATCH", "DELETE"}

ASSIGNMENT = re.compile(r"[A-Za-z_][A-Za-z_0-9]*=")

ALIAS_CACHE = os.path.expanduser("~/.cache/claude-code/guard-bash-aliases.json")
ALIAS_TTL = 6 * 60 * 60
ALIAS_LINE = re.compile(r"^(?:alias )?([^=\s]+)=(.*)$")
MAX_EXPANSIONS = 5


def dump_aliases():
    """Ask the login shell for its alias table."""
    shell = os.environ.get("SHELL", "/bin/zsh")
    argv = [shell, "-ic", "alias -r" if shell.endswith("zsh") else "alias"]
    out = subprocess.run(argv, capture_output=True, text=True, timeout=5,
                         stdin=subprocess.DEVNULL).stdout
    table = {}
    for line in out.splitlines():
        match = ALIAS_LINE.match(line.strip())
        if not match:
            continue
        name, body = match.group(1), match.group(2)
        if body[:1] == "'" and body[-1:] == "'":  # shell-quoted body
            body = body[1:-1].replace("'\\''", "'")
        elif body[:1] == '"' and body[-1:] == '"':
            body = body[1:-1]
        if body:
            table[name] = body
    return table


def publishing_functions():
    """Shell functions whose body publishes — omz ships ggp/ggf/ggfl/grename.

    Function bodies are multi-line shell, not a single command line, so they
    get a phrase sniff instead of the lexer: over-matching here costs one
    confirmation on that function, never on unrelated commands.
    """
    shell = os.environ.get("SHELL", "/bin/zsh")
    out = subprocess.run([shell, "-ic", "functions"], capture_output=True,
                         text=True, timeout=10, stdin=subprocess.DEVNULL).stdout
    phrases = [(binary, rule,
                re.compile(r"\b%s\s+%s\b" % (binary, r"\s+".join(rule))))
               for binary, rules in PUBLISH_RULES.items() for rule in rules]
    found, name = {}, None
    for line in out.splitlines():
        header = re.match(r"^([A-Za-z_][A-Za-z0-9_.-]*) \(\) \{", line)
        if header:
            name = header.group(1)
            continue
        if not name or "--dry-run" in line:
            continue
        for binary, rule, phrase in phrases:
            if phrase.search(line):
                found.setdefault(name, " ".join((binary,) + rule))
    return found


def shell_table():
    """Cached alias + function tables; never fatal — empty just means no expansion."""
    try:
        if time.time() - os.path.getmtime(ALIAS_CACHE) < ALIAS_TTL:
            with open(ALIAS_CACHE) as handle:
                cached = json.load(handle)
            return cached["aliases"], cached["functions"]
    except (OSError, ValueError, KeyError):
        pass
    try:
        table = {"aliases": dump_aliases(), "functions": publishing_functions()}
        os.makedirs(os.path.dirname(ALIAS_CACHE), exist_ok=True)
        with open(ALIAS_CACHE, "w") as handle:
            json.dump(table, handle)
        return table["aliases"], table["functions"]
    except Exception:
        return {}, {}


def lex(command):
    """Tokenize like a shell: quotes honoured, operators kept separate."""
    lexer = shlex.shlex(command, posix=True, punctuation_chars="();<>|&`")
    lexer.whitespace_split = True
    return list(lexer)


def segments(tokens):
    """Split the token stream into individual commands."""
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
    """Drop leading env-assignments and wrapper commands."""
    index = 0
    while index < len(segment):
        token = segment[index]
        if ASSIGNMENT.match(token) or os.path.basename(token) in WRAPPERS:
            index += 1
        else:
            break
    return segment[index:]


def positionals(args, opts_with_arg):
    """Non-option arguments, in order, skipping values of known options."""
    result = []
    index = 0
    while index < len(args):
        token = args[index]
        if token in opts_with_arg:
            index += 2
        elif token.startswith("-"):
            index += 1
        else:
            result.append(token)
            index += 1
    return result


def gh_api_writes(args):
    for index, token in enumerate(args):
        if token in {"-X", "--method"} and index + 1 < len(args):
            if args[index + 1].upper() in MUTATING_METHODS:
                return True
        if token.startswith(("-X", "--method=")):
            if token.split("=")[-1].lstrip("-X").upper() in MUTATING_METHODS:
                return True
    return False


def violation(segment):
    """Return a human label for the publishing command, or None."""
    segment = strip_prefix(segment)
    if not segment:
        return None
    binary = os.path.basename(segment[0])
    rules = PUBLISH_RULES.get(binary)
    if rules is None:
        return None

    args = segment[1:]
    if "--dry-run" in args or (binary == "git" and "-n" in args):
        return None

    found = positionals(args, OPTS_WITH_ARG.get(binary, set()))
    if binary == "gh" and found[:1] == ["api"] and gh_api_writes(args):
        return "gh api -X POST/PUT/PATCH/DELETE"
    for rule in rules:
        if tuple(found[:len(rule)]) == rule:
            return " ".join((binary,) + rule)
    return None


def publishes(command, seen=()):
    try:
        tokens = lex(command)
    except ValueError:  # unbalanced quotes — fall back to the loose rule
        if re.search(r"\bgit\b[^|;&]*\bpush\b", command):
            return "git push"
        return None

    commands = [strip_prefix(segment) for segment in segments(tokens)]
    for segment in commands:
        label = violation(segment)
        if label:
            return label

    if len(seen) >= MAX_EXPANSIONS:
        return None
    aliases, functions = shell_table()
    for segment in commands:
        name = segment[0] if segment else None
        if name in functions:
            return f"{name} → {functions[name]}"
        if name in aliases and name not in seen:
            expansion = " ".join([aliases[name]] + [shlex.quote(a) for a in segment[1:]])
            label = publishes(expansion, seen + (name,))
            if label:
                return f"{name} → {label}"
    return None


def main():
    payload = json.load(sys.stdin)
    if payload.get("tool_name") != "Bash":
        return
    label = publishes(payload.get("tool_input", {}).get("command", ""))
    if label:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "ask",
                "permissionDecisionReason": f"`{label}` leaves the machine — confirm.",
            }
        }))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # fail-open: never let a broken guard nag
        print(f"guard-bash hook error: {exc}", file=sys.stderr)
    sys.exit(0)
