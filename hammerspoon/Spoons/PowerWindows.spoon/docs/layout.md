# Layout

Every layout setting and what it moves. Defaults: [`config/settings.lua`](../config/settings.lua).

## Slots

```
gap                    gap split
 |                       |  |
 v                       v  v
+-+---------------------+-+------------+-+
| |                     | |  side      | |
| |                     | |            | |
| |  main               | +------------+ | <- sideHeight
| |                     | |  corner    | |
| |                     | |            | |
+-+---------------------+-+------------+-+
0                                        1
```

| Slot | Area |
|---|---|
| `main` | left edge to `split`, full height |
| `side` | `split` to right edge, top to `sideHeight` |
| `corner` | under `side`, to the bottom edge |
| `stack` | one window: `side`; two or more: split to right edge, full height, one cell each |
| `top60` / `bottom40` | full width, divided at `topShare` |

## Settings

Fractions are shares of the screen: `0.73` = 73%.

| Setting | Default | Meaning |
|---|---|---|
| `gap` | `0.005` | below `1`: share of the screen; `1` and up: points. `0` = edge to edge |
| `split` | `0.73` | where the right column starts |
| `sideHeight` | `0.70` | where `side` ends and `corner` begins |
| `topShare` | `0.60` | line between `top60` and `bottom40` |
| `animation` | `0.05` | seconds per move; `0` = one move, no motion |
| `tolerance` | `4` | points; this close to a slot = placed; with `cycle`, the next press takes the second option. Terminal may fall one text cell short |

### Gaps

| Where | Gap |
|---|---|
| left, top | 1 gap |
| right | gap ÷ 1.5 |
| bottom | gap × 1.5 |
| `main` ↔ right column | 1 |
| `side` ↔ `corner` | 2 |
| `corner` | to the bottom edge |
| `video` | 2 gaps above the bottom edge |

Big external monitor: the same gap in points on every screen.

```lua
spoon.PowerWindows:configure{ gap = 8 }:start()
```

## Simulators: `device`

iOS Simulator is sized off the screen, not the column, and overlaps `main`.

| Setting | Default | Meaning |
|---|---|---|
| `device.width` | `0.4` | share of screen width |
| `device.maxHeight` | `0.7` | cap, share of screen height; proportions kept |
| `device.raise` | `0.1` | in `main` or whole screen: above center, share of height |

## Dialogs: `dialog`

A small dialog goes to the top right corner and keeps its size up to:

| Setting | Default | Meaning |
|---|---|---|
| `dialog.width` | `0.9` | share of the right column |
| `dialog.height` | `0.4` | share of `sideHeight` |

## Example

Wider chat, no gaps, smaller phone. `device.maxHeight` stays `0.7`: maps merge key by key, one level deep.

```lua
spoon.PowerWindows:configure{
  gap = 0,
  split = 0.68,
  device = { width = 0.35 },
}:start()
```

A misspelled setting, nested ones too, or a wrong type raises an error naming it.

## Screens

A profile per screen: `gap`, `split`, `sideHeight`, `topShare`, `device`, `dialog`. Anything else raises an error.

| Key | Applies to |
|---|---|
| screen name | that screen: `for _, screen in ipairs(hs.screen.allScreens()) do print(screen:name()) end` in the console |
| `portrait` | taller than wide |
| `ultrawide` | width ÷ height ≥ 2.1 (3440×1440, 2560×1080) |

Name beats shape. One profile applies, over the base settings.

```lua
spoon.PowerWindows:configure{
  screens = {
    portrait = { split = 0.5, device = { width = 0.6 } },
    ultrawide = { split = 0.8, gap = 12 },
    ["DELL U2723QE"] = { gap = 8, split = 0.68 },
  },
}:start()
```

## Another screen

`moveToScreen("next" | "prev" | hs.screen)` keeps the slot: the one the window sits in (`main`, `side`, `corner`, `full`, halves, `top60`, `bottom40`), else its own. No default chord: [keys.md](keys.md#other-methods).

Rearrange everything 1 s after a display comes or goes:

```lua
spoon.PowerWindows:configure{ rearrangeOnScreenChange = true }:start()
```

## Check a slot

```lua
hs.inspect(spoon.PowerWindows:slotRect("side"))
```

Names: `main`, `side`, `corner`, `video`, `full`, `halfLeft`, `halfRight`, `top60`, `bottom40`, `column`.
