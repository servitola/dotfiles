# ai — non-interactive prompt to LiteLLM (free models across OpenRouter/Groq/NVIDIA/GitHub)
#
# Usage:
#   ai "single-prompt question"
#   ai -m coder "write a regex for email"
#   ai -m nemotron "explain the CAP theorem"
#   cat file.py | ai "review this code"
#   ai -f screenshot.png "what's in this image"
#
# Flags:
#   -m, --model   model alias from config.yaml. Direct: coder | nemotron | gpt | glm | vision | embed.
#                 Rotation groups: auto (default → coding) | coding | reasoning | fast.
#                 Provider-specific: groq-llama | groq-gpt-oss | groq-compound |
#                                    nvidia-nemotron | nvidia-nemotron-120b | nvidia-kimi | nvidia-deepseek |
#                                    github-gpt4o-mini | github-deepseek-r1.
#   -t, --tokens  max_tokens (default 1500)
#   -s, --system  system prompt
#   -f, --file    image file (png/jpg/gif/webp) — auto-selects vision model
#   -j, --json    raw JSON response instead of plain text
#   -h, --help    show help
#
# Reads stdin if piped and appends to the user prompt as context.
# Requires: jq, curl, LiteLLM container on http://localhost:4000.

ai() {
  local model="auto"
  local max_tokens=1500
  local system=""
  local raw_json=0
  local prompt=""
  local image_file=""
  local model_overridden=0

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -m|--model)
        # All aliases resolve against config.yaml's model_list / model_group_alias.
        # Passing an unknown name returns HTTP 400 from LiteLLM — use `curl
        # http://localhost:4000/v1/models` to list valid names.
        model="$2"
        model_overridden=1
        shift 2 ;;
      -t|--tokens)  max_tokens="$2"; shift 2 ;;
      -s|--system)  system="$2"; shift 2 ;;
      -f|--file)    image_file="$2"; shift 2 ;;
      -j|--json)    raw_json=1; shift ;;
      -h|--help)
        sed -n '2,20p' "${(%):-%x}" 2>/dev/null || grep -E '^# ' "$0" | head -20
        return 0 ;;
      *)
        prompt="${prompt:+$prompt }$1"; shift ;;
    esac
  done

  # Append stdin if piped
  if [ ! -t 0 ]; then
    local stdin_content
    stdin_content="$(cat)"
    if [ -n "$stdin_content" ]; then
      prompt="${prompt}"$'\n\n'"${stdin_content}"
    fi
  fi

  if [ -z "$prompt" ] && [ -z "$image_file" ]; then
    echo "ai: empty prompt. Usage: ai [-m model] [-t tokens] [-s system] [-f image] \"question\"" >&2
    return 1
  fi

  # Auto-select vision model for image files (unless user chose a model)
  if [ -n "$image_file" ] && [ $model_overridden -eq 0 ]; then
    model="vision"
  fi

  # Default prompt for images without explicit text
  if [ -n "$image_file" ] && [ -z "$prompt" ]; then
    prompt="Describe what you see on this image."
  fi

  # Build messages array with jq to handle quoting safely
  local body
  if [ -n "$image_file" ]; then
    # Validate file
    if [ ! -f "$image_file" ]; then
      echo "ai: file not found: $image_file" >&2
      return 1
    fi
    local ext="${image_file##*.}"
    ext="${ext:l}"  # lowercase (zsh)
    local mime="image/png"
    case "$ext" in
      jpg|jpeg) mime="image/jpeg" ;;
      gif) mime="image/gif" ;;
      webp) mime="image/webp" ;;
    esac

    # Write base64 to temp file — screenshots can be several MB,
    # too large for jq --arg (shell ARG_MAX / jq memory limits).
    local b64_file="/tmp/_ai_b64.tmp"
    base64 -i "$image_file" | tr -d '\n' > "$b64_file"

    # Vision message: use --rawfile to read base64 from file
    if [ -n "$system" ]; then
      body=$(jq -n \
        --arg m "$model" \
        --arg s "$system" \
        --arg u "$prompt" \
        --arg mime "$mime" \
        --rawfile b64data "$b64_file" \
        --argjson t "$max_tokens" \
        '{model:$m, max_tokens:$t, messages:[
          {role:"system",content:$s},
          {role:"user",content:[
            {type:"text",text:$u},
            {type:"image_url",image_url:{url:("data:" + $mime + ";base64," + ($b64data | rtrimstr("\n")))}}
          ]}
        ]}')
    else
      body=$(jq -n \
        --arg m "$model" \
        --arg u "$prompt" \
        --arg mime "$mime" \
        --rawfile b64data "$b64_file" \
        --argjson t "$max_tokens" \
        '{model:$m, max_tokens:$t, messages:[
          {role:"user",content:[
            {type:"text",text:$u},
            {type:"image_url",image_url:{url:("data:" + $mime + ";base64," + ($b64data | rtrimstr("\n")))}}
          ]}
        ]}')
    fi
    rm -f "$b64_file"
  elif [ -n "$system" ]; then
    body=$(jq -n \
      --arg m "$model" \
      --arg s "$system" \
      --arg u "$prompt" \
      --argjson t "$max_tokens" \
      '{model:$m, max_tokens:$t, messages:[{role:"system",content:$s},{role:"user",content:$u}]}')
  else
    body=$(jq -n \
      --arg m "$model" \
      --arg u "$prompt" \
      --argjson t "$max_tokens" \
      '{model:$m, max_tokens:$t, messages:[{role:"user",content:$u}]}')
  fi

  local response
  response=$(curl -sS http://localhost:4000/v1/chat/completions \
    -H "Authorization: Bearer ${LITELLM_MASTER_KEY:-sk-local-workbot}" \
    -H "Content-Type: application/json" \
    -d "$body")

  # Use printf — zsh's echo interprets \n inside JSON strings as real newlines,
  # corrupting the response before jq parses it.
  if [ $raw_json -eq 1 ]; then
    printf '%s' "$response" | jq .
    return 0
  fi

  # Extract content; fall back to error message
  local content
  content=$(printf '%s' "$response" | jq -r '.choices[0].message.content // .error.message // "ai: no content"')
  printf '%s\n' "$content"
}
