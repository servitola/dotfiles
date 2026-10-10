# Agent Guidelines for Dotfiles Repository

These dotfiles are an operating system on top of macOS. Not just a set of configs, but a living, evolving workspace management system.

**New here? Read `docs/repo-map.md`** — it tiers every directory by importance
(Core / Important / Secondary / Peripheral / Experiment), so you know what
matters and what's just an experiment. Each directory also has its own
`AGENTS.md` with operational detail.

## Build/Test Commands
- `make` - Full dotfiles installation & symlink setup (thin wrapper: `make` just runs `./install.sh`)
- `up` - System-wide update & cleanup (brew, npm, macOS, cache)

## Architecture & Structure
- **Dotfiles repo**: Configuration files symlinked to system locations (~/.zshrc, ~/.gitconfig, etc.)
- **Package management**: Homebrew with brewfile for app installations and documentation in `/opt/homebrew/docs/`
- **Automation**: Hammerspoon for window management, URL routing, keyboard layouts
- **Keyboard**: Karabiner-Elements for advanced keyboard customization
- **Shell**: Zsh + Oh My Zsh with extensive plugin ecosystem
- **No databases or APIs**: Pure configuration repository
- **Symlinks**: Created by `install.sh` / `install/*.sh` (e.g., ~/.gitconfig → git/gitconfig; app configs link to respective directories)
- **Reference**: See `README.md` for detailed setup

## AI Coding Tools — Shared Configuration
Claude Code (`claude-code/`) is the single source of truth for `commands/`, `agents/`, `skills/`; Qwen Code, and Codex consume them via symlinks the installer creates (`install/ai-tools-links.sh`). Codex keeps its own global config in `codex/`.
When adding new shared commands, agents, or skills — add them to `claude-code/` only.
Detached (opt-in, per-folder) skills and MCP servers live in `claude-code/detached_skills/` and `claude-code/detached_mcp/` — attach with `skill-attach <name> [dir]` / `mcp-attach <name> [dir]`.

Repository is private and self-hosted on Gitea (`origin`; the server itself — i9, access, backups — is documented in `~/projects/services/gitea`); remote `github` is a fork marker, push disabled (`git remote set-url --push github no_push`) — do not publish this repository, it contains personal data

Full symlink map, tool-specific configs, and Codex operational rules (1024-char description limit, vendored `openai-docs`, install via cask only): see `claude-code/AGENTS.md`.
Never `brew uninstall --zap codex` — its zap stanza deletes `~/.codex`.

**`@file.md` imports are Claude-Code-only.** `claude-code/CLAUDE.md` reaches four
harnesses — Claude Code (the whole `~/.claude` dir is a **symlink** to
`claude-code/`, made by `install/08-ai-tools-links.sh`, so edits are live with
no sync step), Codex (`~/.codex/instructions.md` symlink) and OpenCode (`instructions[]` in `opencode.json`). But only Claude Code
expands `@RTK.md`; the other three receive it as literal text (verified
2026-07-25 against a Codex session transcript). Anything every harness must know
goes **inline** in that file — a separate file plus `@import` silently reaches
Claude Code only. `RTK.md` has this problem today and is unfixed.

**`~/.claude/rules/*.md` IS auto-loaded** by Claude Code into the system prompt
(verified on CC 2.1.220). It is gitignored, so it is the wrong home for
hand-written knowledge, and everything there is billed on every session. It is
empty on purpose: `up` used to fill it with `rtk learn --write-rules`, whose
"corrections" were false (`rtk/AGENTS.md`).

**Model lists: query the runtime, never grep a config.** Codex →
`~/.codex/models_cache.json`. LiteLLM → `curl -s localhost:4000/v1/models`.
Grepping `litellm/config.yaml` for `model_name:` gives false positives (it marked
the live `coder` alias as dead). Current model/context/pricing tables for Codex
and Claude live in the `# Models` section of `claude-code/CLAUDE.md`.

