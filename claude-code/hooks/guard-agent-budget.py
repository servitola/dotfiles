#!/usr/bin/env python3
"""PreToolUse(Task|Agent|Workflow) — the agent-budget gate from claude-code/CLAUDE.md.

Counts subagent spawns per session in /tmp; from spawn #6 onward every spawn
asks for confirmation, so a runaway fan-out can't happen silently. Workflow
launches always ask (a single Workflow call can fan out dozens of agents).

Advisory gate → fail-OPEN: if the counter breaks, spawns proceed (stderr notes it).
"""

import json
import os
import re
import sys

LIMIT = 5
STATE_DIR = f"/tmp/claude-agent-budget-{os.getuid()}"


def decision(reason: str) -> None:
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": reason,
        }
    }))
    sys.exit(0)


def main():
    payload = json.load(sys.stdin)
    tool = payload.get("tool_name", "")

    if tool == "Workflow":
        decision("Workflow can fan out many subagents — confirm this run "
                 "(CLAUDE.md: heavyweight multi-agent runs need a go-ahead with a token estimate).")

    if tool not in ("Task", "Agent"):
        sys.exit(0)

    session = re.sub(r"[^0-9a-zA-Z_-]", "", str(payload.get("session_id", "unknown")))
    os.makedirs(STATE_DIR, mode=0o700, exist_ok=True)
    path = os.path.join(STATE_DIR, session)
    try:
        with open(path) as f:
            count = int(f.read().strip() or 0)
    except FileNotFoundError:
        count = 0
    count += 1
    with open(path, "w") as f:
        f.write(str(count))

    if count > LIMIT:
        decision(f"Agent budget: spawn #{count} this session (free budget is {LIMIT}) — confirm "
                 "(CLAUDE.md: >5 agents need explicit approval with an agent/token estimate).")
    sys.exit(0)


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as exc:  # advisory gate: fail-open, but loudly
        print(f"guard-agent-budget hook error: {exc}", file=sys.stderr)
        sys.exit(0)
