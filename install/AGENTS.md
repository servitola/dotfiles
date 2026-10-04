# install — the dotfiles installer (plain zsh)

- Steps run in file-name order. `17-shortcuts.sh` comes late because it needs Homebrew python and the installed apps; `18-spoons.sh` comes last and starts Hammerspoon, whose config needs those Spoons
- Each step sources `lib.sh` first, so any one runs standalone for debugging
- zsh gotcha: an unmatched glob is fatal and aborts
