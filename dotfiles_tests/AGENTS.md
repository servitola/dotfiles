# dotfiles_tests — a new user's Mac, from scratch, in a VM

`run.sh` takes a clean macOS VM, puts these dotfiles on it and runs what a new
user would: `make` (twice), `install/check.sh`, `brew doctor`, a broken-symlink
sweep, a shell start, the hotkeys, and `up` (twice). Green means the repository
installs on an empty Mac, a second install changes nothing, the shell and the
hotkeys work, and `up` keeps it updated.

```
dotfiles_tests/run.sh                 # every stage, then the VM is deleted
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
| `checks.sh` | Runs inside the VM: the `remake`, `links` and `shell` stages |
| `hotkeys.sh` | Runs inside the VM: the `hotkeys` and `apps` stages, through `hs -c` |
| `hotkeys_live.lua` | `hotkeys`: every chord of the HotKeys layout tables is a bound hotkey |
| `hotkeys_apps.lua` | `apps`: every app chord, pressed, brings its app to the front |

## How a run goes

1. On `$TART_HOST` (m1pro), clone `dotfiles-base` into `dotfiles-test-<time>`. The clone is an APFS copy and takes seconds.
2. Copy in the committed HEAD of dotfiles, `$DIR_SKILLS` and `$DIR_CRON` as git bundles. Uncommitted edits are not tested; the VM cannot reach Gitea.
3. `fresh_mac.sh`: `constants.env` from `constants.example.env` as on any new Mac (official Telegram included), `DOCKER=no`, a short skip list for the brewfile, the image's own extras removed, Accessibility for Hammerspoon.
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
- **Official Telegram**: the example's `APP_TELEGRAM`; the owner's Forkgram releases are private.
- **App Store apps** are skipped: nobody can sign in to the App Store in the VM, and without a terminal `make` leaves them out.
- **Time limits**: a dialog nobody sees blocks forever (Gatekeeper once held a run for 4.5 h).
- **Hotkeys are tested after Karabiner.** Karabiner reads the real keyboard through its driver and never sees a key a program posts, and its driver needs a person's approval anyway. So `apps` posts what Karabiner would produce (`F17` for `⇪T`) and checks Hammerspoon's side; Karabiner itself is covered by `docs/keyboard/tools/lint.py`. Chords with `⇪` in the table are skipped: right-hand modifiers cannot be posted apart from left ones.
- **Accessibility through TCC.db**: SIP is off in the cirruslabs image, so `fresh_mac.sh` writes the grant a person would click; Hammerspoon cannot press keys without it.
- **F-keys and fn**: a real F13–F19 press carries the fn flag and the hotkey matches only with it; F20 matches only without it. Measured in the VM.
- **`remake`** fails on any `✓` line of a second `make`: a step that reports a change every time either rewrites something it should leave alone or reports what it did not do (the keyboard layouts and `softwareupdate --schedule` both did).
- **`shell`** fails on any output to stderr from an interactive zsh, or a start slower than 1 s.
- **Two VMs at most**: Apple's license lets a host run two macOS VMs at once; a third does not boot.
