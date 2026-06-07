---
name: install-game-heroic
description: |
  Installs a Windows-only game on macOS: finds the GOG torrent on Rutracker/1337x,
  downloads via Transmission, runs the GOG offline installer silently through Wine,
  registers the game in Heroic Games Launcher as a Windows sideload app, and fixes
  common DirectX/graphics launch errors via DXMT + GPTK.

  Use when: "установи игру через heroic", "скачай и установи игру на мак",
  "добавь игру в heroic", "поставь игру через heroic", "установи windows игру на мак",
  "хочу поиграть в <game> на маке", "install game heroic mac",
  "install windows game on mac", "sideload game heroic", "add game to heroic launcher"
---

# install-game-heroic

Three phases. Troubleshooting applies only on DirectX/graphics errors at first launch.

## Environment

| Resource | Path |
|---|---|
| Wine Crossover | `$HOME/Library/Application Support/heroic/tools/wine/Wine-Crossover-latest/Contents/Resources/wine/bin/wine64` |
| GPTK | `$HOME/Library/Application Support/heroic/tools/game-porting-toolkit/Game-Porting-Toolkit-latest/Contents/Resources/wine/bin/wine64` |
| DXMT DLLs (win) | `$HOME/Library/Application Support/heroic/tools/dxmt/dxmt-v0.80-builtin/x86_64-windows/` |
| DXMT libs (unix) | `$HOME/Library/Application Support/heroic/tools/dxmt/dxmt-v0.80-builtin/x86_64-unix/` |
| GPTK unix libs | `$HOME/Library/Application Support/heroic/tools/game-porting-toolkit/Game-Porting-Toolkit-latest/Contents/Resources/wine/lib/wine/x86_64-unix/` |
| Prefix dir | `$HOME/Games/Heroic/Prefixes/<game_slug>/` |
| Heroic library | `$HOME/Library/Application Support/heroic/sideload_apps/library.json` |
| Heroic GamesConfig | `$HOME/Library/Application Support/heroic/GamesConfig/` |

## Phase 1 — Find & Download

Invoke `rutracker-download` skill, searching for `<game> GOG` (it handles Rutracker search, magnet extraction, and Transmission queuing). Key differences for games:
- Prefer **GOG** release (offline installer: `.exe` + `.bin` files) over Steam/FitGirl repacks
- Search for a **macOS** version first (`rutracker "<game>" mac macos`); if none exists, use Windows GOG

Wait for Transmission to complete. The installer files land in `~/Desktop/game-<name>/` or `~/Documents/Torrents/`.

**Checkpoint:** Verify installer files are present and complete before continuing:
```bash
ls -lh ~/Desktop/game-*/
# Must see: setup_<game>_<version>_(64bit)_(<id>).exe + -1.bin + optionally -2.bin
# Sizes must match what Transmission shows as completed
```

## Phase 2 — Install via Wine

GOG offline installers are InnoSetup — they accept silent flags and always install to `C:\GOG Games\<Name>\`.

### 2.1 Create prefix
```bash
GAME_SLUG="game_name_snake_case"   # snake_case, no spaces
mkdir -p "$HOME/Games/Heroic/Prefixes/$GAME_SLUG"
```

### 2.2 Run installer silently
Use **Wine Crossover** for installation (handles InnoSetup reliably):
```bash
WINE="$HOME/Library/Application Support/heroic/tools/wine/Wine-Crossover-latest/Contents/Resources/wine/bin/wine64"
WINEPREFIX="$HOME/Games/Heroic/Prefixes/$GAME_SLUG"
INSTALLER="/path/to/setup_game_version_(64bit)_(id).exe"

WINEPREFIX="$WINEPREFIX" WINEDEBUG=-all \
  "$WINE" "$INSTALLER" /VERYSILENT /NORESTART /SUPPRESSMSGBOXES \
  > /tmp/game_install.log 2>&1 &

