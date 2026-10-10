#!/bin/zsh
# Rare, deliberate cleanup: everything here costs a re-download, a rebuild or
# lost local state, so every step shows what it frees and asks first.
#
# Usage: deep_clean.sh [-n|--dry-run] [root...]   (roots default to $DIR_PROJECTS)

setopt no_unset pipe_fail

: "${CLEANUP_DIR:=${0:a:h}}"
source "$CLEANUP_DIR/helpers.sh"

DRY_RUN=false
if [[ "${1:-}" == (-n|--dry-run) ]]; then
    DRY_RUN=true
    shift
fi
REPO_ROOTS=("${@:-$DIR_PROJECTS}")

RM_CMD="/bin/rm"

GREEN='\033[0;92m'
YELLOW='\033[0;33m'
BLUE='\033[0;94m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

size_of() {
    local kb
    kb=$(du -skc "$@" 2>/dev/null | tail -1 | cut -f1)
    format_size "${kb:-0}"
}

# Line-based on purpose: `read -q` always talks to the terminal, so the prompt
# could not be driven from a pipe; and a deliberate step deserves an Enter.
confirm_step() {
    local title="$1" size="$2" cost="$3" reply=""
    printf "\n${GREEN}${BOLD}⚡${NC} ${BOLD}%s${NC} — %s\n  ${DIM}%s${NC}\n" "$title" "$size" "$cost"
    $DRY_RUN && return 1
    read -r "reply?  Run it? [y/N] "
    [[ "$reply" == [yY] ]]
}

# git clean -dfx was the first idea and is not used. Measured on this machine,
# it would also delete every ignored .env, local databases, trained models, the
# Claude Code transcripts under claude-code/ and karabiner.json — "ignored" is
# not the same as "regenerable". So a directory goes only when git ignores it
# AND its name is a known build/dependency output.
ARTIFACT_NAMES=(bin obj node_modules build dist target .venv .gradle .next
                .mypy_cache .ruff_cache .pytest_cache __pycache__)

typeset -a artifact_dirs artifacts_in_use
typeset -A repo_kb

collect_repo_artifacts() {
    local running git_dir repo rel dir kb
    running=$(ps -axo command=)
    artifact_dirs=()
    artifacts_in_use=()
    repo_kb=()
    while IFS= read -r -d '' git_dir; do
        repo="${git_dir:h}"
        # ~/.claude is a symlink into this repo, so its ignored dirs hold live
        # tool state (transcripts, plugin caches, installed Spoons), not builds.
        [[ "$repo" == "$DIR_DOTFILES" ]] && continue
        while IFS= read -r -d '' rel; do
            [[ "$rel" == */ ]] || continue
            rel="${rel%/}"
            (( ${ARTIFACT_NAMES[(Ie)${rel:t}]} )) || continue
            dir="$repo/$rel"
            # A live process started from inside (a service on its .venv, a dev
            # server on node_modules) would lose its code mid-flight.
            if [[ "$running" == *"$dir/"* ]]; then
                artifacts_in_use+=("$dir")
                continue
            fi
            kb=$(du -sk "$dir" 2>/dev/null | cut -f1)
            artifact_dirs+=("$dir")
            repo_kb[$repo]=$(( ${repo_kb[$repo]:-0} + ${kb:-0} ))
        done < <(git -C "$repo" ls-files -z --others --ignored --exclude-standard --directory 2>/dev/null)
    done < <(find "${REPO_ROOTS[@]}" -maxdepth 4 \( -name node_modules -o -name .venv \) -prune -o -name .git -print0 2>/dev/null)
}

print_repo_artifacts() {
    local repo dir
    for repo in ${(k)repo_kb}; do
        (( repo_kb[$repo] >= 1024 )) && printf "%d\t%s\n" "${repo_kb[$repo]}" "${repo/#$HOME/~}"
    done | sort -rn | while IFS=$'\t' read -r kb repo; do
        printf "  %8s  %s\n" "$(format_size $kb)" "$repo"
    done
    for dir in $artifacts_in_use; do
        printf "  ${DIM}in use, kept: %s${NC}\n" "${dir/#$HOME/~}"
    done
}

_free_kb_before=$(df -k / | awk 'NR==2 {print $4}')

printf "${BLUE}${BOLD}━━━ Deep Cleanup ━━━${NC}\n"
$DRY_RUN && printf "${DIM}dry run: nothing is deleted${NC}\n"

