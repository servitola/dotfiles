# Hammerspoon Configuration Rules

## Structure
- **init.lua**: Main entry point - loads all Spoons and requires scripts
- **Spoons/**: Custom functionality modules (*.spoon directories)
- **Scripts**: `link_router.lua`, `set_language_on_app_focused.lua`, `reload_hammerspoon_on_script_changed.lua`

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
- LinkRouter — each clicked link to the browser its rule names; Hammerspoon is the system browser. A third-party Spoon (git-ignored here; never edit it in place). Source: `~/projects/linkrouter/LinkRouter.spoon`. Not published yet, so `install/18-spoons.sh` has no line for it and the installed dir is a symlink to the checkout; without it `link_router.lua` hands the system-browser role back to `APP_BROWSER`. Rules live in `link_router.lua`; check one with `spoon.LinkRouter:route(url)` in the console. Replaced URLDispatcher on 2026-10-07.
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
