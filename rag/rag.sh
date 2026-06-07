# rag — local RAG over Qdrant + LiteLLM (OpenRouter free embeddings)
#
# Usage:
#   rag ingest  [flags] <path...>        index files/dirs into Qdrant
#   rag ask     [flags] "question"       retrieve + answer via LiteLLM
#   rag context [flags] "question"       retrieve only, no LLM (good for pbcopy)
#   rag info    <collection>             show stats + indexed file list
#   rag refresh [collection]             re-ingest collections from rag.conf
#   rag list                             list Qdrant collections
#   rag drop    <collection>             delete a collection (asks confirmation)
#   rag status                           health of LiteLLM + Qdrant
#   rag eval    [file] [--verbose]       run canonical questions (rag.eval.json)
#   rag prune-gaps [flags]               drop gap entries that retrieval now closes
#   rag help                             show this help
#
# ingest flags (forwarded to scripts/rag-ingest.py):
#   --collection NAME       target collection (default: workflow)
#   --chunk-size N          chars per chunk (default 1200)
#   --chunk-overlap N       overlap chars between chunks (default 150)
#   --batch-size N          embedding batch size (default 16)
#   --extensions CSV        allowed file extensions, no dots
#   --source LABEL          payload.source label
#   --max-files N           stop after N files
#
# ask/context flags (forwarded to scripts/rag-ask.py):
#   --collection NAME       source collection (default: workflow)
#   --top-k N               retrieved chunks (default 6)
#   --model NAME            chat model alias from config.yaml (default: gpt)
#   --mode MODE             search mode: vector, fts, hybrid (context defaults to hybrid)
#   --show-context          print retrieved chunks before the answer (ask only)
#   --json                  print raw JSON response (ask only)
#
# Examples:
#   rag ingest --collection dotfiles ~/projects/dotfiles/README.md ~/projects/dotfiles/docs
#   rag ask --collection dotfiles "how is the keyboard setup wired up?"
#   rag context --collection dotfiles "what is hammerspoon?" | pbcopy
#   rag info dotfiles
#   rag refresh                  # refresh every collection listed in rag.conf
#   rag refresh dotfiles         # refresh one
#   rag list
#   rag drop smoke
#
# Config file:
#   ~/projects/dotfiles/rag/rag.conf    declarative rules for `rag refresh`
#
# Env vars (shared with scripts/rag-*.py):
#   LITELLM_URL          default http://localhost:4000
#   LITELLM_MASTER_KEY   default sk-local-workbot
#   QDRANT_URL           default http://localhost:6333
#   RAG_EMBED_MODEL      default embed
#   RAG_CHAT_MODEL       default gpt
#   RAG_COLLECTION       default workflow
#
# Requires: python3, curl, jq, LiteLLM + Qdrant containers up
# (see ~/projects/dotfiles/litellm/docker-compose.yml and
#      ~/projects/dotfiles/qdrant/docker-compose.yml).

