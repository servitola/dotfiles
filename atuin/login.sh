#!/bin/zsh
# Logs this Mac in to atuin sync. Install step 7 and up call it when no login
# is in place; it is interactive (username, password, the encryption key from
# another Mac). atuin 18 has no `account status`, so the session file is the
# sign of a login.
set -e
[[ -f $HOME/.local/share/atuin/session ]] && exit 0
atuin login
atuin sync
