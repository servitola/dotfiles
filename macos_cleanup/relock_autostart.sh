#!/bin/zsh
# Re-lock Steam/Google autostart agents
# Requires: colors (GREEN/DIM/NC) from cleanup_all.sh

# Steam (steamclean) and Google Keystone/Updater recreate their LaunchAgents on
# launch or after app/OS updates. We keep them permanently dead by replacing
# each with an empty, root-owned, chmod-000 stub the apps cannot overwrite. This
# re-applies the lock if any agent came back since the last run. Idempotent: an
# already-empty (0-byte) stub is left untouched. To restore an app's updater,
# `sudo rm` its stub and relaunch the app.
relock_autostart_agents() {
    local _autostart_agents=(
        "$HOME/Library/LaunchAgents/com.valvesoftware.steamclean.plist"
        "$HOME/Library/LaunchAgents/com.google.keystone.agent.plist"
        "$HOME/Library/LaunchAgents/com.google.keystone.xpcservice.plist"
        "$HOME/Library/LaunchAgents/com.google.GoogleUpdater.wake.plist"
        "/Library/LaunchAgents/com.google.keystone.agent.plist"
        "/Library/LaunchAgents/com.google.keystone.xpcservice.plist"
        "/Library/LaunchDaemons/com.google.keystone.daemon.plist"
        "/Library/LaunchDaemons/com.google.GoogleUpdater.wake.system.plist"
    )
    local _relocked=0
    local _plist _label
    for _plist in "${_autostart_agents[@]}"; do
        # Absent → nothing to do. Empty (0-byte) → already our locked stub, skip.
        [ -e "$_plist" ] || continue
        [ -s "$_plist" ] || continue
        _label="$(basename "$_plist" .plist)"
        case "$_plist" in
            "$HOME"/*)
                launchctl bootout "gui/$(id -u)/$_label" 2>/dev/null
                rm -f "$_plist" 2>/dev/null
                : > "$_plist" 2>/dev/null
                sudo chown root:wheel "$_plist" 2>/dev/null
                sudo chmod 000 "$_plist" 2>/dev/null
                ;;
            /Library/LaunchDaemons/*)
                sudo launchctl bootout "system/$_label" 2>/dev/null
                sudo rm -f "$_plist" 2>/dev/null
                sudo touch "$_plist" 2>/dev/null
                sudo chmod 000 "$_plist" 2>/dev/null
                ;;
            /Library/LaunchAgents/*)
                sudo rm -f "$_plist" 2>/dev/null
                sudo touch "$_plist" 2>/dev/null
                sudo chmod 000 "$_plist" 2>/dev/null
                ;;
        esac
        _relocked=$(( _relocked + 1 ))
    done
    if [ "$_relocked" -gt 0 ]; then
        printf "  ${GREEN}* Autostart agents: re-locked %d (Steam/Google tried to come back)${NC}\n" "$_relocked"
    else
        printf "  ${DIM}* Autostart agents: all still locked${NC}\n"
    fi
}
