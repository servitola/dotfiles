# PATH only. Sourced from zprofile.sh — runs AFTER macOS path_helper reorders PATH.
# Non-PATH env vars are in exports.sh (sourced from zshenv.sh).

typeset -U PATH path

# Homebrew — must be early to take priority over system binaries
eval "$(/opt/homebrew/bin/brew shellenv)"

# Local dev builds — shadow Homebrew formulae with local build of aoe agent (for testing)
path=( ~/projects/aoe/agent-of-empires/target/release $path )

# Node.js (Homebrew-managed)
path+=( /opt/homebrew/opt/node@22/bin )

# Python: Homebrew keeps unversioned python3/pip3 only in libexec/bin, and only
# python@3 (the current 3.x alias) survives upgrades. Prepended: /usr/bin has a 3.9.
path=( /opt/homebrew/opt/python@3/libexec/bin $path )

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

# The java binary resolves via the /usr/bin/java wrapper; bin/ is for the other tools.
path+=( "$JAVA_HOME/bin" )

# Android SDK (auto-detect latest installed versions)
path+=( "$ANDROID_HOME/cmdline-tools/$(ls "$ANDROID_HOME/cmdline-tools/" 2>/dev/null | sort -V | tail -1)/bin" )
path+=( "$ANDROID_HOME/emulator" )
path+=( "$ANDROID_HOME/build-tools/$(ls "$ANDROID_HOME/build-tools/" 2>/dev/null | sort -V | tail -1)" )
path+=( "$ANDROID_HOME/platform-tools" )

# NPM global packages
path+=( "$NPM_GLOBAL/bin" )

# Rust/Cargo
path+=( "$HOME/.cargo/bin" )

# Dotfiles-shipped tools (rag wrapper, etc.)
path+=( "$HOME/projects/dotfiles/zsh/bin" )
