#!/usr/bin/env python3
"""PostToolUse hook: compress verbose Bash output before it enters context.

Companion to the RTK PreToolUse rewriter (`rtk hook claude`): that one rewrites
known commands to rtk-filtered equivalents, but compound/piped/unknown commands
bypass it and dump raw output into context. This hook catches those on the way
back via hookSpecificOutput.updatedToolOutput.

Conservative by design:
- Bash only; commands already rewritten to `rtk ...` are skipped.
- Output below CHAR_THRESHOLD is never touched.
- Known toolchains go through the matching `rtk pipe -f <filter>`.
- Everything else is compressed only when longer than LINE_THRESHOLD lines:
  head + all error/warning lines + tail, with explicit omission markers.
- Any failure -> exit 0 (original output passes through untouched).
"""
import json
import re
import subprocess
import sys

CHAR_THRESHOLD = 4000    # below this, never touch output
LINE_THRESHOLD = 300     # generic fallback compresses only above this
HEAD, TAIL, MAX_ERR = 60, 60, 150
HARD_CAP = 9500          # updatedToolOutput strings are capped at 10k chars

# High-confidence command -> rtk pipe filter (anchored to command start,
# also matched after each pipe/&&/; segment start).
RTK_FILTERS = [
    (r"(npx\s+|yarn\s+)?tsc\b", "tsc"),
    (r"(npx\s+|yarn\s+)?vitest\b", "vitest"),
    (r"(python3?\s+-m\s+)?pytest\b", "pytest"),
    (r"cargo\s+test\b", "cargo-test"),
    (r"go\s+test\b", "go-test"),
    (r"go\s+build\b", "go-build"),
    (r"mypy\b", "mypy"),
    (r"git\s+log\b", "git-log"),
    (r"git\s+diff\b", "git-diff"),
]
ERR_RE = re.compile(
    r"\b(error|fail(ed|ure)?|exception|fatal|panic|traceback|warn(ing)?|"
    r"assert(ion)?|denied|refused|timeout|unreachable)\b|✖|✗|FAIL",
    re.IGNORECASE,
)


def pick_filter(cmd):
    first = cmd.strip()
    for pat, name in RTK_FILTERS:
        if re.match(pat, first):
            return name
    return None


def rtk_pipe(name, text):
    try:
        proc = subprocess.run(
            ["rtk", "pipe", "-f", name],
            input=text, capture_output=True, text=True, timeout=20,
        )
        out = proc.stdout
        if proc.returncode == 0 and out.strip() and len(out) < len(text):
            return out
    except Exception:
        pass
    return None


def head_errors_tail(text):
    lines = text.splitlines()
    if len(lines) <= LINE_THRESHOLD:
        return None
    head, tail = lines[:HEAD], lines[-TAIL:]
    middle = lines[HEAD:-TAIL]
    errs = [l for l in middle if ERR_RE.search(l)][:MAX_ERR]
    omitted = len(middle) - len(errs)
    parts = head
    if errs:
        parts += [f"... [{omitted} non-error lines omitted; "
                  f"{len(errs)} error/warning lines kept] ..."] + errs
    else:
        parts += [f"... [{omitted} lines omitted] ..."]
    parts += tail
    return "\n".join(parts)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return
    if data.get("tool_name") != "Bash":
        return
    cmd = (data.get("tool_input") or {}).get("command", "")
    if cmd.lstrip().startswith("rtk "):
        return  # already filtered by the PreToolUse rewriter

    resp = data.get("tool_response")
    if isinstance(resp, dict):
        key = next((k for k in ("text", "stdout")
                    if isinstance(resp.get(k), str)), None)
        text = resp.get(key) if key else None
    else:
        key, text = None, None
    if not text or len(text) <= CHAR_THRESHOLD:
        return

    fname = pick_filter(cmd)
    compressed = rtk_pipe(fname, text) if fname else None
    if compressed is None:
        compressed = head_errors_tail(text)
    # only ship a meaningful win
    if compressed is None or len(compressed) >= len(text) * 0.9:
        return

    if len(compressed) > HARD_CAP:
        compressed = compressed[:HARD_CAP] + "\n... [truncated at 10k hook cap]"
    note = (f"\n[output compressed by posttooluse hook: "
            f"{len(text)} -> {len(compressed)} chars; "
            f"rerun with `rtk proxy <cmd>` if full output is needed]")
    new_resp = dict(resp)
    new_resp[key] = compressed + note
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PostToolUse",
            "updatedToolOutput": new_resp,
        }
    }))


if __name__ == "__main__":
    main()
    sys.exit(0)
