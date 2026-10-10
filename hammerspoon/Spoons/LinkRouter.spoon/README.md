# LinkRouter.spoon

[Русский](README.ru.md)

Every link you click opens in the browser its rule names: work sites in one, local servers in another, everything else in your usual one.

- One place for the rules, checked top to bottom, first match wins.
- A rule can look at the app the link was clicked in: meeting links from Telegram to Firefox, from everywhere else to your usual browser.
- A typo in the rules stops the load with the rule's number, instead of quietly sending links elsewhere.
- Nothing to install: plain Hammerspoon.

## Set up

**1. Install.** Unzip `LinkRouter.spoon.zip` from the [latest release](https://github.com/servitola/LinkRouter.spoon/releases/latest) into `~/.hammerspoon/Spoons/`.

**2. Write the rules** in `~/.hammerspoon/init.lua`:

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

**3. Reload Hammerspoon.** macOS asks whether Hammerspoon may become the default browser. Allow it: that is how it sees the links. Then click any link.

## A rule

`{ match, open }`, plus an optional `from`.

| Field | What it is |
|---|---|
| `match` | A [Lua pattern](https://www.lua.org/pil/20.2.html) searched for in the whole address, a list of them (any one is enough), or `function(url, senderBundle) -> boolean`. |
| `open` | A name from `browsers`, a bundle id, or `function(url)` to handle the link yourself. |
| `from` | A bundle id or a list of them. The rule applies only to links clicked in those apps. |

Lua patterns are not regular expressions. A dot means any character, so write `%.` for a dot and `%-` for a hyphen: `"github%.com"`. Anchor with `^` to match the start of the address: `"^https://meet%."`.

`router.localNetwork` is a ready list: `localhost`, `127.*`, `10.*`, `172.16`–`172.31`, `192.168.*` and `*.local` names. It only looks at the host, so `https://example.com/?next=http://localhost` is not local.

Rules are checked from the top; the first one that matches decides. No match: `default`.

## Seeing through redirects

Some apps wrap links in their own redirect. `unwrap` runs before the rules and gives them the real address:

```lua
router.unwrap = { router.slackRedirect }
```

An unwrap is `function(url) -> url or nil`; `nil` leaves the address as it was.

## Checking a rule

From the Hammerspoon console, without opening anything:

```lua
spoon.LinkRouter:route("http://localhost:3000")
-- http://localhost:3000    com.google.Chrome    1
```

The address after `unwrap`, where it goes, and the number of the rule that decided (`nil`: the default). `spoon.LinkRouter:open(url)` opens it the same way a click would.

## Bundle ids

| Browser | Bundle id |
|---|---|
| Safari | `com.apple.Safari` |
| Chrome | `com.google.Chrome` |
| Firefox | `org.mozilla.firefox` |
| Vivaldi | `com.vivaldi.Vivaldi` |
| Brave | `com.brave.Browser` |
| Edge | `com.microsoft.edgemac` |
| Arc | `company.thebrowser.Browser` |

Any other app: `osascript -e 'id of app "Name"'` in Terminal. `from` takes the same ids: `com.tdesktop.Telegram`, `com.tinyspeck.slackmacgap`, `com.apple.mail`.

## Good to know

- Links open with `open -b`, the way Finder hands them over. Some Chromium browsers (Vivaldi 7) start a second, broken copy of themselves when given a link through Hammerspoon's own `openURLWithBundle`.
- A browser in the rules that is not installed: its links go to `default`, and the console says so. A missing `default` stops `start()`.
- `spoon.LinkRouter:stop()` gives links back to `default` as the system browser.

## License

MIT
