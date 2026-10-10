# rtk — Rust Token Killer config

## What lives here (version-controlled)
- `config.toml`  — global RTK config (mirrors built-in defaults; tune here).
- `filters.toml` — custom per-command output filters. Only `docker-compose`
  survives; the rest were inert (see below).

Both are symlinked into `~/Library/Application Support/rtk/`.

## What is NOT tracked (runtime data, lives only in Application Support)
- `history.db` — per-command savings analytics (large, ephemeral).
- `tee/`       — captured stdout/stderr of failed commands.
- `.DS_Store`, `.hook_warn_last`.

## How RTK is wired
- **Auto-rewrite**: a Claude Code PreToolUse hook (`rtk hook claude`, see
  `claude-code/settings.json`) rewrites Bash commands transparently
  (`git status` → `rtk git status`) via `hookSpecificOutput.updatedInput`.
  It also rewrites an **inner** built-in inside a wrapper
  (`uv run pytest` → `uv run rtk pytest`). Fires in main **and** subagent
  contexts (verified: subagent Bash calls get `agent_id` + compacted output;
  note the transcript logs the *pre*-rewrite command, so counting `rtk `
  prefixes in transcripts undercounts real coverage — measure via `history.db`).
- **Docs for the AI**: `claude-code/RTK.md` (imported into the global CLAUDE.md).

## Trust gate (rtk ≥0.44)
`rtk gain` prints `[rtk] N untrusted custom filter(s) not applied` until you run
`rtk trust` (`--yes` for non-interactive). Trust is stored **outside this repo**
in `~/Library/Application Support/rtk/trusted_filters.json` (untracked machine
state, alongside history.db) as *path + sha256 of the target*, so any edit to
`filters.toml` un-trusts it and the banner returns. `up` re-runs
`rtk trust --yes` from `$HOME` for exactly this reason — from `$HOME` there is no
project-local `.rtk/filters.toml`, so it can only ever trust our own
version-controlled file. Revoke with `rtk untrust`.

Filters are declarative only — the schema (`TomlFilterDef`) is
`match_command` / `strip_ansi` / `strip_lines_matching` / `keep_lines_matching`
/ `max_lines` / head / tail / regex replace. **No command execution.** The trust
prompt exists because a hostile project-local `.rtk/filters.toml` could silently
*hide* lines (errors, diffs) from the agent, not because it could run code. That
is also the only real cost of a bad filter of your own: `max_lines` truncation.

## ⚠️ Custom filters.toml do NOT auto-trigger (verified rtk 0.43.0, still true 0.45.0)
The hook only rewrites its **hardcoded ~50 built-in tools** (`rtk --help`:
git, grep, rg, ls, find, cat/read, docker, kubectl, npm, npx, cargo, go, pip,
pytest, ruff, mypy, tsc, lint, prettier, playwright, gradlew, mvn, gh, curl,
wget, wc…). It does **not** consult `filters.toml` to decide what to rewrite —
there is no include-list config, only `[hooks] exclude_commands`. So a custom
filter for a **non-built-in** command never fires, because the hook never routes
it into rtk. Verify any candidate with `rtk hook check "<cmd>"` — if it says
`No rewrite for: …`, a filter is inert. The `python3` / `hs` / `launchctl` /
`git ls-files` filters were **deleted 2026-08-09** — re-checked on 0.45.0, all
four still `No rewrite for: …`. Only `docker compose` routes in
(`rtk docker compose ps`). Custom filters only
help when rtk already handles the command (they augment a built-in handler) or
when invoked explicitly as `rtk <cmd>` — which the hook won't do for you.

**To actually cover more:** the command must be a built-in, or wrap a built-in
so the inner rewrite fires (`uv run pytest` works; `uv run script.py` and `ssh`
stay raw — no local fix in 0.43.0). `rtk discover` lists bypassed commands but
its "add a filter" suggestion is misleading here — a filters.toml entry won't
change the hook's rewrite decision. Real levers are upstream (file/upvote
rtk-ai/rtk) or accepting built-in-only coverage.

## Useful meta commands
- `rtk gain`     — token savings so far (global). A `rtk:toml` prefix in the
  per-command table means a TOML filter did the work — those are the *bundled*
  ones inside the binary (ps, make, jq, du, gcloud, helm, gradle…), not
  `filters.toml`.
- `rtk verify`   — hook integrity + bundled filter self-tests (expect
  `154/154 tests passed` on 0.45.0). Run after any RTK upgrade.
- `rtk discover` — commands still bypassing RTK + est. savings. **Its "missed
  savings" table is unreliable**: it scans transcripts, which log the
  *pre*-rewrite command, so things the hook already rewrites (`git diff`,
  `grep -n`, `ls -la`, `make`, `ps`, `pre-commit`) show up as "missed". Confirm
  any line with `rtk hook check "<cmd>"` before acting on it. The
  TOP UNHANDLED section is the honest half.
- `rtk learn`    — "CLI corrections" from history. Not run by `up` any more (see
  note below); never use `--write-rules`.

### Note on `rtk learn`
It pairs a failed Bash call with the next successful one that shares its "base
command" — the first two words — and reports the second as the fix. Agent
commands here start with `cd <dir> && …`, so the base command is the directory
and any two unrelated commands run in one project become a correction. Measured
2026-10-02 on rtk 0.50.0 (`rtk learn --all`, 1316 sessions): 547 pairs, 374 of
them keyed on `cd`, 471 typed "General Error". The only pair that passed
`--min-occurrences 2` said to run `sed -n '90,140p' pyproject.toml` instead of
`ruff check`.

`--write-rules` puts the result in `~/.claude/rules/cli-corrections.md`, which
Claude Code loads into every session as an instruction. `up` used to do that on
every run, so a false rule of this kind was always live. The step was removed
and the file deleted; the real lever stays the same — turn recurring *inline
heredocs* into named scripts in `zsh/bin/` (see `docs/commands.md`).
