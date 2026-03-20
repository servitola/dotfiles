# =============================================================================
# PATH Configuration
# Sourced from zprofile.sh — runs AFTER macOS path_helper reorders PATH
# Non-PATH env vars are in exports.sh (sourced from zshenv.sh)
# =============================================================================

# Deduplicate PATH entries (zsh built-in)
typeset -U PATH path

# Homebrew — must be early to take priority over system binaries
eval "$(/opt/homebrew/bin/brew shellenv)"

# Local dev builds — shadow Homebrew formulae with local build of aoe agent (for testing)
path=( ~/projects/aoe/agent-of-empires/target/release $path )

# Node.js (Homebrew-managed)
path+=( /opt/homebrew/opt/node@22/bin )

# Python (Homebrew-managed, 3.12 as default)
path+=( /opt/homebrew/opt/python@3.12/libexec/bin )

# Go
path+=( "$GOPATH/bin" )

# Local binaries
path+=( ~/.local/bin )

# DotNet
path+=( "$DOTNET_ROOT" "$HOME/.dotnet/tools" )

# SQLite (Homebrew, works on both Apple Silicon and Intel)
path+=( "$HOMEBREW_PREFIX/opt/sqlite/bin" )

# JetBrains Toolbox Scripts
path+=( ~/Library/Application\ Support/JetBrains/Toolbox/scripts )

# Java (java binary found via /usr/bin/java wrapper, but add bin/ for other tools)
path+=( "$JAVA_HOME/bin" )

# Android SDK
path+=( "$ANDROID_HOME/cmdline-tools/16.0/bin" )
path+=( "$ANDROID_HOME/emulator" )
path+=( "$ANDROID_HOME/build-tools/35.0.1" )
path+=( "$ANDROID_HOME/platform-tools" )

# NPM global packages
path+=( "$NPM_GLOBAL/bin" )

# Rust/Cargo
path+=( "$HOME/.cargo/bin" )

# System extras
path+=( /Library/Frameworks/Mono.framework/Versions/Current/Commands )
