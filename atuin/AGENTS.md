# atuin — shell-history SQLite DB with encrypted cross-machine sync + Ctrl-R fuzzy search

- `config.toml` — the only real config. Symlinked to `~/.config/atuin/config.toml` by the Makefile
- Maintenance is external: `macos_update/update_all.sh` runs `atuin sync`; `macos_cleanup/cleanup_all.sh` clears `~/.local/share/atuin/backups/` and `VACUUM`s the DB. The DB/key/session live under `~/.local/share/atuin/` (paths commented out in config = defaults).
