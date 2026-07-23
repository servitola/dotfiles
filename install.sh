#!/bin/zsh
#
# Dotfiles installer (run by `make` and CI). Runs the numbered steps in
# install/ in order, aborting on the first failure. `ls install/` = the whole
# installation as a list, 01 to 15. Each step runs in its own subshell, and
# everything is also written to a timestamped logfile.
cd "$HOME/projects/dotfiles" || exit 1
source install/lib.sh
log_init
log "logging to $LOGFILE"

steps=(install/[0-9]*.sh)
total=$#steps
index=0
started=$SECONDS

for step in $steps; do
    index=$(( index + 1 ))
    name=${step:t:r}; name=${name#[0-9][0-9]-}     # 07-config-links.sh -> config-links
    step_begin $index $total "$name"
    step_started=$SECONDS
    if zsh "$step"; then
        step_ok $(( SECONDS - step_started ))
    else
        step_fail "$name"
        err "see $LOGFILE"
        exit 1
    fi
done

print -r -- ""
print -r -- "${_green}${_bold}✓ Installation complete${_reset} ${_dim}($(( SECONDS - started ))s · $LOGFILE)${_reset}"
zsh zsh/bin/random_ascii.sh
