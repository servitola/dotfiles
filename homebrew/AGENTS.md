# Homebrew — installed apps & packages

This directory is the **source of truth for what software is installed** on the
machine. If you want to know whether an app/CLI is installed, or to install a
new one, it starts here.

## Files

- **`brewfile`** — the canonical list of *everything* installed via Homebrew:
  `tap`, `brew` (CLI formulae), `cask` (GUI apps), and `mas` (Mac App Store).
  ~500 entries. This is the answer to "what apps do I have" and "is X installed".
- **`install_all_homebrew_packages.sh`** — installs everything:
  `brew bundle --file=~/projects/dotfiles/homebrew/brewfile`.
- Install step 3 (`install/03-homebrew.sh`) bootstraps Homebrew itself and
  installs the whole `brewfile`. A failed entry is reported, not fatal; mas apps
  fail until the App Store is signed in, and `install/check.sh` ignores them.
  There is no minimum list any more: it drifted from what `make` and `up` call.

## Keeping the list in sync

The `up` command (`macos_update/update_all.sh`) runs
`brew bundle dump --force --describe --file=…/homebrew/brewfile`, so the brewfile
is regenerated from the actually-installed set on every system update. Don't
hand-curate stale entries — `up` reconciles them.

## Installing a new app — the two halves

Installing an app in these dotfiles is **two independent steps**:

1. **Install the binary (this directory):** add a line to `brewfile`
   (`brew "ripgrep"`, `cask "shottr"`, or `tap "owner/repo"`), then
   `brew bundle --file=~/projects/dotfiles/homebrew/brewfile`. `up` will keep it.

2. **Wire up its config (separate flow):** if the app has config files you want
   version-controlled and symlinked into `~`, create `dotfiles/<app>/`, copy the configs,
   and add a `link` line to `install/07-config-links.sh` (the installer is zsh
   now, not make) so `make`/`./install.sh` symlinks them.

So: **brewfile = the app itself; the installer = its configs.** A full "install X and
set it up" touches both.
