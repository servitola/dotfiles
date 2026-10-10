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

section "LaunchAgents of the scheduled jobs (\$DIR_CRON/launchagents)"
# The personal schedule layer lives with the crontab fragments; reboot-reminder
# here is the one generic example. Runners are built by make in their helper/.
link "$DOTFILES/launchagents/com.servitola.reboot-reminder.plist" \
     "$LAUNCH_AGENTS/com.servitola.reboot-reminder.plist"
setopt null_glob
for plist in "${DIR_CRON:?}"/launchagents/*.plist "${DIR_CRON:?}"/launchagents/*/*.plist; do
    link "$plist" "$LAUNCH_AGENTS/${plist:t}"
done

section "pre-commit hooks"
( cd "$DOTFILES" && pre-commit install )

section "drop the old voiceink clean filter if a prior install set it"
# It broke pre-commit's stash and rolled back unstaged edits (voiceink/AGENTS.md).
( cd "$DOTFILES" && git config --unset filter.vk-json-normalize.clean 2>/dev/null || true )
