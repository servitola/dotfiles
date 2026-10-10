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

- **`install/` is the whole installation as a numbered ladder** —
  `install/01-macos-defaults.sh` … `install/18-spoons.sh`. `ls install/`
  shows first step to last. `install.sh` counts them dynamically, so adding a
  step needs no edit anywhere else. Steps that are just a wrapper around an existing
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
  `CONFIG`, `CLAUDE_CODE`, …) and the helpers `section`, `link`,
  `link_all`. `link <source> <destination>` does mkdir-parent + `sudo rm -rf` +
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

**State (2026-10-09, cron moved out). Committed here (not pushed); the new
repository is pushed to Gitea (`servitola/cron`, private, no GitHub mirror).** Everything that was
`cron/` — 72 fragments (125 jobs, 24 of them never tracked), 36 scripts, the
installer, calendar and weekly report — now lives in `~/projects/cron`
(`$DIR_CRON`). Design: `docs/superpowers/specs/2026-10-09-cron-extraction-design.md`,
plan: `docs/superpowers/plans/2026-10-09-cron-extraction.md`.

- **Constants carry the move:** `DIR_CRON`, `DIR_CRON_JOBS`, `DIR_CRON_SCRIPTS`.
  Fragments and scripts use them instead of 190 absolute paths; cron gets them
  through `~/.zshenv`. The `tg-send*.sh` wrappers reach `tg` via `$DIR_DOTFILES`.
  Verified: the installed crontab equals the new installer's output, and the
  first jobs after the reinstall wrote to `~/projects/cron/logs`.
- **Still in dotfiles:** `zsh/bin/cron-cal`, `zsh/bin/perfcheck`, `install/15`
  (runs the installer from `$DIR_CRON`), `install/check.sh`, the `cron-job`
  skill, `macos/com.servitola.kindle-autosync.plist` (launchd needs the absolute
  path; re-bootstrapped) — all pointing at `$DIR_CRON`. The scripts in
  `android_phone*`, `serho_topics`, `homebrew-tap` that call `tg-send-thread.sh`
  were retargeted and committed in their repos; the bot's «Крон» topic too.
- **Fixed on the way:** the weekly report saw 12 jobs of 126 (non-recursive
  glob). `work-snapshot` has been timing out on every run for a long time
  (15 000+ `urlopen error timed out` lines) — pre-existing, not touched.
- **Open:** stale mentions in `claude-code/plans/` and `rag/gaps/` were left as history.
  `~/projects/cron-conductor` (uninstalled Swift menu-bar app) still points its
  Makefile at the old dotfiles path. The `_EXPORTS_LOADED` guard in
  `zsh/exports.sh` means a long-lived shell keeps old constant values until it
  is restarted — `_EXPORTS_LOADED= zsh -c 'source ~/.zshenv; …'` for a test.

**State (2026-10-01, fork-sync jobs moved out). Committed here (not pushed); the
new repository is pushed.** Everything that keeps the forks rebased, built and
installed — nine `*-sync.sh` jobs, `alttab-upstream-merge.sh`, `claude-agent.sh`,
their LaunchAgent plists and the nine per-job runners — now lives in
`~/projects/forks` (private on Gitea, with a private push mirror on GitHub). Read its `AGENTS.md` before touching
a fork job; nothing about them is documented here any more.

- **What dotfiles still owns:** the apps' own configs (`zap/`, `voiceink/`), the
  brewfile, `launchagents/helper/{serho-runner,mma-runner}`. The forks repository
  reads constants and the brewfile from here; nothing here calls into it.
  `DIR_FORKS` in `constants.env` is its path.
- **One runner, one grant.** `forks-runner <job>` replaced nine binaries. Labels
  (`com.servitola.<job>-sync`), `~/.cache/<job>-sync` state and knobs are unchanged,
  so every `launchctl kickstart` line in older notes still works. Logs moved to
  `~/projects/forks/logs/`.
- **Verified:** a launchd probe through the new runner (volume read/write/exec,
  keychain, constants, Full Disk Access after the owner granted it); opentracks
  no-op run; a forced full boring-notch build — build, release, `brew upgrade`,
  exit 0. The other seven were cut over without a manual run on purpose (a
  kickstart starts a real build when upstream moved).
- **Open:** the first scheduled night (Sat 2026-10-03) has not been observed.
  `telegram-android-sync` and `voiceink-upstream-sync` were already red before the
  move (baseline in `~/projects/forks/docs/`). Nine stale Full Disk Access entries
  for the old `dotfiles/launchagents/helper/*-sync-runner` paths can be removed in
  System Settings. Entries below that mention `cron/scripts/*-sync.sh` or
  `launchagents/helper/*-sync-runner` predate the move.
- `rag/rag.eval.json` still holds ~30 auto-generated cases whose `origin` is a
  moved file; they were left to the `rag-improve` strike mechanism.

---

