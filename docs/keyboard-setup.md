# Keyboard Setup Guide

Complete documentation of the keyboard customization system including Karabiner-Elements, Hammerspoon, custom layouts, and shortcuts.

## Overview

The keyboard setup consists of three main components:
- **Karabiner-Elements**: Remaps original keyboard to my set of keycodes. Including Caps Lock (Hyper) as all 4 right modifiers at once
- **Custom Layout**: Birman keyboard layout in keyboard-layout directory is installed and used as the default layout in OS
- **Hammerspoon**: Catches key events and runs the apps and specific functions

## Key Concepts

- **External 60% keyboard compatibility**: Same behavior on both internal and 60% external keyboards
- **60% keyboard usage**: Fn key bound to left Control, media keys remain media keys
- **Same topic actions on same keys**: Related functionality uses consistent keys across different contexts (e.g., Hyper+G = Git client, Rider Ctrl+G = Git window, Rider Ctrl+Shift+G = file history)
- **Not changing macOS default shortcuts**: Respect system shortcuts to avoid conflicts
- **Left-hand focus**: Left hand can access all needed work shortcuts for ergonomic efficiency
- **Shortcut accessibility hierarchy**: Easy-to-reach shortcuts for frequent actions, harder combinations (Ctrl+Shift+Hyper) for less frequent but important functions

## Karabiner-Elements Configuration

Source of truth: per-rule JSON files in `karabiner/rules/`. Each file is one logical concern (e.g. `09-hyper-command.json`, `05-grave-to-escape.json`). The combined `karabiner.json` consumed by Karabiner-Elements is **generated** — run `karabiner/build.sh` after editing rules.

### Caps Lock → Hyper
Caps Lock sends Right Shift + Right Command + Right Control + Right Option simultaneously. Hammerspoon binds chords against this 4-mod set, so it never collides with real left-modifier shortcuts.

### F-key remaps
Many Hyper+letter chords (B, F, G, H, P, R, T, V, Y) are not bound directly — Karabiner first translates the keystroke to an F-key (F13–F20), and Hammerspoon binds the F-key. Result: looking only at `layout/60%/*.lua` won't reveal these; cross-reference with `karabiner/rules/*hyper*.json`.

## Hammerspoon Configuration

The full set of bindings is the **per-key Lua files** in `hammerspoon/Spoons/HotKeys.spoon/layout/60%/`. Trying to maintain an ASCII keyboard picture in this doc has rotted twice — instead use:

- **Visual**: rendered SVGs in `docs/keyboard/` (regenerated from sources, always current). Start with [hyper.svg](keyboard/hyper.svg) for the main layer or [by-action.svg](keyboard/by-action.svg) for a category-grouped view.
- **Text/grep**: `hammerspoon/Spoons/HotKeys.spoon/layout/60%/SUMMARY.md` — auto-generated chord index (`Hyper+B → fn zap.launch_default`, etc.) regenerated on each edit. Best target for «what does Hyper+X do» searches.
- **Source**: open the per-key file directly (e.g. `g.lua` for everything on G).

### Hyper layer cheatsheet
The most-used chords on the Hyper layer (Caps Lock + key). For the complete list see `SUMMARY.md` or [hyper.svg](keyboard/hyper.svg):

| Chord | Action | Notes |
|---|---|---|
| `⇪B` | Zap (custom launcher) | `fn zap.launch_default` |
| `⇪F` | Finder | direct binding |
| `⇪G` | Fork | + `⌥G` browser GitHub, `⌥F13` Fork in cTraderDev |
| `⇪H` | Firefox | + `F16` Safari, `⇧F13` hide current window |
| `⇪I` | system health overlay | `fn system_health` |
| `⇪J` | Workbot | window: right |
| `⇪M` | center window | |
| `⇪N` | VSCode | |
| `⇪P` | Music | |
| `⇪R` (=F17) | Rider | + `⇧F17` Android Studio, `⌘F17` OrbStack |
| `⇪T` (=F18) | Telegram | window: right |
| `⇪V` (=F19) | Yandex Browser | + `⇧F19` Chrome, `⌃F19` VPN toggle |
| `⇪Y` | IINA | window: bottom |
| `⇪Z` (=F20) | toggle Android emulator window | |

Anything with `(=F##)` goes through a Karabiner F-key remap.

## Extended Layers

