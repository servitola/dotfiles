# Options

PowerWindows works with no configuration. Each section below is one thing you can change.

## Proportions

Defaults, every setting: [`config/settings.lua`](../config/settings.lua). Layout settings explained: [layout.md](layout.md).
`gap` 1 and up = points.

```lua
spoon.PowerWindows:configure{ split = 0.68, gap = 8 }:start()
```

## Per-app places

Slots: `main`, `side`, `corner`, `stack`, `dialog`; `false` = never placed automatically. More: [apps.md](apps.md).

```lua
spoon.PowerWindows:configure{
  overrides = { ["com.tinyspeck.slackmacgap"] = "main", ["com.example.overlay"] = false },
}:start()
```

## Keys

All actions and rebinding: [keys.md](keys.md).
`🌐⌃` keys stay macOS's: [macos-keys.md](macos-keys.md).

```lua
spoon.PowerWindows:configure{ wasd = false }:start()
spoon.PowerWindows:bindHotkeys{ center = { { "ctrl", "alt" }, "c" } }
```

## Second screen

The window keeps its slot on the next screen. Each screen can have its own proportions: [layout.md](layout.md#screens).

```lua
spoon.PowerWindows:configure{ screens = { portrait = { split = 0.5 } } }:start()
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "right", function() spoon.PowerWindows:moveToScreen("next") end)
```

## Focus sets

One call: kept apps take their places, the rest hide. [guide.md](guide.md#focus-sets).

```lua
spoon.PowerWindows:configure{ focusSets = { work = { keep = { "com.jetbrains.rider" } } } }:start()
hs.hotkey.bind({ "shift", "ctrl", "alt", "cmd" }, "up", function() spoon.PowerWindows:focusSet("work") end)
```

## Missing app or dialog

One line in [`config/catalog.lua`](../config/catalog.lua) or [`config/dialogs.lua`](../config/dialogs.lua), as a pull request. For yourself: `overrides` ([apps.md](apps.md)).

## Press again

Off by default. With `cycle = true` a key pressed again, the window already there, gives the second option: left half, right half, native fullscreen. More: [keys.md](keys.md).

```lua
spoon.PowerWindows:configure{ cycle = true }:start()
```
