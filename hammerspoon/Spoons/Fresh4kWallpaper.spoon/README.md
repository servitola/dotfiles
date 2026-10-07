# Fresh4kWallpaper.spoon

[Русский](README.ru.md)

A new 4K wallpaper every time Hammerspoon starts. One file on disk, ever.

- Pictures come from GitHub collections; five are built in, add your own.
- 4K only: anything smaller than 3840×2160 is skipped and remembered, so it is never downloaded twice.
- The last 100 pictures are not repeated.
- The previous wallpaper is deleted when the next one arrives.
- Nothing to install and no GitHub token: plain Hammerspoon and `sips`, which ships with macOS.

## Install

Unzip `Fresh4kWallpaper.spoon.zip` from the [latest release](https://github.com/servitola/Fresh4kWallpaper.spoon/releases/latest) into `~/.hammerspoon/Spoons/`, then in `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Fresh4kWallpaper")
spoon.Fresh4kWallpaper:start()
```

A new wallpaper appears on start and on every reload, then once a day while Hammerspoon keeps running.

## Use

| Call | Does |
|---|---|
| `start()` | Changes the wallpaper and starts the daily timer. |
| `next()` | Changes the wallpaper now. |
| `stop()` | Stops the timer. The wallpaper stays. |
| `bindHotkeys{ next = { mods, key } }` | A hotkey for `next()`. |

```lua
spoon.Fresh4kWallpaper:bindHotkeys{ next = { { "ctrl", "alt", "cmd" }, "w" } }
```

## Settings

Fields on `spoon.Fresh4kWallpaper`, set them between `hs.loadSpoon` and `start()`:

```lua
hs.loadSpoon("Fresh4kWallpaper")
spoon.Fresh4kWallpaper.only4k = false                  -- any size
spoon.Fresh4kWallpaper.interval = 60 * 60              -- every hour instead of every day
spoon.Fresh4kWallpaper.changeOnStart = false           -- only the timer changes it
spoon.Fresh4kWallpaper.sources = { "owner/repo/path" } -- your collections instead of the built-in ones
spoon.Fresh4kWallpaper:start()
```

| Field | Default | |
|---|---|---|
| `sources` | five collections, see below | `"owner/repo"` for every picture in a GitHub repository, `"owner/repo/path"` for one folder of it, subfolders included. |
| `only4k` | `true` | Skip pictures below 3840×2160. |
| `interval` | `86400` | Seconds between changes. |
| `changeOnStart` | `true` | Change on `start()`. |
| `historySize` | `100` | Recent pictures that are not repeated. |
| `cacheDays` | `7` | How long a collection's file list is reused before GitHub is asked again. |
| `dir` | `~/Pictures/Fresh4kWallpaper` | The current wallpaper, `history.log`, `blocklist.txt`, cached file lists. |
| `token` | none | A GitHub token. Not needed in normal use, see below. |

Only files named `Fresh4kWallpaper-<time>.<ext>` are ever deleted from `dir`; other files in it are left alone.

The wallpaper is set on the main screen, for the Space that is in front.

## Where the pictures come from

Built in, with thanks to the people who collected them:

- [AngelJumbo/gruvbox-wallpapers](https://github.com/AngelJumbo/gruvbox-wallpapers)
- [Nix3l/wallpapers](https://github.com/Nix3l/wallpapers)
- [dharmx/walls](https://github.com/dharmx/walls)
- [makccr/wallpapers](https://github.com/makccr/wallpapers)
- [Ajaymanikandan0x/hyprland_wallpapers](https://github.com/Ajaymanikandan0x/hyprland_wallpapers)

The Spoon ships no pictures. It downloads one at a time from these repositories to your Mac; the pictures belong to their authors.

## GitHub limits

GitHub answers 60 anonymous API requests an hour. The Spoon asks once per collection for the list of its files and keeps the list for `cacheDays`; changing the wallpaper then only downloads a picture, which is not an API request. With the built-in collections that is five requests a week, however often Hammerspoon reloads. To pick up new pictures sooner, delete `cache/` in `dir`.

## Tests

```sh
lua tests/run.lua
```

## License

MIT
