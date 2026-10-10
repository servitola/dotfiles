# Hammerspoon Configuration Rules

## Structure
- **init.lua**: Main entry point - loads all Spoons and requires scripts
- **Spoons/**: Custom functionality modules (*.spoon directories)
- **Scripts**: `link_router.lua`, `game_mode.lua`, `reload_hammerspoon_on_script_changed.lua`
- **Spoons/BirmanLayer.spoon**: right-⌥ typographic layer (Birman ⌥ / ⇧⌥ layers and dead keys over Apple's layouts), a third-party Spoon installed from its GitHub release by `install/18-spoons.sh` (never edit it in place). `init.lua` always loads it and hands it `baseFixups = true`, `excludedLayouts` = Greek (Apple's own Greek ⌥ layer) and `excludedBundles` from `game_mode.lua`; no `overrides`. It knows no input source names — the ⌥ layers are positional, dead keys compose by typed character. The keyboard SVGs and lint D2 read its `typography_table.lua` (and Apple's ⌥ dumps for excluded layouts) through `docs/keyboard/parse_birman.py`.
- **Layout names** come from `LAYOUT_PRIMARY` / `LAYOUT_SECONDARY` / `LAYOUT_TERTIARY` in `constants.env` — named by role, not by language; never write `"ABC"` in a call site.
- **actions/**: personal hotkey actions registered into `spoon.HotKeys` (`actions/init.lua` lists the modules; `actions/lib/` holds their helpers). Loaded by `require "actions"` right before `spoon.HotKeys:start()`.

## Spoon Loading Pattern
```lua
hs.loadSpoon("SpoonName")  -- Loads from Spoons/SpoonName.spoon/
```
Most Spoons load at the top of `init.lua`, before the scripts; AutoKeyboardLayout and BirmanLayer load after `link_router` because they only need to be up, not referenced.

Third-party Spoons are **tracked in git** even when `install/18-spoons.sh` installs them from a release (since 7d5e6c8f, 2026-10-07): a fresh clone works without network, and the install step re-downloads the pinned releases over them. A `git diff` after running it means the release and the committed copy disagree — commit the new build or fix the pin; `install/check.sh` compares the installed versions with the pins.

HotKeys is two-phase: `hs.loadSpoon("HotKeys")` only loads chords; `spoon.HotKeys:start()` binds them and must come after `require "actions"`.

## Auto-Switching Features
- **Layout per app** (AutoKeyboardLayout.spoon, configured in `init.lua`): every app → `LAYOUT_PRIMARY`; Telegram clients (the Spoon's built-in `secondaryApps` list) → `LAYOUT_SECONDARY`
- **Karabiner profiles** (`game_mode.lua`): games use the "Empty" profile (disables shortcuts), others "Default"; its `bundles` list is also what BirmanLayer is told to stay out of
- **URL routing**: work domains (workname/workproject/xd.adobe) → Firefox, localhost and
  private ranges → Chrome, everything else → the browser named by `APP_BROWSER`

## Application Watcher Pattern
Uses `hs.application.watcher` to detect app focus changes:
- Check `bundleID()` not app name
- Get bundle ID: `osascript -e 'id of app "AppName"'`
- Add 50ms delay before switching to avoid race conditions

## Installed Spoons
- AudioSwitcher
- AutoKeyboardLayout — a keyboard layout per app, applied when the app comes to the front. A third-party Spoon (never edit it in place). Source: `~/projects/autokeyboardlayout/AutoKeyboardLayout.spoon`. Installed from its GitHub release by `install/18-spoons.sh`. Replaced `set_language_on_app_focused.lua` on 2026-10-01.
- BirmanLayer — right-⌥ typographic layer (from its GitHub release, `install/18-spoons.sh`)
- BrowserTabOpener — `open(name)` / `open(pattern, url[, { prefer = js }])`: jump to a site's open tab, cycle on repeat, open the address when there is none. A third-party Spoon (never edit it in place). Source: `~/projects/browsertabopener/BrowserTabOpener.spoon`. Installed from its GitHub release by `install/18-spoons.sh`. `spoon.BrowserTabOpener:check()` in the console says what works with the current browser. `init.lua` sets its `browser` from `APP_BROWSER_BUNDLE`; the sites are in `actions/browser.lua`.
- Displays
- Fresh4kWallpaper — a new 4K wallpaper on every load, then daily; keeps one file in `~/Pictures/Fresh4kWallpaper`. A third-party Spoon (never edit it in place). Source: `~/projects/fresh4kwallpaper/Fresh4kWallpaper.spoon`. Installed from its GitHub release by `install/18-spoons.sh`. Needs no GitHub token: file lists are cached for a week in `~/Pictures/Fresh4kWallpaper/cache`. Replaced the in-repo GruvboxWallpapers.spoon on 2026-10-01.
- GlobalProtectToggle — GlobalProtect VPN on a key (`toggle` / `connect` / `disconnect` / `status`), by clicking its menu bar panel. A third-party Spoon (never edit it in place). Source: `~/projects/globalprotecttoggle/GlobalProtectToggle.spoon`. The GitHub repository is private for now (`v0.1.0`, not verified live), so `install/18-spoons.sh` has no line for it — its unauthenticated download would 404 — and the dir here is a committed copy of the checkout's last commit (refresh with `git -C ~/projects/globalprotecttoggle/GlobalProtectToggle.spoon archive HEAD | tar -x -C hammerspoon/Spoons/GlobalProtectToggle.spoon`). Its `notify` is replaced with glasswings banners in `actions/system.lua`. Replaced `actions/lib/vpn_globalprotect.lua` on 2026-10-02; never run its `toggle` from an agent session — VPN is the owner's to switch.
- HotKeys
- KSheet
- PopupTranslateSelection
- PowerWindows — window layout, a third-party Spoon installed from its GitHub release by `install/18-spoons.sh` (never edit it in place). Source: `/Volumes/SanDisk/projects/powerwindows/lab/spoon` (external drive; `~/projects/powerwindows` links there). `lab/ship.sh` turns a finished change into one commit of the public repository next to it, `lab/release.sh <version> --install` puts a release build here; the installed dir is always such a build, so Hammerspoon works with the drive unplugged. To develop, replace the installed dir with a symlink to `lab/spoon`, and install a build again when done. Configured by `window_rules.lua` + `window_focus_sets.lua`.
- ScreenGlow — edge glow while an agent drives the desktop; `hs -c 'spoon.ScreenGlow:pulse(45)'` / `:stop()`. A third-party Spoon installed from its GitHub release by `install/18-spoons.sh` (never edit it in place). Source: `~/projects/screenglow/ScreenGlow.spoon`.
- LinkRouter — each clicked link to the browser its rule names; Hammerspoon is the system browser. A third-party Spoon; never edit it in place. Source: `~/projects/linkrouter/LinkRouter.spoon`. Not published yet, so `install/18-spoons.sh` has no line for it: the dir here is a committed copy of the checkout's last commit (refresh with `git -C ~/projects/linkrouter/LinkRouter.spoon archive HEAD | tar -x -C hammerspoon/Spoons/LinkRouter.spoon`). Without it `link_router.lua` hands the system-browser role back to `APP_BROWSER`. Rules live in `link_router.lua`; check one with `spoon.LinkRouter:route(url)` in the console. Replaced URLDispatcher on 2026-10-07.
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
