plugins=(
  git            # Core git integration

)

#   fzf            # Fuzzy finder

# Defer loading of non-critical plugins
# zsh-defer source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
# zsh-defer source ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
# zsh-defer load-plugin dotenv        # Environment variables
# zsh-defer load-plugin npm           # npm completions
# zsh-defer load-plugin pip           # pip completions
# zsh-defer load-plugin python        # python utilities
# zsh-defer load-plugin nx-completion # nx completions
# zsh-defer load-plugin aliases         # alias management
# zsh-defer load-plugin common-aliases  # common aliases
# zsh-defer load-plugin macos           # macOS specific features
# # zsh-defer load-plugin sudo            # ESC ESC to add sudo
# zsh-defer load-plugin colored-man-pages # colored man pages
# zsh-defer load-plugin dirhistory      # directory navigation
# zsh-defer load-plugin last-working-dir # restore last directory
# zsh-defer load-plugin web-search      # web search from terminal
# zsh-defer load-plugin ohmyzsh-full-autoupdate  # updates oh-my-zsh plugins
# zsh-defer load-plugin zsh-navigation-tools # https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/zsh-navigation-tools
# # Define the plugin loading function
# function load-plugin() {
#   local plugin=$1
#   if [[ -f $ZSH/plugins/$plugin/$plugin.plugin.zsh ]]; then
#     source $ZSH/plugins/$plugin/$plugin.plugin.zsh
#   elif [[ -f $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh ]]; then
#     source $ZSH_CUSTOM/plugins/$plugin/$plugin.plugin.zsh
#   fi
# }
