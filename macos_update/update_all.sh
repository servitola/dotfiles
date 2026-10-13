#!/bin/zsh
# Update all packages and tools
#
# Strict mode (fail-fast policy): any failing step aborts the run, referencing
# an unset variable is an error, a pipeline fails if any component fails.
# Run as a child process (`zsh update_all.sh`) — never source into an
# interactive shell, or these options leak into it and break the prompt.
setopt err_exit no_unset pipe_fail

source ~/projects/dotfiles/macos_update/functions.sh

# Gruvbox colors
GREEN='\033[0;92m'      # Bright green
YELLOW='\033[0;33m'
BLUE='\033[0;94m'       # Bright blue
BOLD='\033[1m'
NC='\033[0m'

print_section() {
    printf "\n${BLUE}${BOLD}━━━ %s ━━━${NC}\n" "$1"
}

print_task() {
    printf "\n${GREEN}${BOLD}⚡${NC} ${BOLD}%s${NC}\n" "$1"
}

print_section "Apps Updates"

rm -rf "$(brew --cache)" > /dev/null 2>&1 || true  # best-effort: locked files are fine
brew tap --repair
brew update
brew upgrade --greedy

print_task "Removing quarantine flags from updated applications"
brew_unquarantine

# mas 2.x enumerates installed apps through the Spotlight index, which is
# disabled on this machine (`mdutil -s /` → off). With it off, `mas upgrade`
# finds nothing and only prints noise — App Store apps auto-update anyway. Run
# it only where indexing is enabled (e.g. another machine sharing these dotfiles).
if mdutil -s / 2>/dev/null | grep -q "Indexing enabled"; then
    mas upgrade
fi
brew cleanup --scrub

brew doctor || true  # informational: exits non-zero on any warning
# Dump everything except mas (Spotlight is off, so brew's `mas list` returns
# nothing and would wipe the App Store section), then regenerate the mas block
# ourselves by detecting _MASReceipt apps in /Applications. See homebrew/mas-dump.sh.
brew bundle dump --force --no-mas --file=~/projects/dotfiles/homebrew/brewfile
~/projects/dotfiles/homebrew/mas-dump.sh >> ~/projects/dotfiles/homebrew/brewfile

print_task "Updating VSCode extensions"
code --update-extensions

npm config set fund false
# Package installers predate strict mode and report per-package failures
# themselves (❌ lines) — relax err_exit/pipe_fail around them, keep no_unset.
unsetopt err_exit pipe_fail
source ~/projects/dotfiles/npm/install-globals.sh
npm cache verify

uv python install 3.12
source ~/projects/dotfiles/python/install-globals.sh
source ~/projects/dotfiles/python/install-uv-tools.sh
source ~/projects/dotfiles/python/install-tts.sh
setopt err_exit pipe_fail

print_task "Update Appium plugins and drivers"
appium plugin update installed
appium driver update installed

print_task "Updating .NET tools"
if command -v dotnet >/dev/null; then   # installed by hand, only where .NET work happens
    dotnet tool update -g dotnet-trace
else
    echo "  * Skip: no dotnet on this machine"
fi

print_task "Updating precommit hooks"
# autoupdate needs CWD inside the dotfiles git repo (it git-fetches hook repos);
# run in a subshell so the cd doesn't leak into the rest of the script.
(cd ~/projects/dotfiles && pre-commit autoupdate)

print_section "Docker Containers"

~/projects/dotfiles/docker/up.sh

print_section "Immich Sync"

print_task "Syncing local folders to Immich on i9"
if [[ -x $DIR_SERVICES/immich/sync.sh ]]; then   # its own project, cloned only where photos are synced
    "$DIR_SERVICES/immich/sync.sh"
else
    echo "  * Skip: no $DIR_SERVICES/immich on this machine"
fi

print_section "LiteLLM Model Health"

print_task "Checking model availability across providers"
if [[ -d $DIR_LITELLM ]]; then
    python3 "$DIR_LITELLM/scripts/check-models.py" || echo "  * model-health check failed"
else
    echo "  * LiteLLM is not on this machine ($DIR_LITELLM missing) — skipped"
fi

print_section "RAG Index"

# docker/up.sh (re)starts LiteLLM above, but `docker compose up -d` returns as
# soon as the container *starts*, not when it's *healthy* — LiteLLM's boot (DB
# migrations, redis, config load) lags behind. An immediate refresh then races a
# not-yet-ready proxy and `rag` exits clean ("not responding") without
# refreshing anything. Wait up to ~60s for the same health endpoint rag.sh's
# preflight uses; tolerate timeout.
print_task "Waiting for LiteLLM to be ready"
for _i in {1..30}; do
    curl -sSf --max-time 2 http://localhost:4000/health/liveliness >/dev/null 2>&1 && break
    sleep 2
done

print_task "Refreshing Qdrant collections from rag.conf"
if [[ -r $DIR_RAG/rag.sh ]]; then
    source "$DIR_RAG/rag.sh"
    rag refresh || echo "  * rag refresh failed (litellm/qdrant down?)"
else
    echo "  * rag not installed ($DIR_RAG/rag.sh missing) — skipped"
fi

