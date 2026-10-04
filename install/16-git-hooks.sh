#!/bin/zsh
# Rejects AI co-author footers in every repo on this Mac (git/AGENTS.md).
source "${0:a:h}/lib.sh"
set -euo pipefail

section "init.templateDir -> git/hooks/template (new repos get the hook for free)"
git config --global init.templateDir "$DOTFILES/git/hooks/template"
ok "init.templateDir set"

section "backfill: existing repos under ~/projects don't get the template retroactively"
"$DOTFILES/git/hooks/backfill.sh"
