# npm — tracked global npm package list, installer, and global npmrc

- `global-packages.txt` is the source-of-truth list of global npm packages, one per line.
- `install-globals.sh` installs missing packages, moves unpinned ones to the newest version that `min-release-age` allows (never down: a newer version installed by hand stays)

```bash
source ~/projects/dotfiles/npm/install-globals.sh
```
