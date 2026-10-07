# How to live with it

You never move windows. Every window knows its place. Four keys, when you really need them: `⌃⌥←` `⌃⌥→` `⌃⌥↑` `⌃⌥↓`. The rest is optional.

## The loop

| Chord | Window goes to |
|---|---|
| `⌃⌥←` | left column |
| `⌃⌥→` | right column |
| `⌃⌥↑` | whole screen, with gaps |
| `⌃⌥↓` | its place, and every other window to its own |

Two apps side by side: `⇧⌃⌥←` on one, `⇧⌃⌥→` on the other. Back: `⌃⌥↓`.

With `cycle = true` a chord pressed again gives the second option: left half, right half, native fullscreen ([options.md](options.md#press-again)).

A player or a dialog keeps its place on `⌃⌥→`. From native fullscreen, `⌃⌥←` and `⌃⌥→` leave it first.

Same on `W A S D`; halves and 60/40 on `⇧`: [keys.md](keys.md).

## Morning

Open what you need. Press `⌃⌥↓`: the editor left, the chat right, the player in the corner.

A focused window in native fullscreen only leaves it on the first `⌃⌥↓`. Press again.
A background window stretched to the whole screen stays stretched. Minimized windows and hidden apps stay where they are.

## The shape

```
+------------------------------+----------+
|                              |  side    |
|                              |  chat    |
|  main                        |          |
|  the app you work in         +----------+
|                              |  corner  |
|                              |  video   |
+------------------------------+----------+
```

- `main`: every app, unless told otherwise.
- `side`: messengers.
- `corner`: players and picture-in-picture.
- `stack`: simulators. Two or more share the right column evenly.

Which app goes where: [apps.md](apps.md). Proportions: [layout.md](layout.md).

## Optional

Nothing below is needed.

### Minimize and go on

macOS minimizes and leaves focus nowhere. `minimizeAndFocusNext` focuses the next window: same app first. Corner video is skipped. On `⌘H` (replaces Hide):

```lua
spoon.PowerWindows:bindHotkeys{ minimizeAndFocusNext = { { "cmd" }, "h" } }
```

### Swap sides

`swapSides`: the two top windows trade sides. Both at once: [keys.md](keys.md#swap-sides-on-a-and-d-together).

### Second monitor

Laptop plus a big screen. A window keeps its slot on either; the big one gets gaps in points.

```lua
local powerWindows = spoon.PowerWindows
powerWindows:configure{
  screens = { ["DELL U2723QE"] = { gap = 8, split = 0.68 } },
  rearrangeOnScreenChange = true,
}:start()
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "right", function() powerWindows:moveToScreen("next") end)
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "left", function() powerWindows:moveToScreen("prev") end)
```

Screen names: `for _, screen in ipairs(hs.screen.allScreens()) do print(screen:name()) end` in the console. Profiles by shape: [layout.md](layout.md#screens).

### Focus sets

A desktop for one kind of work: kept apps come back to their places, the rest hide. An open picture-in-picture window stays.

```lua
spoon.PowerWindows:configure{
  focusSets = {
    work = {
      keep  = { "com.jetbrains.rider", "com.DanPristupov.Fork", "org.mozilla.firefox", "ru.keepcoder.Telegram" },
      focus = { "org.mozilla.firefox", "com.jetbrains.rider" },
    },
    personal = {
      keep  = { "com.colliderli.iina" },
      focus = { "ru.keepcoder.Telegram" },
      video = "corner",
    },
    comms = {
      keep  = { "ru.keepcoder.Telegram", "us.zoom.xos" },
      focus = { "us.zoom.xos", "ru.keepcoder.Telegram" },
    },
  },
}:start()
```

| Field | Meaning |
|---|---|
| `keep` | bundle IDs: unhidden, unminimized, placed |
| `focus` | bundle IDs: the first running one gets focus |
| `video` | where a kept video popup goes: `"main"` (default; `"left"` is the same) or `"corner"` |
| `custom` | `{ [bundle] = function(app, powerWindows) }`: your own handling |

Firefox and Zen: a front tab whose title contains a `videoTitleMarkers` word is popped into picture-in-picture first, so it survives.

No chords by default. Example, `⇧⌃⌥⌘` + arrows:

```lua
local powerWindows = spoon.PowerWindows
for key, name in pairs({ up = "work", left = "personal", right = "comms" }) do
  hs.hotkey.bind({ "shift", "ctrl", "alt", "cmd" }, key, function() powerWindows:focusSet(name) end)
end
```

An unknown set name returns `false` and does nothing. Scripts call `focusSet()` directly: a synthesized chord does not reach a Hammerspoon hotkey.
