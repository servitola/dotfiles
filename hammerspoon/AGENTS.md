# Hammerspoon Configuration Rules

## Structure
- **init.lua**: Main entry point - loads all Spoons and requires scripts
- **Spoons/**: Custom functionality modules (*.spoon directories)
- **Scripts**: `link_router.lua`, `game_mode.lua`, `reload_hammerspoon_on_script_changed.lua`
- **Spoons/BirmanLayer.spoon**: right-⌥ typographic layer (Birman ⌥ / ⇧⌥ layers and dead keys over Apple's layouts), a third-party Spoon installed from its GitHub release by `install/18-spoons.sh` (git-ignored here; never edit it in place). `init.lua` always loads it and hands it `baseFixups = true`, `excludedLayouts` = Greek (Apple's own Greek ⌥ layer) and `excludedBundles` from `game_mode.lua`; no `overrides`. It knows no input source names — the ⌥ layers are positional, dead keys compose by typed character. The keyboard SVGs and lint D2 read its `typography_table.lua` (and Apple's ⌥ dumps for excluded layouts) through `docs/keyboard/parse_birman.py`.
- **Layout names** come from `LAYOUT_PRIMARY` / `LAYOUT_SECONDARY` / `LAYOUT_TERTIARY` in `constants.env` — named by role, not by language; never write `"ABC"` in a call site.
- **actions/**: personal hotkey actions registered into `spoon.HotKeys` (`actions/init.lua` lists the modules; `actions/lib/` holds their helpers). Loaded by `require "actions"` right before `spoon.HotKeys:start()`.

## Spoon Loading Pattern
```lua
hs.loadSpoon("SpoonName")  -- Loads from Spoons/SpoonName.spoon/
```
All Spoons loaded in init.lua before scripts are required

## Auto-Switching Features
- **Language per app**: Forkgram/Telegram/AyuGram → Russian, Games → ABC, Everything else → English
- **Karabiner profiles**: Games use "Empty" profile (disables shortcuts), others use "Default"
- **URL routing**: Work domains open in Safari, everything else in Vivaldi browser

## Application Watcher Pattern
Uses `hs.application.watcher` to detect app focus changes:
- Check `bundleID()` not app name
- Get bundle ID: `osascript -e 'id of app "AppName"'`
- Add 50ms delay before switching to avoid race conditions

## Installed Spoons
- AudioSwitcher
- BrowserTabOpener
- GruvboxWallpapers
- HotKeys
- KSheet
- PopupTranslateSelection
- ScreenGlow — edge glow while an agent drives the desktop; `hs -c 'spoon.ScreenGlow:pulse(45)'` / `:stop()`
- LinkRouter — each clicked link to the browser its rule names; Hammerspoon is the system browser. A third-party Spoon; never edit it in place. Source: `~/projects/linkrouter/LinkRouter.spoon`. Not published yet, so `install/18-spoons.sh` has no line for it: the dir here is a committed copy of the checkout's last commit (refresh with `git -C ~/projects/linkrouter/LinkRouter.spoon archive HEAD | tar -x -C hammerspoon/Spoons/LinkRouter.spoon`). Without it `link_router.lua` hands the system-browser role back to `APP_BROWSER`. Rules live in `link_router.lua`; check one with `spoon.LinkRouter:route(url)` in the console. Replaced URLDispatcher on 2026-10-07.
- Windows
- YouTrackTasks
- YouTrackTicket
- YouTubeStream

## Critical Rules
- **Always reload after changes**: `hs -c "hs.reload()"`
- Check console for errors: `open -a "Hammerspoon Console"`
- Spoon names are case-sensitive
- Scripts in root use `require`, Spoons use `hs.loadSpoon()`

## Anti-Patterns
- Don't modify Spoon files without checking their init.lua
