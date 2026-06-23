# eza — config for the `eza` modern `ls` replacement (Gruvbox Dark Hard colours)

- `theme.yml` — colour scheme for every eza element (filekinds, perms, size units, users, git status, file types). Gruvbox Dark Hard palette. This is the only config file here.
- The whole `eza/` dir is symlinked to `~/.config/eza` by the Makefile (`make install`, "setup eza symlinks" target). eza reads `theme.yml` from that dir.
- `zsh/exports.sh` sets `EZA_CONFIG_DIR=$HOME/.config/eza` — needed because macOS eza does not read `~/.config/eza` by default.
- `zsh/aliases.sh` wires the commands: `ls`/`l` → `eza --icons --group-directories-first --color=always`, and `e` → `eza`. These pick up the theme automatically via `EZA_CONFIG_DIR`.
- Invariant: symlink target + `EZA_CONFIG_DIR` + theme filename (`theme.yml`) must stay consistent — eza looks for exactly `theme.yml` inside the config dir.
