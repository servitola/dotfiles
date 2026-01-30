# Hammerspoon Configuration Rules

## Structure
- **init.lua**: Main entry point - loads all Spoons and requires scripts
- **Spoons/**: Custom functionality modules (*.spoon directories)
- **Scripts**: `config_UrlDispatcher.lua`, `set_language_on_app_focused.lua`, `reload_hammerspoon_on_script_changed.lua`

## Spoon Loading Pattern
```lua
hs.loadSpoon("SpoonName")  -- Loads from Spoons/SpoonName.spoon/
```
All Spoons loaded in init.lua before scripts are required

## Auto-Switching Features
- **Language per app**: Telegram/AyuGram → Russian, Games → ABC, Everything else → English
- **Karabiner profiles**: Games use "Empty" profile (disables shortcuts), others use "Default"
- **URL routing**: Work domains open in Safari, everything else in Yandex

## Application Watcher Pattern
Uses `hs.application.watcher` to detect app focus changes:
- Check `bundleID()` not app name
- Get bundle ID: `osascript -e 'id of app "AppName"'`
- Add 50ms delay before switching to avoid race conditions

## Installed Spoons
- AudioSwitcher
- BrowserTabOpener
- CursorMemory
- FoodyOrder
- GruvboxWallpapers
- HotKeys
- KSheet
- PopupTranslateSelection
- URLDispatcher
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
