plugins=(
  aliases # run 'acs' to see all aliases
  common-aliases # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/common-aliases
  macos # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/macos
  sudo # press 'esc' twice to run sudo
  Colored-man-pages # colors
  dirhistory
  last-working-dir # automatically jumps into last used working directory
  zsh-navigation-tools # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/zsh-navigation-tools
  ohmyzsh-full-autoupdate  # updates oh-my-zsh plugins
  web-search # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/web-search
  zoxide
  fzf
  z
  git            # Core git integration
)

# Defer loading of non-critical plugins
zsh-defer source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
zsh-defer source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
zsh-defer load-plugin dotenv        # Environment variables
zsh-defer load-plugin npm           # npm completions
zsh-defer load-plugin pip           # pip completions
zsh-defer load-plugin python        # python utilities
zsh-defer load-plugin nx-completion # nx completions
