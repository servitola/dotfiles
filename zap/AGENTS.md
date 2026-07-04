# zap — config for Zap, the primary terminal (open-source Warp fork)

- Zap is the everyday terminal here; shell behavior lives in `zsh/` (Zsh + oh-my-zsh + p10k), this dir is terminal-app config only.
- Symlinked by the Makefile: `~/.zap → ~/projects/dotfiles/zap` (single directory link). There is no `warp/` dir and no `~/.warp` symlink — Zap reads `~/.zap`.
- `settings.toml` — main settings: appearance (Gruvbox Dark theme, `override_opacity`/`override_blur`, JetBrainsMono Nerd Font, vertical tabs, dim-inactive-panes), notifications, external editor (VS Code), and the large `[agents.warp_agent]` provider/model catalog (302.AI OpenAI-compatible endpoint). The model list is volatile — do not treat specific model entries as durable.
- `themes/` — custom color themes (`gruvbox_dark.yaml`); the active theme is selected by `appearance.themes.theme` in settings.toml.
- `keybindings.yaml` — terminal keybinding overrides (separate from the Hammerspoon/Karabiner layer in the rest of the repo).
- `tab_configs/` (named tab/worktree configs) and `default_tab_configs/` (the `worktree.toml` template for the "New worktree" flow) drive tabs and git-worktree creation. `launch_configurations/*.yaml` are multi-tab session presets (e.g. `Default.yaml`).
- Invariant: generated tab/worktree configs still embed legacy absolute `~/.warp/worktrees/...` paths (inherited from the Warp fork). Keep paths absolute and consistent with whatever Zap actually writes; do not hand-edit generated configs into divergence.
