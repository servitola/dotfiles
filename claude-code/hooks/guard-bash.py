#!/usr/bin/env python3
"""PreToolUse(Bash) policy gate — two rules.

  ask   commands that publish outward: `git push`, `gh pr create`,
        `docker push`, `npm publish`, ... ("explicit go-ahead" becomes a
        literal confirmation prompt)

  destroy  commands that delete or rewrite what is already published:
        `gh repo delete`, `gh release delete`, `git push --force`, a pushed
        ref deletion, `git filter-repo`, `gh api -X DELETE`, ... In an
        interactive session they ask like the rule above. Sessions started
        with --dangerously-skip-permissions (the Telegram bot) never show an
        "ask" — it passes silently — so there they are denied instead, and
        go through only when the command carries OWNER_APPROVED=1, which the
        agent adds after the owner said yes in the chat. Approved runs are
        appended to APPROVED_LOG.

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

# Deleting or rewriting published state: stars, releases, attestations and
# history do not come back.
DESTRUCTIVE_RULES = {
    "gh": [("repo", "delete"), ("repo", "archive"), ("repo", "rename"),
           ("release", "delete"), ("release", "delete-asset"),
           ("run", "delete")],
    "git": [("filter-repo",), ("filter-branch",)],
}

# `git push` options that overwrite or delete refs on the remote.
DESTRUCTIVE_PUSH_OPTIONS = {"-f", "--force", "--force-if-includes", "--mirror",
                            "-d", "--delete", "--prune"}

# `gh repo edit` options that change who can see the repository.
DESTRUCTIVE_REPO_EDIT_OPTIONS = ("--visibility",)

# `gh api -X POST ...` creates PRs and releases straight through the API.
MUTATING_METHODS = {"POST", "PUT", "PATCH", "DELETE"}

APPROVAL = re.compile(r"(?:^|[\s;&|(])OWNER_APPROVED=1(?=\s)")
APPROVED_LOG = os.path.expanduser("~/.cache/claude-code/destructive-approved.log")

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


def gh_api_method(args):
    for index, token in enumerate(args):
        if token in {"-X", "--method"} and index + 1 < len(args):
            return args[index + 1].upper()
        if token.startswith(("-X", "--method=")):
            return token.split("=")[-1].lstrip("-X").upper()
    return None


def push_destroys(args, found):
    """A push that force-overwrites or deletes remote refs."""
    for token in args:
        if token in DESTRUCTIVE_PUSH_OPTIONS or token.startswith("--force-with-lease"):
            return True
    # `git push origin +main` forces, `git push origin :refs/tags/v1` deletes.
    return any(ref[:1] in {"+", ":"} for ref in found[2:])


def destroys(binary, args, found):
    """Return a label when the command deletes or rewrites published state."""
    if binary == "git" and found[:1] == ["push"] and push_destroys(args, found):
        return "git push --force / ref deletion"
    if binary == "gh" and found[:2] == ["repo", "edit"] and any(
            token.startswith(DESTRUCTIVE_REPO_EDIT_OPTIONS) for token in args):
        return "gh repo edit --visibility"
    if binary == "gh" and found[:1] == ["api"] and gh_api_method(args) == "DELETE":
        return "gh api -X DELETE"
    for rule in DESTRUCTIVE_RULES.get(binary, []):
        if tuple(found[:len(rule)]) == rule:
            return " ".join((binary,) + rule)
    return None


def violation(segment):
    """Return ("destroy" | "publish", human label) for a guarded command, or None."""
    segment = strip_prefix(segment)
    if not segment:
        return None
    binary = os.path.basename(segment[0])
    if binary not in PUBLISH_RULES and binary not in DESTRUCTIVE_RULES:
        return None

    args = segment[1:]
    found = positionals(args, OPTS_WITH_ARG.get(binary, set()))
    label = destroys(binary, args, found)
    if label:
        return "destroy", label
    if "--dry-run" in args or (binary == "git" and "-n" in args):
        return None

    if binary == "gh" and found[:1] == ["api"] and gh_api_method(args) in MUTATING_METHODS:
        return "publish", "gh api -X POST/PUT/PATCH/DELETE"
    for rule in PUBLISH_RULES.get(binary, []):
        if tuple(found[:len(rule)]) == rule:
            return "publish", " ".join((binary,) + rule)
    return None


def guarded(command, seen=()):
    """Return (kind, label) for the most serious guarded command, or None."""
    try:
        tokens = lex(command)
    except ValueError:  # unbalanced quotes — fall back to the loose rule
        if re.search(r"\bgit\b[^|;&]*\bpush\b", command):
            return "publish", "git push"
        return None

    commands = [strip_prefix(segment) for segment in segments(tokens)]
    hits = [hit for hit in map(violation, commands) if hit]

    if len(seen) < MAX_EXPANSIONS:
        aliases, functions = shell_table()
        for segment in commands:
            name = segment[0] if segment else None
            if name in functions:
                hits.append(("publish", f"{name} → {functions[name]}"))
            elif name in aliases and name not in seen:
                expansion = " ".join([aliases[name]] + [shlex.quote(a) for a in segment[1:]])
                hit = guarded(expansion, seen + (name,))
                if hit:
                    hits.append((hit[0], f"{name} → {hit[1]}"))

    for kind in ("destroy", "publish"):
        for hit in hits:
            if hit[0] == kind:
                return hit
    return None


def unattended(payload):
    """True when no one can answer an "ask": it would pass without a prompt.

    The payload is not enough. A session started with
    --dangerously-skip-permissions reports its current mode, "acceptEdits" in
    the Telegram bot (measured 2026-09-24), while every ask still passes
    silently. The flag itself is on the claude process's command line.
    """
    if payload.get("permission_mode") == "bypassPermissions":
        return True
    pid = os.environ.get("CLAUDE_PID")
    if not pid:
        return False
    argv = subprocess.run(["ps", "-o", "command=", "-p", pid],
                          capture_output=True, text=True, timeout=5).stdout
    return "--dangerously-skip-permissions" in argv.split()


def decide(kind, label, command, bypass):
    """Hook output for a guarded command, or None to let it through."""
    if kind == "destroy" and bypass:
        if APPROVAL.search(command):
            os.makedirs(os.path.dirname(APPROVED_LOG), exist_ok=True)
            with open(APPROVED_LOG, "a") as log:
                log.write(f"{time.strftime('%Y-%m-%d %H:%M:%S')}\t{command}\n")
            return None
        return ("deny", f"`{label}` deletes or rewrites something already published, "
                        "and this session cannot show a confirmation. Stop and ask the owner "
                        "in the chat: name the command and what is lost for good. Only after "
                        "an explicit yes, rerun it prefixed with OWNER_APPROVED=1.")
    if kind == "destroy":
        return ("ask", f"`{label}` deletes or rewrites something already published — confirm.")
    return ("ask", f"`{label}` leaves the machine — confirm.")


def main():
    payload = json.load(sys.stdin)
    if payload.get("tool_name") != "Bash":
        return
    command = payload.get("tool_input", {}).get("command", "")
    hit = guarded(command)
    decision = hit and decide(*hit, command, unattended(payload))
    if decision:
        print(json.dumps({
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": decision[0],
                "permissionDecisionReason": decision[1],
            }
        }))


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:  # fail-open: never let a broken guard nag
        print(f"guard-bash hook error: {exc}", file=sys.stderr)
    sys.exit(0)
