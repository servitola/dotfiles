# Keyboard Setup Guide

Complete documentation of the keyboard customization system including Karabiner-Elements, Hammerspoon, custom layouts, and shortcuts.

## Quick reference — where to change what

One principle: **Karabiner owns keys, Hammerspoon owns meaning.** A press that
must become another key is Karabiner's; a result that needs state or knowledge
(apps, windows, layouts, Unicode) is Hammerspoon's. A job lives in one place.

| I want to… | Edit | Apply |
|---|---|---|
| bind a chord to an app / window action / function | `hammerspoon/Spoons/HotKeys.spoon/layout/60%/<key>.lua` — a `{ chord = …, app\|fn = … }` line plus a row in the ASCII table | save; Hammerspoon reloads itself |
| add a new function for a chord | `hammerspoon/actions/<group>.lua` → `register("name", function() … end)` | same |
| change which app plays a role everywhere | `constants.env` → `APP_BROWSER=…`, `APP_IDE=…`, … | `hs -c 'hs.reload()' </dev/null` |
| make Hyper + key send a key (arrow, PgUp, media) | `karabiner/layers.toml`, the layer's table, one line | `zsh karabiner/build.sh` |
| a special Karabiner rule (gesture, mouse, shell) | `karabiner/rules/NN-*.json` by hand | same |
| a macOS / Shottr / Maccy / menu shortcut | `macos_shortcuts/shortcuts.toml` | `python3 macos_shortcuts/shortcuts.py apply` |
| a character on the right Option layer | `layer.overrides` in `hammerspoon/init.lua` (shape: the Spoon's `docs/configuration.md`) | `hs.reload()`; `python3 docs/keyboard/generate.py` |

The rule to remember: eight Hyper launcher letters are renamed to F-keys by
keyboard column — `z=F13 · r f v = F14 F15 F16 · t g b = F17 F18 F19 · h=F20`,
left modifiers ride along (`⇪⌘v` = `⌘F16`). `python3 docs/keyboard/tools/bridge.py`
prints it. Check everything with `python3 docs/keyboard/tools/lint.py --strict`
(pre-commit runs it). Never open: `karabiner/rules/07…17.json`, `karabiner.json`,
`app_bundle_ids.lua`, `typography_table.lua` — all generated.

## Overview

The keyboard setup consists of three main components:
- **Karabiner-Elements**: Remaps original keyboard to my set of keycodes. Including Caps Lock (Hyper) as all 4 right modifiers at once
- **Layouts**: Apple's `ABC`, `Russian – PC` and `Greek`; BirmanLayer.spoon adds Ilya Birman's typographic layers on the right Option key (see *Typographic layer*).
- **Hammerspoon**: Catches key events and runs the apps and specific functions

## Key Concepts

- **External 60% keyboard compatibility**: Same behavior on both internal and 60% external keyboards
- **60% keyboard usage**: media keys remain media keys; `fn` is left unmapped on the MacBook — it carries the mirror layer (below), so `⌃` sits one key further right there than on the 60% board
- **Same topic actions on same keys**: Related functionality uses consistent keys across different contexts (e.g., Hyper+G = Git client, Rider Ctrl+G = Git window, Rider Ctrl+Shift+G = file history)
- **Not changing macOS default shortcuts**: Respect system shortcuts to avoid conflicts
- **Left-hand focus**: Left hand can access all needed work shortcuts for ergonomic efficiency
- **Shortcut accessibility hierarchy**: Easy-to-reach shortcuts for frequent actions, harder combinations (Ctrl+Shift+Hyper) for less frequent but important functions

## Karabiner-Elements Configuration

Source of truth: per-rule JSON files in `karabiner/rules/`. Each file is one logical concern (e.g. `05-grave-to-escape.json`, `30-fn-layer-mirror.json`); the Hyper layers `07`–`17` are generated from `karabiner/layers.toml` (see below). The combined `karabiner.json` consumed by Karabiner-Elements is **generated** — run `karabiner/build.sh` after editing rules.

The Hyper layers (`07`–`17`) are themselves generated: edit `karabiner/layers.toml` (one `key_code = "output"` table per layer) and run `karabiner/build.sh`, which calls `docs/keyboard/tools/gen_layers.py`; bridge slots come from its `[slots]` table, and what the table cannot express goes to `karabiner/layers.raw/<rule>.json` (see `karabiner/AGENTS.md`).

### Caps Lock → Hyper
Caps Lock sends Right Shift + Right Command + Right Control + Right Option simultaneously. Hammerspoon binds chords against this 4-mod set, so it never collides with real left-modifier shortcuts.

### F-key remaps
`hs.hotkey` cannot tell `⇪v` from `⇪⌘v` (both carry ⌘), so the eight Hyper letters Hammerspoon launches from and that have left-modifier variants — `z r f v t g b h` — are renamed by Karabiner to an F-key, the letter's **slot**. Slots follow the left-hand keyboard columns, left to right, top to bottom: `q a z` → `z = F13`; `r f v` → `F14 F15 F16`; `t g b` → `F17 F18 F19`; `y h n` → `h = F20`. Every Hyper layer sends `⇪ [+left modifiers] X` as `[same modifiers] slot(X)` — `⇪v` → `F16`, `⇪⌘v` → `⌘F16`, `⇪⇧t` → `⇧F17` — unless `layers.toml` (or `layers.raw/`) maps that letter in that layer itself (`⇪⌘f` → `⌘o`). A new variant therefore needs only the Lua binding. Chords without Hyper (`⌃⌥⌘h`, `⇧⌃⌥⌘←`) and `⇪⇧␣` are bound directly.

Two gestures keep a keypad code: `⌃⌥a+d` / `⌃⌥←+→` (swap windows) → `num8`, right `⌥␣` (Punto) → `num9`; `num0`–`num7` stay free for future slot letters. The UGREEN mouse's held button 5 sends `F16`, the same as `⇪v`.

- `python3 docs/keyboard/tools/bridge.py` prints every slot with the chord and the layout binding on each code, the two exceptions, and the free codes.
- Lint: `B2` fails when a layout binds an F13–F20/keypad code that is neither a slot variant nor `num8`/`num9`; `B4` warns when a `layers.raw/` manipulator would fit the table; `G1` fails when rules `07`–`17` differ from what `gen_layers.py` generates.
- An app's own global hotkey on an F13–F20 chord (Maccy's popup, see `macos_shortcuts/shortcuts.toml`) fires from whichever slot variant sends that chord, so re-slotting a letter moves the app's trigger with it.

