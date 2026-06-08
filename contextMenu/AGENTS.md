# contextMenu — Finder right-click actions for the ContextMenu.app (net.langui.ContextMenuHelper)

- Custom macOS Finder context-menu actions: open in editors (VS Code, Fork, Rider), file/clipboard utilities, image/video conversion, QR codes, "Send to Telegram", Wi-Fi toggles, new-file templates, etc.
- Each action is a bundle folder `actions/<Name>.cmaction/` containing `info.json` (declares `type`, `path`, `options`, `uuid`, `icon`), an `icon.icns`, and — for `type: shell` — a `main.sh`/`script.sh` that receives selected paths as `"$@"`.
- Action types: `shell` (runs a script with `path` interpreter, e.g. `/bin/zsh`) and `file` (new-file template; `path` is the template file like `document.md`, with `prefix`/`suffix` options).
- `actions/menu.plist` is the ordering/enabled manifest — lists each action's `name`, `icon`, `path`, and `enabled` flag. Add a new action here too, not just as a folder.
- To add one: create `actions/<Name>.cmaction/` with `info.json` (new `uuid`), an icon, a script, then register it in `menu.plist`.
- `helper_script.sh` installs a helper at `~/Library/Application Scripts/net.langui.ContextMenuHelper/contextmenu.sh` that kills the ScriptMonitor progress UI before exec'ing the action (run once after install).
