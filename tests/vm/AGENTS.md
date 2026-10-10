# tests/vm — fresh-Mac integration test of `make` and `up`

- `run.sh` runs from the main Mac and drives tart on `$TART_HOST` over ssh. Each run clones `dotfiles-base` (APFS clone, instant), pushes the **committed HEAD** of dotfiles, `$DIR_SKILLS` and `$DIR_CRON` as git bundles (the VM cannot reach Gitea; uncommitted edits are not tested), runs the stages, saves one log per stage under `~/.local/state/dotfiles/vm-test/<vm>/`, then deletes the clone. `--keep` leaves it running and prints the ssh line.
- `dotfiles-base` is baked once from `ghcr.io/cirruslabs/macos-tahoe-base` (same major macOS as the main Mac): both machines' ssh keys authorized for `admin`, disk grown to 100 GB. Delete it on the host to re-bake, e.g. after a new image.
- The guest is reachable only through the host (`ssh -J`): tart's NAT network lives on the host.
- `make` installs the whole brewfile, so a run is long. Homebrew downloads go to `~/.cache/tart-homebrew` on the host, shared into the VM (`tart run --dir`) as `HOMEBREW_CACHE` for `make` only (`up` wipes its cache); later runs reuse them. Without a terminal step 3 leaves the mas apps out (nobody can sign in to the App Store there).
- Stages: `make`, `check` (install/check.sh), `doctor` (`brew doctor` must be clean on a fresh install), `up`. A failed `make` stops the run.
- The clone's `constants.env` gets `DOCKER=no` (read by `docker/up.sh` and `install/check.sh`): M1/M2 have no nested virtualization, so no Docker daemon can run in the VM and the stacks go untested.
- A short list in `run.sh` drops brewfile entries the VM cannot install for reasons a real Mac does not share (`idb-companion` needs a full Xcode, i.e. an Apple ID). Add to it only with such a reason next to the line.
- Apple's license lets a host run two macOS VMs at once; a run fails to boot when two other VMs are already up there.
