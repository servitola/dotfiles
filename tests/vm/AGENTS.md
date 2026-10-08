# tests/vm — fresh-Mac integration test of `make` and `up`

- `run.sh` runs from the main Mac and drives tart on `$TART_HOST` over ssh. Each run clones `dotfiles-base` (APFS clone, instant), pushes the repo's **committed HEAD** as a git bundle (uncommitted edits are not tested), runs the stages, saves one log per stage under `~/.local/state/dotfiles/vm-test/<vm>/`, then deletes the clone. `--keep` leaves it running and prints the ssh line.
- `dotfiles-base` is baked once from `ghcr.io/cirruslabs/macos-tahoe-base` (same major macOS as the main Mac): both machines' ssh keys authorized for `admin`, disk grown to 100 GB. Delete it on the host to re-bake, e.g. after a new image.
- The guest is reachable only through the host (`ssh -J`): tart's NAT network lives on the host.
- Apple's license lets a host run two macOS VMs at once; a run fails to boot when two other VMs are already up there.