## Machine shortcuts (system + apps)

Shortcuts that live in macOS preferences rather than in this repo are declared in `macos_shortcuts/shortcuts.toml`, one row each:

- `[[system]]` — every `com.apple.symbolichotkeys` id, enabled or not. Most are disabled on purpose so the chord goes to an app instead (screenshots `28`–`31` so Shottr owns `⇧⌘3`/`⇧⌘4`, Spotlight `64`, …). `id` is the identity; `name` is only a label, `"unknown"` for ids nobody has pinned down.
- `[[app]]` — an app's own global hotkey; `format` says how the app stores it (default `keyboardshortcuts`, so rows without the field stay valid; `capture` always writes it). `keys = "none"` when unset.
- `[[menu]]` — `NSUserKeyEquivalents`, a shortcut on any menu item by its exact title (System Settings → Keyboard → App Shortcuts); `NSGlobalDomain` means all apps.

`keys` uses the layout chord grammar (`⇧⌃⌥⌘` + key glyph), plus `🌐` for fn/Globe, which only symbolic hotkeys can hold (`docs/keyboard/keycodes.py` converts). `python3 macos_shortcuts/shortcuts.py`:

- `capture --write` rewrites the file from the running machine; sorted, so an unchanged machine re-captures to no diff.
- `check` reads only: prints every row that is not `ok` (`differs`, `missing`, or `unwritable` when the app is sandboxed) and exits 1 if there is one; warns about symbolic ids the file does not declare. `up` runs `capture --write` on every pass, so the file follows the machine; run `check` by hand to see the difference without rewriting.
- `apply` (install step `install/17-shortcuts.sh` runs it, not on CI) writes the rows that differ, then runs `activateSettings -u` for symbolic hotkeys and `killall cfprefsd` after any app or menu write, and names the apps to relaunch. Sandboxed apps (a `~/Library/Containers/<domain>` exists) cannot be written from a script and are skipped with "set it by hand". `--dry-run` prints the `defaults write` commands instead.

### App hotkey formats

No macOS API enumerates the global hotkeys apps have registered: `RegisterEventHotKey` and event taps are private to the process that made them. So `[[app]]` covers only the stores found by reading every installed app's preferences (inventory of 2026-09-26):

