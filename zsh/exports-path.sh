# PATH only. Sourced from zprofile.sh — runs AFTER macOS path_helper reorders PATH.
# Non-PATH env vars are in exports.sh (sourced from zshenv.sh).

typeset -U PATH path

# System /usr/local — in login shells these arrive via macOS `path_helper`
# (/etc/zprofile), but non-login `zsh -c` invocations (launchd services like
# the serho bot, cron jobs) skip /etc/zprofile, so path_helper never runs and
# /usr/local/{bin,sbin} silently drop out. Add them explicitly here — this
# file is sourced from ~/.zshenv too — so tools installed to /usr/local/bin
# (e.g. the voiceink CLI) stay visible to those processes. (2026-07-14)
path=( /usr/local/bin /usr/local/sbin $path )

# Must be early to take priority over system binaries.
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