nuget_dirs=(${(f)"$(dotnet nuget locals all --list | sed 's/^[^:]*: //')"})
if confirm_step "NuGet: all local caches" "$(size_of $nuget_dirs)" \
    "next restore of every solution re-downloads its packages"; then
    dotnet nuget locals all --clear
fi

# A project .venv survives: on APFS uv clones files into it, nothing points back
# into the cache. --force because the launchd uv services hold the cache
# permanently and a guarded clean would never run.
uv_cache_dir=$(uv cache dir)
if confirm_step "uv: whole cache" "$(size_of "$uv_cache_dir")" \
    "project .venv dirs keep working; \`uv run script.py\` services are restarted and re-download their wheels (torch, mlx: GBs), as does any rebuilt .venv"; then
    uv cache clean --force
    restart_services_with_deleted_uv_env "$uv_cache_dir"
fi

if confirm_step "npm: download cache" "$(size_of ~/.npm/_cacache)" \
    "next npm install re-downloads every tarball"; then
    npm cache clean --force
fi

if confirm_step "Go: build + module cache" "$(size_of "$(go env GOCACHE)" "$(go env GOMODCACHE)")" \
    "next go build re-downloads modules and recompiles from scratch"; then
    go clean -cache -modcache
fi

spinner_start "Measuring build output in repositories"
collect_repo_artifacts
spinner_stop_dim "Repositories scanned: ${REPO_ROOTS[*]/#$HOME/~}"
print_repo_artifacts
if confirm_step "Repositories: ignored build + dependency dirs (${#artifact_dirs} dirs)" \
    "$(format_size $(( ${(j:+:)repo_kb:-0} )))" \
    "only git-ignored dirs named ${ARTIFACT_NAMES[*]}; every repo needs restore/install/sync and a full rebuild"; then
    for dir in $artifact_dirs; do
        "$RM_CMD" -rf -- "$dir"
    done
fi

if confirm_step "iOS simulators: erase all, delete unavailable" \
    "$(size_of ~/Library/Developer/CoreSimulator/Devices)" \
    "every simulator returns to factory state: installed apps, logins and test data are gone"; then
    xcrun simctl shutdown all
    xcrun simctl erase all
    xcrun simctl delete unavailable
fi

if confirm_step "Docker: all unused images, stopped containers, build cache" \
    "$(docker system df --format '{{.Type}} {{.Reclaimable}}' | grep -v Volumes | paste -sd ',' -)" \
    "images of stopped stacks are re-pulled or rebuilt on their next start; named volumes are not touched"; then
    docker system prune -a -f
    docker builder prune -a -f
fi

if confirm_step "Git: expire reflogs + aggressive gc in every repository under ~" "size unknown" \
    "dropped commits, deleted branches and lost stashes become unrecoverable; takes minutes and fetches every remote"; then
    _git_repo_count=0
    while IFS= read -r -d '' git_dir; do
        repo_path="${git_dir%/.git}"
        git -C "$repo_path" rev-parse --git-dir &>/dev/null || continue
        _git_repo_count=$(( _git_repo_count + 1 ))
        printf "  ${DIM}* Pruning: ${repo_path/#$HOME/~}${NC}\r"
        git -C "$repo_path" reflog expire --expire=now --expire-unreachable=now --all 2>/dev/null
        git -C "$repo_path" gc --aggressive --prune=now 2>/dev/null
        git -C "$repo_path" remote prune origin 2>/dev/null
        git -C "$repo_path" fetch --prune 2>/dev/null
        git -C "$repo_path" repack -a -d --depth=250 --window=250 2>/dev/null
        git -C "$repo_path" prune --expire=now 2>/dev/null
    done < <(find "$HOME" -type d -name ".git" -not -path "*/node_modules/*" -not -path "*/.Trash/*" -not -path "*/Library/*" -print0 2>/dev/null)
    printf "\r\033[K  ${_S_GREEN}${_S_BOLD}* Git aggressive gc: pruned ${_git_repo_count} repositories${_S_NC}\n"
fi

$DRY_RUN && exit 0

_free_kb_after=$(df -k / | awk 'NR==2 {print $4}')
printf "\n${YELLOW}${BOLD}✨ Deep cleanup done. Freed $(format_size $(( _free_kb_after - _free_kb_before ))) ($(( _free_kb_after / 1048576 )) GB available)${NC}\n"
