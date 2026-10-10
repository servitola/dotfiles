#!/bin/zsh
source "${0:a:h}/lib.sh"
set -euo pipefail

section "/etc/hosts"
link "$DOTFILES/macos/hosts" /etc/hosts
