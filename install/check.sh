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
# mas apps wait for an App Store sign-in that only a person can do
# the list install step 3 installed: this Mac's Telegram client, mas apps aside
expect "brewfile satisfied, mas apps aside (brew bundle check)" brew bundle check --no-upgrade --file =(grep -v '^mas ' "$STATE/brewfile")
expect "login shell is zsh" test "${SHELL:t}" = zsh
expect "Hammerspoon running" pgrep -x Hammerspoon
expect "Karabiner rules match layers.toml" python3 docs/keyboard/tools/gen_layers.py --check
expect "~/.codex/config.toml is a file" test -f "$HOME/.codex/config.toml"
expect "shortcuts match macos_shortcuts/shortcuts.toml" python3 macos_shortcuts/shortcuts.py check
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
[[ ! -f serho/com.servitola.serho.plist ]] || expect "serho agent loaded" launchctl print "gui/$UID/com.servitola.serho"
machine=$(scutil --get LocalHostName)
[[ $DOCKER == no ]] || grep -hv '^#' docker/compose-projects.txt docker/compose-projects.private.txt | while read -r stack machines; do
    [[ -n $stack && " $machines " == *" $machine "* ]] || continue
    [[ $stack == /* ]] || stack=$HOME/$stack
    [[ -d $stack ]] || continue   # a stack on an unplugged drive
    expect "${stack:t} stack running" zsh -c "
        wanted=\$(docker compose --project-directory '$stack' config --format json | jq '[.services[] | select((.restart // \"no\") != \"no\")] | length')
        (( \$(docker compose --project-directory '$stack' ps --status running -q | wc -l) >= wanted ))"
done
[[ ! -d $DIR_CRON_JOBS ]] || expect "crontab matches \$DIR_CRON_JOBS" zsh -c 'diff <(timeout 10 crontab -l) <(cron/install.sh --print)'

section "git"
expect "init.templateDir -> git/hooks/template" test "$(git config --global init.templateDir)" = "$DOTFILES/git/hooks/template"
expect "pre-commit hook installed here" test -x .git/hooks/pre-commit

if (( problems )); then
    err "$problems check(s) failed"
    exit 1
fi
ok "everything in place"
