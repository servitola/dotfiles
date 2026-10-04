#!/bin/zsh
# What a finished install leaves behind. install.sh runs it last; alone: zsh install/check.sh
source "${0:a:h}/lib.sh"
cd "$DOTFILES"

problems=0
expect() {  # expect <what> <command...>: silent when it holds
    local what=$1; shift
    "$@" >/dev/null 2>&1 && return
    err "$what"
    problems=$(( problems + 1 ))
}

section "links"
if [[ -f $STATE/links.tsv ]]; then
    sort -u "$STATE/links.tsv" | while IFS=$'\t' read -r destination source; do
        expect "${destination/#$HOME/~} -> ${source/#$HOME/~}" test "$destination" -ef "$source"
    done
else
    warn "no $STATE/links.tsv yet: it is written by the next install"
fi

section "apps and tools"
expect "minimum brewfile satisfied (brew bundle check)" brew bundle check --file homebrew/minimum_brewfile
expect "login shell is zsh" test "${SHELL:t}" = zsh
expect "Hammerspoon running" pgrep -x Hammerspoon
expect "Karabiner rules match layers.toml" python3 docs/keyboard/tools/gen_layers.py --check
expect "~/.codex/config.toml is a file" test -f "$HOME/.codex/config.toml"
expect "shortcuts match macos/shortcuts.toml" python3 docs/keyboard/tools/shortcuts.py check
setopt null_glob
for app in /Applications/Ableton*.app; do
    expect "${app:t} has the ableton-mcp-extended Remote Script" cmp \
        "$app/Contents/App-Resources/MIDI Remote Scripts/AbletonMCP/__init__.py" \
        "$HOME/projects/ableton_setup/ableton-mcp-extended/AbletonMCP_Remote_Script/__init__.py"
done

section "Spoons"
grep -oE 'install_spoon [A-Za-z0-9]+ [^ ]+ "\$[A-Z0-9_]+"' install/18-spoons.sh | while read -r _ name _ variable; do
    wanted=$(grep -oE "^${variable//[\"\$]/}=v[^ ]+" install/18-spoons.sh | cut -d= -f2)
    expect "$name.spoon is $wanted" grep -qE "version = \"${wanted#v}\"" "hammerspoon/Spoons/$name.spoon/init.lua"
done

section "services"
expect "serho agent loaded" launchctl print "gui/$UID/com.servitola.serho"
for stack in litellm docker-logger; do
    expect "$stack containers running" zsh -c "docker compose -f $stack/docker-compose.yml ps --status running -q | grep -q ."
done
expect "crontab matches cron/cron_jobs" zsh -c 'diff <(timeout 10 crontab -l) <(cron/init-cron-jobs.sh --print)'

section "git"
expect "init.templateDir -> git/hooks/template" test "$(git config --global init.templateDir)" = "$DOTFILES/git/hooks/template"
expect "pre-commit hook installed here" test -x .git/hooks/pre-commit

if (( problems )); then
    err "$problems check(s) failed"
    exit 1
fi
ok "everything in place"
