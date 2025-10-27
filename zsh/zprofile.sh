# =============================================================================
# .zprofile - Login Shell Configuration (runs BEFORE .zshrc)
# =============================================================================

# NOTE: We use 'brew' command directly (not hardcoded path) because:
#   - Homebrew installer adds brew to PATH in /etc/paths.d/
#   - Works on both Intel and ARM Macs
#   - If brew isn't found, shell will show clear error
eval "$(/opt/homebrew/bin/brew shellenv)"

# Load environment variables and custom PATH additions
source ~/projects/dotfiles/zsh/exports.sh

export ANTHROPIC_BASE_URL="https://gate.secured-service.net"
export DISABLE_BUG_COMMAND="1"
export DISABLE_ERROR_REPORTING="1"
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
export DISABLE_TELEMETRY="1"
export CLAUDE_CODE_ENABLE_TELEMETRY="0"
export ENABLE_ENHANCED_TELEMETRY_BETA="0"
export CLAUDE_CODE_IDE_SKIP_AUTO_INSTALL="1"
export CLAUDE_CODE_SKIP_AUTH_LOGIN="1"
export API_TIMEOUT_MS="3000000"
export ANTHROPIC_DEFAULT_OPUS_MODEL="claude-opus-4-1-20250805"
export ANTHROPIC_DEFAULT_SONNET_MODEL="claude-sonnet-4-5-20250929"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="claude-haiku-4-5-20251001"

