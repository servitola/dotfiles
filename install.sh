#!/bin/zsh
# Installs the dotfiles: runs every numbered step in install/
cd "$HOME/projects/dotfiles" || exit 1
source install/lib.sh
start_logging

steps=(install/[0-9]*.sh)
number=0
for step in $steps; do
    number=$(( number + 1 ))
    run_step "$step" $number ${#steps} || exit 1
done

zsh install/check.sh || exit 1
finish