print_section "Tokens Savings"
# Trust is keyed by sha256 of rtk/filters.toml, so every edit to it silently
# disables our filters until re-trusted. Run from $HOME: there is no
# project-local .rtk/filters.toml there, so this can only trust our own file.
( cd "$HOME" && rtk trust --yes >/dev/null 2>&1 ) || true
rtk gain

print_section "Bloat Cleanup"

print_task "Disable Chrome on-device AI model (Gemini Nano)"
# https://chromeenterprise.google/policies/gen-ai-local-foundational-model-settings/
defaults write com.google.Chrome GenAILocalFoundationalModelSettings -int 1

print_task "Clearing macOS aerial wallpaper downloads"
# macOS keeps re-downloading multi-GB .mov aerial wallpapers; purge them every update.
# Currently-used aerial (if any) is locked and will be skipped silently.
AERIAL_DIR="$HOME/Library/Application Support/com.apple.wallpaper/aerials"
if [ -d "$AERIAL_DIR/videos" ]; then
    # (N) = null_glob: empty match expands to nothing instead of erroring;
    # || true tolerates the locked in-use aerial file
    rm -f "$AERIAL_DIR"/videos/*.mov(N) 2>/dev/null || true
    rm -f "$AERIAL_DIR"/thumbnails/*(N) 2>/dev/null || true
fi

print_section "Final Updates"

print_task "Updating TLDR cache"
tldr --update > /dev/null || echo "Error updating tldr cache"

print_task "Updating Bat cache"
bat cache --build > /dev/null || echo "Error updating bat cache"

print_task "Checking Android SDK licenses are accepted and Accept them"
yes | sdkmanager --licenses 2>&1 | grep -v "Warning: " > /dev/null || {
    error_code=$?
    if [ $error_code -ne 0 ] && [ $error_code -ne 141 ]; then
        echo "Error verifying Android SDK licenses"
    fi
}

print_task "Updating Powerlevel10k theme"
git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" pull

print_task "Updating shared skill repos"
"${DIR_SKILLS:?}/shared/skills-repos/update.sh"

print_task "Updating Oh My Zsh"
zsh -ic "omz update"

print_task "Updating Atuin db (zsh history)"
if [[ -f $HOME/.local/share/atuin/session ]]; then
    atuin sync
elif [[ -t 0 ]]; then
    zsh ~/projects/dotfiles/atuin/login.sh
else
    printf "  ✗ atuin is not logged in: run zsh ~/projects/dotfiles/atuin/login.sh\n"
fi


print_task "Re-rendering configs generated from constants"
zsh ~/projects/dotfiles/constants/render-all.zsh

print_task "Regenerating keyboard SVGs"
python3 ~/projects/dotfiles/docs/keyboard/generate.py 2>&1 | tail -3

print_task "Capturing this Mac's shortcuts into macos_shortcuts/shortcuts.toml"
python3 ~/projects/dotfiles/macos_shortcuts/shortcuts.py capture --write

print_task "Capturing Rider's keymap into jetbrains rider/keymap.xml"
python3 ~/projects/dotfiles/docs/keyboard/rider.py capture

print_task "Projecting the captured shortcuts into the HotKeys key tables (⚙ / ◆ / ℝ lines)"
python3 ~/projects/dotfiles/docs/keyboard/tools/normalize.py --project

print_task "Setting macOS appearance"
m appearance --highlightcolor grape

print_section "Static Data Compression (APFS/LZFSE)"
~/projects/dotfiles/applesauce/compress.sh

print_section "Security Guards"

# `sysadminctl -screenLock` reports on stderr and always exits 0, so the state
# has to come from the string. Reading it needs no auth; only the reset does —
# and `-password -` prompts, which is fine because it fires solely on drift.
print_task "Verifying screen lock delay"
screen_lock=$(sysadminctl -screenLock status 2>&1)
if [[ "$screen_lock" == *"delay is immediate"* ]]; then
    echo "  ✓ immediate"
else
    printf "  ⚠ %s — resetting to immediate\n" "${screen_lock##*] }"
    sysadminctl -screenLock immediate -password -
fi

# Signatures once sat two months stale with nothing surfacing it: the OS reports
# healthy whether or not XProtect is updating. In Tahoe the enforced copy under
# /var/protected is converted from what Software Update fetches, so a disabled
# ConfigDataInstall silently freezes both channels at once. An absent key is NOT
# proof of "off" (Apple omits it when the GUI sets it), so only an explicit 0 is
# flagged — the pending-update scan is the ground truth. Warn, never fix: `up`
# is deliberately sudo-free, and both remedies need root.
print_task "Verifying XProtect signatures are current"
for key in ConfigDataInstall CriticalUpdateInstall; do
    setting=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate "$key" 2>/dev/null) || continue
    if [[ "$setting" == 0 ]]; then
        printf "  ⚠ %s is 0 — security data will not install\n" "$key"
    fi
done
xprotect_pending=$(softwareupdate -l --include-config-data 2>&1 | grep XProtect || true)
if [[ -n "$xprotect_pending" ]]; then
    printf "  ⚠ installed %s, but pending:\n%s\n" "$(xprotect version 2>&1)" "$xprotect_pending"
    echo "    fix: sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true && sudo xprotect update"
else
    printf "  ✓ %s\n" "$(xprotect version 2>&1)"
fi

printf '\n%b✨ All updates completed!%b\n' "${YELLOW}${BOLD}" "${NC}"
