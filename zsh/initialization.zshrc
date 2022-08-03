# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# BASH FIX
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="/usr/local/sbin:$PATH"

export PATH="/usr/local/share/dotnet/x64:$PATH"
# Add .NET Core SDK tools
export PATH="$PATH:/Users/vkonovalov/.dotnet/tools"

export TERM="xterm-256color"
export EDITOR='nano'
export ZSH="/Users/servitola/.oh-my-zsh"

# ANDROID
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"

# unknow now (not used on Spotware)
export PATH="/usr/local/opt/sqlite/bin:$PATH"