rag() {
  local cmd="${1:-help}"
  [[ $# -gt 0 ]] && shift

  local qdrant_url="${QDRANT_URL:-http://localhost:6333}"
  local litellm_url="${LITELLM_URL:-http://localhost:4000}"
  local rag_dir="$HOME/projects/dotfiles/rag"
  local scripts_dir="$rag_dir/scripts"
  local conf="$rag_dir/rag.conf"
  local conf_private="$rag_dir/rag.private.conf"

  # Pre-flight helper defined inline so it cannot drift out of sync with rag()
  # across partial re-sources or stale persistent shells (Claude Code, tmux).
  _rag_preflight() {
    local need_litellm="$1" need_qdrant="$2"
    local litellm_hint="start: cd ~/projects/dotfiles/litellm && docker compose up -d"
    local qdrant_hint="start: cd ~/projects/dotfiles/qdrant && docker compose up -d"
    if [ "$need_litellm" = "1" ]; then
      if ! curl -sSf --max-time 2 "$litellm_url/health/liveliness" >/dev/null 2>&1; then
        printf 'rag: LiteLLM is not responding at %s\n     %s\n' "$litellm_url" "$litellm_hint" >&2
        return 1
      fi
    fi
    if [ "$need_qdrant" = "1" ]; then
      if ! curl -sSf --max-time 2 "$qdrant_url/healthz" >/dev/null 2>&1; then
        printf 'rag: Qdrant is not responding at %s\n     %s\n' "$qdrant_url" "$qdrant_hint" >&2
        return 1
      fi
    fi
    return 0
  }

  case "$cmd" in
    ingest)
      if [ ! -f "$scripts_dir/rag-ingest.py" ]; then
        echo "rag: $scripts_dir/rag-ingest.py not found" >&2
        return 1
      fi
      _rag_preflight 1 1 || return 1
      python3 "$scripts_dir/rag-ingest.py" "$@"
      ;;

    ask)
      if [ ! -f "$scripts_dir/rag-ask.py" ]; then
        echo "rag: $scripts_dir/rag-ask.py not found" >&2
        return 1
      fi
      _rag_preflight 1 1 || return 1
      python3 "$scripts_dir/rag-ask.py" "$@"
      ;;

    context)
      if [ ! -f "$scripts_dir/rag-ask.py" ]; then
        echo "rag: $scripts_dir/rag-ask.py not found" >&2
        return 1
      fi
      _rag_preflight 1 1 || return 1
      # Default to hybrid search for context retrieval (boosts exact keyword matches).
      # Explicit --mode in "$@" overrides this via argparse (last wins).
      python3 "$scripts_dir/rag-ask.py" --context-only --mode hybrid "$@"
      ;;

    eval)
      if [ ! -f "$scripts_dir/rag-eval.py" ]; then
        echo "rag: $scripts_dir/rag-eval.py not found" >&2
        return 1
      fi
      _rag_preflight 1 1 || return 1
      python3 "$scripts_dir/rag-eval.py" "$@"
      ;;

    improve)
      if [ ! -f "$scripts_dir/rag-improve.py" ]; then
        echo "rag: $scripts_dir/rag-improve.py not found" >&2
        return 1
      fi
      _rag_preflight 1 1 || return 1
      python3 "$scripts_dir/rag-improve.py" "$@"
      ;;

    prune-gaps)
      if [ ! -f "$scripts_dir/rag-prune-gaps.py" ]; then
        echo "rag: $scripts_dir/rag-prune-gaps.py not found" >&2
        return 1
      fi
      _rag_preflight 1 1 || return 1
      python3 "$scripts_dir/rag-prune-gaps.py" "$@"
      ;;

    status)
      local color_ok color_bad reset
      if [ -t 1 ]; then
        color_ok=$'\033[32m'; color_bad=$'\033[31m'; reset=$'\033[0m'
      else
        color_ok=''; color_bad=''; reset=''
      fi
      local rc=0
      if curl -sSf --max-time 2 "$litellm_url/health/liveliness" >/dev/null 2>&1; then
        printf '  LiteLLM   %s   %shealthy%s\n' "$litellm_url" "$color_ok" "$reset"
      else
        printf '  LiteLLM   %s   %sDOWN%s\n' "$litellm_url" "$color_bad" "$reset"
        rc=1
      fi
      if curl -sSf --max-time 2 "$qdrant_url/healthz" >/dev/null 2>&1; then
        printf '  Qdrant    %s   %shealthy%s\n' "$qdrant_url" "$color_ok" "$reset"
      else
        printf '  Qdrant    %s   %sDOWN%s\n' "$qdrant_url" "$color_bad" "$reset"
        rc=1
      fi
      if [ $rc -ne 0 ]; then
        printf '  %s→ LiteLLM:  cd ~/projects/dotfiles/litellm && docker compose up -d%s\n' "$color_bad" "$reset"
        printf '  %s→ Qdrant:   cd ~/projects/dotfiles/qdrant && docker compose up -d%s\n' "$color_bad" "$reset"
      fi
      return $rc
      ;;

    info)
      local name="$1"
      if [ -z "$name" ]; then
        echo "rag info: collection name required" >&2
        return 1
      fi
      local meta
      meta=$(curl -sS "$qdrant_url/collections/$name")
      if [ "$(printf '%s' "$meta" | jq -r '.result')" = "null" ]; then
        printf '%s\n' "$meta" | jq -r '.status.error // "collection not found"' >&2
        return 1
      fi
      printf 'collection: %s\n' "$name"
      printf '%s' "$meta" | jq -r '.result | "points:     \(.points_count)\nvectors:    \(.config.params.vectors.size)\nstatus:     \(.status)"'
      printf '\nindexed files:\n'
      curl -sS -X POST "$qdrant_url/collections/$name/points/scroll" \
        -H 'Content-Type: application/json' \
        -d '{"limit": 10000, "with_payload": ["path"], "with_vector": false}' \
        | jq -r '.result.points[].payload.path' \
        | sort | uniq -c | sort -rn \
        | awk '{printf "  %3d  %s\n", $1, substr($0, index($0,$2))}'
      ;;

    refresh)
      if [ ! -f "$conf" ]; then
        echo "rag: $conf not found" >&2
        return 1
      fi
      _rag_preflight 1 1 || return 1
      local only="${1:-}"
      local line name paths
      local refreshed=0
      while IFS= read -r line; do
        # strip comments and blank lines
        line="${line%%#*}"
        [[ -z "${line// }" ]] && continue
        name="${line%%:*}"
        paths="${line#*:}"
        name="${name// /}"
        [ -z "$name" ] && continue
        if [ -n "$only" ] && [ "$only" != "$name" ]; then
          continue
        fi
        echo "→ refresh '$name'"
        # Smart incremental sync: skip unchanged files, delete orphans,
        # LLM-generated summaries for new/changed files only.
        # Capture stderr to a tmp file (via tee so it stays visible live) so
        # that on failure we can surface the actual cause instead of just
        # printing 'failed' and losing the message in the scroll-back.
        local err_log
        err_log="$(mktemp -t rag-refresh-XXXXXX)"
        if ! eval "python3 '$scripts_dir/rag-ingest.py' --collection '$name' --sync --llm-summary $paths" 2> >(tee "$err_log" >&2); then
          echo "rag refresh: '$name' failed — last 20 stderr lines:" >&2
          echo "─────────────────────────────────────────────────" >&2
          tail -20 "$err_log" >&2
          echo "─────────────────────────────────────────────────" >&2
        fi
        rm -f "$err_log"
        refreshed=$((refreshed + 1))
      done < <(cat "$conf" "$conf_private" 2>/dev/null)
      if [ -n "$only" ] && [ "$refreshed" -eq 0 ]; then
        echo "rag refresh: collection '$only' not in $conf (or $conf_private)" >&2
        return 1
      fi
      ;;

    list|ls)
      curl -sS "$qdrant_url/collections" | jq -r '.result.collections[].name' | sort
      ;;

    drop|rm|delete)
      local name="${1:-}"
      if [ -z "$name" ]; then
        echo "rag drop: collection name required" >&2
        return 1
      fi
      printf 'Delete Qdrant collection "%s"? [y/N] ' "$name"
      local reply
      if ! read -r reply; then
        echo
        return 1
      fi
      case "$reply" in
        y|Y|yes|YES) ;;
        *) echo "cancelled"; return 1 ;;
      esac
      curl -sS -X DELETE "$qdrant_url/collections/$name" | jq .
      ;;

    help|-h|--help|"")
      local self="${(%):-%x}"
      if [ -n "$self" ] && [ -f "$self" ]; then
        sed -n '1,/^rag() {$/p' "$self" | sed '/^rag() {$/d; s/^# \{0,1\}//'
      else
        echo "rag: ingest|ask|context|info|refresh|list|drop|help"
      fi
      ;;

    *)
      echo "rag: unknown command '$cmd'. Try 'rag help'." >&2
      return 1
      ;;
  esac
}

