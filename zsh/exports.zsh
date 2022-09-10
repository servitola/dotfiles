

export TERM="xterm-256color"
export EDITOR='nano'
export ZSH=~/.oh-my-zsh

# BASH
export PATH=$PATH:~/bin
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/local/sbin

export PATH=$PATH:/usr/local/share/dotnet/x64
export PATH=$PATH:~/.dotnet/tools
export PATH=$PATH:/usr/local/opt/sqlite/bin


# ANDROID
export ANDROID_HOME=~/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# NPM
NPM_PACKAGES="~/.npm-packages"
export PATH="$PATH:$NPM_PACKAGES/bin"
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"

#export PATH=$PATH:/Library/Java/JavaVirtualMachines/microsoft-11.jdk