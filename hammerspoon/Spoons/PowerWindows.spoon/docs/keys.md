# Keys

Every chord and action, and how to change them.

## Default chords

Bound by `start()`.

| Chord | Action | Press again, with `cycle` |
|---|---|---|
| `⌃⌥←` `⌃⌥A` | `left`: to `main` | left half |
| `⌃⌥→` `⌃⌥D` | `right`: to `side` | right half |
| `⌃⌥↑` `⌃⌥W` | `fullscreen`: whole screen, with gaps | native fullscreen |
| `⌃⌥↓` `⌃⌥S` | `arrangeAll`: every window to its place | — |
| `⇧⌃⌥←` `⇧⌃⌥A` | `halfLeft` | — |
| `⇧⌃⌥→` `⇧⌃⌥D` | `halfRight` | — |
| `⇧⌃⌥↑` `⇧⌃⌥W` | `top60` | — |
| `⇧⌃⌥↓` `⇧⌃⌥S` | `bottom40` | — |

Pressing again does nothing by default: one chord, one place. `cycle = true` turns the second option on: the window already sits in that slot, within `tolerance`. A third press of `left` or `right` returns to the column; native fullscreen is left by `left`, `right` or `arrangeAll`.

```lua
spoon.PowerWindows:configure{ cycle = true }:start()
```

## Actions without a chord

| Action | Does |
|---|---|
| `center` | centers the window, size kept |
| `swapSides` | swaps the two top windows, left and right |
| `minimizeAndFocusNext` | minimizes, focuses the next window: same app first |
| `minimizeCurrent` | minimizes the focused window |

These twelve actions are all `bindHotkeys` and `macosKeys` accept.

## Add a chord

`{ action = { mods, key } }`, or a list of chords per action. `stop()` pauses it, `start()` resumes.

```lua
spoon.PowerWindows:bindHotkeys{
  center = { { "ctrl", "alt" }, "c" },
  minimizeAndFocusNext = { { "cmd" }, "h" },
  swapSides = { { { "ctrl", "alt" }, "x" }, { {}, "pad8" } },
}
```

## Other methods

`moveToScreen`, `focusSet`, `placeDefault`, `moveLeft`: bind with `hs.hotkey`.

```lua
local powerWindows = spoon.PowerWindows
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "right", function() powerWindows:moveToScreen("next") end)
hs.hotkey.bind({ "ctrl", "alt", "cmd" }, "left", function() powerWindows:moveToScreen("prev") end)
hs.hotkey.bind({ "shift", "ctrl", "alt", "cmd" }, "up", function() powerWindows:focusSet("work") end)
```

## Change the default chords

`keys` in [`config/settings.lua`](../config/settings.lua). Each field you give replaces that field whole; a misspelled field or action raises at `configure`.

```lua
spoon.PowerWindows:configure{
  keys = {
    mods = { "cmd", "alt" },
    shiftMods = { "shift", "cmd", "alt" },
    letters = { left = "h", right = "l", fullscreen = "k", arrangeAll = "j" },
  },
}:start()
```

Arrows only: `wasd = false`. No chords at all: `hotkeys = false`. Key settings apply on the next `start()`.

```lua
spoon.PowerWindows:configure{ hotkeys = false }:start()
hs.hotkey.bind({ "cmd", "alt" }, "left", function() spoon.PowerWindows:left() end)
```

## macOS's own window keys

`🌐⌃` + arrows, `F`, `C` stay macOS's until `macosKeys` names them: [macos-keys.md](macos-keys.md).

## Swap sides on A and D together

`hs.hotkey` cannot see two keys at once; Karabiner-Elements can. This rule turns `⌃⌥A`+`D` and `⌃⌥←`+`→` within 50 ms into keypad 8.
Karabiner › Complex Modifications › Add your own rule:

```json
{
  "description": "Ctrl+Option + A and D together = keypad 8 (PowerWindows swapSides)",
  "manipulators": [
    {
      "type": "basic",
      "from": {
        "modifiers": { "mandatory": ["left_control", "left_option"] },
        "simultaneous": [{ "key_code": "a" }, { "key_code": "d" }]
      },
      "parameters": { "basic.simultaneous_threshold_milliseconds": 50 },
      "to": [{ "key_code": "keypad_8" }]
    },
    {
      "type": "basic",
      "from": {
        "modifiers": { "mandatory": ["left_control", "left_option"] },
        "simultaneous": [{ "key_code": "left_arrow" }, { "key_code": "right_arrow" }]
      },
      "parameters": { "basic.simultaneous_threshold_milliseconds": 50 },
      "to": [{ "key_code": "keypad_8" }]
    }
  ]
}
```

```lua
spoon.PowerWindows:bindHotkeys{ swapSides = { {}, "pad8" } }
```

Cost: a lone `⌃⌥A` or `⌃⌥←` waits up to 50 ms for its partner.
