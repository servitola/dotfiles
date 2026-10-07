# AutoKeyboardLayout.spoon

[English](README.md)

У каждого приложения своя раскладка: она включается, как только приложение выходит на передний план.

- Одна раскладка для всего, вторая — для Telegram: любой Telegram-клиент, без настройки.
- Вернулись в приложение — его раскладка включена снова, что бы вы ни набирали в других.
- Раскладки задаются именем из Системных настроек, методы ввода тоже подходят.
- Опечатка в имени раскладки — ошибка при запуске, а не тихое «не переключилось».

## Установка

Распакуйте `AutoKeyboardLayout.spoon.zip` из [последнего релиза](https://github.com/servitola/AutoKeyboardLayout.spoon/releases/latest) в `~/.hammerspoon/Spoons/`, затем в `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("AutoKeyboardLayout")
spoon.AutoKeyboardLayout.primary = "ABC"
spoon.AutoKeyboardLayout.secondary = "Russian"
spoon.AutoKeyboardLayout:start()
```

Теперь любое приложение открывается с `ABC`, а Telegram — с `Russian`. Внутри приложения вы переключаете раскладку руками, как обычно; Spoon срабатывает только в момент, когда приложение выходит на передний план.

## Настройки

Поля `spoon.AutoKeyboardLayout`, задаются между `hs.loadSpoon` и `start()`:

| Поле | По умолчанию | |
|---|---|---|
| `primary` | нет | Раскладка для всех приложений. Не задана — обычные приложения не трогаются. |
| `secondary` | нет | Раскладка для приложений из `secondaryApps`. Не задана — они считаются обычными. |
| `secondaryApps` | Telegram-клиенты | Bundle id приложений, которым включается `secondary`. |
| `overrides` | `{}` | Bundle id → любая раскладка, либо `false` — это приложение не трогать. Сильнее, чем `secondaryApps`. |
| `delay` | `0.05` | Секунд между выходом приложения на передний план и переключением. |

Раскладка — это её имя в Системных настройках → Клавиатура → Источники ввода (`"ABC"`, `"Russian – PC"`), имя метода ввода или id источника ввода (`"com.apple.keylayout.ABC"`). Что установлено:

```lua
hs.inspect(hs.keycodes.layouts())
```

Bundle id приложения:

```sh
osascript -e 'id of app "Telegram"'
```

### Каким приложениям включается вторая раскладка

Встроены: Telegram для macOS, Telegram Desktop и его форки, Telegram Lite, Telegram A, AyuGram.

```lua
-- ещё одно приложение
table.insert(spoon.AutoKeyboardLayout.secondaryApps, "net.whatsapp.WhatsApp")

-- свой список вместо встроенного
spoon.AutoKeyboardLayout.secondaryApps = { "net.whatsapp.WhatsApp", "com.apple.MobileSMS" }

-- убрать из него один Telegram-клиент
spoon.AutoKeyboardLayout.overrides = { ["org.telegram.TelegramA"] = "ABC" }
```

### Всё остальное

```lua
spoon.AutoKeyboardLayout.overrides = {
    ["com.apple.Notes"] = false,          -- не трогать никогда
    ["com.apple.dt.Xcode"] = "Greek",     -- третья раскладка
}
```

Только некоторые приложения, остальные не трогать: не задавайте `primary` и перечислите приложения в `overrides`.

`stop()` выключает переключение; текущая раскладка остаётся.

## В macOS есть похожая настройка

Системные настройки → Клавиатура → Источники ввода → «Автоматически переключаться на источник ввода документа» запоминает последнюю раскладку каждого окна. Задать, какая раскладка должна быть у приложения, она не даёт. Этому Spoon'у та настройка не нужна — ни включённая, ни выключенная.

## Тесты

```sh
lua tests/run.lua
```

## Лицензия

MIT
