# BASH FIX
export PATH=$PATH:~/bin:/usr/local/bin
export PATH=$PATH:/usr/local/sbin

export PATH=$PATH:/usr/local/share/dotnet/x64
# Add .NET Core SDK tools
export PATH="$PATH:~/.dotnet/tools"

export TERM="xterm-256color"
export EDITOR='nano'
export ZSH="/Users/servitola/.oh-my-zsh"

# ANDROID
export ANDROID_HOME="~/Library/Android/sdk"
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin 
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/platform-tools

# unknow now
export PATH="$PATH:/usr/local/opt/sqlite/bin"

NPM_PACKAGES="~/.npm-packages"
export PATH="$PATH:$NPM_PACKAGES/bin"
# Preserve MANPATH if you already defined it somewhere in your config.
# Otherwise, fall back to `manpath` so we can inherit from `/etc/manpath`.
export MANPATH="${MANPATH-$(manpath)}:$NPM_PACKAGES/share/man"

