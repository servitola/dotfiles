export TERM="xterm-256color"
export EDITOR='code'
export ZSH=~/.oh-my-zsh

# BASH
export PATH=$PATH:~/bin
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/local/sbin
export PATH=$PATH:/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources

# HOMEBREW
export PATH=$PATH:/opt/homebrew/bin/brew

# DOTNET
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT
export PATH=$PATH:$DOTNET_ROOT/tools
export PATH=$PATH:/usr/local/share/dotnet/x64
export PATH=$PATH:/usr/local/opt/sqlite/bin

# JAVA & ANDROID
export JAVA_HOME=/Library/Java/JavaVirtualMachines/microsoft-11.jdk/Contents/Home
export PATH=$PATH:$JAVA_HOME

export ANDROID_SDK=~/Library/Android/sdk
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# NPM
export NODE_PATH=/usr/local/Cellar/node/node_global
export NPM_PACKAGES=~/.npm-packages
export PATH="$PATH:$NODE_PATH/bin"
export PATH="$PATH:$NPM_PACKAGES/bin"
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"