| format | how it is stored | apps on this machine | apply |
|---|---|---|---|
| `keyboardshortcuts` | `KeyboardShortcuts_<name>` = JSON `{carbonKeyCode, carbonModifiers}`, `false`/`0` = none; found by `defaults find` | Shottr, Maccy, Boring Notch (all sandboxed), VoiceInk, ChatGPT (uninstalled, prefs left) | writable unless sandboxed |
| `masshortcut` | `{keyCode, modifierFlags}` dict, NSEvent flags; cleared = key absent | Itsycal `GlobalShortcut` | writable; `none` refused (would need a delete) |
| `carbon-dict` | same dict, Carbon flags | Day One `DOMenuEntryGlobalShortcut` (group container) | unwritable (group container) |
| `ice` | `Hotkeys` → JSON data `[keyCode, modifiers]` in Ice's own flag set, or `null` | Ice | read-only: only `null`s here, encoding taken from Ice's source |
| `services` | pbs `NSServicesStatus` → `<service> → key_equivalent`, a menu combo (uppercase letter = ⇧) | Services menu, Shortcuts.app keyboard shortcuts (`… - runShortcutAsService`) | writable; runs `pbs -update` after |

Checked and not supported: Raycast (SQLCipher-encrypted `settings_v2.db`), Zoom (encrypted DB), Discord (Electron leveldb), AltTab (keeps its defaults in code until changed; nothing persisted here), iTerm2 `GlobalKeyMap` (in-app only), Telegram/Forkgram (in-app only), Karabiner and Hammerspoon (their config is this repo). Orphan prefs whose app is gone: Lunar (`hotkeys`, JSON with Carbon flags), VMware Fusion, Last.fm Scrobbler.

Adding an app that uses a known format is one `Slot(...)` line in `REGISTRY` in `shortcuts.py` (domain or `~/…` plist path, format, `key=` for one top-level key or `parent=` for a dict of hotkeys, and the Settings path `apply` shows when it refuses). A new format is a `Format(decode, validate, encode)` entry in `FORMATS`; flag spaces live in `keycodes.py`. Leave `encode` out (read-only) unless a fixture captured from the machine proves the write round-trips.

### Event taps

`shortcuts.py taps [--json]` lists every CoreGraphics event tap (`CGGetEventTapList`): owning process, tap point (`hid`, `session`, or a single target pid), `active` (can filter or swallow events) or `listen`, enabled, the event mask as names, and min/avg/max latency exactly as macOS reports it. It flags a process holding several active taps on one mask (a leaked re-registration; Boring Notch showed three on `systemDefined`) and an active tap that is disabled (macOS turns off a tap whose callback times out; its owner can too). It needs pyobjc, which it pulls with `uvx --with pyobjc-framework-Quartz`, so `shortcuts.py` itself imports on a bare python.

Lint reads the file (not the machine), so it runs in pre-commit: `S1` fails when a layout chord is an enabled system shortcut, compared as macOS receives it (a bridge is its emitted F-key, `⇪` is `⇧⌃⌥⌘`); `S2` warns when an `[[app]]`/`[[menu]]` row sits on an enabled system chord; `S3` warns when two app/menu rows share a chord and can be live together (menu rows only within one app or `NSGlobalDomain`).

## Hammerspoon Configuration

The full set of bindings is the **per-key Lua files** in `hammerspoon/Spoons/HotKeys.spoon/layout/60%/`. Trying to maintain an ASCII keyboard picture in this doc has rotted twice — instead use:

- **Visual**: rendered SVGs in `docs/keyboard/` (regenerated from sources, always current). Start with [hyper.svg](keyboard/hyper.svg) for the main layer or [by-action.svg](keyboard/by-action.svg) for a category-grouped view.
- **Text/grep**: `hammerspoon/Spoons/HotKeys.spoon/layout/60%/SUMMARY.md` — auto-generated chord index regenerated on each edit. Best target for «what does Hyper+X do» searches.
- **Source**: open the per-key file directly (e.g. `g.lua` for everything on G).

### Hyper layer cheatsheet
The most-used chords on the Hyper layer (Caps Lock + key). For the complete list see `SUMMARY.md` or [hyper.svg](keyboard/hyper.svg):

| Chord | Action | Notes |
|---|---|---|
| `⇪B` (=F19) | Zap | + `⇪⇧B` alt terminal |
| `⇪F` (=F15) | Finder | + `⇪⇧F` files app |
| `⇪G` (=F18) | Fork | + `⌥G` browser GitHub, `⇪⌘G` Fork in dotfiles, `⇪⌥G` Fork in workprojectDev |
| `⇪H` (=F20) | Firefox | + `⇪⇧H` Safari; `⌃⌥⌘H` hides the current window |
| `⇪I` | system health overlay | `fn system_health` |
| `⇪M` | center window | |
| `⇪N` | VSCode | |
| `⇪P` | Music | |
| `⇪R` (=F14) | Rider | + `⇪⌃R` clipboard LLM, `⇪⌘R` OrbStack |
| `⇪T` (=F17) | Forkgram | window: right; + `⇪⇧T` zoom.us |
| `⇪V` (=F16) | Vivaldi | + `⇪⇧V` Chrome, `⇪⌃V` VPN toggle, `⇪⌘V` search selection |
| `⇪Y` | IINA | window: bottom |
| `⇪Z` (=F13) | toggle Android emulator window | |

