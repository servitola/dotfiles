#!/usr/bin/env bash
# commit-msg check: reject AI co-author/tool footers, case-insensitively.
# Deployed into every repo's .git/hooks/commit-msg via init.templateDir
# (git/hooks/template/hooks/commit-msg) — see git/AGENTS.md.
set -euo pipefail

msg_file="$1"
body="$(grep -v '^#' "$msg_file" || true)"

patterns=(
    'Co-Authored-By:.*(claude|anthropic|copilot|cursor|codex|gemini)'
    'noreply@anthropic\.com'
    'Generated (with|by) (Claude|Copilot|Cursor|Codex|Gemini)'
    '🤖.*Generated with'
)

for pattern in "${patterns[@]}"; do
    offending="$(printf '%s\n' "$body" | grep -inE "$pattern" || true)"
    if [ -n "$offending" ]; then
        echo "commit-msg: AI co-author/tool footer not allowed — ${offending#*:}" >&2
        exit 1
    fi
done
