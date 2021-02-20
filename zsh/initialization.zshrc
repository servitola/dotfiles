# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# BASH FIX
export PATH=$HOME/bin:/usr/local/bin:$PATH
export PATH="/usr/local/sbin:$PATH"

export TERM="xterm-256color"
export EDITOR='nano'
export ZSH="/Users/servitola/.oh-my-zsh"