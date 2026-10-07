**English** · [Русский](configuration.ru.md)

# Configuration

## The basics

Nothing is required after `start()`. Two changes are common; set them before `start()`:

```lua
hs.loadSpoon("BirmanLayer")
local layer = spoon.BirmanLayer
layer.excludedBundles = { "com.example.game" }   -- apps where the layer stays silent
layer.excludedLayouts = { "com.apple.keylayout.Greek" }   -- layouts that keep their own ⌥ layer
layer.rightOptionOnly = false                    -- both ⌥ keys, as in Birman's Mac layout
layer:start()
```

Settings are read by `start()`; call it again after changing one. Methods: `start()`, `stop()`, `state()`
(`running`, pending dead key).

## Advanced

### All settings

| Variable | Default | Meaning |
| --- | --- | --- |
| `overrides` | `{}` | changes to Birman's table, see below |
| `rightOptionOnly` | `true` | the layer sits on the right ⌥ only (like Windows); `false`: on both ⌥ keys, as in Birman's Mac layout |
| `baseFixups` | `false` | type Birman's plain/Shift characters on the few keys where Apple's ABC and Russian – PC differ (ISO keyboards) |
| `excludedBundles` | `{}` | bundle IDs in which nothing is intercepted |
| `excludedLayouts` | `{}` | input source IDs (`hs.keycodes.currentSourceID()`) in which the layer stays out, so ⌥ types that layout's own characters: Apple's Greek ⌥ layer has the tonos letters (`ά έ ή`) and Greek symbols |
| `deadKeyTimeout` | `3` | seconds a dead key waits |
| `logger` | `hs.logger.new("BirmanLayer")` | Spoon logger |

### Overrides

`overrides` is keyed by `"*"` (every input source) or by one input source id, as
`hs.keycodes.currentSourceID()` prints it (`com.apple.keylayout.Greek`). An id's table sits on top
of `"*"`, which sits on top of Birman's. Each value has the shape of the Spoon's own table:

```lua
layer.overrides = {
    ["*"] = {
        keys = {
            g = { opt = "©", shift_opt = "℗" },        -- key names are QWERTY positions (a, 1, [, space, section), or key codes
            x = { opt = false },                       -- types nothing
            ["1"] = { opt = { pass = true } },         -- leave this key to Apple's own ⌥ layer
            ["/"] = { shift_opt = { dead = "acute" } }, -- enter a dead key
        },
        dead = {
            acute = {
                compose = { ["і"] = "і́", ["е"] = "е́" },   -- acute, then the key that types і / е
                keys = { i = { opt = "!" } },           -- a ⌥ key pressed inside the state
            },
        },
        terminators = { acute = "´" },                  -- what an unfinished dead key types
    },
    ["com.apple.keylayout.Greek"] = { keys = { ["="] = { shift_opt = "≥" } } },  -- this layout only
}
```

- A cell is text, `{ dead = "<state>" }`, `false` (type nothing) or `{ pass = true }` (Apple's).
- Birman's states: `acute grave circumflex diaeresis tilde ring caron breve cedilla double_acute`; any other name in `dead` defines a new one.
- `opt` is right ⌥ (either ⌥ when `rightOptionOnly = false`), `shift_opt` is ⇧ + that key.
- Key names are QWERTY positions whatever layout is active; an unknown name is an error when you call `start()`. Rows of `fixups` take names too.

### Change what Birman did

Some of Birman's choices look like slips, or differ between his English and Russian layouts. The Spoon
keeps them all; each is one `overrides` entry:

```lua
layer.overrides = {
    ["*"] = { dead = {
        -- ⇧⌥6 twice: English types two combining circumflexes (U+0302 U+0302), Russian one.
        circumflex = { keys = { ["6"] = { shift_opt = "\u{302}" } } },
        -- ¨ then ⌥i: English types the accent and then і, Russian types ï and Ї.
        diaeresis = { keys = { i = { opt = "ï", shift_opt = "Ї" } } },
    } },
    -- ISO Russian – PC has a second ё key (beside left ⇧) that Birman leaves out of the dead keys;
    -- this composes it like the first one (˘ then ё → ӗ).
    ["com.apple.keylayout.RussianWin"] = { dead = {
        breve = { keys = { ["`"] = { base = "ӗ", shift = "Ӗ" } } },
    } },
}
```

`base` and `shift` in a dead state's `keys` are cells for a plain or Shift key pressed by position; they
win over `compose`, and `{ pass = true }` there means "this key does not compose", which is how
Birman's layout leaves that second ё key out.

### `baseFixups`

Birman's layout also moves a few plain keys: `` ` `` and `~` on the ISO `§` key, `\` on the ISO key
beside left ⇧ in ABC, `Ё` on ⇧`` ` `` in Russian – PC. `baseFixups = true` types those, for
`com.apple.keylayout.ABC` and `com.apple.keylayout.RussianWin` only. It is meant for ISO
keyboards: on an ANSI keyboard the second fixup would turn the grave key into a backslash, which is why
it is off by default.
