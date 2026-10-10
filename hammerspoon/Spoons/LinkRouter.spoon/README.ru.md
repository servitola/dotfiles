# LinkRouter.spoon

[English](README.md)

Каждая ссылка, по которой ты кликаешь, открывается в браузере, который назначило правило: рабочие сайты — в одном, локальные серверы — в другом, всё остальное — в обычном.

- Правила в одном месте, проверяются сверху вниз, срабатывает первое подходящее.
- Правило может смотреть, в каком приложении кликнули: ссылки на созвоны из Telegram — в Firefox, из остальных мест — в обычный браузер.
- Опечатка в правилах останавливает загрузку и называет номер правила, а не уводит ссылки молча не туда.
- Ничего не нужно ставить: только Hammerspoon.

## Установка

**1. Поставить.** Распаковать `LinkRouter.spoon.zip` из [последнего релиза](https://github.com/servitola/LinkRouter.spoon/releases/latest) в `~/.hammerspoon/Spoons/`.

**2. Написать правила** в `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("LinkRouter")
local router = spoon.LinkRouter

router.browsers = {
    main = "com.vivaldi.Vivaldi",
    work = "org.mozilla.firefox",
    dev  = "com.google.Chrome",
}
router.default = "main"
router.rules = {
    { router.localNetwork,                     "dev" },
    { { "jira%.mycorp%.com", "mycorp%.okta" }, "work" },
    { "^https://meet%.google%.com/",           "work", from = "com.tdesktop.Telegram" },
}
router:start()
```

**3. Перезагрузить Hammerspoon.** macOS спросит, можно ли сделать Hammerspoon браузером по умолчанию. Разрешить: только так он видит ссылки. Дальше — кликать по ссылкам.

## Правило

`{ match, open }` и необязательное `from`.

| Поле | Что это |
|---|---|
| `match` | [Lua-шаблон](https://www.lua.org/pil/20.2.html), который ищется во всём адресе; список шаблонов (хватит любого); или `function(url, senderBundle) -> boolean`. |
| `open` | Имя из `browsers`, bundle id или `function(url)`, чтобы обработать ссылку самому. |
| `from` | Bundle id или их список. Правило срабатывает только для ссылок из этих приложений. |

Lua-шаблоны — не регулярные выражения. Точка значит «любой символ», поэтому точку пишут как `%.`, дефис — как `%-`: `"github%.com"`. `^` привязывает к началу адреса: `"^https://meet%."`.

`router.localNetwork` — готовый список: `localhost`, `127.*`, `10.*`, `172.16`–`172.31`, `192.168.*` и имена `*.local`. Смотрит только на хост, так что `https://example.com/?next=http://localhost` — не локальный.

Правила проверяются сверху; решает первое подошедшее. Ничего не подошло — `default`.

## Ссылки в обёртках

Некоторые приложения заворачивают ссылки в свой редирект. `unwrap` выполняется до правил и отдаёт им настоящий адрес:

```lua
router.unwrap = { router.slackRedirect }
```

Unwrap — это `function(url) -> url или nil`; `nil` оставляет адрес как был.

## Проверить правило

В консоли Hammerspoon, ничего не открывая:

```lua
spoon.LinkRouter:route("http://localhost:3000")
-- http://localhost:3000    com.google.Chrome    1
```

Адрес после `unwrap`, куда он пойдёт, и номер решившего правила (`nil` — default). `spoon.LinkRouter:open(url)` открывает так же, как клик.

## Bundle id

| Браузер | Bundle id |
|---|---|
| Safari | `com.apple.Safari` |
| Chrome | `com.google.Chrome` |
| Firefox | `org.mozilla.firefox` |
| Vivaldi | `com.vivaldi.Vivaldi` |
| Brave | `com.brave.Browser` |
| Edge | `com.microsoft.edgemac` |
| Arc | `company.thebrowser.Browser` |

Любое другое приложение: `osascript -e 'id of app "Name"'` в Терминале. `from` принимает те же id: `com.tdesktop.Telegram`, `com.tinyspeck.slackmacgap`, `com.apple.mail`.

## Полезно знать

- Ссылки открываются через `open -b`, так же как их передаёт Finder. Некоторые Chromium-браузеры (Vivaldi 7) от `openURLWithBundle` самого Hammerspoon запускают вторую, сломанную копию себя.
- Браузер из правил не установлен — его ссылки идут в `default`, консоль об этом пишет. Не установлен `default` — `start()` останавливается с ошибкой.
- `spoon.LinkRouter:stop()` возвращает роль системного браузера `default`.

## Лицензия

MIT
