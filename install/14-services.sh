#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

section "serho (Telegram AI agent) launchd"
# The plist is local to the machine that hosts the bot and not in git,
# so a fresh Mac has none and gets no agent.
if [[ -f $DOTFILES/serho/com.servitola.serho.plist ]]; then
    link "$DOTFILES/serho/com.servitola.serho.plist" \
         "$LAUNCH_AGENTS/com.servitola.serho.plist"
else
    log "no serho/com.servitola.serho.plist here, skipped"
fi

section "pre-commit hooks"
( cd "$DOTFILES" && pre-commit install )

section "drop the old voiceink clean filter if a prior install set it"
# It broke pre-commit's stash and rolled back unstaged edits (voiceink/AGENTS.md).
( cd "$DOTFILES" && git config --unset filter.vk-json-normalize.clean 2>/dev/null || true )
