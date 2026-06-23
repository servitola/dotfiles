# npm — tracked global npm package list, installer, and global npmrc

- `global-packages.txt` is the source-of-truth list of global npm packages (one per line, `#` comments allowed). `install-globals.sh` rewrites it from the live `npm -g` state on every run, so it stays self-syncing.
- `install-globals.sh` installs missing packages and updates outdated ones to `@latest` (clears xattr quarantine before each install). Invoked by `make` and by `up`.
- `npmrc` is symlinked to `~/.npmrc` by the Makefile. It sets `prefix=~/.npm-global` (global installs land there, off the system Node), `fund=false`, and `min-release-age=7` (skip releases newer than 7 days).
- Relation to `macos_update/`: the `up` command (`macos_update/update_all.sh`) sources `install-globals.sh` to refresh globals during a full system update.

```bash
source ~/projects/dotfiles/npm/install-globals.sh
```