Anything with `(=F##)` goes through its bridge slot (see *F-key remaps*).

## Extended Layers

- **`⌃⌥` + key** — window management (left/right/fullscreen/reset, audio source switching on 1-4).
  The four arrows cycle on a repeated press: `←` 73% ↔ half-left, `→` right panel ↔ half-right,
  `↑` maximized ↔ native macOS fullscreen, `↓` leaves native fullscreen if the window is in it,
  otherwise resets the whole layout. The cycle step is read back from the window's current frame,
  so moving the window by hand restarts it.
- **`⌃⌥⇧` + key** — half-window positioning (half-left, half-right, top 60%, bottom 40%).
- **`fn` + key** — mirror layer: the i-th key of a row's left half sends the i-th key of that row's
  right half, so the right hand's territory is typeable from the home position: `1…6` → `7 8 9 0 - =`,
  `qwerty` → `uiop[]`, `asdfg` → `jkl;'`, `zxcvb` → `nm,./`. Modifiers ride along, so `fn`+`⌘`+`1`
  is `⌘7`. `fn`+`h` sends `\` — the top row has one target more than sources, the home row one
  source more than targets, so the spare covers the orphan and the right-hand block is fully
  typeable from the left. The layer takes over the macOS 🌐-shortcuts on those letters
  (🌐+E, +F, +C, +Q, +A, +D, +H) on purpose.
  Rule: `karabiner/rules/30-fn-layer-mirror.json`.
- **`F13–F20` (Hyper slot letters)** — primary app launchers (see Hyper cheatsheet above).
- **`⇧F##` / `⌘F##` / `⌃F##` / `⌥F##`** — the same slot letter under `⇪⇧` / `⇪⌘` / `⇪⌃` / `⇪⌥`.
- **`⇧⌃⌥⌘` + arrow** — desktop focus sets, one chord each: `↑` work, `↓` only-work,
  `←` personal, `→` comms. The layout files bind the arrow chords directly; Karabiner
  (`rules/27-left-all-hide.json`) turns `⇧⌃⌥⌘` + `w a s d` into the same arrows. Membership lives in
  `hammerspoon/window_focus_sets.lua`; which browser and which Telegram client
  count come from `constants.env`. The same four sets answer to the voice verb
  `win` (VoiceCtl).

## Custom Keyboard Layout

### Typographic layer (right Option)

