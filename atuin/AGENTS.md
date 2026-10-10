# atuin — shell-history SQLite DB with encrypted cross-machine sync + Ctrl-R fuzzy search

- `config.toml` — the only real config. Symlinked to `~/.config/atuin/config.toml` by the Makefile
- Up arrow is atuin's (`atuin init zsh` without `--disable-up-arrow`): prefix search over the whole synced history, every tab and every Mac. The native zsh search it replaced read only `~/.zsh_history`, which a shell writes on exit, so commands from open tabs and other Macs never showed up. `auto_sync = true` syncs every `sync_frequency`, not only on `up`.
- Maintenance is external: `macos_update/update_all.sh` runs `atuin sync`; `macos_cleanup/cleanup_all.sh` clears `~/.local/share/atuin/backups/` and `VACUUM`s the DB. The DB/key/session live under `~/.local/share/atuin/` (paths commented out in config = defaults).
