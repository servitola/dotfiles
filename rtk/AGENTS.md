# rtk/ — Rust Token Killer config

RTK is a CLI proxy that filters/compacts command output before it reaches the
LLM context (60–90% token savings on dev ops). Installed via Homebrew.

## What lives here (version-controlled)
- `config.toml`  — global RTK config (mirrors built-in defaults; tune here).
- `filters.toml` — custom per-command output filters (python3, hammerspoon,
  launchctl, docker-compose, git ls-files, …). Add new noisy commands here.

Both are symlinked by the Makefile into `~/Library/Application Support/rtk/`.

## What is NOT tracked (runtime data, lives only in Application Support)
- `history.db` — per-command savings analytics (large, ephemeral).
- `tee/`       — captured stdout/stderr of failed commands.
- `.DS_Store`, `.hook_warn_last`.

## How RTK is wired
- **Auto-rewrite**: a Claude Code PreToolUse hook (`rtk hook claude`, see
  `claude-code/settings.json`) rewrites Bash commands transparently
  (`git status` → `rtk git status`), including `&&`-chains. No manual prefixing.
- **Docs for the AI**: `claude-code/RTK.md` (imported into the global CLAUDE.md).

## Adding a filter
Edit `filters.toml`, then `rtk config` to confirm it loads. A filter matches a
command by regex (`match_command`) and strips/caps its output. Find candidates
with `rtk discover` (missed savings) — the top "unhandled" commands are the ones
worth a filter.

## Useful meta commands
- `rtk gain`     — token savings so far (global).
- `rtk discover` — commands still bypassing RTK + est. savings.
- `rtk learn`    — recurring CLI corrections from history (see note below).

### Note on `rtk learn`
For this user it currently yields **0 recurring rules** — corrections are
overwhelmingly unique one-off heredocs, not repeated mistakes. The real lever is
turning recurring *inline heredocs* into named scripts in `zsh/bin/` (see
`docs/commands.md`), so they stop being opaque one-liners RTK can't compact.