## Code Style Guidelines
- **Comments are English-only.** Every comment in this repo — Lua, shell, Python, YAML, TOML —
  is written in English, whatever language the conversation that produced it was in. Enforced by
  the `no-russian-comments` pre-commit hook. This is about *prose*: Cyrillic that is **data** stays
  untouched — the `ru` column of the keyboard-layout tables in `HotKeys.spoon/layout/60%/*.lua`,
  paths under `~/projects/serho_topics/`, Telegram message texts, dictation dictionaries, test
  fixtures. Translating those breaks the thing they describe.
- **Docs are English-only too, on the same terms.** `AGENTS.md`, `CLAUDE.md`, `README.md` and
  anything else in `docs/` is written in English even when the session that produced it ran in
  Russian. The hook does not cover `.md` (it only knows comment markers, and Markdown has none),
  so this one is on you. Same data carve-out, and it matters more here: skill and agent
  descriptions under `claude-code/skills/` and `claude-code/agents/` carry Russian **trigger
  phrases** on purpose — a skill fires on the words the user actually types, so translating a
  `description:` silently stops it from firing. Body prose in those files is English; the trigger
  lists are data. Same for `claude-code-memory/`, where Russian source titles and quotes are
  content, not writing.
- **Theme**: Gruvbox Dark Hard. If possible modern **Apple-glass Gruvbox**
- **Fail-fast philosophy**: Do NOT add existence checks for dependencies, tools, or paths. If something required is missing, the script should fail loudly. This is intentional — it surfaces setup issues immediately.
- **Linting**: No linting required - this is a configuration repository (shell scripts, Lua scripts, dotfiles)

## Install conventions

The installer is plain zsh, not make. `Makefile` is a one-line wrapper
(`install: ; @./install.sh`) kept only so `make` and CI still work.

- **`install/` is the whole installation as a numbered ladder** —
  `install/01-macos-defaults.sh` … `install/15-ci-guarded.sh`. `ls install/`
  shows first step to last. Steps that are just a wrapper around an existing
  script elsewhere (defaults, xcode, zsh, dock, iterm, ableton) are one-line
  `exec zsh "$DOTFILES/…"` files, so the ladder stays complete.
- **`install.sh`** is a trivial loop: `for step in install/[0-9]*.sh` → run in
  order (numbered `━━ [NN/18]` framing + per-step timing), abort on the first
  failure. Each step runs in its own subshell (`zsh "$step"`), reproducing the
  old Makefile model. Everything is tee'd to a timestamped logfile under
  `~/.local/state/dotfiles/`. `lib.sh` (no number prefix) is excluded by the
  glob.
- **Strict mode:** each logic step (03, 05–08, 12, 14, 15) sets
  `set -euo pipefail`, so a failure inside a step surfaces immediately instead
  of being swallowed. Wrappers just `exec`; external scripts run as
  subprocesses so `set -e` doesn't leak into them.
- **`install/lib.sh`** holds full-word path vars (`DOTFILES`, `APP_SUPPORT`,
  `CONFIG`, `CLAUDE_CODE`, …) and the helpers `section`, `link`, `link_all`,
  `copy_dir`. `link <source> <destination>` does mkdir-parent + `sudo rm -rf` +
  `sudo ln -sfvh` — the `sudo` is kept from the old Makefile on purpose (some
  targets are system paths; existing $HOME symlinks may be root-owned from
  prior runs). `link_all <src1> <dst1> <src2> <dst2> …` links a flat list of
  pairs, so a step reads as a scannable table instead of one `link` per line.
- **Each step** starts with `source "${0:a:h}/lib.sh"`, so it's runnable on its
  own for debugging (e.g. `zsh install/07-config-links.sh`).
- **Adding an app config:** add a `"$DOTFILES/<app>/<file>" "<dest>"` pair to
  the right `link_all` table in `install/07-config-links.sh` (app configs) or
  `install/08-ai-tools-links.sh` (AI tools). Full paths, quoted — readable, no
  `$(call …)`.
