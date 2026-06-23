# macos — one-shot macOS system configuration: `defaults` tweaks, per-extension default apps, Dock, hosts.

- `set_defaults.sh` is the main entry: idempotent `defaults write` / PlistBuddy tweaks across Finder, keyboard, Safari, Transmission, Dock, Software Update, dark mode, etc. Run from repo root (sources `zsh/functions.sh` and `helpers/` by relative path); needs `sudo`. Prints a changed/already-set summary.
- `set_default_apps.sh` maps file extensions and UTIs to default apps via `duti` (VSCode for source/text, IINA for media, Shottr for images, Preview for PDF, etc.). One `duti -s <bundle-id> <type> all` line per type.
- `dock_setup.sh` configures the Dock with `defaults` + `dockutil` (orientation, removes all icons, adds chosen apps), then `killall Dock`.
- `helpers/` holds sourced functions: `set_macos_default_if_different.sh` and `set_plist_value_if_different.sh` (only write when current value differs, drive the summary counters), `colors.sh`, `spinner.sh`, and `try_to_clean_directory.sh` / `try_to_clean_by_pattern.sh` (the latter two are shared with `macos_cleanup/`).
- `hosts` is symlinked to `/etc/hosts` by the Makefile; it null-routes telemetry domains (Anthropic, VS Code, Microsoft, analytics).
- Invoked by the root `Makefile` `install` target: `set_defaults.sh`, `set_default_apps.sh`, `dock_setup.sh` are `source`d; `hosts` is linked. Not run automatically otherwise.
- Standalone utilities (not part of `make`): `git-repo-analyzer.sh` (find/prune git repos), `move-addictive-drums-to-external.sh` (migrate AD2 samples to external drive + symlink), `update_all_and_cleanup_all.sh` (convenience wrapper that sources `macos_update/update_all.sh` then `macos_cleanup/cleanup_all.sh`).
- Sibling dirs `macos_update/` (brew/npm/macOS updates) and `macos_cleanup/` (cache/log pruning) are separate; this dir is config/setup, they are maintenance. They meet only via `update_all_and_cleanup_all.sh` and the shared `helpers/try_to_clean_*` scripts.
