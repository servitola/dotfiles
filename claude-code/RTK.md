# RTK

A PreToolUse hook rewrites Bash commands automatically (`git status` → `rtk git status`) to compact their output. Transparent — never prefix `rtk` yourself, and don't "fix" it when you see `rtk` in a command.

- `rtk proxy <cmd>` — run a command bypassing the filter (needed for `du -sh */` and per-directory breakdowns, which RTK mangles).
- Only ~50 built-in tools are compacted (git, grep, ls, find, docker, pytest, cargo, npm, tsc…); everything else (ssh, `uv run script.py`, `python3 -c`) runs raw. Compaction **caps** output (grep 200 hits, `git status` 15 files). If a result looks cut off or you need the complete list, re-run that one command via `rtk proxy <cmd>` for the full output.
- **A pipe kills the rewrite.** `git status` → `rtk git status`, but
  `git status | head -5` → no rewrite at all. Verified 0.45.0; `&&` and `;`
  chains are fine, only `|` bails. Measured over 30 days of transcripts: 11 760
  Bash calls (23%) started with an RTK built-in and lost the rewrite to a pipe,
  8 545 of them to a bare `| tail -N` / `| head -N`.
  So **do not append `| head -N` / `| tail -N` to a built-in to shorten output**
  — RTK already caps it, and better: `tail -20` is a blind positional cut that
  drops the traceback and keeps the summary, while `rtk pytest` keeps the
  failures and drops the noise. Need a real cap? Use the tool's own flag
  (`rtk read --max-lines`, `rtk grep --max`). Pipe only when you need the pipe's
  *semantics* (`| wc -l`, `| jq`) — and then remember the count is computed over
  raw output, which is why RTK refuses to rewrite there.
- `rtk gain` / `rtk discover` — token-savings analytics (run only when asked).
  `discover`'s "missed savings" table over-reports: it reads transcripts, which
  log the *pre*-rewrite command, so already-handled tools look missed. Confirm
  with `rtk hook check "<cmd>"` before believing a line.
