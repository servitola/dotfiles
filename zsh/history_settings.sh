# History
HISTFILE=~/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt EXTENDED_HISTORY       # save timestamp + duration
setopt HIST_IGNORE_ALL_DUPS   # remove old duplicate when new one added
setopt HIST_SAVE_NO_DUPS      # don't write duplicates to file
setopt HIST_IGNORE_SPACE      # space-prefix commands not saved (secrets)
setopt HIST_REDUCE_BLANKS     # strip extra whitespace
setopt HIST_VERIFY            # expand !! before executing
setopt NO_HIST_BEEP

# Atuin manages cross-session sync via SQLite.
# SHARE_HISTORY and INC_APPEND_HISTORY* break atuin's preexec hook —
# commands get recorded with empty text, which is why search returns blank results.
unsetopt SHARE_HISTORY
unsetopt INC_APPEND_HISTORY
unsetopt INC_APPEND_HISTORY_TIME
