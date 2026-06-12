# RTK - Rust Token Killer

Token-optimized CLI proxy (60-90% savings on dev operations). A PreToolUse hook rewrites Bash commands automatically (`git status` → `rtk git status`) — transparent, no action needed.

## Meta Commands (always use rtk directly)

```bash
rtk gain              # Token savings analytics (--history for per-command)
rtk discover          # Analyze Claude Code history for missed opportunities
rtk proxy <cmd>       # Execute raw command without filtering (for debugging)
```
