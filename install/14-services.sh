#!/bin/zsh
# Step 14 — serho launchd agent, pre-commit hooks.
source "${0:a:h}/lib.sh"
set -euo pipefail

section "serho (Telegram AI agent) launchd"
link "$DOTFILES/serho/com.servitola.serho.plist" \
     "$LAUNCH_AGENTS/com.servitola.serho.plist"

section "pre-commit hooks"
( cd "$DOTFILES" && pre-commit install )

section "drop the old voiceink clean filter if a prior install set it"
# VoiceInk JSON normalization now runs as the normalize-voiceink-json
# pre-commit hook (git-format-staged, staged-only). The old git clean filter
# corrupted pre-commit's stash and rolled back unstaged edits on error — unset
# it on machines that still have it. See voiceink/AGENTS.md.
( cd "$DOTFILES" && git config --unset filter.vk-json-normalize.clean 2>/dev/null || true )
