# tmux — terminal multiplexer config (single self-contained tmux.conf)

- `tmux.conf` is the only file: Gruvbox Dark Hard theming (status/pane-border/message styles), truecolor via `default-terminal "xterm-256color"` + `terminal-overrides ...:RGB`, mouse on, 50000-line history, 1-based window/pane indexing with `renumber-windows`, low `escape-time`/`focus-events` for vim/neovim, and vi copy mode (`mode-keys vi`).
- No prefix remap — keeps the default `C-b`.
- No plugin manager (tpm) and no plugins; everything is plain built-in tmux options, so it works on a bare `brew install tmux` with zero bootstrap.
- Symlinks to `~/.tmux.conf` via the Makefile `install` target (`LINK tmux/tmux.conf → ~/.tmux.conf`); `tmux` itself comes from `homebrew/brewfile`.
- Pairs with the `zsh/` terminal stack (Oh My Zsh + p10k + atuin) inside the Zap terminal; theme matches the repo-wide Gruvbox Dark Hard convention.
- atuin treats `tmux` as a history-filter keyword (`atuin/config.toml`); a cron reaper (`cron/scripts/serho-tmux-reaper.py`) prunes stale sessions — both external to this dir, edit them there.