The system layouts are Apple's `ABC`, `Russian – PC` and `Greek` (`LAYOUT_PRIMARY` / `LAYOUT_SECONDARY` /
`LAYOUT_TERTIARY` in `constants.env`, named by role). Everything Ilya Birman's typography layout adds on top of
them — the ⌥ and ⇧⌥ layers, dead-key accents, the stress mark — comes from
[BirmanLayer.spoon](https://github.com/servitola/BirmanLayer.spoon), like AltGr on Windows.
`init.lua` loads it and hands it its config: `baseFixups = true`, `excludedLayouts` = Greek
(Apple's own Greek ⌥ layer keeps the accented letters ά έ ή and Greek symbols) and `excludedBundles` from
`game_mode.lua`. No `overrides`: the layer is Birman's layout as he published it. (Until 2026-10-01 a
`birman_extended.lua` added nine ⌥ cells and a Greek ⇧⌥ layer; both turned out to be copies of Apple
Greek's ⌥ layer, so it was deleted and Greek excluded instead.)

- **Layout names.** Every Hammerspoon call site that names a layout reads `LAYOUT_*`
  (the AutoKeyboardLayout config in `init.lua`, `punto_switcher.lua`, the HotKeys
  `set_secondary_layout` / `set_primary_layout` built-ins). The Spoon itself knows no
  layout names.
- **Russian – PC, not Russian.** Birman's Russian base and Shift layers are Apple's
  `Russian – PC` (`.` `,` on the `/` key, `№ ; : ?` on ⇧3 ⇧4 ⇧6 ⇧7, `ё` on the grave
  key); Apple's `Russian` differs on 13 keys. The only difference from Russian – PC
  is ⇧ on kVK 50, where Apple types Latin `Ë` (U+00CB) instead of `Ё`.
- **Base/Shift fixups** (`baseFixups`, off by default in the Spoon, on here). The few base and
  Shift cells where Apple's ABC / Russian – PC differ from Birman are typed as Birman's character
  when no ⌥ / ⌘ / ⌃ (either side) is down: Russian – PC ⇧kVK 50 → `Ё`; ABC kVK 10 → `` ` `` /
  ⇧ → `~`, kVK 50 → `\`. They are the table's `fixups`, keyed by input source id
  (`com.apple.keylayout.ABC`, `…RussianWin`); any other layout gets none. **ISO caveat:** kVK 10
  is the `§` key of an ISO keyboard and kVK 50 the key beside left ⇧; an ANSI board has no
  kVK 10. Karabiner rule 05 already turns both of these keys into Escape when pressed bare or
  with a left modifier, so in practice the fixups show up only with right ⇧.
- **Excluded apps.** The layer passes every event while the frontmost app is one of
  `bundles` in `game_mode.lua` — the games and GeForce NOW that
  get the Karabiner `Empty` profile. That table is the only list: `init.lua`
  passes it as `spoon.BirmanLayer.excludedBundles`, so add a bundle there and both follow.
- **What right ⌥ does.** Right ⌥ + key and ⇧ + right ⌥ + key type that key's Birman
  ⌥ / ⇧⌥ character, by position, whatever layout is active (`©` on C, `—` on `-`, `«»` on `, .`,
  `₽` on H). On the Greek layout right ⌥ is Apple's own (`excludedLayouts`).
  It stays out of the way when right ⌘ or right ⌃ is down (Hyper), when left ⌘ or
  left ⌃ is down (a shortcut), and when left ⌥ is down: **left ⌥ keeps the stock
  macOS ⌥ layer.** That is the Spoon's `rightOptionOnly = true` (default, the one difference from
  Birman's Mac layout, which takes both ⌥ keys); `false` gives his behavior, and then the `⌥`-only
  Hammerspoon hotkeys below would lose to the layer on either key. It also wins over Hammerspoon's
  own ⌥-only hotkeys (`⌥1`, `⌥c`, `⌥g`, `⌥r`, `⌥x`, `⌥[`, `⇧⌥2`, `⇧⌥z`): those fire from left ⌥ only.
  A key whose Birman ⌥ cell is empty types nothing rather than Apple's stock ⌥ character.
  Secure input (password fields) disables event taps, so the layer does nothing there.
- **Dead keys.** ⇧ + right ⌥ on `/ ~ 6 ; h z v q r n` enters acute, grave,
  circumflex, diaeresis, double acute, cedilla, caron, breve, ring and tilde (Greek:
  right ⌥ `;` → dialytika-tonos). The next key composes **by the character it types** in the
  active layout (`´` then the `a` key → `á`, then a Russian `к` → `ќ`), so no layout name is
  involved; a key the state does not know types the spacing accent and then itself; Escape cancels; the
  state expires after 3 s or on an app switch. The dead key pressed twice types the
  combining accent — on `/` that is the stress mark U+0301, typed *after* the vowel.
  Birman's Russian acute composes only `ќ ѓ`, so stress on a Cyrillic vowel is always
  "vowel, then ⇧⌥/ twice".
- **Karabiner rule 03** (right ⌥ + C E D A R → © € ° ≈ ® through the clipboard)
  was deleted on 2026-09-27: the layer types those characters directly.
- **Changing a character.** Set `layer.overrides` in `hammerspoon/init.lua` (the shape is the
  Spoon's `docs/configuration.md`, "Overrides"), then `hs.reload()`.
  The Spoon's own `typography_table.lua` is Birman's and is never edited here.
- **Keyboard pictures and lint.** `docs/keyboard/parse_birman.py` gives the `en ru el` characters
  of the SVGs and lint rule D2: plain and Shift from Apple's layouts
  (`docs/keyboard/apple-layouts/*.json`, refresh with `python3 docs/keyboard/tools/dump_apple_layouts.py`
  after a macOS update) with the Spoon's `fixups`, ⌥ and ⇧⌥ from the installed Spoon's table, or from Apple's dump for
  the layouts `init.lua` lists in `excludedLayouts`. After changing either, run `python3 docs/keyboard/generate.py` and
  `python3 docs/keyboard/tools/lint.py --strict`.
- **Where the Spoon lives.** Like any user, the dotfiles *install* BirmanLayer from its
  GitHub release: `install/18-spoons.sh` downloads the pinned tag's zip into
  `hammerspoon/Spoons/` (the directory is git-ignored here). Update: bump `BIRMAN_LAYER` there,
  run `zsh install/18-spoons.sh`, `hs.reload()`. Building and releasing the Spoon is not done from
  this repo.

## Layout System

The shortcut system uses a **per-key architecture** in `HotKeys.spoon/layout/60%/` (note capital K — case matters on case-sensitive filesystems). Each physical key has its own `.lua` file containing all modifier combinations for that key.

`HotKeys.spoon/init.lua` loads all key files listed in its `buttonFiles` array, collects chord entries, and binds them by type (`app`, `fn`, or `sendKey`).

### Directory layout

- **`layout/60%/`** — active per-key files. Every physical key on a 60% keyboard has one file.
- **`layout/extra/`** — placeholder files for F-keys, escape, fn, power. Currently no active chords (F-keys are remapped from Hyper letters in Karabiner instead).

### Key file format

Each key file returns an array of chord definitions:

```lua
return {
  { chord = "⇪f", app = "Finder" },                          -- Hyper+F launches Finder
  { chord = "⌃⌥a", fn = "window.left" },                     -- Ctrl+Alt+A triggers window function
  { chord = "⇪t", app = "Forkgram", window_default_position = "right" }, -- With window positioning
  { chord = "F14", app = "Rider" },                          -- ⇪r, via its bridge slot
}
```

#### Chord syntax
- `⇪` = Hyper (Caps Lock)
- `⌃` = Control
- `⌥` = Option/Alt
- `⇧` = Shift
- `⌘` = Command
- `F13`–`F20` with modifiers — a Hyper slot letter (`⌘F16` is `⇪⌘v`); `num8`, `num9` — the two gestures (see *F-key remaps*)
- `␣` = Space

#### Entry types
- **`app`**: macOS app name to launch / focus / hide (case-sensitive — must match `.app` bundle name). `"@APP_BROWSER"`, `"@APP_TERMINAL"` and other `@KEY` forms read `constants.env` instead — the chord then follows whatever app currently holds that role. Every chord that means a role is written this way (`APP_BROWSER`, `APP_BROWSER_ALT`, `APP_BROWSER_WORK`, `APP_TERMINAL`, `APP_TERMINAL_ALT`, `APP_TELEGRAM`, `APP_EDITOR`, `APP_IDE`, `APP_GIT_GUI`, `APP_FILES`, `APP_MUSIC`, `APP_VIDEO`); the SVGs, the bundle-ID map and the ASCII tables all show the resolved name. The per-app remap table in `init.lua` is keyed by the same constants.
- **`fn`**: name of a custom function. Must be registered via the action registry (`HotKeys.spoon/actions.lua`). See [Custom functions](#custom-functions) below.
- **`sendKey`**: literal string typed via `hs.eventtap.keyStrokes` (used to inject text).
- **`window_default_position`**: optional, registers the app with `spoon.PowerWindows` via `setOverride`: `"right"` → side, `"bottom"` → corner (anything else fails loudly); the app must be in `app_bundle_ids.lua`.

### Key file documentation comment

Each key file starts with a **canonical 5-column ASCII table** documenting every reachable chord on that physical key. The lint hook enforces format and column geometry:

```
-- chord │ karabiner │ en | ru | el │ G │ app — function
-- ⇪w    │     ↑     │              │   │         — up
-- ⇧w    │           │ W    Ц    Ω  │   │
-- ⌘w    │           │              │ ✓ │ — close window
```

Column geometry: `│` at positions 17, 32, 47, 51. See `a.lua` for the reference.

| # | Column | Source of truth |
|---|---|---|
| 1 | **chord** — pressed combination, right-aligned (last char at col 13) | the Lua entry's `chord` field |
| 2 | **karabiner** — what Karabiner sends downstream (arrows, F-keys, modifier combos) | `karabiner/rules/*.json` |
| 3 | **birman** — characters in `en  ru  el` layout order | `docs/keyboard/parse_birman.py` (Apple layouts + BirmanLayer.spoon, Apple's ⌥ in `excludedLayouts`) |
| 4 | **G** — `✓` if this is a stock macOS global shortcut | macOS Keyboard prefs |
| 5 | **description** — `App — function`, or `— function` for global. Optional tags: `B:` Birman-only, `ⓘ:` informational | the Lua entry |

`parse_birman.py` builds that column as described under *Typographic layer*, "Keyboard pictures and lint".

## Tools

All under `docs/keyboard/tools/`. Run from the repo root.

| Tool | Purpose |
|---|---|
| `python3 docs/keyboard/tools/lint.py` | Validate format, column geometry, and chord/comment coverage. `--strict` fails on errors (used by pre-commit), `--skip-drift` skips the Karabiner/Birman cross-check for speed. |
| `python3 docs/keyboard/tools/normalize.py --insert-missing` | Auto-fix column geometry and insert missing chord rows into the ASCII comment based on the actual Lua entries. |
| `python3 docs/keyboard/generate.py` | Regenerate all SVG layer diagrams in `docs/keyboard/`. Also produces `by-action.svg` (category-grouped view) and re-emits both `SUMMARY.md` files. |
| `python3 docs/keyboard/tools/gen_layers.py` | Write `karabiner/rules/07`–`17` from `karabiner/layers.toml` (tables + `[slots]`) + `layers.raw/` (`karabiner/build.sh` runs it). `--check` exits 1 with a diff on drift (lint `G1`, pre-commit). |
| `python3 docs/keyboard/tools/gen_bundle_ids.py` | Regenerate `HotKeys.spoon/app_bundle_ids.lua` — the app-name → bundle-ID map used for fast exact `hs.application.get()` lookups (names in layout files stay the source of truth; unresolved names fall back to fuzzy `find`). Re-run after adding a new `app = "..."` chord. |
| `python3 docs/keyboard/tools/dump_apple_layouts.py` | Dump Apple's ABC / Russian / Russian – PC / Greek base and Shift layers (`UCKeyTranslate`) into `docs/keyboard/apple-layouts/`, the plain and Shift characters `parse_birman.py` labels keys with. |
| `python3 macos_shortcuts/shortcuts.py` | `capture` / `check` / `apply` for `macos_shortcuts/shortcuts.toml`, `taps` for event taps — see *Machine shortcuts* above. |
| `.git-hooks/lint-keyboard-layout.sh` | Pre-commit hook — runs `lint.py --strict --skip-drift` on any staged `layout/60%/*.lua` files, and over all of them when `macos_shortcuts/shortcuts.toml` is staged. |

## Custom functions

`fn` entries resolve through the action registry (`HotKeys.spoon/actions.lua`). Generic actions are registered by the Spoon itself; everything personal lives in `hammerspoon/actions/` and registers with `spoon.HotKeys:register(name, fn)`. Grouped by category:

- **Window**: `window.left` `window.right` `window.fullscreen` `window.set_all_to_default` `window.half_left` `window.half_right` `window.top_60` `window.bottom_40` `window.center` `window.hide_current` `window.minimize_and_focus_next` `window.swap_sides` `window.hide_all_except_work` `window.focus_work` `window.focus_personal` `window.focus_comms`
  - `window.minimize_and_focus_next` is bound to `⌘H`, replacing the macOS Hide. It minimizes the
    focused window and moves focus on: to the app's next window if it has one, otherwise to the
    topmost window of another app. A fullscreen window leaves fullscreen first. `⌥4`
    (`karabiner/rules/31-alt-shortcuts-4.json` → `⌘H`) lands in the same handler.
    Real macOS Hide is still on `⌥⌘H` (Hide Others).
  - `window.swap_sides` swaps the two topmost windows left↔right. Pressed as `⌃⌥` + **both**
    arrows at once, or `⌃⌥` + **A and D** at once (the same pair that moves a window left/right
    on the letter keys) — `hs.hotkey` fires on the first key and cannot read a two-key gesture, so
    Karabiner (`rules/32-swap-sides.json`, `simultaneous`, 50 ms window) catches it and sends
    `num8` (keypad 8), which is what the layout binds. Cost: a single `⌃⌥←`/`⌃⌥→`/`⌃⌥A`/`⌃⌥D` is buffered
    for up to 50 ms while Karabiner waits for the partner key.
- **Displays (external screen)**: `display.toggle_window_to_tv` (`⌃⌥t` — текущее окно на телевизор и обратно) `display.toggle_mirror` (`⇧⌃⌥t` — зеркало ↔ extend)
- **Audio (AudioSwitcher)**: `audio.internal` `audio.external` `audio.marshall` `audio.connect_marshall` `audio.bt`
- **Translate (PopupTranslateSelection)**: `translate_to_russian` `translate_to_english` `translate_to_greek`
- **Browser (BrowserTabOpener)**: `browser_git` `browser_git_dotfiles` `browser_youtube` `browser_youtube_playing` `browser_search_selected`
- **System**: `hammerspoon_reload` `wallpaper_refresh` `system_health` `vpn.toggle_globalprotect` `info.show_shortcuts` `app_usage_stats`
- **Apps (custom launchers)**: `vscode.dotfiles` `fork.dotfiles` `fork.workprojectdev` `forkgram.chat` `zap.launch_default`
- **Misc**: `paste_bypass` `musicapp.play_pause` `press_return` `android.show_all` `set_secondary_layout` `set_primary_layout` `clipboard_llm` `show_youtrack` `show_youtrack_tasks` `youtube_stream`

A chord whose `fn` is not registered is reported by `start()` (red notification + console ERROR) and rejected by lint rule A1.

## App-specific hotkeys

`HotKeys.spoon/app_specific_hotkeys.lua` enables per-app rebinds via an `hs.application.watcher` (centralized in `appWatcherHub`). The table lives at the top of `init.lua`:

```lua
local appSpecificHotkeys = {
    ["Fork"]    = { { from = {"cmd","shift"}, key = "e", to = {"cmd","shift"}, target_key = "l" } },
    ["Music"]   = { { from = {"cmd"},         key = "e", to = {"cmd"},         target_key = "l" } },
    ["Zap"]     = { { from = {"alt"},         key = "z", sendText = "/new" } },
    ["Finder"]  = { { from = {"alt"},         key = "z", to = {"cmd","alt"},   target_key = "l" } },
    ["*"]       = { … },  -- always active
}
```

Use `from`+`to`+`target_key` for chord remaps, or `from`+`sendText` to type a string (e.g. Zap slash commands). `"*"` runs in every app.

## Customization

### Adding a new shortcut
1. Edit the per-key file in `hammerspoon/Spoons/HotKeys.spoon/layout/60%/`
2. Add a new chord entry to the returned array.

**Example — Slack on Hyper+S:**
```lua
-- in s.lua
{ chord = "⇪s", app = "Slack" },
```

3. Run `python3 docs/keyboard/tools/normalize.py --insert-missing` to update the ASCII comment table, then `python3 docs/keyboard/generate.py` to refresh the SVGs. If the chord launches a **new app**, also run `python3 docs/keyboard/tools/gen_bundle_ids.py` to refresh the bundle-ID map (skipping this is safe — the app just uses the slower fuzzy lookup).
4. Reload Hammerspoon. The config auto-reloads on save **only if Lua syntax is valid** — if the reload notification doesn't appear, open the console (`open -a "Hammerspoon Console"`) or force-reload with `hs -c "hs.reload()"`.

### Adding a custom function
1. Add `register("your.name", function() … end)` to the matching file in `hammerspoon/actions/` (new group: new file, listed in `actions/init.lua`).
2. Add the chord entry with `fn = "your.name"` to the per-key file.
3. Reload Hammerspoon (see above). An unregistered name shows a red "HotKeys: unregistered actions" notification.

## Visual reference

See **`docs/keyboard/`** for auto-generated SVG diagrams of all 24 shortcut layers plus the action-grouped `by-action.svg`. Index with category legend lives at `docs/keyboard/README.md.`

Regenerate everything: `python3 docs/keyboard/generate.py`

## Files reference

- `karabiner/rules/` — Karabiner rule files (source of truth; `karabiner.json` is generated via `karabiner/build.sh`)
- `hammerspoon/init.lua` — main Hammerspoon entry point
- `hammerspoon/Spoons/HotKeys.spoon/` — shortcut Spoon (capital K)
- `hammerspoon/Spoons/HotKeys.spoon/init.lua` — chord parser, built-in actions, binder
- `hammerspoon/Spoons/HotKeys.spoon/app_specific_hotkeys.lua` — per-app rebind helper
- `hammerspoon/actions/` — personal hotkey actions (`register` calls) and their helpers in `actions/lib/`
- `hammerspoon/Spoons/HotKeys.spoon/layout/60%/` — per-key layout files (active)
- `hammerspoon/Spoons/HotKeys.spoon/layout/60%/SUMMARY.md` — auto-generated chord index for grep / AI agents
- `hammerspoon/Spoons/HotKeys.spoon/app_bundle_ids.lua` — auto-generated app-name → bundle-ID map (via `docs/keyboard/tools/gen_bundle_ids.py`)
- `hammerspoon/Spoons/HotKeys.spoon/layout/extra/` — F-key placeholder files
- `docs/keyboard/` — auto-generated SVG keyboard shortcut diagrams
- `docs/keyboard/tools/lint.py` — canonical-format validator
- `docs/keyboard/tools/normalize.py` — auto-formatter / missing-row inserter
- `macos_shortcuts/shortcuts.toml` — system, app and menu shortcuts outside the repo (`macos_shortcuts/shortcuts.py`)
- `docs/keyboard/keycodes.py` — chord ↔ key code / Carbon / NSEvent / menu-combo conversions
- `.git-hooks/lint-keyboard-layout.sh` — pre-commit hook wiring `lint.py` into git
