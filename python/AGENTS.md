# python — tracked global Python package/tool lists and their uv-based installers

- `global-packages.txt` is the source-of-truth list of global Python packages (one per line, `#` comments allowed). `install-globals.sh` installs/upgrades each via `uv pip install --upgrade`, then rewrites the list from the live `uv pip list` state on every run, so it stays self-syncing (the file is normally regenerated, not hand-curated).
- `install-uv-tools.sh` is the parallel track for standalone CLI tools: it runs `uv tool upgrade --all` and rewrites `uv-packages.txt` from `uv tool list`. Keep the two separate — `pip`-style env packages vs. `uv tool` isolated CLIs.
- `install-tts.sh` is independent of the two lists: it provisions a dedicated `~/.venv/tts` Piper TTS venv, downloads the Russian voice model, and registers the `piper-shim` launchd agent (used by `litellm/`). Not part of the global-packages flow.
- `uv/uv.toml` (sibling dir, symlinked to the uv config home) sets `exclude-newer` so uv skips too-fresh releases; it governs all `uv` invocations here, mirroring npm's `min-release-age`.
- Relation to `macos_update/`: the `up` command (`macos_update/update_all.sh`) sources all three scripts to refresh Python globals, uv tools, and TTS during a full system update. `make` runs `install-globals.sh` + `install-uv-tools.sh` at install time.
- Invariant (repo fail-fast policy): no existence/availability guards around `uv` — a missing tool should fail loudly.

```bash
source ~/projects/dotfiles/python/install-globals.sh
```
