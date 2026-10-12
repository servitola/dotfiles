# rtk — Rust Token Killer config

- `config.toml` and `filters.toml` are linked into `~/Library/Application Support/rtk/`.
  Everything else there (`history.db`, `tee/`, `trusted_filters.json`) is machine state and
  stays untracked.
- **Wiring:** the Claude Code PreToolUse hook `rtk hook claude` (`claude-code/settings.json`)
  rewrites Bash commands (`git status` → `rtk git status`), also an inner built-in inside a
  wrapper (`uv run pytest` → `uv run rtk pytest`), in the main session and in subagents. What
  the agent is told about it is `claude-code/RTK.md`.
- **Transcripts log the command before the rewrite.** Counting `rtk ` prefixes in them
  undercounts coverage, and the "missed savings" table of `rtk discover` lists commands the
  hook already handles; its TOP UNHANDLED section is the honest half. Measure with
  `history.db`, confirm one command with `rtk hook check "<cmd>"`.

## A filter in filters.toml does not make the hook rewrite a command

The hook rewrites only its ~50 built-in tools (`rtk --help`) and never consults
`filters.toml`; the only knob is `[hooks] exclude_commands`. A filter for any other command
is inert: `rtk hook check "<cmd>"` answers `No rewrite for: …`. That is why the `python3`,
`hs`, `launchctl` and `git ls-files` filters were deleted (2026-08-09, re-checked on 0.45.0)
and only `docker-compose` is left — `docker` is a built-in, so the filter augments it.

To cover more, the command has to be a built-in or wrap one. `uv run script.py` and `ssh`
stay raw, and nothing local changes that.

## Trust

`rtk gain` prints `N untrusted custom filter(s) not applied` until `rtk trust --yes`. Trust
is the path plus the sha256 of `filters.toml`, so every edit revokes it. `up` re-trusts from
`$HOME`, where no project-local `.rtk/filters.toml` exists, so it can only trust this file.
Filters are declarative (strip, keep, truncate lines) and run no code: the prompt guards
against a project hiding errors from the agent.

## After an upgrade

`rtk verify` — hook integrity and the bundled filters' self-tests.

## Never `rtk learn --write-rules`

`rtk learn` pairs a failed command with the next successful one sharing its first two words.
Agent commands start with `cd <dir> && …`, so two unrelated commands in one project become a
"correction": 374 of 547 pairs on 2026-10-02 (rtk 0.50.0) were keyed on `cd`.
`--write-rules` writes them to `~/.claude/rules/`, which Claude Code loads into every session
as instructions. `up` no longer runs it.

## codex-hook.sh

Codex speaks Claude Code's hook protocol, but needs `hookSpecificOutput.permissionDecision`
in the reply, which rtk does not write; the shim adds it. Wired in `~/.codex/hooks.json`.
Verified on codex-cli 0.149.0 (2026-08-24).

- **An untrusted hook is skipped silently**, which looks exactly like a broken shim. Re-run
  with `--dangerously-bypass-hook-trust`: if the rewrite appears, only trust is missing.
- Trust is written by the interactive TUI prompt alone (it is not a hash of `hooks.json` or
  of the script), so it takes one interactive `codex` run in a real terminal.
- **That flag must not go into the Telegram bot's codex argv.** `~/.codex/` is writable by
  every agent the bot spawns, so one topic could plant a `hooks.json` whose command then
  runs in every other topic's session.
