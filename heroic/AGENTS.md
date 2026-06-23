# heroic — Heroic Games Launcher default settings, synced for running Windows games on macOS

- `config.json` — the only tracked file. Holds `defaultSettings` (the template Heroic applies to new games): GPTK Wine runner, install path `/Volumes/SanDisk/Games`, default prefix dir, esync/msync on, updates/analytics off. Symlinked by the Makefile to `~/Library/Application Support/heroic/config.json` (see Makefile "setup Heroic Launcher symlinks").
- Wine runner default is Game-Porting-Toolkit (`wineVersion.type: "toolkit"`); the rest of Heroic's state (installed games, prefixes, tools) lives under `~/Library/Application Support/heroic/` and is NOT tracked here.
- Driven by the `install-game-heroic` skill in `claude-code/skills/install-game-heroic/` — it downloads GOG torrents, installs via Wine, registers games as Windows sideload apps in `~/Library/Application Support/heroic/sideload_apps/library.json` + per-game `GamesConfig/<app>.json`, and fixes DirectX errors via DXMT/GPTK.
- App installed via Homebrew: `cask "heroic"` in `homebrew/brewfile`.
- Invariant: only `defaultSettings` belongs here. Per-game configs, library, and prefixes are machine-local runtime state, written by the skill or the app, not committed.
