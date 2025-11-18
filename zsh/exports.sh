# =============================================================================
# Environment Variables Configuration
# =============================================================================

export TERM='xterm-256color'
export EDITOR='code'
export ZSH=~/.oh-my-zsh

# Homebrew completions
export FPATH="$HOMEBREW_PREFIX/share/zsh/site-functions:$FPATH"

# System Paths
export PATH=$PATH:~/.local/bin
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/local/sbin
export PATH=$PATH:/bin
export PATH=$PATH:/sbin
export PATH=$PATH:/usr/bin
export PATH=$PATH:/usr/sbin
export PATH=$PATH:/Library/Frameworks/Mono.framework/Versions/Current/Commands
export PATH=$PATH:/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources
export SDKROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator.sdk
export PATH=$PATH:/Users/servitola/.local/bin

# DotNet Configuration
export DOTNET_ROOT=/usr/local/share/dotnet
export USER_DOTNET_ROOT=/usr/local/share/dotnet
export PATH=$PATH:$DOTNET_ROOT
export PATH=$PATH:$DOTNET_ROOT/tools
export PATH=$PATH:/Users/servitola/.dotnet/tools
export PATH=$PATH:/usr/local/opt/sqlite/bin

# JetBrains Toolbox Scripts
export PATH=$PATH:~/Library/Application\ Support/JetBrains/Toolbox/scripts

# Java & Android Development
export JAVA_HOME=/opt/homebrew/Cellar/openjdk@17/17.0.16
export PATH=$PATH:$JAVA_HOME

# Docker (via Colima)
export DOCKER_HOST=unix:///$HOME/.colima/docker.sock

# Android SDK Configuration
export ANDROID_SDK=~/Library/Android/sdk
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/16.0/bin
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/build-tools/35.0.1
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Node.js & NPM Configuration
export PATH="$PATH:/opt/homebrew/opt/node@22/bin"
export NODE_PATH=~/.npm-global/bin
export NPM_PACKAGES=~/.npm-packages
export PATH="$PATH:$NODE_PATH/bin"
export PATH="$PATH:$NODE_PATH"
export PATH="$PATH:$NPM_PACKAGES/bin"
export PATH="$PATH:$NPM_PACKAGES"
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"

# n8n Configuration
export N8N_USER_FOLDER="/Users/servitola/projects/services/n8n/.n8n"
