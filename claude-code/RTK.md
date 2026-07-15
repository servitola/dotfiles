# RTK

A PreToolUse hook rewrites Bash commands automatically (`git status` → `rtk git status`) to compact their output. Transparent — never prefix `rtk` yourself, and don't "fix" it when you see `rtk` in a command.

- `rtk proxy <cmd>` — run a command bypassing the filter (needed for `du -sh */` and per-directory breakdowns, which RTK mangles).
- `rtk gain` / `rtk discover` — token-savings analytics (run only when asked).
