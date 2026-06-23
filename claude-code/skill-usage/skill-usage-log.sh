#!/bin/sh
# skill-usage-log.sh — append one JSON line per skill invocation.
#
# Wired from settings.json hooks:
#   PostToolUse (matcher "Skill")  -> model-invoked skills (tool_input.skill)
#   UserPromptExpansion            -> user-typed /slash skills
#
# Pure telemetry: never blocks, always exits 0, never deletes or mutates anything.
# Log lands at ~/.claude/skill-usage.jsonl (gitignored).

LOG="$HOME/.claude/skill-usage.jsonl"

# Read the hook JSON from stdin, extract the skill name from whichever field
# the event provides, and append a compact record. If no skill name is found
# (non-skill event shape), the line is dropped silently.
jq -c '
  (.tool_input.skill // .command_name // .command // .name // .skill) as $s
  | select($s != null and ($s | type == "string") and $s != "")
  | { ts: (now | todate), event: .hook_event_name, skill: $s, cwd: .cwd, session: .session_id }
' >> "$LOG" 2>/dev/null

exit 0
