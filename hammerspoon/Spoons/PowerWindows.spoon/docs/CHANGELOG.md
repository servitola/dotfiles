# Changelog

## 0.3.0 — 2026-10-03

- A chord pressed again does nothing. `cycle = true` restores the second option: left half, right half, native fullscreen. See [keys.md](keys.md).
- `config/catalog.lua` is lists of bundle IDs, one per destination.
- Catalog entries match by `identifier` (`AXIdentifier`). Kaset's video window goes to the corner.
- A window larger than its slot stays on the screen.
- A `rule`, a focus-set handler or a skip predicate that raises is printed to the console and no longer stops the pass.
- `start()` validates override slots; switches such as `cycle` accept only `true` or `false`.
- The README ends at install; everything optional is in [options.md](options.md).
- Three layers: `init.lua` hands `config/` to `lib/core.lua`; `lib/domain.lua` builds on it.
- Tests live outside this repository.

## 0.2.0 — 2026-09-30

- Moves: one AX write per property instead of `setFrame`'s three, for every move (fit, center, stack too): fewer repaints. `animation` `0.05`; `0` = one move.
- `gap`: `1` and above = points; below `1` = share of the screen, as before.
- `screens`: per-screen `gap`, `split`, `sideHeight`, `topShare`, `device`, `dialog`, by name, `portrait` or `ultrawide`.
- `moveToScreen("next" | "prev" | screen)`: same slot on another screen. No default chord.
- `rearrangeOnScreenChange`: arrange all when displays change. Off by default.
- `macosKeys` off by default: [macos-keys.md](macos-keys.md).
- Chords act on the focused window, not the floating picture-in-picture player.
- Arrange all skips minimized windows and hidden apps.
- A typo or a wrong type in nested settings, keys, actions or override slots raises at `configure`.
- `stop()` then `start()` keeps `bindHotkeys` chords.
- Terminal and other text-cell apps cycle on the second press.
- `moveToScreen` keeps the iOS Simulator's shape.

## 0.1.0 — 2026-09-29

- From dotfiles `Windows.spoon`.
- Slots, cycling actions, arrange all, swap sides.
- Minimize and focus next.
- Focus sets, app catalog, dialogs.
- Place on launch (experimental).
- macOS's Globe window keys (`macosKeys`).
