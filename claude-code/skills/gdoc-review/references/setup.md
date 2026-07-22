# gdoc-review — авторизация и настройка

## Что переиспользуется

Скилл берёт **уже существующий** OAuth-клиент из `~/.config/openai_key.sh`:
`GOOGLE_CLIENT_ID` + `GOOGLE_API_SECRET`. Отдельный GCP-проект заводить не нужно.
Обёртка `scripts/gdoc` сама `source`-ит этот файл перед запуском.

Токен нашего скилла хранится **отдельно** от календарного MCP:
`~/.config/gdoc-review/token.json` (chmod 600). Календарь мы не трогаем.

## Скоупы (минимальные)

- `https://www.googleapis.com/auth/documents` — читать/править содержимое дока (`batchUpdate`).
- `https://www.googleapis.com/auth/drive.file` — создавать файлы и читать комменты **только на файлах, созданных этим приложением**.

`drive.file` — намеренно узкий scope: скилл видит лишь доки, которые сам создал через `gdoc create`.
Комменты пользователя на этих доках читаются полностью.

## Разовая авторизация

```
! ~/projects/dotfiles/claude-code/skills/gdoc-review/scripts/gdoc auth
```

Откроется браузер (loopback-redirect на `http://localhost:<случайный порт>`), выбираешь
Google-аккаунт, разрешаешь доступ. Токен сохранится, дальше refresh идёт автоматически.

## Возможные проблемы

**`redirect_uri_mismatch` при consent.**
Значит OAuth-клиент имеет тип «Web application» без разрешённого loopback. Варианты:
1. В Google Cloud Console → APIs & Services → Credentials → этот OAuth client → добавить
   `http://localhost` в Authorized redirect URIs.
2. Либо создать новый OAuth client типа **Desktop app** и подставить его id/secret
   (можно временно экспортнуть `GOOGLE_CLIENT_ID` / `GOOGLE_API_SECRET` перед `gdoc auth`).

**`access_denied` / экран «app not verified».**
Приложение в режиме Testing и аккаунт не добавлен в тестовые пользователи. Console →
OAuth consent screen → Test users → добавить свой email. Либо на экране предупреждения
нажать «Advanced → Go to … (unsafe)» (это твоё же приложение).

**Docs/Drive API не включены.**
Console → APIs & Services → Library → включить **Google Docs API** и **Google Drive API**
в том же проекте, что и OAuth-клиент.

**`invalid_grant` при обычной работе.**
Токен отозван/протух без refresh → просто перезапусти `gdoc auth`.

## Работа с уже существующим (не созданным скиллом) доком

`drive.file` этого не позволяет by design. Если понадобится — поменять в `scripts/gdoc.py`
скоуп `drive.file` на `https://www.googleapis.com/auth/drive` (полный Drive) и заново
пройти `gdoc auth`. Это более широкий доступ — включать только при явной необходимости.
