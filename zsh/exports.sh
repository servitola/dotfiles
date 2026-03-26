# =============================================================================
# Environment Variables Configuration (non-PATH)
# Sourced from zshenv.sh — runs for ALL shell types (scripts, interactive, login)
# PATH is set in zprofile.sh (after macOS path_helper reorders it)
# =============================================================================

# Guard: skip if already loaded
[[ -n "$_EXPORTS_LOADED" ]] && return 0
export _EXPORTS_LOADED=1

export EDITOR='code'
export ZSH=~/.oh-my-zsh

# Locale
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Homebrew environment variables (constants on Apple Silicon)
# PATH is properly set via brew shellenv in exports-path.sh/zprofile.sh
export HOMEBREW_PREFIX="/opt/homebrew"
export HOMEBREW_CELLAR="/opt/homebrew/Cellar"
export HOMEBREW_REPOSITORY="/opt/homebrew"
export HOMEBREW_AUTO_UPDATE_SECS="86400"
export HOMEBREW_NO_ANALYTICS=1

# Homebrew completions
export FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"

# Source keys
if [ -f ~/.config/openai_key.sh ]; then
    source ~/.config/openai_key.sh
else
    echo "\033[31mError: API key file not found at ~/.config/openai_key\033[0m"
fi

# Go
export GOPATH="$HOME/go"

# .NET SDK
export DOTNET_ROOT=/usr/local/share/dotnet

# Java & Android Development — ARM64 Homebrew JDK 21
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
export ANDROID_HOME=~/Library/Android/sdk

# Docker (via OrbStack)
export DOCKER_HOST=unix://$HOME/.orbstack/run/docker.sock

# Node.js & NPM Configuration
export NPM_GLOBAL=~/.npm-global
export NODE_PATH="$NPM_GLOBAL/lib/node_modules"

# Claude Code
export CLAUDE_CODE_USE_BEDROCK=0
export CLAUDE_CODE_ENABLE_TELEMETRY=0
export CLAUDE_MODEL="claude-opus-4-6"
export CLAUDE_SMALL_FAST_MODEL="claude-haiku-4-5-20251001"

# Firefox: disable safe mode dialog (Hyper key sends Option, which triggers it)
export MOZ_DISABLE_SAFE_MODE_KEY=1
launchctl setenv MOZ_DISABLE_SAFE_MODE_KEY 1

# n8n Configuration
export N8N_USER_FOLDER="$HOME/projects/services/n8n"
