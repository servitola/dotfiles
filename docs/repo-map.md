# Repo map — what every tool is, and how central it is

Importance tiers for every top-level directory in these dotfiles

Tiers: **Core** (the spine — the setup isn't itself without these) ·
**Important** (daily drivers) · **Secondary** (convenience) ·
**Peripheral** (niche but actively used) · **Experiment** (tried, not in active
use — safe to ignore or delete).

## Core — the spine

- **zsh** — the interactive shell core; everything runs inside it (`~/.zshrc`).
- **homebrew** — source of truth for *what is installed* (`brewfile` + `brew bundle`).
- **karabiner** — keyboard remap engine: Caps Lock → Hyper; `karabiner.json` is generated from per-rule files. Always running.
- **hammerspoon** — the keyboard brain: catches keys, launches/focuses apps, window management, language-per-app, URL routing. The signature of this setup. Always running.
- **claude-code** — **the primary AI coding tool** (paid Claude, used daily): the harness — hooks, settings, agents, scripts. Skills, detached skills and commands moved to `~/projects/skills` (`$DIR_SKILLS`) on 2026-10-10 and are linked in (codex symlink to it).
- **litellm** — gone: the local free LLM/TTS proxy at `:4000` and its shims live in `~/projects/services/litellm` (`$DIR_LITELLM`) since 2026-10-10; it was for CI, bulk, image gen, and `rag`
- **rag** — the `zsh/bin/rag` wrapper, the `rag-context-inject` hook and the refresh step in `up`. Backed by qdrant + litellm here.
- **macos_update** — the `up` command: one-shot system-wide update + cleanup (brew/npm/python/rag/docker), and `brew bundle dump` keeps homebrew/brewfile in sync.
- **docker** — registry-driven starter for the local compose stacks (litellm, qdrant); the engine is OrbStack.
- **constants** — the values that are true about this machine (project paths, chosen browser/terminal/editor, Telegram chat ids), in one `constants.env` at the repo root, readable from zsh, Python, Hammerspoon and AI agents (`const <key>`).
- **zap** — the primary terminal, launched on Hyper+B.
- **(root)** — install orchestration: `install.sh` + the numbered `install/` steps (symlink every app's config; `Makefile` is a one-line wrapper that runs `./install.sh`), `AGENTS.md`/`CLAUDE.md`, `README.md`.

## Important — daily drivers

- **fork** — primary Git GUI client
- **vscode** — the general editor: logs, configs, dotfiles, everything non-C#. (For C# work the IDE is **Rider**.)
- **xcode** — iOS key bindings. The dir is small, but **iOS/Android mobile development is the primary work**, so Xcode + Android Studio are first-class.
- **voiceink** — primary voice→text dictation; always running.
- **atuin** — shell-history SQLite DB with fuzzy Ctrl-R + cross-machine sync.
- **tmux** — terminal multiplexer
- **cron** — the mechanism only: `install.sh` merges `$DIR_CRON_JOBS/**/*.cron` into the crontab (`cron-install`), `cron-calendar.py` / `cron-report.py` watch it (`cron-cal`). The jobs themselves are private and live in `~/projects/cron` (`$DIR_CRON`) since 2026-10-09; the fork-sync jobs in `~/projects/forks`.
- **qdrant** — vector DB backing `rag` (embeddings from litellm's `embed` alias).
- **npm · python · uv** — dev toolchains: tracked global package lists + installers (refreshed by `up`).
- **macos** — system configuration: `defaults` tweaks, per-extension default apps (LaunchServices plist), Dock, `/etc/hosts` blocklist.
- **contextMenu** — Finder right-click actions; always loaded and used.

## Secondary — convenience

- **eza** — modern `ls` (Gruvbox colours), used by zsh aliases.
- **btop** — resource-monitor TUI (occasional).
- **eqmac** — system-audio equalizer; always running as a service.
- **adguard** — system-wide ad blocker; always running (config excluded from the RAG index).
- **noti** — desktop notification when a long command finishes.
- **iina** — media player (Hyper+Y).
- **docs** — human/agent reference docs (keyboard-setup, app-integration, this map).
- **docker-logger** — centralized container log collection.
- **claude-code-memory** — persistent knowledge base agents read to understand this system.
- **macos_cleanup** — cache/junk cleanup (the cleanup half of `up`).
- **applesauce** — APFS compression of SDKs and app bundles; last step of `up`. Add a path to `targets.sh`.

## Peripheral — niche but actively used

- **heroic** — real: in active use.
- **ableton** — real: in active use.
- **annepro2** — Anne Pro 2 60% external keyboard firmware state — used as the keyboard on the **m1pro** Mac (m3pro uses its internal keyboard).
- **iterm** — iTerm2 prefs (secondary terminal; zap is primary).
- **chromium-vimium-extension · firefox-vimium-addon** — exported Vimium keyboard-nav settings (manual-restore backups).

## Experiment — tried, not in active use

Safe to ignore. Kept for reference; could be removed without affecting the setup.

- **Alternative AI coding agents** (Claude Code is the real one): **aider · opencode · codex · mistral-vibe** — all wired to the litellm proxy but not in daily use.
- **cursor · windsurf** — AI editors. Not used.
- **hermes · aichat** — AI CLIs. Experiments.
- **lazygit · lazydocker** — TUIs; Fork + OrbStack cover everything, so unused.
- **marta** — dual-pane file manager. Experiment; only wired to a secondary Finder + Shift shortcut.

## Machines

Three Macs, configs shared via this repo but roles differ:

- **MacBook Pro 16 M3Pro** — the **primary daily driver**. Uses its **internal keyboard** (a 60% external exists for it but isn't the daily one).
- **Mac Studio M1Pro** — a second important workstation; always driven by the **60% external (Anne Pro 2)** keyboard.
- **MacBook Pro 16 i9 (2019)** — the **home server** (runs immich, etc.), not an interactive driver.

## Default apps (the human's daily drivers, by role)

What to assume when a task just says "open the browser", "the editor", etc. Most
are launched from the Hyper layer (see `docs/keyboard-setup.md`).

- **Terminal:** Zap (Hyper+B) — `zap/`.
- **Editors:** **Rider** for C# projects; **VS Code** (Hyper+N) for everything else (logs, configs, dotfiles — "a text editor on steroids"). `nano` for the rare quick terminal edit.
- **AI coding:** **Claude Code** (paid) — the daily driver. The local agents (opencode/aider/qwen-code/codex/mistral-vibe) are experiments.
- **Git client:** Fork (Hyper+G).
- **Docker runtime / launcher:** OrbStack (Hyper+⌘+R). `docker/` compose stacks run on it.
- **Browsers (split by purpose):** Vivaldi = main (Hyper+V); Chrome = technical / dev sites (Hyper+⇧+V); Firefox = work sites (Hyper+H). LinkRouter.spoon routes links by the rules in `hammerspoon/link_router.lua`; which browser is "main" is one line in `constants.env` (`APP_BROWSER`), and `hammerspoon/browsers.lua` keeps Zen, Yandex, Chrome, Firefox and Opera listed so a move is that one line. Vivaldi is Chromium, so tab cycling works over AppleScript — but only after Settings → Privacy → Apple Events allows JavaScript, otherwise `⇧⌃⌥V` falls back to the first matching tab.
- **Messenger:** Telegram (Hyper+T) — also the keyboard-language exception (manual switching, type Russian).
- **Music:** Apple Music — Music.app (Hyper+P). Never Spotify/web players.
- **Voice → text:** VoiceInk (`voiceink/`), always running. `whisper-x` via `w` for batch files.
- **Torrents:** Transmission.
- **Media player:** IINA (Hyper+Y).
- **Mobile dev (primary work):** Xcode (iOS) + Android Studio + emulators (Hyper+Z toggles the Android emulator window).

## Always-on background apps

Services/agents that run constantly (mostly installed via `homebrew/brewfile`,
not all have a config dir here). Knowing these are always up explains a lot of
the macOS behavior:

adguard · alttab · amphetamine · appcleaner · **claude-counter** (the human's own
app) · contextMenu (Finder extensions) · day one · eqmac · hammerspoon ·
karabiner · lulu (firewall) · maccy (clipboard) · neptunes · orbstack · peek ·
raycast (beta) · shottr (screenshots) · voiceink.

## Work vs personal

- **Rider** — used specifically for C# / .NET projects.
- **Focus mode** (Hammerspoon, work in progress but actively liked): `⇧⌃⌥⌘`+arrow
  hides/focuses app groups — `work` = Rider/Fork/Zap/Code/WebStorm/Xcode/Firefox/Telegram,
  `only-work` = Zap/Telegram, `personal` = Telegram + the browser of the day,
  `comms` = Telegram/zoom/Telemost. The two "which app" roles come from
  `constants.env` (`APP_BROWSER`, `APP_TELEGRAM`); the sets live in
  `hammerspoon/window_focus_sets.lua`.

## Cross-cutting conventions

Facts that span the whole repo and don't live in any single directory:

- **Theme:** Gruvbox Dark Hard everywhere — terminal (zap), TUIs (btop, lazygit, lazydocker), eza, tmux. New tool configs should match it.
- **Fail-fast:** scripts do NOT add existence checks for tools/paths/deps. If something required is missing, fail loudly — a broken setup should surface immediately, not be silently skipped.
- **Secrets:** all API keys live in `~/.config/openai_key.sh` (gitignored, sourced by zsh, litellm, contextMenu, cron). Never hardcode keys.
- **AI model strategy:** **Claude (paid) is the primary AI** — used by Claude Code for real work. The **litellm free proxy** handles the cheap/bulk lane: CI, small tasks, image generation (some paid image models), and all `rag` knowledge work. Within litellm, the `coding` alias is the de-facto default; `fast` for quick, `reasoning` for planning. See `litellm/AGENTS.md`.
- **Keyboard layout per app:** AutoKeyboardLayout.spoon (config in `hammerspoon/init.lua`) sets `LAYOUT_PRIMARY` for every app as it comes to the front and `LAYOUT_SECONDARY` for the Telegram clients; inside an app switching is manual. Games additionally get the Karabiner `Empty` profile from `hammerspoon/game_mode.lua`.
- **Audio → text:** VoiceInk (always on) for dictation; `whisper-x` via the `w` alias for files. Text → audio (TTS) is separate — litellm `tts*` aliases and language-specific TTS skills built on top.
- **Per-directory docs:** every config/tool dir has an `AGENTS.md` (role-level summary) with a `CLAUDE.md` symlink; this file ranks them by importance.
