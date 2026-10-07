# AutoKeyboardLayout.spoon

[Русский](README.ru.md)

Every app gets its keyboard layout the moment it comes to the front.

- One layout for everything, your second one for Telegram — any Telegram client, out of the box.
- Come back to an app and its layout is on again, whatever you typed elsewhere.
- Layouts by the name System Settings shows, input methods included.
- A typo in a layout name is an error at start, not a silent nothing.

## Install

Unzip `AutoKeyboardLayout.spoon.zip` from the [latest release](https://github.com/servitola/AutoKeyboardLayout.spoon/releases/latest) into `~/.hammerspoon/Spoons/`, then in `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("AutoKeyboardLayout")
spoon.AutoKeyboardLayout.primary = "ABC"
spoon.AutoKeyboardLayout.secondary = "Russian"
spoon.AutoKeyboardLayout:start()
```

Every app now opens in `ABC`; Telegram opens in `Russian`. Inside an app you switch by hand as usual; the Spoon only acts when an app comes to the front.

## Settings

Fields on `spoon.AutoKeyboardLayout`, set them between `hs.loadSpoon` and `start()`:

| Field | Default | |
|---|---|---|
| `primary` | none | The layout every app gets. Not set: ordinary apps are left alone. |
| `secondary` | none | The layout for the apps in `secondaryApps`. Not set: they are ordinary apps. |
| `secondaryApps` | Telegram clients | Bundle ids of the apps that get `secondary`. |
| `overrides` | `{}` | Bundle id → any layout, or `false` to leave that app alone. Beats `secondaryApps`. |
| `delay` | `0.05` | Seconds between an app coming to the front and the switch. |

A layout is its name in System Settings → Keyboard → Input Sources (`"ABC"`, `"Russian – PC"`), an input method name, or an input source id (`"com.apple.keylayout.ABC"`). What is installed:

```lua
hs.inspect(hs.keycodes.layouts())
```

An app's bundle id:

```sh
osascript -e 'id of app "Telegram"'
```

### Which apps get the second layout

Built in: Telegram for macOS, Telegram Desktop and its forks, Telegram Lite, Telegram A, AyuGram.

```lua
-- one more app
table.insert(spoon.AutoKeyboardLayout.secondaryApps, "net.whatsapp.WhatsApp")

-- your own list instead of the built-in one
spoon.AutoKeyboardLayout.secondaryApps = { "net.whatsapp.WhatsApp", "com.apple.MobileSMS" }

-- one Telegram client out of it
spoon.AutoKeyboardLayout.overrides = { ["org.telegram.TelegramA"] = "ABC" }
```

### Anything else

```lua
spoon.AutoKeyboardLayout.overrides = {
    ["com.apple.Notes"] = false,          -- never touched
    ["com.apple.dt.Xcode"] = "Greek",     -- a third layout
}
```

Only some apps, the rest untouched: leave `primary` unset and list the apps in `overrides`.

`stop()` stops switching; the current layout stays.

## macOS has a similar setting

System Settings → Keyboard → Input Sources → "Automatically switch to a document's input source" remembers the last layout of each window. It does not let you say which layout an app should have. This Spoon does not need that setting, on or off.

## Tests

```sh
lua tests/run.lua
```

## License

MIT
