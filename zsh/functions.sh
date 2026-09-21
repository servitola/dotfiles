#!/bin/zsh

function mkd() {
    mkdir -p "$@" && cd "$_"
}

# cd to git repo root
function groot() {
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) || { echo "Not in a git repository" >&2; return 1; }
    cd "$root"
}

# get macOS app Bundle ID and copy to clipboard
function bundleid() {
    local id=$(osascript -e "id of app \"$1\"" 2>/dev/null)
    if [[ -n "$id" ]]; then
        echo "$id" | tr -d '\n' | pbcopy
        echo "$id (copied)"
    else
        echo "App not found: $1"
        return 1
    fi
}

# text -> speech via the local LiteLLM proxy; plays it unless -o is given
function tts() {
    local model="${TTS_MODEL:-tts}" out="" voice="" text=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -m|--model) model="$2"; shift 2 ;;
            -v|--voice) voice="$2"; shift 2 ;;
            -o|--out)   out="$2";   shift 2 ;;
            -h|--help)
                echo "usage: tts [-m model] [-v voice] [-o file.mp3] 'text'   (text also read from stdin)"
                echo "models: tts (Gemini), tts-piper (ru, fast), tts-kokoro (en), tts-bagdasaryan (ru clone, slow)"
                return 0 ;;
            *) text="$1"; shift ;;
        esac
    done
    [[ -n "$text" ]] || text="$(cat)"
    [[ -n "$text" ]] || { echo "tts: no text" >&2; return 2; }

    local target="${out:-$(mktemp -t tts).mp3}" code
    code=$(jq -n --arg m "$model" --arg i "$text" --arg v "${voice:-alloy}" \
              '{model:$m, input:$i, voice:$v, response_format:"mp3"}' \
        | curl -sS -o "$target" -w '%{http_code}' \
              --max-time "${TTS_TIMEOUT:-600}" \
              -X POST "${LITELLM_BASE:-http://localhost:4000}/v1/audio/speech" \
              -H "Authorization: Bearer ${LITELLM_MASTER_KEY:-sk-local-workbot}" \
              -H 'Content-Type: application/json' --data @-)

    if [[ "$code" != 200 ]]; then
        echo "tts: $model returned HTTP $code" >&2
        head -c 400 "$target" >&2; echo >&2
        [[ -n "$out" ]] || rm -f "$target"
        return 1
    fi
    if [[ -n "$out" ]]; then echo "$out"; else afplay "$target" && rm -f "$target"; fi
}

# Quick jump between git worktrees via fzf
function wt() {
    if ! command -v git &> /dev/null; then
        echo "Ошибка: git не установлен" >&2
        return 1
    fi
    if ! command -v fzf &> /dev/null; then
        echo "Ошибка: fzf не установлен" >&2
        return 1
    fi

    local worktree
    worktree=$(git worktree list --porcelain | awk '/^worktree/ {print $2}' | fzf --height=40% --reverse --prompt="Выберите worktree: ")

    if [[ -z "$worktree" ]]; then
        echo "Выбор отменен" >&2
        return 1
    fi

    cd "$worktree" || {
        echo "Ошибка: не удалось перейти в $worktree" >&2
        return 1
    }
    echo "Переход в: $(pwd)"
}

# `git reflog` prints either the HEAD@{N} index or a date, never both, and the
# builtin cannot be taught a default: reflog ignores log.date, and git silently
# drops an alias that shadows a builtin. The shell is the only layer left, so
# plain `git reflog` is routed to git-rl. Scripts and non-interactive shells
# never load this file, so they keep the stock output.
function git() {
    if [[ "$1" == reflog && "$2" != (expire|delete|exists|-h|--help) && "$*" != *--date=* ]]; then
        shift
        git-rl "$@"
    else
        command git "$@"
    fi
}
