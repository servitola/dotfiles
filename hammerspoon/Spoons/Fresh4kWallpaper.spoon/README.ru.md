# Fresh4kWallpaper.spoon

[English](README.md)

Новые 4K-обои при каждом запуске Hammerspoon. На диске всегда один файл.

- Картинки берутся из коллекций на GitHub; пять встроены, можно добавить свои.
- Только 4K: всё, что меньше 3840×2160, пропускается и запоминается, второй раз не скачивается.
- Последние 100 картинок не повторяются.
- Прошлые обои удаляются, когда приходят следующие.
- Ставить ничего не нужно, токен GitHub тоже не нужен: хватает Hammerspoon и `sips`, который есть в macOS.

## Установка

Распакуйте `Fresh4kWallpaper.spoon.zip` из [последнего релиза](https://github.com/servitola/Fresh4kWallpaper.spoon/releases/latest) в `~/.hammerspoon/Spoons/`, затем в `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("Fresh4kWallpaper")
spoon.Fresh4kWallpaper:start()
```

Обои меняются при запуске и при каждой перезагрузке конфига, дальше раз в сутки, пока Hammerspoon работает.

## Использование

| Вызов | Что делает |
|---|---|
| `start()` | Меняет обои и запускает суточный таймер. |
| `next()` | Меняет обои сейчас. |
| `stop()` | Останавливает таймер. Обои остаются. |
| `bindHotkeys{ next = { mods, key } }` | Хоткей для `next()`. |

```lua
spoon.Fresh4kWallpaper:bindHotkeys{ next = { { "ctrl", "alt", "cmd" }, "w" } }
```

## Настройки

Поля `spoon.Fresh4kWallpaper`, задаются между `hs.loadSpoon` и `start()`:

```lua
hs.loadSpoon("Fresh4kWallpaper")
spoon.Fresh4kWallpaper.only4k = false                  -- любой размер
spoon.Fresh4kWallpaper.interval = 60 * 60              -- раз в час, а не раз в сутки
spoon.Fresh4kWallpaper.changeOnStart = false           -- меняет только таймер
spoon.Fresh4kWallpaper.sources = { "owner/repo/path" } -- свои коллекции вместо встроенных
spoon.Fresh4kWallpaper:start()
```

| Поле | По умолчанию | |
|---|---|---|
| `sources` | пять коллекций, см. ниже | `"owner/repo"` — все картинки репозитория на GitHub, `"owner/repo/path"` — одна его папка вместе с подпапками. |
| `only4k` | `true` | Пропускать картинки меньше 3840×2160. |
| `interval` | `86400` | Секунд между сменами. |
| `changeOnStart` | `true` | Менять при `start()`. |
| `historySize` | `100` | Сколько последних картинок не повторять. |
| `cacheDays` | `7` | Сколько дней список файлов коллекции используется повторно, прежде чем снова спросить GitHub. |
| `dir` | `~/Pictures/Fresh4kWallpaper` | Текущие обои, `history.log`, `blocklist.txt`, кэш списков файлов. |
| `token` | нет | Токен GitHub. В обычной работе не нужен, см. ниже. |

Из `dir` удаляются только файлы вида `Fresh4kWallpaper-<время>.<расширение>`; остальные файлы в папке не трогаются.

Обои ставятся на главный экран, для того Space, который сейчас открыт.

## Откуда картинки

Встроенные коллекции, спасибо их авторам:

- [AngelJumbo/gruvbox-wallpapers](https://github.com/AngelJumbo/gruvbox-wallpapers)
- [Nix3l/wallpapers](https://github.com/Nix3l/wallpapers)
- [dharmx/walls](https://github.com/dharmx/walls)
- [makccr/wallpapers](https://github.com/makccr/wallpapers)
- [Ajaymanikandan0x/hyprland_wallpapers](https://github.com/Ajaymanikandan0x/hyprland_wallpapers)

В самом Spoon'е картинок нет. Он скачивает по одной из этих репозиториев на ваш Mac; картинки принадлежат их авторам.

## Лимиты GitHub

GitHub отвечает на 60 анонимных запросов к API в час. Spoon один раз спрашивает у каждой коллекции список файлов и хранит его `cacheDays` дней; смена обоев после этого только скачивает картинку, а это не запрос к API. Со встроенными коллекциями выходит пять запросов в неделю, как бы часто Hammerspoon ни перезагружался. Чтобы новые картинки подхватились раньше, удалите `cache/` в `dir`.

## Тесты

```sh
lua tests/run.lua
```

## Лицензия

MIT
