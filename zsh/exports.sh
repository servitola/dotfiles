export TERM='xterm-256color'
export EDITOR='code'
export ZSH=~/.oh-my-zsh
export PATH=""

# HomeBrew
export PATH=$PATH:/opt/homebrew/bin # M1
export PATH=$PATH:/opt/homebrew/sbin
export PATH=$PATH:/opt/homebrew/opt/ruby/bin #Ruby
export PATH=$PATH:/usr/local/Homebrew/bin # Intel

# Bash
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/local/sbin
export PATH=$PATH:/bin
export PATH=$PATH:/sbin
export PATH=$PATH:/usr/bin
export PATH=$PATH:/usr/sbin
export PATH=$PATH:/Library/Frameworks/Mono.framework/Versions/Current/Commands
export PATH=$PATH:/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources

# DotNet
#export DOTNET_ROOT=$HOME/.dotnet
export DOTNET_ROOT=/usr/local/share/dotnet
export PATH=$PATH:$DOTNET_ROOT
export PATH=$PATH:$DOTNET_ROOT/tools
export PATH=$PATH:/usr/local/opt/sqlite/bin
# export PATH=$PATH:/usr/local/share/dotnet
# export PATH=$PATH:/usr/local/share/dotnet/x64

# JetBrains
export PATH=$PATH:~/Library/Application\ Support/JetBrains/Toolbox/scripts

# Java & Android for Xamarin
#export JAVA_HOME=/Library/Java/JavaVirtualMachines/microsoft-11.jdk/Contents/Home
export JAVA_HOME=/Library/Java/JavaVirtualMachines/openlogic-openjdk-17.jdk/Contents/Home
export PATH=$PATH:$JAVA_HOME

export DOCKER_HOST=unix:///$HOME/.colima/docker.sock

export ANDROID_SDK=~/Library/Android/sdk
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/build-tools/34.0.0
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# NPM
export NODE_PATH=~/.npm-global/bin
export NPM_PACKAGES=~/.npm-packages
export PATH="$PATH:$NODE_PATH/bin"
export PATH="$PATH:$NODE_PATH"
export PATH="$PATH:$NPM_PACKAGES/bin"
export PATH="$PATH:$NPM_PACKAGES"
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"
