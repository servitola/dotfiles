---
name: amphetamine-control
description: |
  Control the Amphetamine.app on macOS via AppleScript / URL scheme:
  start a wake-lock session (indefinite or N minutes/hours), check if a
  session is active, end the session. Falls back to built-in `caffeinate`
  if Amphetamine is not installed.

  Use when: "не давай компу заснуть", "включи amphetamine", "запусти амфетамин",
  "keep mac awake", "stay awake", "отключи сон", "не дай уснуть",
  "продли бодрствование", "останови amphetamine", "выключи амфетамин",
  "проверь активна ли сессия amphetamine", "сколько ещё не заснёт".
---

# Amphetamine Control

Amphetamine.app has no official CLI. The supported automation surface is AppleScript (via `osascript`) and the `amphetamine://` URL scheme. Prefer AppleScript — it returns values you can inspect; URL scheme is fire-and-forget.

If `/Applications/Amphetamine.app` does not exist, use `caffeinate` (built into macOS) instead. Leave installation to the user.

## Start a session

Indefinite (until manually stopped):

```bash
osascript -e 'tell application "Amphetamine" to start new session'
```

Timed session — `duration` is a number, `interval` is `minutes` or `hours`. `displaySleepAllowed:false` keeps the screen on too; set `true` if the user only cares about the machine not sleeping while the lid is open.

```bash
osascript -e 'tell application "Amphetamine" to start new session with options {duration:120, interval:minutes, displaySleepAllowed:false}'
osascript -e 'tell application "Amphetamine" to start new session with options {duration:3, interval:hours, displaySleepAllowed:false}'
```

URL-scheme equivalent (no AppleScript required, but no return value):

```bash
open "amphetamine://start-new-session?duration=120&interval=minutes&displaySleepAllowed=false"
```

If a session is already active, `start new session` is a no-op for an indefinite session, and replaces the timer for a timed one. Call it directly — `end session` first is only needed when the user explicitly asks to restart.

## Check status

`session is active` must be inside a `tell` block — the one-liner form `tell application "Amphetamine" to session is active` is a syntax error in AppleScript.

```bash
osascript -e 'tell application "Amphetamine"
session is active
end tell'
```

Returns `true` / `false`. For remaining time on a timed session, there is no AppleScript getter — Amphetamine intentionally doesn't expose it. Tell the user that if they ask.

## End a session

```bash
osascript -e 'tell application "Amphetamine" to end session'
```

Or:

```bash
open "amphetamine://end-session"
```

Safe to call when no session is active — it's a no-op.

## Fallback: `caffeinate`

Built into macOS, no app needed. Lives in the foreground of whatever shell launched it — Ctrl+C stops it. Useful when Amphetamine is not installed or the user wants something one-shot from a script.

```bash
caffeinate -dimsu           # block display + idle + system sleep until Ctrl+C
caffeinate -t 7200          # 2 hours, then exit
caffeinate -dimsu -w $$     # active while current shell PID is alive
```

Flags: `-d` display, `-i` idle, `-m` disk, `-s` system (only on AC power), `-u` declare user activity, `-t SECONDS` timer, `-w PID` tied to a process.

Trade-off vs Amphetamine: `caffeinate` ties the lock to a running process, so backgrounding it requires `nohup` or a launchd plist. Amphetamine keeps the session across shell sessions and reboots-from-sleep without that ceremony.

## Telling the user what changed

One short line: what was started/stopped, duration if timed, whether the screen is allowed to sleep. If status was checked, just report `active` or `not active`. Show the AppleScript only when the user asks how it works.
