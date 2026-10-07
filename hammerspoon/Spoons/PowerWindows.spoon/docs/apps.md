# Apps

Which window goes where, and how to change it.

## Slots

| Slot | Where |
|---|---|
| `main` | big left area; default for every app |
| `side` | right column, upper part |
| `corner` | right column, under `side` |
| `stack` | one window: like `side`; two or more: whole right column, split evenly |
| `dialog` | top right corner, size kept when it fits |

Proportions: [layout.md](layout.md). Bundle ID of an app:

```sh
osascript -e 'id of app "Telegram"'
```

## Catalog

[`config/catalog.lua`](../config/catalog.lua): one list per destination. Add a bundle ID to the list that fits:

| List | Windows go |
|---|---|
| `side` | right column |
| `players` | `corner`, proportions kept |
| `leaveAlone` | nowhere: never placed automatically; a chord still moves them |
| `chromiumBrowsers` / `geckoBrowsers` | picture-in-picture window → `corner` |
| `special` | full entries, for one kind of window told by title or size |

```lua
side = {
    "com.example.Chat",
},
```

A `special` entry; they are checked before the lists, first match wins:

```lua
{ "com.apple.Music", "corner", title = "^Mini Player$", sample = "Mini Player" },
```

| Field | Meaning |
|---|---|
| `[1]` | bundle ID, or `"*"` |
| `[2]` | slot, or `false` = never placed automatically; a chord still moves it |
| `title` / `notTitle` | Lua pattern the title must / must not match |
| `identifier` | the window's accessibility identifier (`AXIdentifier`), exact; for windows whose title changes |
| `sample` | a title that `title` matches; the tests check it |
| `maxTitle` | title at most this many characters |
| `maxSize` | `{ w, h }`: window strictly smaller |
| `keepAspect` | resize without changing proportions |
| `device` | phone-sized: `device` in [layout.md](layout.md) |
| `popup` | floating player: focus sets keep it and minimize the app's other windows |

Missing or wrong? One line, pull request: <https://github.com/servitola/PowerWindows.spoon>. Off: `catalog = false`.

## Overrides

A slot, `false`, or a table. Merges bundle by bundle. An unknown slot raises.

```lua
spoon.PowerWindows:configure{
  overrides = {
    ["com.tinyspeck.slackmacgap"] = "main",
    ["com.example.overlay"] = false,
    ["com.example.player"] = { slot = "corner", keepAspect = true },
  },
}:start()
spoon.PowerWindows:setOverride("com.example.Chat", "side") -- nil clears
```

## Leave alone

`false` in the catalog, `overrides` or `rule`, or a skip predicate: never moved automatically. `⌃⌥↓` and place on launch pass the window by; focus sets do not place it, but still hide or restore its app. A chord still moves it.

```lua
spoon.PowerWindows:addSkipPredicate(function(window) return window:title() == "Scratch" end)
```

## Dialogs

Small Save, Open, Export, Print, Copy windows go to the top right corner. List: [`config/dialogs.lua`](../config/dialogs.lua). Any match is a dialog. Off: `dialogs = false`.

```lua
{ "*", title = "^Save", maxSize = { 800, 600 } },
{ "com.apple.finder", maxSize = { 500, 300 }, maxTitle = 29 },
```

| Field | Meaning |
|---|---|
| `[1]` | bundle ID or `"*"` |
| `title` / `notTitle` | title must / must not match |
| `maxSize` | `{ w, h }`: strictly smaller |
| `maxTitle` | title at most this many characters |

## Rule

Runs first for every window. `info` = `{ bundle, app, title, w, h, identifier }`. Return a slot, `false`, a table, or `nil` to fall through.

```lua
spoon.PowerWindows:configure{
  rule = function(window, info)
    if info.bundle == "org.hammerspoon.Hammerspoon" and info.title == "" then return false end
    if info.app == "Zoom" and info.title == "Zoom Meeting" then return "main" end
  end,
}:start()
```

## Decision order

First answer wins:

1. `rule`, unless `nil`
2. `overrides`: `false`
3. catalog: `false`, when no override
4. `config/dialogs.lua`: `dialog`
5. `overrides`: slot
6. catalog: slot
7. `main`

An override naming the catalog's slot keeps its `keepAspect`, `device`, `popup`. Check a window; `source` says who decided (`rule`, `override`, `catalog`, `dialog`, `default`):

```lua
hs.timer.doAfter(3, function() print(hs.inspect(spoon.PowerWindows:resolve())) end) -- switch to the window within 3 s
```

## Place on launch (experimental)

For apps that open centered or re-center after loading (Electron).

```lua
spoon.PowerWindows:configure{
  experimental = { placeOnLaunch = { bundles = { "com.jetbrains.rider" }, finderFirstWindow = true } },
}:start()
```

- `bundles`: waits up to 30 s for the first window and places it. A `main`, `side` or `corner` window the app moves within 12 s is put back once.
- `finderFirstWindow`: a new Finder window is placed when it is the only one.
