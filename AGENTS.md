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

## Git hooks
Two separate layers, don't confuse them:
- **This repo's own hooks** (`no-russian-comments`, `lint-shell`, …) run only here, via
  `.git-hooks/` + `.pre-commit-config.yaml` — see `## Code Style Guidelines` above.
- **A machine-wide `commit-msg` hook rejects AI co-author/tool footers in every repo on this
  machine**, dotfiles included, deployed via `init.templateDir` (not `core.hooksPath` — that
  option breaks `pre-commit install`, see below). Full mechanism, proof, and blind spots:
  `git/AGENTS.md`.

## Install conventions

The installer is plain zsh, not make. `Makefile` is a one-line wrapper
(`install: ; @./install.sh`) kept only so `make` and CI still work.
