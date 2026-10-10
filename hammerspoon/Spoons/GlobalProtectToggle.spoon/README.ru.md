# GlobalProtectToggle.spoon

[English](README.md)

Включение и выключение VPN GlobalProtect одной клавишей.

У GlobalProtect для Mac нет ни командной строки, ни хоткея: управлять им можно только через панель под иконкой в строке меню. Этот Spoon открывает панель, нажимает кнопку и закрывает панель — за долю секунды.

Неофициальный; не связан с Palo Alto Networks.

## Настройка

**1. Установите.** Распакуйте `GlobalProtectToggle.spoon.zip` из [последнего релиза](https://github.com/servitola/GlobalProtectToggle.spoon/releases/latest) в `~/.hammerspoon/Spoons/`.

**2. Дайте клавишу** в `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("GlobalProtectToggle")
spoon.GlobalProtectToggle:bindHotkeys{
    toggle = { { "ctrl", "alt", "cmd" }, "v" },
}
```

**3. Перезагрузите Hammerspoon и нажмите клавишу.** В первый раз macOS спросит, можно ли Hammerspoon управлять System Events. Разрешите. Ещё Hammerspoon нужен доступ «Универсальный доступ» — обычно он уже есть.

## Использование

| Вызов | Что делает |
|---|---|
| `toggle()` | Подключает, если отключено; отключает, если подключено. |
| `connect()` | Подключает; если уже подключено — ничего не делает. |
| `disconnect()` | Отключает; если уже отключено — ничего не делает. |
| `status(callback)` | Вызывает `callback("connected")` или `callback("disconnected")`. |
| `bindHotkeys{ … }` | Хоткеи для `toggle`, `connect`, `disconnect`. |

«Подключает» значит, что нажата кнопка Connect. Дальше GlobalProtect тратит свои обычные несколько секунд и спрашивает пароль или второй фактор, если так требует ваша компания.

## Настройки

### Сообщения

По умолчанию короткий `hs.alert` говорит, что произошло. Замените его своей функцией:

```lua
spoon.GlobalProtectToggle.notify = function(event, problem)
    -- event: "connect", "disconnect"       кнопка нажата
    --        "connected", "disconnected"   делать нечего, состояние уже такое
    --        "error"                       причина в problem
    hs.notify.show("VPN", "", event == "error" and problem or event)
end
```

`spoon.GlobalProtectToggle.notify = function() end` — без сообщений.

### GlobalProtect на другом языке

Spoon определяет состояние по тексту главной кнопки панели. Если у вас там не Connect / Disconnect:

```lua
spoon.GlobalProtectToggle.labels = { connect = "Verbinden", disconnect = "Trennen" }
```

## Если не работает

| Сообщение | Почему | Что делать |
|---|---|---|
| GlobalProtect is not running | Нет иконки в строке меню, нажимать некуда | Запустите GlobalProtect |
| macOS does not let Hammerspoon send events | Отказано в разрешении «Автоматизация» | Системные настройки → Конфиденциальность и безопасность → Автоматизация → Hammerspoon → System Events |
| macOS does not let Hammerspoon click | Нет разрешения «Универсальный доступ» | Системные настройки → Конфиденциальность и безопасность → Универсальный доступ → Hammerspoon |
| The button reads "…" | GlobalProtect занят подключением, либо у него не английский язык | Подождите или задайте `labels` |
| The panel did not open or looks different | Версия GlobalProtect с другой раскладкой панели | Заведите issue с номером версии GlobalProtect |

## Как это устроено и где пределы

Spoon кликает: иконка в строке меню, вторая кнопка панели, снова иконка. Панель на мгновение появляется. Если обновление GlobalProtect передвинет эту кнопку, Spoon перестанет работать, пока его не поправят. Написан под GlobalProtect 6 для macOS.

## Тесты

```sh
lua tests/run.lua
```

## Лицензия

MIT
