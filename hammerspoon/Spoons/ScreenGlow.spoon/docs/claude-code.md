# ScreenGlow with Claude Code

[Русский](claude-code.ru.md)

Two hooks in `~/.claude/settings.json`: glow while Claude runs desktop commands, fade out when its turn ends.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "grep -qE 'osascript|cliclick' && hs -c \"spoon.ScreenGlow:pulse(45, 'act'); spoon.ScreenGlow:beat()\" </dev/null >/dev/null 2>&1; exit 0",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "hs -c 'spoon.ScreenGlow:stop()' </dev/null >/dev/null 2>&1; exit 0",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

- The first hook reads the tool call from stdin and lights up only when the command drives the desktop. Add your own tools to `osascript|cliclick`.
- Each matching command extends the glow by 45 s, and the Stop hook fades it out when the turn ends. The watchdog puts it out even if Claude never stops cleanly.
- `</dev/null` is required: without it `hs -c` can hang when its output is redirected.
- `exit 0`: the hook never blocks the command, even when Hammerspoon is not running.

For a long scenario, ask Claude to light the glow up front, in `CLAUDE.md`:

```markdown
Before a multi-step desktop scenario (osascript keystrokes/clicks, window moves, cliclick),
run `hs -c 'spoon.ScreenGlow:pulse(300)'` so I keep my hands off the mouse.
```