- **`⌃⌥` + key** — window management (left/right/fullscreen/reset, audio source switching on 1-4).
- **`⌃⌥⇧` + key** — half-window positioning (half-left, half-right, top 60%, bottom 40%).
- **`F13–F20` (Hyper letters)** — primary app launchers (see Hyper cheatsheet above).
- **`⇧F##` / `⌘F##` / `⌃F##` / `⌥F##`** — secondary launchers and per-app actions for the same physical key.

### Calibration shortcut
`⌃⌥⌘⇧+;` (`_calibrate_telegram_personal`) — hover over the Telegram "Personal" folder tab, then press to save the click offset to `~/.hammerspoon/.telegram_personal_offset`. Used by `fn window.focus_personal` to click into Personal after Cmd+Tab. Re-run when Telegram window layout changes.

## Custom Keyboard Layout

### Ilya Birman Layout
The system uses Ilya Birman's custom keyboard layout with:
- **English**: Optimized for programming with additional symbols
- **Russian**: Cyrillic layout optimized for typing

### Layout Creation (Ukelele)
- **Tool**: Ukelele keyboard layout editor
- **Source Files**: XML `.keylayout` files in `Birman.bundle/Contents/Resources/`
- **Editable**:

## Layout System

The shortcut system uses a **per-key architecture** in `HotKeys.spoon/layout/60%/` (note capital K — case matters on case-sensitive filesystems). Each physical key has its own `.lua` file containing all modifier combinations for that key.

`HotKeys.spoon/init.lua` loads all key files listed in its `buttonFiles` array, collects chord entries, and binds them by type (`app`, `fn`, or `sendKey`).

### Directory layout

- **`layout/60%/`** — active per-key files. Every physical key on a 60% keyboard has one file.
- **`layout/extra/`** — placeholder files for F-keys, escape, fn, power. Currently no active chords (F-keys are remapped from Hyper letters in Karabiner instead).
- **`old/`** — 30 numbered legacy layout files (`01. English.lua` … `30. Shift_Alt_Command.lua`) from the pre-per-key architecture. **Not loaded.** Kept for reference only.

### Key file format

Each key file returns an array of chord definitions:

```lua
return {
  { chord = "⇪f", app = "Finder" },                          -- Hyper+F launches Finder
  { chord = "⌃⌥a", fn = "window.left" },                     -- Ctrl+Alt+A triggers window function
  { chord = "⇪j", app = "Workbot", window_default_position = "right" },  -- With window positioning
  { chord = "F17", app = "Rider" },                          -- Via Karabiner F-key remap
}
```

#### Chord syntax
- `⇪` = Hyper (Caps Lock)
- `⌃` = Control
- `⌥` = Option/Alt
- `⇧` = Shift
- `⌘` = Command
- `F13`–`F20`, `num0`–`num9` — raw Karabiner output (used when Karabiner translates a chord before Hammerspoon sees it)

