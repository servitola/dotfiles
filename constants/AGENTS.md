# constants/

Every value true about this machine — paths, browser of the day, chat ids,
proxies — so nothing hardcodes them again.

| File | Role |
|---|---|
| `../constants.env` | This Mac's values. Not in git: each Mac keeps its own. |
| `../constants.example.env` | Generated from `schema.toml` (every key's `about` and `example`); `install.sh` copies it to `constants.env` on a new Mac. Never edit it by hand. |
| `load.zsh` | Exports them, via `zsh/exports.sh` → every shell, service, cron job. |
| `constants.py` | `from constants import K`, where there is no shell. |
| `../hammerspoon/constants.lua` | `require("constants")` — in `hammerspoon/`, the only path its `require` sees. |
| `render-all.zsh` | Runs every `*/render.zsh`. Called by `const sync`, `install/07-config-links.sh`, `up`. |
| `template.zsh` | `render <config>` → `~/.local/state/dotfiles/generated/<same name>`. |
| `../<app>/render.zsh` | Two lines: source `template.zsh`, `render` that config. Today `git/`, `nuget/`. |
| `../zsh/bin/const` | The CLI — how an AI agent reads a value. |
| `schema.toml` | One line per key: `type`, `about`, `example`, and the flags below. A private key's `example` is a placeholder, never the real value. |
| `check.py` | Holds the file, the schema and the consumers to each other. Runs on every commit; `const check` adds the checks that need this machine. |

`KEY=value`, no quotes, no `export`; the value is the rest of the line verbatim.
`#` only at line start — inline it lands inside the value. `$HOME` is the one
expansion every reader does; `${HOME}` is not. `NONE` means this Mac has no
such thing (no work proxy on m1pro): `check.py` skips its type, and `render`
writes it as empty, which git and NuGet read as "off".

```zsh
$APP_BROWSER       # already exported in any shell
const app.browser  # dots and case normalise to APP_BROWSER
const list DIR_    # namespaces: ME_ APP_ DIR_ FILE_ TG_ PROXY_ HOST_ MODEL_
```

## Generated consumers

git config and NuGet XML expand nothing, so their configs are templates: the repo
file keeps its ordinary name (`git/identity.gitconfig`, `nuget/NuGet.Config`) and
holds `${CONSTANT}` — edit that one, then `const sync`. `<app>/render.zsh`
expands it into `~/.local/state/dotfiles/generated/`, where the `~/.nuget`
symlink and the `git/gitconfig` include point. A new consumer is one two-line
`render.zsh`, registered nowhere.

Every `$` expands, comments included — a literal one needs `\$`; an unknown name
aborts the render instead of writing empty. Nothing generated is in the repo: if
git asks who you are, the render never ran.

## Schema and checks

A key exists in `constants.env` and in `schema.toml`, or in neither. Types:
`text email timezone app bundle cli dir file chat_id url host`. Flags:

- `private = true` — the value identifies the owner or the employer. It decides
  which keys leave the public half of the file when the repo is published, and
  it makes the value a forbidden literal everywhere else.
- `unread = true` — nothing reads the key yet. A baseline, not a permission: a
  new key without a reader fails, and the flag fails once a reader appears.
- `removable = true` — a path that is allowed to be absent (an external drive).

`check.py` fails a commit on:

- a value that does not fit its type, or a line the four loaders (`load.zsh`,
  `const`, `constants.py`, `constants.lua`) would read differently — it runs all
  four on the real file and compares;
- a key nobody reads, and a reference to a key that does not exist (`K["X"]`,
  `constants.X`, `"@APP_X"`, `const x.y`, `$X` in a constants namespace);
- a staged line that hardcodes a private value or the home path. Only added
  lines count, so the existing ones do not block; `const literals` lists them
  all. A format that can expand nothing goes into `[literals] allow`.

`const check` adds: paths exist, apps are installed, CLIs are on `PATH`.
Tests: `python3 constants/test-check.py`.

## Rules

- A value belongs here when a second consumer needs it — not every string.
- Secrets stay in `constants.env`, which is not committed.
- Adding a key is two lines — its schema entry with an `example`, and its value in
  your `constants.env`. The commit hook (`check.py`) rewrites `constants.example.env`
  when the schema changed and asks you to stage it. Other Macs get the key from the
  example only on a fresh install: add it to their `constants.env` by hand.
- Consumers read the constant, never copy it. `hammerspoon/browsers.lua`:
  `APP_BROWSER` picks `M.main`, unknown name fails loudly.
- `app = "@APP_BROWSER"` in a keyboard chord resolves in three places that must
  stay in step: `HotKeys.spoon/init.lua`, `docs/keyboard/parse_active.py`,
  `docs/keyboard/app_constants.py`.
- `APP_*` is the role vocabulary of the keyboard layout: a chord binds `@APP_IDE`,
  not `Rider`. Adding a role means a chord (or another consumer) exists for it;
  `_BUNDLE` and `_CLI` suffixes are companions of the same role, not roles.
