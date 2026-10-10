#!/bin/sh
# RTK PreToolUse hook for codex (0.147+).
#
# Codex carries hooks in Claude Code's format — the stdin payload matches
# verbatim, so `rtk hook claude` parses it as native. Only the reply differs:
# codex requires a "permissionDecision" field in hookSpecificOutput, and rtk
# 0.45.0 doesn't write it (Claude Code works fine without it). Without the
# field codex prints "hook: PreToolUse Failed" and silently runs the ORIGINAL
# command — so a breakage in this shim costs the lost compaction, not
# functionality. Measured on codex-cli 0.147.0 in the serho image, 2026-08-21.
#
# Installed into $CODEX_HOME/hooks.json:
#   {"hooks":{"PreToolUse":[{"hooks":[{"type":"command",
#     "command":"/opt/rtk/codex-hook.sh"}]}]}}
set -eu

OUT=$(rtk hook claude 2>/dev/null) || exit 0
[ -n "$OUT" ] || exit 0

printf '%s' "$OUT" | python3 -c '
import json, sys

try:
    payload = json.load(sys.stdin)
except ValueError:
    sys.exit(0)  # could not parse rtk reply — stay quiet, codex runs the original
out = payload.get("hookSpecificOutput")
if not isinstance(out, dict) or "updatedInput" not in out:
    sys.exit(0)  # rtk decided not to rewrite
out.setdefault("permissionDecision", "allow")
json.dump(payload, sys.stdout)
'
