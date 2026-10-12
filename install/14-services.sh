#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

setopt null_glob

section "LaunchAgents of other repositories (DIRS_LAUNCHAGENTS)"
for folder in ${${(s:,:)DIRS_LAUNCHAGENTS}:#NONE}; do
    for plist in $folder/*.plist; do
        link "$plist" "$LAUNCH_AGENTS/${plist:t}"
    done
done

section "LaunchAgents of the scheduled jobs (\$DIR_CRON/launchagents)"
# The personal schedule layer lives with the crontab fragments; reboot-reminder
# here is the one generic example; runners are built by make next to their plists.
link "$DOTFILES/launchagents/com.servitola.reboot-reminder.plist" \
     "$LAUNCH_AGENTS/com.servitola.reboot-reminder.plist"
for plist in "${DIR_CRON:?}"/launchagents/*.plist "${DIR_CRON:?}"/launchagents/*/*.plist; do
    link "$plist" "$LAUNCH_AGENTS/${plist:t}"
done

section "pre-commit hooks"
( cd "$DOTFILES" && pre-commit install )

section "drop the old voiceink clean filter if a prior install set it"
# It broke pre-commit's stash and rolled back unstaged edits (voiceink/AGENTS.md).
( cd "$DOTFILES" && git config --unset filter.vk-json-normalize.clean 2>/dev/null || true )
