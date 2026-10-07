**English** · [Русский](troubleshooting.ru.md)

# If right ⌥ + `c` types nothing

Open the Hammerspoon console (menu bar icon → Console) and type `hs.inspect(spoon.BirmanLayer:state())`.

- **Nothing named `BirmanLayer`**: the Spoon is not loaded. The folder must be exactly
  `~/.hammerspoon/Spoons/BirmanLayer.spoon`, and `init.lua` needs both lines from the README; reload the config.
- **`running = false`**: `start()` was not called, or it stopped with an error, which is shown in the console
  (for example an unknown key name in `overrides`).
- **`running = true`, still nothing**:
  - **Accessibility.** Hammerspoon must be ticked in System Settings → Privacy & Security → Accessibility. After a
    Hammerspoon update the tick can stay on while macOS no longer honors it: remove Hammerspoon from the list with
    `−`, add it again, restart it.
  - **Secure input.** Password fields and terminals with *Secure Keyboard Entry* switch every key tap off; nothing
    can type there.
  - **The app is excluded**: its bundle ID is in `excludedBundles`.
  - **Something else owns the right ⌥.** Karabiner-Elements, BetterTouchTool and similar tools can turn the right
    Option into another key, and then Hammerspoon never sees it. Karabiner-EventViewer shows what the key sends; it
    must be `right_option`. Right ⌥ held together with ⌘ or ⌃ is treated as a shortcut on purpose.
  - **A dead key is waiting.** Press Escape and try again.

A key types something, but not what you expect: [characters.md](characters.md) lists every key, and the ⌥ layer
is positional (QWERTY positions, whatever the layout).

## Removing it

Delete `~/.hammerspoon/Spoons/BirmanLayer.spoon` and the two lines from `~/.hammerspoon/init.lua`, then reload
the config.
