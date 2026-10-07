# BrowserTabOpener.spoon

[Русский](README.ru.md)

One key for a site: jump to its open tab, press again for the next one, open it if there is none.

- No more tenth YouTube tab: the key finds the one you already have.
- Press again to walk through every tab of that site, newest first.
- Can prefer the tab where a video is playing.
- Nothing to install: plain Hammerspoon and AppleScript.

## Set up

**1. Install.** Unzip `BrowserTabOpener.spoon.zip` from the [latest release](https://github.com/servitola/BrowserTabOpener.spoon/releases/latest) into `~/.hammerspoon/Spoons/`.

**2. Name your sites and give them keys** in `~/.hammerspoon/init.lua`:

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

**3. Reload Hammerspoon and press a key.** The first time, macOS asks whether Hammerspoon may control your browser. Allow it.

That is all. `⌃⌥G` now goes to a GitHub tab; pressed again, to the next GitHub tab; with no GitHub tab open, it opens github.com.

## A site is a pattern and an address

| Field | What it is |
|---|---|
| `pattern` | A piece of text the tab's address must contain. This is how the tab is found. |
| `url` | What to open when no tab has that text. |

Write the pattern without `https://` and without `www.`: an address like `https://www.youtube.com/watch?v=…` contains `youtube.com`, and that is enough.

The narrower the pattern, the fewer tabs the key walks through:

| Pattern | Finds |
|---|---|
| `github.com` | every GitHub tab |
| `github.com/servitola` | only that account's pages |
| `github.com/pulls` | only the pull requests page |
| `youtube.com/watch` | only YouTube tabs with a video, not the home page |
| `mail.google.com` | Gmail |
| `localhost:3000` | your dev server |

The pattern and the address may differ on purpose: `pattern = "youtube.com/watch", url = "https://youtube.com"` looks for a video tab and opens the home page when there is none.

## The tab that is playing

Ten YouTube tabs, one of them playing — this goes straight to that one:

```lua
spoon.BrowserTabOpener.tabs = {
    playing = {
        pattern = "youtube.com/watch",
        url     = "https://youtube.com",
        prefer  = spoon.BrowserTabOpener.videoPlaying,
    },
}
```

With nothing playing, the key walks through the matching tabs as usual.

`prefer` asks the page a question in JavaScript, and browsers do not allow that until you say so:

- **Chrome:** menu View → Developer → Allow JavaScript from Apple Events. Other Chromium browsers keep the same switch in their Developer menu.
- **Vivaldi:** Settings → Privacy → Apple Events → allow JavaScript.

Until then `prefer` is ignored, the rest works, and the Hammerspoon console says so once.

`videoPlaying` is a ready condition. Any JavaScript that answers true or false works: `prefer = "document.title.includes('Inbox')"`.

## Which browser

The system default browser, unless you name one by its bundle id:

```lua
spoon.BrowserTabOpener.browser = "com.google.Chrome"
```

| Browser | Bundle id |
|---|---|
| Chrome | `com.google.Chrome` |
| Vivaldi | `com.vivaldi.Vivaldi` |
| Brave | `com.brave.Browser` |
| Edge | `com.microsoft.edgemac` |
| Opera | `com.operasoftware.Opera` |

Any other: `osascript -e 'id of app "Name"'` in Terminal.

Switching tabs works in Chromium browsers; they share one scripting interface. Tested in Vivaldi. Firefox and Zen cannot switch tabs from a script, so there a key just opens the address.

## From your own code

```lua
spoon.BrowserTabOpener:open("github")                                  -- a site from tabs, by name
spoon.BrowserTabOpener:open("github.com", "https://github.com")        -- or pattern and address
spoon.BrowserTabOpener:open("youtube.com/watch", "https://youtube.com", { prefer = spoon.BrowserTabOpener.videoPlaying })
```

## When it does not work

Open the Hammerspoon console and run:

```lua
spoon.BrowserTabOpener:check()
```

It prints which browser is used, whether its tabs can be switched, and whether `prefer` can run.

| What you see | Why | What to do |
|---|---|---|
| Every press opens a new tab | macOS does not let Hammerspoon control the browser | System Settings → Privacy & Security → Automation → Hammerspoon → turn the browser on |
| Every press opens a new tab, in Firefox or Zen | No tab scripting in these browsers | Nothing; use a Chromium browser for switching |
| The key ignores the playing tab | JavaScript from Apple Events is off | See "The tab that is playing" |
| The key goes to the wrong tabs | The pattern is too wide | Make it longer: `github.com/your-name` |
| The key finds nothing though the tab is open | The tab is in another window, or the pattern has `www.` or `https://` in it | Only the front window is searched; write the pattern bare |
| An error at start: `no "x" in tabs` | `bindHotkeys` names a site that `tabs` does not have | Same names in both |

## Not yet

- Tabs in other windows: only the front window is searched.
- Safari.

## Tests

```sh
lua tests/run.lua
```

## License

MIT