# ---- zsh completion ----

_rag() {
  local -a subcommands
  subcommands=(
    'ingest:index files/dirs into Qdrant'
    'ask:retrieve context and answer via LiteLLM'
    'context:retrieve only, no LLM (pipe to pbcopy)'
    'info:show collection stats and indexed files'
    'refresh:re-ingest collections from rag.conf'
    'list:list Qdrant collections'
    'drop:delete a collection'
    'status:show health of LiteLLM and Qdrant'
    'eval:run canonical questions for regression check'
    'improve:autonomous loop: propose new cases, validate, grow corpus'
    'prune-gaps:drop gap entries that retrieval now closes'
    'help:show help'
  )

  _rag_collections() {
    local qdrant_url="${QDRANT_URL:-http://localhost:6333}"
    local -a names
    names=(${(f)"$(curl -sS --max-time 2 "$qdrant_url/collections" 2>/dev/null | jq -r '.result.collections[].name' 2>/dev/null)"})
    compadd -a names
  }

  _rag_conf_collections() {
    local conf="$HOME/projects/dotfiles/rag/rag.conf"
    local conf_private="$HOME/projects/dotfiles/rag/rag.private.conf"
    local -a names
    names=(${(f)"$(cat "$conf" "$conf_private" 2>/dev/null | sed 's/#.*//' | awk -F: 'NF>1 && $1 !~ /^[[:space:]]*$/ {gsub(/^[[:space:]]+|[[:space:]]+$/,"",$1); print $1}')"})
    compadd -a names
  }

  if (( CURRENT == 2 )); then
    _describe 'rag subcommand' subcommands
    return
  fi

  local sub="${words[2]}"
  case "$sub" in
    ingest)
      _arguments \
        '--collection[target collection]:collection:_rag_collections' \
        '--chunk-size[characters per chunk]:chars' \
        '--chunk-overlap[overlap characters]:chars' \
        '--batch-size[embedding batch size]:n' \
        '--extensions[allowed extensions, CSV]:ext' \
        '--source[payload.source label]:label' \
        '--max-files[stop after N files]:n' \
        '*:path:_files'
      ;;
    ask|context)
      _arguments \
        '--collection[source collection]:collection:_rag_collections' \
        '--top-k[retrieved chunks]:n' \
        '--model[chat model alias]:model:(coder nemotron gpt glm vision groq-llama groq-gpt-oss nvidia-nemotron nvidia-kimi nvidia-deepseek polza-gpt4o polza-claude)' \
        '-m[chat model alias]:model:(coder nemotron gpt glm vision groq-llama groq-gpt-oss nvidia-nemotron nvidia-kimi nvidia-deepseek polza-gpt4o polza-claude)' \
        '--mode[search mode]:mode:(vector fts hybrid)' \
        '--show-context[print retrieved chunks]' \
        '--json[print raw JSON response]' \
        '*:question'
      ;;
    info|drop|rm|delete)
      _rag_collections
      ;;
    refresh)
      _rag_conf_collections
      ;;
    eval)
      _arguments \
        '--verbose[show retrieved paths on failures]' \
        '*:eval-file:_files -g "*.json"'
      ;;
    improve)
      _arguments \
        '--collection[target collection]:collection:_rag_collections' \
        '--files-per-run[N files sampled per run]:n' \
        '--cases-per-file[N proposals per file]:n' \
        '--chat-model[chat model alias]:model:(coder reasoning fast gpt nemotron glm)' \
        '--top-k[retrieval depth]:n' \
        '--revisit-sample[revisit N old auto cases]:n' \
        '--dry-run[propose/judge but do not write]' \
        '--no-revisit[skip strike-check of old cases]' \
        '--no-git[disable git-based sampling]' \
        '--no-final-eval[skip full-eval sweep]' \
        '--no-prune-gaps[skip gap-prune phase]'
      ;;
    prune-gaps)
      _arguments \
        '--collection[target collection]:collection:_rag_collections' \
        '--top-k[retrieval depth]:n' \
        '--legacy[also process rag/rag-gaps.md]' \
        '--dry-run[report only, write nothing]'
      ;;
  esac
}

if [[ -n "$ZSH_VERSION" ]] && whence compdef >/dev/null 2>&1; then
  compdef _rag rag
fi
