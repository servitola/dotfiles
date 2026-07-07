# zsh shell configuration

- Three symlinked entry points (via `setup_zsh.sh` / Makefile): `~/.zshenv` → `zshenv.sh` (all shells: sources `exports.sh` + `exports-path.sh`), `~/.zprofile` → `zprofile.sh` (login: sources `exports-path.sh` after macOS `path_helper`), `~/.zshrc` → `zshrc.sh` (interactive: sources the rest below).
- `exports.sh` — non-PATH env vars (locale, Homebrew, Go/.NET/Java/Android/Node, Claude, tool config dirs); sources `~/.config/openai_key.sh` for secrets. Guarded by `_EXPORTS_LOADED`.
- `exports-path.sh` — PATH only (brew shellenv, language toolchains, `~/projects/dotfiles/zsh/bin`). Kept separate so login runs it after `path_helper` reorders PATH.
- `plugins.sh` — the oh-my-zsh `plugins=(...)` array (sourced before oh-my-zsh loads). `completion.sh` — completion behavior/menu/caching (sourced AFTER oh-my-zsh's compinit, does not run compinit). `history_settings.sh` — HISTFILE/HISTSIZE + opts tuned to NOT fight atuin (no SHARE_HISTORY/INC_APPEND).
- `aliases.sh` (guarded by `_ALIASES_LOADED`) and `functions.sh` hold most aliases/shell functions — small helper funcs live INLINE in these two files, NOT in `functions/` (that dir is empty/unused).
- `bin/` — standalone executable wrappers on PATH, callable from any shell or tool (not just zsh): `rag`, `agents-link`, `new-topic`, `skill-stats`, `skill-attach` (attach detached skills per folder), `mcp-attach` (attach detached MCP servers per folder). Prefer adding cross-tool CLIs here.
- Prompt is powerlevel10k: theme set in `zshrc.sh`, config in `p10k.zsh` (large generated file — edit via `p10k configure`, not by hand).
