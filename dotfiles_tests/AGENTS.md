# dotfiles_tests — a new user's Mac, from scratch, in a VM

`run.sh` takes a clean macOS VM, puts these dotfiles on it and runs what a new
user would: `make`, then `install/check.sh`, `brew doctor` and `up`. Green means
the repository installs on an empty Mac and keeps it updated.

```
dotfiles_tests/run.sh                 # all four stages, then the VM is deleted
dotfiles_tests/run.sh --keep          # leave the VM up and print its ssh line
dotfiles_tests/run.sh make check      # only some stages
```

A full run takes ~30 min (the whole brewfile installs). Logs, one per stage:
`~/.local/state/dotfiles/vm-test/<vm>/`.

## Files

| File | What it is |
|---|---|
| `run.sh` | The test: stages, their commands and time limits, the order of a run |
| `vm.sh` | Tart plumbing: base image, throwaway clone, ssh, copying repositories in |
| `fresh_mac.sh` | Runs inside the VM before `make`: makes the CI image look like a new user's Mac |

## How a run goes

1. On `$TART_HOST` (m1pro), clone `dotfiles-base` into `dotfiles-test-<time>`. The clone is an APFS copy and takes seconds.
2. Copy in the committed HEAD of dotfiles, `$DIR_SKILLS` and `$DIR_CRON` as git bundles. Uncommitted edits are not tested; the VM cannot reach Gitea.
3. `fresh_mac.sh`: `DOCKER=no`, the official Telegram, a short skip list for the brewfile, the image's own extras removed.
4. The stages, each with a time limit. A failed `make` stops the run.

## Changing it

- **A stage**: one line in `command` and one in `minutes` in `run.sh`.
- **What a new user's Mac looks like**: `fresh_mac.sh`. A brewfile entry goes on its skip list only with the reason next to it, and leaves as soon as the reason does.
- **A new macOS**: change `IMAGE` in `vm.sh` and delete `dotfiles-base` on the host (`ssh m1pro tart delete dotfiles-base`); the next run bakes a new one.

## Why it is this way

- **The host does the work.** Tart's VM network is private to `$TART_HOST`, so every ssh hop goes through it (`-J`).
- **`dotfiles-base`** is baked once from `IMAGE`: our ssh keys in (the image only knows admin/admin) and the disk grown to 100 GB (the image has ~7 GB free).
- **Shared download cache.** Homebrew downloads (~11 GB) live on the host in `~/.cache/tart-homebrew` and reach the VM through `tart run --dir`, for `make` only: `up` begins by deleting its cache.
- **`DOCKER=no`**: M1/M2 have no nested virtualization, so no Docker daemon runs in a VM. The stacks are checked by `install/check.sh` on the real Macs.
- **Official Telegram**: the owner's Forkgram releases are private, so the run installs as anyone else would.
- **App Store apps** are skipped: nobody can sign in to the App Store in the VM, and without a terminal `make` leaves them out.
- **Time limits**: a dialog nobody sees blocks forever (Gatekeeper once held a run for 4.5 h).
- **Two VMs at most**: Apple's license lets a host run two macOS VMs at once; a third does not boot.
