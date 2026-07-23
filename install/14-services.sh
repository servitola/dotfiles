#!/bin/zsh
# Step 14 — serho launchd agent, pre-commit, voiceink normalize filter.
source "${0:a:h}/lib.sh"
set -euo pipefail

section "serho (Telegram AI agent) launchd"
link "$DOTFILES/serho/com.servitola.serho.plist" \
     "$LAUNCH_AGENTS/com.servitola.serho.plist"

section "pre-commit hooks"
( cd "$DOTFILES" && pre-commit install )

section "voiceink json normalize filter"
# jq -S canonicalizes VoiceInk's non-deterministic key order so a pure
# reshuffle is a no-op diff. Clone-local config. See voiceink/AGENTS.md.
( cd "$DOTFILES" && git config filter.vk-json-normalize.clean "jq -S ." )
