# Homebrew — installed apps & packages

This directory is the **source of truth for what software is installed** on the
machine. If you want to know whether an app/CLI is installed, or to install a
new one, it starts here.

## Files

- **`brewfile`** — the canonical list of *everything* installed via Homebrew:
  `tap`, `brew` (CLI formulae), `cask` (GUI apps), and `mas` (Mac App Store).
  ~500 entries. This is the answer to "what apps do I have" and "is X installed".
- **`minimum_brewfile`** — a minimal essential subset for a fresh/lightweight
  machine.
- **`install_all_homebrew_packages.sh`** — installs everything:
  `brew bundle --file=~/projects/dotfiles/homebrew/brewfile`.
- **`install_minimum_homebrew_packages.sh`** — installs the minimal set from
  `minimum_brewfile`.
- **`install.sh`** — bootstraps Homebrew itself.

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
   version-controlled and symlinked into `~`, follow the App Integration Guide
   in `docs/app-integration.md` — create `dotfiles/<app>/`, copy the configs,
   and add a `link` line to `install/07-config-links.sh` (the installer is zsh
   now, not make) so `make`/`./install.sh` symlinks them.

So: **brewfile = the app itself; the installer = its configs.** A full "install X and
set it up" touches both.
