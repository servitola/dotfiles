# PowerWindows.spoon
I never move windows with my mouse.
Forget that windows can be dragged.
Every window already knows its place. Need it elsewhere: one key.

![demo](docs/demo.gif)

| Key | Window goes to |
|---|---|
| `⌃⌥←` | left column |
| `⌃⌥→` | right column |
| `⌃⌥↑` | whole screen |
| `⌃⌥↓` | its place, and every other window to its own |

Also on: `⌃⌥WASD` = the arrows, `⇧` for halves and 60/40.

## Install

Unzip `PowerWindows.spoon.zip` from the latest release into `~/.hammerspoon/Spoons/`, then:

```lua
hs.loadSpoon("PowerWindows")
spoon.PowerWindows:start()
```

That's all. How to live with it: [docs/guide.md](docs/guide.md). Everything else is optional: [docs/options.md](docs/options.md).
