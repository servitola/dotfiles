# ScreenGlow и Claude Code

[English](claude-code.md)

Два хука в `~/.claude/settings.json`: свечение, пока Claude выполняет команды, управляющие рабочим столом, и затухание, когда его ход закончился.

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

- Первый хук читает вызов инструмента со стандартного ввода и включает свечение, только если команда управляет рабочим столом. Свои инструменты допишите в `osascript|cliclick`.
- Каждая подходящая команда продлевает свечение на 45 с, а хук Stop гасит его в конце хода. Сторожевой таймер погасит его, даже если Claude не завершится нормально.
- `</dev/null` обязателен: без него `hs -c` может зависнуть, когда его вывод перенаправлен.
- `exit 0`: хук никогда не блокирует команду, даже если Hammerspoon не запущен.

Для длинного сценария попросите Claude включать свечение заранее, в `CLAUDE.md`:

```markdown
Перед многошаговым сценарием на рабочем столе (нажатия и клики через osascript, перемещение окон, cliclick)
выполни `hs -c 'spoon.ScreenGlow:pulse(300)'`, чтобы я не трогал мышь.
```