echo "PID: $!"
```

The `.bin` files must be in the same directory as the `.exe` — InnoSetup finds them automatically.

### 2.3 Wait and verify
```bash
wait   # or poll with: ps aux | grep wine
ls "$HOME/Games/Heroic/Prefixes/$GAME_SLUG/drive_c/GOG Games/"
```

Identify the main `.exe` — not `unins000.exe`, not `UnityCrashHandler64.exe`.

**Checkpoint:** The game directory must exist under `drive_c/GOG Games/` with the main `.exe` before continuing:
```bash
ls "$HOME/Games/Heroic/Prefixes/$GAME_SLUG/drive_c/GOG Games/"*/
# Must see: <Game>.exe (+ UnityPlayer.dll for Unity games, or equivalent)
```

## Phase 3 — Register in Heroic

### 3.1 Generate unique app_name
```bash
python3 -c "import random, string; print(''.join(random.choices(string.ascii_letters + string.digits, k=22)))"
```
Save this value as `APP_NAME` — used in both files below.

### 3.2 Add to library.json
Append inside the `"games": [...]` array in `$HOME/Library/Application Support/heroic/sideload_apps/library.json`.
Replace `$HOME` with the actual absolute path (JSON doesn't expand variables):

```json
{
  "runner": "sideload",
  "app_name": "<APP_NAME>",
  "title": "Game Title",
  "install": {
    "executable": "/Users/<username>/Games/Heroic/Prefixes/<slug>/drive_c/GOG Games/<Game>/<Game>.exe",
    "platform": "Windows",
    "is_dlc": false
  },
  "folder_name": "/Users/<username>/Games/Heroic/Prefixes/<slug>/drive_c/GOG Games/<Game>",
  "art_cover": "",
  "art_square": "",
  "is_installed": true,
  "canRunOffline": true,
  "browserUrl": "",
  "customUserAgent": "",
  "launchFullScreen": false
}
```

### 3.3 Create GamesConfig
Create `$HOME/Library/Application Support/heroic/GamesConfig/<APP_NAME>.json`.
Replace `$HOME` with the actual absolute path:

```json
{
  "<APP_NAME>": {
    "autoInstallDxvk": false,
    "autoInstallDxvkNvapi": false,
    "autoInstallVkd3d": false,
    "preferSystemLibs": false,
    "enableEsync": true,
    "enableMsync": true,
    "enableFsync": false,
    "enableWineWayland": false,
    "enableHDR": false,
    "enableWoW64": false,
    "nvidiaPrime": false,
    "enviromentOptions": [],
    "wrapperOptions": [],
    "showFps": false,
    "useGameMode": false,
    "battlEyeRuntime": false,
    "eacRuntime": false,
    "language": "",
    "verboseLogs": true,
    "wineVersion": {
      "wineserver": "/Users/<username>/Library/Application Support/heroic/tools/wine/Wine-Crossover-latest/Contents/Resources/wine/bin/wineserver",
      "lib": "/Users/<username>/Library/Application Support/heroic/tools/wine/Wine-Crossover-latest/Contents/Resources/wine/lib",
      "lib32": "/Users/<username>/Library/Application Support/heroic/tools/wine/Wine-Crossover-latest/Contents/Resources/wine/lib",
      "bin": "/Users/<username>/Library/Application Support/heroic/tools/wine/Wine-Crossover-latest/Contents/Resources/wine/bin/wine64",
      "name": "Wine Crossover - 23.7.1-1",
      "type": "wine"
    },
    "wineCrossoverBottle": "",
    "winePrefix": "/Users/<username>/Games/Heroic/Prefixes/<slug>"
  },
  "version": "v0",
  "explicit": true
}
```

### 3.4 Reload Heroic
```bash
pkill -x Heroic; sleep 1; open -a Heroic
```

**Checkpoint:** The game must appear in the Heroic library (sideload/Other section) after restart before considering Phase 3 complete. If it doesn't appear, recheck JSON syntax in library.json.

## Verification

Launch the game from Heroic. Success = game reaches the main menu.

If a graphics/DirectX error appears on launch — see Troubleshooting below.

## Troubleshooting (only if DirectX/graphics error on first launch)

### "Failed to initialize player / Failed to initialize graphics / DirectX error"

The Wine Crossover D3D layer isn't sufficient for this game. Fix: switch to GPTK + install DXMT (DirectX → Metal translator).

**Step 1 — Update GamesConfig** — replace `wineVersion` block with GPTK:
```json
"wineVersion": {
  "wineserver": "/Users/<username>/Library/Application Support/heroic/tools/game-porting-toolkit/Game-Porting-Toolkit-latest/Contents/Resources/wine/bin/wineserver",
  "lib": "/Users/<username>/Library/Application Support/heroic/tools/game-porting-toolkit/Game-Porting-Toolkit-latest/Contents/Resources/wine/lib",
  "lib32": "/Users/<username>/Library/Application Support/heroic/tools/game-porting-toolkit/Game-Porting-Toolkit-latest/Contents/Resources/wine/lib",
  "bin": "/Users/<username>/Library/Application Support/heroic/tools/game-porting-toolkit/Game-Porting-Toolkit-latest/Contents/Resources/wine/bin/wine64",
  "name": "Game-Porting-Toolkit-latest",
  "type": "toolkit"
}
```

**Step 2 — Install DXMT DLLs** into the prefix:
```bash
DXMT="$HOME/Library/Application Support/heroic/tools/dxmt/dxmt-v0.80-builtin"
SYS32="$HOME/Games/Heroic/Prefixes/$GAME_SLUG/drive_c/windows/system32"
GPTK_UNIX="$HOME/Library/Application Support/heroic/tools/game-porting-toolkit/Game-Porting-Toolkit-latest/Contents/Resources/wine/lib/wine/x86_64-unix"

cp "$DXMT/x86_64-windows/d3d11.dll"     "$SYS32/"
cp "$DXMT/x86_64-windows/dxgi.dll"      "$SYS32/"
cp "$DXMT/x86_64-windows/d3d10core.dll" "$SYS32/"
cp "$DXMT/x86_64-windows/winemetal.dll" "$SYS32/"
cp "$DXMT/x86_64-unix/winemetal.so"     "$GPTK_UNIX/"
```

**Step 3 — Set DLL overrides** so Wine uses DXMT instead of its built-in D3D:
```bash
WINE="$HOME/Library/Application Support/heroic/tools/game-porting-toolkit/Game-Porting-Toolkit-latest/Contents/Resources/wine/bin/wine64"
WINEPREFIX="$HOME/Games/Heroic/Prefixes/$GAME_SLUG"

for dll in d3d11 dxgi d3d10core; do
  WINEPREFIX="$WINEPREFIX" WINEDEBUG=-all "$WINE" reg add \
    "HKEY_CURRENT_USER\Software\Wine\DllOverrides" \
    /v $dll /t REG_SZ /d native /f 2>/dev/null
done
```

Restart Heroic and launch again.
