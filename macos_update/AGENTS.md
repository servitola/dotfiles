# macos_update — the update half of the `up` command: system-wide package & tool updates

- `update_all.sh` is the update phase that `up` runs. `up` (alias in `zsh/aliases.sh`) sources `macos/update_all_and_cleanup_all.sh`, which runs this `update_all.sh` first, then `macos_cleanup/cleanup_all.sh` — both as **child zsh processes** (not sourced), then reloads the shell.
- It updates everything in one pass: Homebrew, Mac App Store (`mas`), VSCode extensions, Appium plugins, .NET tools, pre-commit hooks, Oh My Zsh, Powerlevel10k, TLDR/Bat caches, Atuin sync
- Runs `brew bundle dump --force --describe` to sync the live Homebrew state back into `homebrew/brewfile` — so the brewfile is regenerated from the machine, not hand-edited here.
- Refreshes the RAG index by sourcing `rag/rag.sh` and running `rag refresh` and `spotware-rag refresh` (best-effort; failures are tolerated if litellm/qdrant are down).
- Also triggers other dotfiles subsystems: `docker/up.sh`, `immich/sync.sh`, `litellm/scripts/check-models.py`, `claude-code/shared/skills-repos/update.sh`, `docs/keyboard/generate.py`, and `rtk gain`.
- strips `com.apple.quarantine` xattrs from `/Applications/*.app` after upgrades); `update_all.sh` sources it and calls it.
- Invariant: per repo fail-fast policy, do not add existence/availability guards around tools — missing tools should fail loudly. Per-step `|| echo` fallbacks exist only for network-dependent services (rag, litellm, immich/i9) that are expected to be intermittently offline. `|| true` is used only where non-zero status is informational, not a failure (`brew doctor` warnings, locked in-use files).
