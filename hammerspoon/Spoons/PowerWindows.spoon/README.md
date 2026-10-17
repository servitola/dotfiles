# PowerWindows.spoon
I never move windows with my mouse.
Forget that windows can be dragged.
Every window already knows its place. Need it elsewhere: one key.

One layout, not a collection of them: the app you work in, large, on the left; a panel on the right; a video under it. Everything can be changed, but that is the whole idea.

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

That's all. How to live with it: [docs/guide.md](docs/guide.md).

Messengers already go to the right column and players to the corner under it: the list is [`config/catalog.lua`](config/catalog.lua). Send your own apps to the same places, one line each:

```lua
spoon.PowerWindows:configure{
  overrides = {
    ["com.apple.reminders"] = "side",    -- right column
    ["com.apple.calculator"] = "corner", -- under it
  },
}:start()
```

The name in brackets is the app's bundle ID: `osascript -e 'id of app "Reminders"'`. Prefer to place every app yourself? `catalog = false` switches the built-in list off.

Everything else is optional: [docs/options.md](docs/options.md).
