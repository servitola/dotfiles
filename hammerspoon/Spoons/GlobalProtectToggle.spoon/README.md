# GlobalProtectToggle.spoon

[Русский](README.ru.md)

Connect and disconnect the GlobalProtect VPN with a key.

GlobalProtect for Mac has no command line and no shortcut: the only control is the panel under its menu bar icon. This Spoon opens that panel, presses the button and closes it again, in a fraction of a second.

Unofficial; not affiliated with Palo Alto Networks.

## Set up

**1. Install.** Unzip `GlobalProtectToggle.spoon.zip` from the [latest release](https://github.com/servitola/GlobalProtectToggle.spoon/releases/latest) into `~/.hammerspoon/Spoons/`.

**2. Give it a key** in `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("GlobalProtectToggle")
spoon.GlobalProtectToggle:bindHotkeys{
    toggle = { { "ctrl", "alt", "cmd" }, "v" },
}
```

**3. Reload Hammerspoon and press the key.** The first time, macOS asks to let Hammerspoon control System Events. Allow it. Hammerspoon also needs Accessibility, which it normally already has.

## Use

| Call | Does |
|---|---|
| `toggle()` | Connects when disconnected, disconnects when connected. |
| `connect()` | Connects; nothing happens when already connected. |
| `disconnect()` | Disconnects; nothing happens when already disconnected. |
| `status(callback)` | Calls `callback("connected")` or `callback("disconnected")`. |
| `bindHotkeys{ … }` | Hotkeys for `toggle`, `connect`, `disconnect`. |

"Connects" means the Connect button was pressed. GlobalProtect then takes its usual few seconds, and asks for a password or a second factor if your company requires one.

## Settings

### Messages

By default a short `hs.alert` says what happened. Replace it with your own function:

```lua
spoon.GlobalProtectToggle.notify = function(event, problem)
    -- event: "connect", "disconnect"   the button was pressed
    --        "connected", "disconnected"   nothing to do, already in that state
    --        "error"                        problem is the reason
    hs.notify.show("VPN", "", event == "error" and problem or event)
end
```

`spoon.GlobalProtectToggle.notify = function() end` for silence.

### GlobalProtect in another language

The Spoon tells the state by the text of the panel's main button. If yours does not read Connect / Disconnect:

```lua
spoon.GlobalProtectToggle.labels = { connect = "Verbinden", disconnect = "Trennen" }
```

## When it does not work

| Message | Why | What to do |
|---|---|---|
| GlobalProtect is not running | No menu bar icon to click | Start GlobalProtect |
| macOS does not let Hammerspoon send events | The Automation permission was refused | System Settings → Privacy & Security → Automation → Hammerspoon → System Events |
| macOS does not let Hammerspoon click | No Accessibility permission | System Settings → Privacy & Security → Accessibility → Hammerspoon |
| The button reads "…" | GlobalProtect is busy connecting, or its language is not English | Wait, or set `labels` |
| The panel did not open or looks different | A GlobalProtect version with another panel layout | Open an issue with your GlobalProtect version |

## How it works, and its limits

It clicks: the menu bar icon, then the second button of the panel, then the icon again. The panel flashes for a moment. If a GlobalProtect update moves that button, the Spoon stops working until it is adjusted. Written against GlobalProtect 6 for macOS.

## Tests

```sh
lua tests/run.lua
```

## License

MIT
