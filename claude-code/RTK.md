# RTK

A PreToolUse hook rewrites Bash commands automatically (`git status` → `rtk git status`) to compact their output. Transparent — never prefix `rtk` yourself, and don't "fix" it when you see `rtk` in a command.

- `rtk proxy <cmd>` — run a command bypassing the filter (needed for `du -sh */` and per-directory breakdowns, which RTK mangles).
- Only ~50 built-in tools are compacted (git, grep, ls, find, docker, pytest, cargo, npm, tsc…); everything else (ssh, `uv run script.py`, `python3 -c`) runs raw. Compaction **caps** output (grep 200 hits, `git status` 15 files). If a result looks cut off or you need the complete list, re-run that one command via `rtk proxy <cmd>` for the full output.
- `rtk gain` / `rtk discover` — token-savings analytics (run only when asked).