**State (2026-09-28 evening, BirmanLayer consumed like any user). Committed, nothing pushed.**
The dotfiles now hold only what a user of the Spoon has: `install/18-spoons.sh` (pinned
release zip into the git-ignored `hammerspoon/Spoons/BirmanLayer.spoon/`), the `init.lua`
config (always loaded; the birman/standard layout-mode switch is gone) and the hand-maintained
`hammerspoon/birman_extended.lua`. Everything an author has — Birman's archives, the owner's
Ukelele bundle, the table generator and its tests, publishing notes, launch posts — moved to the
private local repo `~/projects/birman/lab` (no remote yet; its README has the ship procedure).
`docs/keyboard/parse_birman.py` no longer reads keylayouts: Apple dumps in
`docs/keyboard/apple-layouts/` + the Spoon's `fixups` for plain/Shift, the installed Spoon table
+ `birman_extended.lua` for ⌥/⇧⌥; lint and SVGs came out identical. Report:
`.superpowers/sdd/birman-lab-report.md`. Entries below predate the move; their paths into the
old author material now live in the lab.

---

**State (2026-09-28, BirmanLayer 3.9.0: Birman's truth, no layout names). Committed
(`874507eb`, `3bdc9cf1`), nothing pushed; the running Hammerspoon already uses it.** The
Spoon claimed to be Ilya Birman's layout but was generated from this repo's edit
of it, and it was keyed to the input source names `ABC` / `Russian – PC` / `Greek`.

- **Truth is Birman's own build (`original/`, now in `~/projects/birman/lab`)**: Birman's Mac 3.9 (and 3.8 via Wayback, Windows
  3.7), sha256-summed. His build is English + Russian only; `Gr` in
  the owner's Ukelele bundle is ours (the Ukrainian experiment was deleted). Compared with an independent reader: base, Shift, dead keys
  and terminators of the bundle's En/Ru are identical to 3.9; the ⌥ layer has **nine extra
  cells** (`g z q 4 7 [ ] \ n` → `© § · £ ϗ » « ¦ ‘`) that the public Spoon used to type as
  "Birman".
- **The lab's generator now builds the Spoon table from `original/3.9-mac`** and writes the
  difference to `hammerspoon/birman_extended.lua` (the nine cells + the Greek layer),
  which `hammerspoon/init.lua` passes as `overrides`; typing on this Mac is unchanged. It
  stops if the bundle differs from Birman beyond the ⌥ layers, or if the En and Ru
  additions differ. New `tools/keylayout.py` (ElementTree
  reader, cross-checked with `parse_birman.py` on 576 cells).
- **The Spoon knows no layout name.** ⌥ layers are positional; a dead key composes by the
  character `event:getCharacters()` reports (verified live on ABC, Russian – PC, Greek), so
  any Latin/Cyrillic layout works. `layouts` is gone. `overrides` (`"*"` or an input source
  id, key names or codes, `false`, `{pass=true}`, `dead`/`compose`/`terminators`) is the
  configuration surface. `baseFixups` (ISO `§`/`` ` `` corrections) is opt-in and keyed by
  source id — it is on here, off by default because on ANSI it would turn the grave key into `\`.
- **Verified against the original:** `tests/official_cases.json` (~3 700 presses read from
  Birman's layouts) replays through the real handler: `PASS 14629`, **no deviations**: the
  owner wants exactly Birman, quirks included (En's doubled combining circumflex, Ru's `у`+`¨` → `ÿ`).
  His Russian layout is a `cyrillic` overlay on the English table, chosen when kVK 0 types Cyrillic;
  the README shows how to change any of it with `overrides`.
- **Russian docs (owner's request, an exception to English-only docs):** the Spoon has `README.ru.md`,
  `docs/*.ru.md`, `CHANGELOG.ru.md` and `assets/layout.ru.svg`, each linked to its English twin — keep
  them in step. Birman's own pictures are NOT in the Spoon (removed 2026-09-28: he names the pictures as his);
  the copies stay in the lab's `original/scheme/`.
- **Repo state (2026-09-28):** the Spoon repository was recreated as one commit, tag `v3.9.0`, made
  PUBLIC with a release zip; no Action; no PR to Hammerspoon/Spoons yet; launch posts drafted (now in the lab's `docs/posts/`), to go out ~2026-10-28. **Not done, owner's call:** telling Ilya Birman (his FAQ allows a derived
  layout if credited; the archives stay out of the public repo); whether the nine extras
  should exist at all. The Greek ⇧⌥ layer (tonos letters) is personal, not Birman-derived.

---

**State (2026-09-27, keyboard core reworked; 25–27 Sep). Shipped, committed,
not pushed except `BirmanLayer.spoon`, which is public.** One principle now
governs the whole keyboard stack: **Karabiner owns keys, Hammerspoon owns
meaning.** If a press must become another key (arrow, F-code, media, `⌘←`),
that is Karabiner — the only layer that sees left/right modifiers, devices and
simultaneous presses. If the result needs state or knowledge (frontmost app,
windows, layouts, typing Unicode, a state machine), that is Hammerspoon, at
~1 ms in-process. A job lives in one place, never both. The owner considered and
**rejected**: moving per-app remaps to Karabiner, Punto into Hammerspoon,
disabling the keylog instrumentation or `input_logger`, and "Hyper as a
Hammerspoon modal" — leave those alone unless he raises them.

- **Where things live.** Chord → action: `hammerspoon/Spoons/HotKeys.spoon/layout/60%/<key>.lua`
  (hand-maintained; a binding line plus a row in the ASCII table; the table's
  `karabiner`/`birman`/`G` columns are lint-checked against the real data).
  Actions: `hammerspoon/actions/*.lua` via `register("name", fn)`; the Spoon has
  no personal code. App roles: `constants.env` `APP_*` (browser/alt/work, terminal/alt,
  ide, editor, git_gui, files, messenger…). Hyper layers: `karabiner/layers.toml`
  (one line per chord; `gen_layers.py` writes rules `07`–`17`, never edit those JSON
  files). Other Karabiner rules: hand-written JSON. macOS + third-party hotkeys:
  `macos_shortcuts/` (`shortcuts.toml` + `shortcuts.py capture|check|apply|taps`)
  (applied by `install/17-shortcuts.sh`). Apply keyboard changes with
  `zsh karabiner/build.sh` and `hs.reload()`; check with
  `python3 docs/keyboard/tools/lint.py --strict` (pre-commit runs it).
- **Bridges are a formula, not a table.** Hyper letters that are Hammerspoon
  launchers *and* have left-modifier variants need a Karabiner rename (Hyper =
  four right modifiers, so `hs.hotkey` cannot tell `⇪v` from `⇪⌘v`). Eight letters,
  eight F-keys, by keyboard column: `z=F13 · r f v = F14 F15 F16 · t g b = F17 F18
  F19 · h=F20`; `⇪⌘v → ⌘F16`. Two gestures keep out-of-formula codes: `⌃⌥a+d`
  swap → `num8`, right-`⌥␣` Punto → `num9`. `tools/bridge.py` prints the table.
  Everything else under Hyper is a plain key remap and needs no bridge; non-Hyper
  chords (`⌃⌥⌘h`, `⇧⌃⌥⌘↑`) are bound directly.
- **Layouts are Apple's now** (`ABC`, `Russian – PC`,
  `Greek`). Everything Ilya Birman's layouts added — ⌥/⇧⌥ layers, dead keys,
  the stress mark, plus base fixups (`Ё`, ISO `§`) — is `BirmanLayer.spoon`: an
  event tap on the **right** Option (raw flag 0x40; Hyper is excluded via right
  ⌘/⌃), table generated from the owner's Ukelele bundle (now in
  `~/projects/birman/lab`). Left ⌥ is the stock macOS layer. The
  bundle is no longer installed as a system layout (install step 05 dropped it).
  Public repo <https://github.com/servitola/BirmanLayer.spoon> holds the Spoon dir
  (remote `birman-spoon`; publish as in `docs/keyboard-setup.md`, "Publishing" — not
  `git subtree push`, its history no longer matches);
  one commit tagged `v3.9.0` (versions follow Birman's: `3.9.N`), no GitHub Action (private repos need billing) and no release page. Credit wording is plain ("Thanks to Ilya Birman", "Unofficial"): no "in his honor" phrases anywhere;
  Ilya has not been asked yet — a draft letter exists in the session notes; the
  Hammerspoon/Spoons PR waits for the owner.
- **Tried and rolled back the same day:** generating the Lua layout from a
  `chords.toml`, and a catalog of app shortcuts rendering the tables. Too much
  machinery for one user; the regenerated (data-correct) layout files and the
  Greek-column parser fix were kept. Specs under `docs/superpowers/specs/2026-09-2*`
  carry status lines. The `keylord` extraction (`~/projects/keylord`) is parked;
  BirmanLayer is the only piece that was worth sharing.
- **Gotchas learned:** `hs -c` hangs when stdout is redirected unless stdin is
  `</dev/null`; `hs.application.frontmostApplication()` over `hs -c` hangs the IPC;
  `hs.hotkey.getHotkeys()` labels depend on the layout active at bind time (force
  `En Birman`/`ABC` before `hs.reload()` when comparing); Karabiner reloads on every
  `build.sh` (do not run it mid-keystroke storms); two Boring Notch instances with
  active event taps froze every trackpad click on 26.09 — `shortcuts.py taps` shows
  who sits in the input path.

**Open, all optional (`docs/backlog.md`):** Maccy vs system hotkey 60 — resolved
by itself when Maccy's preview hotkey was cleared; Music duplicate menu entries;
`services` adapter `enabled` flag; leftover prefs of uninstalled apps in
`shortcuts.toml`; three identical Boring Notch taps and the notch cron's kill
order (another session owns that script).

---

**The 2026-09-05 note on the build-fix agent (`claude -p` in the fork-sync jobs)
moved with the jobs** — it is the "Build-fix agent" section of
`~/projects/forks/AGENTS.md` now.

---

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
