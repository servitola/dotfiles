#!/bin/zsh
# Step 16 — machine-wide git hook: reject AI co-author/tool footers in every
# commit message, in every repo. Mechanism and blind spots: git/AGENTS.md.
source "${0:a:h}/lib.sh"
set -euo pipefail

section "init.templateDir -> git/hooks/template (new repos get the hook for free)"
git config --global init.templateDir "$DOTFILES/git/hooks/template"
ok "init.templateDir set"

section "backfill: existing repos under ~/projects don't get the template retroactively"
"$DOTFILES/git/hooks/backfill.sh"
