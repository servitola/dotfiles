#!/bin/zsh
# Rejects AI co-author footers in every repo on this Mac (git/AGENTS.md).
source "${0:a:h}/lib.sh"
set -euo pipefail

section "init.templateDir -> git/hooks/template (new repos get the hook for free)"
if [[ $(git config --global init.templateDir || true) == "$DOTFILES/git/hooks/template" ]]; then
    log "already set"
else
    git config --global init.templateDir "$DOTFILES/git/hooks/template"
    ok "init.templateDir set"
fi

section "backfill: existing repos under ~/projects don't get the template retroactively"
"$DOTFILES/git/hooks/backfill.sh"
