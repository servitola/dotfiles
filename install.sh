#!/bin/zsh
cd "$HOME/projects/dotfiles"
source install/lib.sh
start_logging

# One password prompt for the whole run: sudo forgets it after 5 minutes, and
# the cask installers of a long brew bundle would stall on a prompt nobody sees.
sudo -v
while kill -0 $$ 2>/dev/null; do sudo -n true; sleep 50; done 2>/dev/null &

steps=(install/[0-9]*.sh)
number=0
for step in $steps; do
    number=$(( number + 1 ))
    run_step "$step" $number ${#steps} || exit 1
done

zsh install/check.sh || exit 1
finish
