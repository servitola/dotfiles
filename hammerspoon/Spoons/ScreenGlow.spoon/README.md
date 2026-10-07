# ScreenGlow.spoon

[Русский](README.ru.md)

The screen edges glow while an AI agent drives your Mac. Hands off the mouse until it fades.

- Soft pulse along every screen edge, on every display.
- The focused window stays lit, the rest dims.
- Clicks ripple, so you see where the agent clicks.
- A timer in the menu bar; click it to stop the glow.
- A line of text at the bottom says what the agent is doing.
- A watchdog: a crashed agent never leaves the screen glowing.

## Install

Unzip `ScreenGlow.spoon.zip` from the [latest release](https://github.com/servitola/ScreenGlow.spoon/releases/latest) into `~/.hammerspoon/Spoons/`, then in `~/.hammerspoon/init.lua`:

```lua
require("hs.ipc")
hs.loadSpoon("ScreenGlow")
```

`hs.ipc` lets the agent reach Hammerspoon from a shell through the `hs` command. If `hs` is not found, run `hs.ipc.cliInstall()` once in the Hammerspoon console.

## Use

```sh
hs -c 'spoon.ScreenGlow:pulse(300)'                          # glow for up to 5 minutes
hs -c 'spoon.ScreenGlow:pulse(60, "act", "Filling the form")' # color and caption
hs -c 'spoon.ScreenGlow:beat()'                              # flash: something happened
hs -c 'spoon.ScreenGlow:stop()'                              # fade out
```

| Call | Does |
|---|---|
| `pulse(seconds, phase, text)` | Starts the glow or extends it to `seconds` from now. Everything optional: 45 s, `think`, no caption. |
| `beat()` | A short flash, if the glow is on. |
| `stop()` | Fades out. |
| `active()` | `true` while it glows. |

Phases: `think` orange, `act` aqua, `wait` red (the agent waits for you).

Teach your agent when to call it: [docs/claude-code.md](docs/claude-code.md) has hooks for Claude Code.

## Settings

Fields on `spoon.ScreenGlow`, set them after `hs.loadSpoon`:

```lua
spoon.ScreenGlow.phases.act = { hex = "#4f9dff" }
spoon.ScreenGlow.sound_start = nil   -- silent start; nil for sound_stop too
spoon.ScreenGlow.alpha_max = 0.6     -- a calmer pulse
```

All of them with defaults are at the top of [init.lua](init.lua): layers and width of the glow, pulse period, fades, dimming, focus ring, click ripples, caption size, sounds.

## License

MIT
