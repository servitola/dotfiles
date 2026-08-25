#!/bin/zsh
# Every <app>/render.zsh in the repo writes that app's config from constants.env.
# Run by `const sync`, install/07-config-links.sh and macos_update/update_all.sh.
set -euo pipefail

print "rendered from constants.env:"
for renderer in ~/projects/dotfiles/*/render.zsh; do
    zsh "$renderer"
done
