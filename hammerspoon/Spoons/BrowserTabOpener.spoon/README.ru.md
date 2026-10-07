# BrowserTabOpener.spoon

[English](README.md)

Одна клавиша на сайт: переходит на его открытую вкладку, по второму нажатию — на следующую, а если вкладки нет — открывает.

- Больше никакой десятой вкладки с YouTube: клавиша находит ту, что уже есть.
- Повторные нажатия перебирают все вкладки этого сайта, начиная с самой новой.
- Может предпочесть вкладку, где играет видео.
- Ставить ничего не нужно: хватает Hammerspoon и AppleScript.

## Настройка

**1. Установите.** Распакуйте `BrowserTabOpener.spoon.zip` из [последнего релиза](https://github.com/servitola/BrowserTabOpener.spoon/releases/latest) в `~/.hammerspoon/Spoons/`.

**2. Назовите свои сайты и дайте им клавиши** в `~/.hammerspoon/init.lua`:

```lua
hs.loadSpoon("BrowserTabOpener")

spoon.BrowserTabOpener.tabs = {
    github  = { pattern = "github.com",  url = "https://github.com" },
    youtube = { pattern = "youtube.com", url = "https://youtube.com" },
}

spoon.BrowserTabOpener:bindHotkeys{
    github  = { { "ctrl", "alt" }, "g" },
    youtube = { { "ctrl", "alt" }, "y" },
}
```

**3. Перезагрузите Hammerspoon и нажмите клавишу.** В первый раз macOS спросит, можно ли Hammerspoon управлять браузером. Разрешите.

Это всё. `⌃⌥G` теперь переходит на вкладку GitHub; нажатая ещё раз — на следующую вкладку GitHub; если ни одной нет — открывает github.com.

## Сайт — это шаблон и адрес

| Поле | Что это |
|---|---|
| `pattern` | Кусок текста, который должен быть в адресе вкладки. По нему вкладка ищется. |
| `url` | Что открыть, если вкладки с таким текстом нет. |

Шаблон пишите без `https://` и без `www.`: в адресе `https://www.youtube.com/watch?v=…` есть `youtube.com`, этого достаточно.

Чем уже шаблон, тем меньше вкладок перебирает клавиша:

| Шаблон | Находит |
|---|---|
| `github.com` | все вкладки GitHub |
| `github.com/servitola` | только страницы этого аккаунта |
| `github.com/pulls` | только страницу пул-реквестов |
| `youtube.com/watch` | только вкладки YouTube с видео, без главной |
| `mail.google.com` | Gmail |
| `localhost:3000` | ваш локальный сервер |

Шаблон и адрес могут различаться намеренно: `pattern = "youtube.com/watch", url = "https://youtube.com"` ищет вкладку с видео, а если её нет — открывает главную.

## Вкладка, которая играет

Десять вкладок YouTube, в одной играет видео — клавиша идёт сразу в неё:

```lua
spoon.BrowserTabOpener.tabs = {
    playing = {
        pattern = "youtube.com/watch",
        url     = "https://youtube.com",
        prefer  = spoon.BrowserTabOpener.videoPlaying,
    },
}
```

Если ничего не играет, клавиша перебирает подходящие вкладки как обычно.

`prefer` задаёт странице вопрос на JavaScript, а браузеры этого не позволяют, пока вы не разрешите:

- **Chrome:** меню View → Developer → Allow JavaScript from Apple Events. В других Chromium-браузерах тот же переключатель лежит в меню разработчика.
- **Vivaldi:** Настройки → Приватность → Apple Events → разрешить JavaScript.

До этого `prefer` не учитывается, остальное работает, а в консоли Hammerspoon один раз появится сообщение об этом.

`videoPlaying` — готовое условие. Подойдёт любой JavaScript, который отвечает true или false: `prefer = "document.title.includes('Inbox')"`.

## Какой браузер

Системный браузер по умолчанию, если не указать другой по bundle id:

```lua
spoon.BrowserTabOpener.browser = "com.google.Chrome"
```

| Браузер | Bundle id |
|---|---|
| Chrome | `com.google.Chrome` |
| Vivaldi | `com.vivaldi.Vivaldi` |
| Brave | `com.brave.Browser` |
| Edge | `com.microsoft.edgemac` |
| Opera | `com.operasoftware.Opera` |

Любой другой: `osascript -e 'id of app "Название"'` в Терминале.

Переключение вкладок работает в Chromium-браузерах: у них общий скриптовый интерфейс. Проверено в Vivaldi. Firefox и Zen переключать вкладки из скрипта не умеют, там клавиша просто открывает адрес.

## Из своего кода

```lua
spoon.BrowserTabOpener:open("github")                                  -- сайт из tabs, по имени
spoon.BrowserTabOpener:open("github.com", "https://github.com")        -- или шаблон и адрес
spoon.BrowserTabOpener:open("youtube.com/watch", "https://youtube.com", { prefer = spoon.BrowserTabOpener.videoPlaying })
```

## Если не работает

Откройте консоль Hammerspoon и выполните:

```lua
spoon.BrowserTabOpener:check()
```

Она напечатает, какой браузер используется, можно ли переключать его вкладки и работает ли `prefer`.

| Что видите | Почему | Что делать |
|---|---|---|
| Каждое нажатие открывает новую вкладку | macOS не разрешает Hammerspoon управлять браузером | Системные настройки → Конфиденциальность и безопасность → Автоматизация → Hammerspoon → включить браузер |
| Каждое нажатие открывает новую вкладку, в Firefox или Zen | В этих браузерах нет скриптового доступа к вкладкам | Ничего; для переключения нужен Chromium-браузер |
| Клавиша не замечает играющую вкладку | JavaScript из Apple Events выключен | См. «Вкладка, которая играет» |
| Клавиша ходит не по тем вкладкам | Шаблон слишком широкий | Удлините его: `github.com/ваше-имя` |
| Клавиша ничего не находит, хотя вкладка открыта | Вкладка в другом окне, либо в шаблоне есть `www.` или `https://` | Поиск идёт только в переднем окне; шаблон пишите без приставок |
| Ошибка при запуске: `no "x" in tabs` | В `bindHotkeys` указан сайт, которого нет в `tabs` | Одинаковые имена в обоих местах |

## Пока нет

- Вкладок в других окнах: поиск идёт только в переднем окне.
- Safari.

## Тесты

```sh
lua tests/run.lua
```

## Лицензия

MIT
