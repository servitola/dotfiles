# iterm — iTerm2 preferences + exported profile, restored as a custom prefs folder

- Secondary terminal. The primary daily terminal is Zap (open-source Warp fork; see `zap/` and root README); iTerm2 is kept as a fallback / classic terminal.
- `com.googlecode.iterm2.plist` — full iTerm2 preferences plist (colors, keymaps, window/profile settings). This is the synced source of truth, not `~/Library/Preferences`.
- `servitola_profile.json` — exported "servitola" profile (dynamic profile JSON): font, colors, triggers, working dir, etc.
- `install.sh` — wiring (not a symlink). Points iTerm2 at this folder via `defaults write com.googlecode.iterm2 PrefsCustomFolder` + `LoadPrefsFromCustomFolder -bool true`, so iTerm2 reads/writes its prefs here.
- Installed by the Makefile (`make`), which runs `iterm/install.sh` rather than creating a symlink. iTerm2 must be relaunched to pick up the custom folder.