- **CI-only skips** live in `install/15-ci-guarded.sh` behind `if [[ -n "$CI" ]]`
  (GitHub Actions sets `CI=true`; this replaced the Makefile `ifdef CI`).

## zsh gotcha: unmatched globs

The installer runs under zsh, where an unmatched glob is a fatal error, not a
literal. In a `for` header it **aborts the whole script** (even without
`set -e`); as a command argument it only skips that command. Any loop over
`/Applications/Foo*` or similar needs `setopt null_glob` first — see the Rider
loop in `install/config-links.sh`. This class of bug once took down
`make install` via `ableton/setup-mcp.sh` when Ableton was absent.

## Default apps

`macos/set_default_apps.sh` binds extensions and UTIs to apps from one
`HANDLERS` dict — that dict is the only thing to edit. Two constraints are
baked in: the write goes through `defaults import`, because a raw write to
`com.apple.launchservices.secure.plist` is silently reverted by cfprefsd; and
every bundle id must belong to an installed app, because a dead id makes macOS
start asking which app to open a file with. Verify a binding by asking
`NSWorkspace.urlForApplication(toOpen:)` about a real file — anything that
resolves by UTI cannot see the extension bindings.

Safari is deliberately not configured: its prefs live in a sandboxed container
that `defaults` cannot write without Full Disk Access (which we don't grant),
and `IncludeDevelopMenu` is dead since Safari 17.

## Adding New Applications/Tools

See `docs/app-integration.md` for detailed integration guide.

## Keyboard Setup

See `docs/keyboard-setup.md` for complete keyboard customization documentation.

## Documentation Structure
- **docs/** - Specialized guides that AI can read selectively when needed
- `docs/commands.md` — catalog of custom `zsh/bin/` commands (usable from any shell/tool). Prefer these over inline heredocs.
- Reference by plain path in backticks (`` `docs/filename.md` ``) — NEVER via `@path` import syntax: `@` force-loads the file into every session's context, recursively following the imported file's own `@` refs

## Handoff

**State (2026-10-10, launchd layer moved out). Committed here (not pushed).**
`serho/` and `launchagents/helper/` are gone: the bot's plist, `serho-runner.c`
and its Makefile live in `~/projects/serho/launchd/` (`$DIR_SERHO`); the ten
`com.servitola.mma.*` agents, `mma-job.zsh`, `mma-runner` and the
`sync-friend-skills` plist live in `~/projects/cron/launchagents/`
(`$DIR_CRON`). `launchagents/` keeps `reboot-reminder` as the one generic
example; `install/14` links `$DIR_SERHO/launchd/*.plist` and every plist under
`$DIR_CRON/launchagents/`.

- **Full Disk Access is bound to the runner's path.** Both runners were rebuilt
  at their new paths with their stable identities (serho: Developer ID; mma:
  VoiceInk Local Signing) and the owner re-granted FDA for both in System
  Settings. The mma path was verified with a manual kickstart; the serho
  restart was the owner's step (it kills every agent session).
- mma stays on the external SanDisk; its launchd layer is on the internal disk on
  purpose — a plist or runner on an unmounted volume never loads at login.

**State (2026-10-10, litellm moved out). Committed here (not pushed); the new
repository is pushed to Gitea (`servitola/litellm`, private).** The proxy stack
(`docker compose`: litellm, postgres, redis), the five TTS/STT shims with their
plists, `ai.sh`, the health and smoke scripts and `greek-tts.sh` live in
`~/projects/services/litellm` (`$DIR_LITELLM`). Design and plan:
`docs/superpowers/{specs,plans}/2026-10-10-litellm-extraction*.md`.

- **Consumers:** `zsh/zshrc.sh` sources `$DIR_LITELLM/ai.sh`; `up` runs
  `check-models.py` from there; `python/install-tts.sh` installs the piper plist
  from there; `docker/compose-projects.txt` lists the new stack path;
  `litellm-config-diff` diffs the new repository. Outside: `cron`
  (`litellm-smoke`), `rag` (`rag.sh`, docs), `skills` (`tts`, `greek-tts`).
- **Live move verified:** `docker compose up -d` from the new directory
  re-adopted the stack (named volumes untouched, 54 models answer); the five
  LaunchAgents were re-pointed (three copies rewritten, two symlinks re-created,
  the plists inside the repository too) and re-bootstrapped; a `bootstrap`
  right after `bootout` fails with `Input/output error` once — retry works.
  kokoro re-downloads its `uv` environment on every cold start, so it answers
  on 8179 only a minute later.

**State (2026-10-10, skills moved out). Committed here (not pushed); the new
repository is pushed to Gitea (`servitola/skills`, private).** `claude-code/skills`
(87), `detached_skills` (23, 14 of them never tracked), `commands` (12),
`skill-presets.json`, `skill-tests/`, `shared/skills-repos/` now live in
`~/projects/skills` (`$DIR_SKILLS`). Design and plan:
`docs/superpowers/{specs,plans}/2026-10-10-skills-extraction*.md`.

- **The three directories are git-ignored symlinks** into `$DIR_SKILLS`, made by
  `install/08`. Every consumer going through `~/.claude/...` is untouched (Codex
  `~/.agents/skills`, OpenCode commands, `serho-users/*/.claude/skills`). Retargeted
  by hand: `skill_cli.py`, `skill-attach`, `bind-topic-skill.sh`, VoiceCtl
  (`voice-mac/aliases.json`), `update_all.sh` (skills-repos update), the
  `sync-friend-skills` LaunchAgent (WatchPaths, re-bootstrapped), the four friends'
  `settings.json` permission paths, `cron/scripts/insight-miner-nightly.sh`.
- The `lint-skill-frontmatter` pre-commit hook left with the skills; `~/projects/skills`
  runs it on its own commits.
- `agents/` stays: harness, not content.

**State (install refactor).** The `Makefile` install target (298 lines of
`$(call link,…)` + `$(D)/$(H)/$(A)` shorthands + `SHELL := /bin/zsh -c`) was
extracted into plain zsh. `Makefile` is now a one-line wrapper `install: ;
@./install.sh`. Logic lives in `install.sh` (orchestrator / table of contents)
and `install/*.sh` steps, sharing `install/lib.sh` (path vars + `link` /
`copy_dir` / `section`). Behaviour is 1:1 with the old Makefile — same order,
same `@echo` headings (now `section`), same `sudo` on links, same `ifdef CI`
skips (now `if [[ -n "$CI" ]]` in `install/ci-guarded.sh`). Verified with
`zsh -n` on all steps + `pre-commit` (lint-shell → `zsh -n`) green. Not run
end-to-end here — the link steps need `sudo`/TTY; `make install` on a machine
or the CI `macos-install` job is the real test.


**Open questions.**
- If after login `.cs` still opens in Rider, the user default did NOT beat
  Rider's Info.plist Editor claim — escalate (make VSCode declare the type, or
  strip Rider's claim). Standard LS behavior says the user default wins.
- **pre-commit + voiceink gotcha:** the `vk-json-normalize` (`jq -S .`) clean
  filter on `voiceink/VoiceInk_Settings_Backup.json` makes pre-commit's stash
  unrestorable when that file is modified-but-unstaged — it silently ROLLS BACK
  all uncommitted edits. Commit that file first (with `--no-verify`) or keep it
  clean before committing anything else.
- `ableton/setup-mcp.sh` installs the **upstream** remote script, but the machine
  runs the `ableton-mcp-extended` fork (`~/projects/ableton_setup`, pinned in
  brewfile). Every `make` silently downgrades it. Owner is deciding.
- Five taps in `homebrew/minimum_brewfile` are untrusted, so `brew cu` and
  `brew autoupdate` currently refuse to run. Owner is handling this.
- Full Disk Access will NOT be granted — don't propose fixes that need it.
- An external process auto-commits with the message `1`, sweeping in whatever is
  in the working tree. Don't leave junk uncommitted, and expect noisy history.
