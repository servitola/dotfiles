export TERM='xterm-256color'
export EDITOR='code'
export ZSH=~/.oh-my-zsh
export PATH=""

# Bash
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/local/sbin
export PATH=$PATH:/bin
export PATH=$PATH:/usr/bin
export PATH=$PATH:/usr/sbin
export PATH=$PATH:/Library/Frameworks/Mono.framework/Versions/Current/Commands
export PATH=$PATH:/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources

# HomeBrew
export PATH=$PATH:/opt/homebrew/bin # M1
export PATH=$PATH:/usr/local/Homebrew/bin # Intel

# DotNet
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT
export PATH=$PATH:$DOTNET_ROOT/tools
export PATH=$PATH:/usr/local/opt/sqlite/bin
# export PATH=$PATH:/usr/local/share/dotnet
# export PATH=$PATH:/usr/local/share/dotnet/x64

# JetBrains
export PATH=$PATH:~/Library/Application\ Support/JetBrains/Toolbox/scripts

# Java & Android for Xamarin
export JAVA_HOME=/Library/Java/JavaVirtualMachines/microsoft-11.jdk/Contents/Home
export PATH=$PATH:$JAVA_HOME

export ANDROID_SDK=~/Library/Android/sdk
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# NPM
export NODE_PATH=~/.npm-global/bin
export NPM_PACKAGES=~/.npm-packages
export PATH="$PATH:$NODE_PATH/bin"
export PATH="$PATH:$NPM_PACKAGES/bin"
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"