#### Entry types
- **`app`**: macOS app name to launch / focus / hide (case-sensitive — must match `.app` bundle name).
- **`fn`**: name of a custom function. Handler must exist in `init.lua` dispatch (`init.lua:232-365`). See [Custom functions](#custom-functions) below.
- **`sendKey`**: literal string typed via `hs.eventtap.keyStrokes` (used to inject text).
- **`window_default_position`**: optional, registers the app with `spoon.Windows`. Only `"right"` and `"bottom"` are implemented — `"left"` is silently ignored.

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
| 3 | **birman** — characters in `en  ru  el` layout order | `keyboard-layout/Birman.bundle/*.keylayout` |
| 4 | **G** — `✓` if this is a stock macOS global shortcut | macOS Keyboard prefs |
| 5 | **description** — `App — function`, or `— function` for global. Optional tags: `B:` Birman-only, `ⓘ:` informational | the Lua entry |

## Tools

All under `docs/keyboard/tools/`. Run from the repo root.

| Tool | Purpose |
|---|---|
| `python3 docs/keyboard/tools/lint.py` | Validate format, column geometry, and chord/comment coverage. `--strict` fails on errors (used by pre-commit), `--skip-drift` skips the Karabiner/Birman cross-check for speed. |
| `python3 docs/keyboard/tools/normalize.py --insert-missing` | Auto-fix column geometry and insert missing chord rows into the ASCII comment based on the actual Lua entries. |
| `python3 docs/keyboard/generate.py` | Regenerate all SVG layer diagrams in `docs/keyboard/`. Also produces `by-action.svg` (category-grouped view) and re-emits both `SUMMARY.md` files. |
| `.git-hooks/lint-keyboard-layout.sh` | Pre-commit hook — runs `lint.py --strict --skip-drift` on any staged `layout/60%/*.lua` files. |

## Custom functions

`fn` entries dispatch to handlers defined in `HotKeys.spoon/init.lua` (around lines 232–365). Grouped by category:

- **Window**: `window.left` `window.right` `window.fullscreen` `window.set_all_to_default` `window.half_left` `window.half_right` `window.top_60` `window.bottom_40` `window.center` `window.hide_current` `window.hide_all_except_work` `window.focus_work` `window.focus_personal` `window.focus_comms`
- **Audio (AudioSwitcher)**: `audio.internal` `audio.external` `audio.marshall` `audio.connect_marshall` `audio.bt`
- **Translate (PopupTranslateSelection)**: `translate_to_russian` `translate_to_english` `translate_to_greek`
- **Browser (BrowserTabOpener)**: `browser_git` `browser_git_dotfiles` `browser_youtube` `browser_youtube_playing` `browser_search_selected`
- **System**: `hammerspoon_reload` `wallpaper_refresh` `apps.close_unnecessary` `system_health` `vpn.toggle_globalprotect` `info.show_shortcuts` `app_usage_stats`
- **Apps (custom launchers)**: `vscode.dotfiles` `fork.dotfiles` `fork.ctraderdev` `zap.launch_default`
- **Misc**: `paste_bypass` `musicapp.play_pause` `press_return` `android.show_all` `set_russian_language` `set_english_language` `clipboard_llm` `screenshot_ai` `show_youtrack` `show_youtrack_tasks` `youtube_stream`

Adding a new `fn` requires both a chord entry and a matching `elseif functionName == "..."` branch in `init.lua:init()`.

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

3. Run `python3 docs/keyboard/tools/normalize.py --insert-missing` to update the ASCII comment table, then `python3 docs/keyboard/generate.py` to refresh the SVGs.
4. Reload Hammerspoon. The config auto-reloads on save **only if Lua syntax is valid** — if the reload notification doesn't appear, open the console (`open -a "Hammerspoon Console"`) or force-reload with `hs -c "hs.reload()"`.

### Adding a custom function
1. Add the chord entry with `fn = "your.name"` to the appropriate per-key file.
2. Add an `elseif functionName == "your.name" then ... end` branch in the dispatch in `init.lua:init()`.
3. Reload Hammerspoon (see above).

## Visual reference

See **`docs/keyboard/`** for auto-generated SVG diagrams of all 24 shortcut layers plus the action-grouped `by-action.svg`. Index with category legend lives at `docs/keyboard/README.md.`

Regenerate everything: `python3 docs/keyboard/generate.py`

## Files reference

- `karabiner/rules/` — Karabiner rule files (source of truth; `karabiner.json` is generated via `karabiner/build.sh`)
- `hammerspoon/init.lua` — main Hammerspoon entry point
- `hammerspoon/Spoons/HotKeys.spoon/` — shortcut Spoon (capital K)
- `hammerspoon/Spoons/HotKeys.spoon/init.lua` — chord parser + `fn` dispatch
- `hammerspoon/Spoons/HotKeys.spoon/app_specific_hotkeys.lua` — per-app rebind helper
- `hammerspoon/Spoons/HotKeys.spoon/layout/60%/` — per-key layout files (active)
- `hammerspoon/Spoons/HotKeys.spoon/layout/60%/SUMMARY.md` — auto-generated chord index for grep / AI agents
- `hammerspoon/Spoons/HotKeys.spoon/layout/extra/` — F-key placeholder files
- `hammerspoon/Spoons/HotKeys.spoon/old/` — legacy 30 numbered layout files (not loaded)
- `keyboard-layout/Birman.bundle/` — custom keyboard layout (Ukelele bundle)
- `keyboard-layout/Birman.bundle/Contents/Resources/`*.keylayout — Ukelele XML source files
- `docs/keyboard/` — auto-generated SVG keyboard shortcut diagrams
- `docs/keyboard/tools/lint.py` — canonical-format validator
- `docs/keyboard/tools/normalize.py` — auto-formatter / missing-row inserter
- `.git-hooks/lint-keyboard-layout.sh` — pre-commit hook wiring `lint.py` into git
