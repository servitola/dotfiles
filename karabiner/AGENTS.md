# Karabiner Configuration Rules

## What Is What
```
layers.toml              ← the layout. Edit this.
hand/NN-name.json        ← six whole rules no table can say. Edit by hand.
hand/raw/NN-name.json    ← manipulators appended to a generated rule (same NN-name).
karabiner-template.json  ← everything in karabiner.json that is not a rule: profile, devices, parameters.
generator/               ← layers.toml + hand/ + template → karabiner.json. Code, not config.
build.sh                 ← run after any edit: generator, then instrument.py (keylog markers).
karabiner.json           ← the output Karabiner loads. Git-ignored. Never edit, never read.
```

There are no intermediate files: the generator builds every rule in memory and writes only
`karabiner.json`. To look at the rules it produces, `python3 generator/gen_rules.py --check --dump
/tmp/rules` writes one `<stem>.json` per rule there.

- **Edit** `layers.toml` (or `hand/`), then **run** `./build.sh`. Karabiner reloads the file itself.
- `python3 generator/gen_rules.py --check` generates without writing; pre-commit and
  `install/check.sh` run it. It fails on a row the grammar rejects and on a manipulator that can
  never fire.
- The generator needs `python3` ≥ 3.11 (`tomllib`); the Apple `/usr/bin/python3` 3.9 is not enough
  — Homebrew's is on PATH first.
- **Bridge slots**: `[slots]` in `layers.toml` gives eight Hyper letters an F-key each; the
  generator sends every modifier variant of the letter as the same variant of its F-key. See
  *Bridge Slots* below.

### generator/
| file | what it holds |
|---|---|
| `gen_rules.py` | the command: `--check`, `--dump DIR`, or write `karabiner.json` |
| `layers.py` | reads `layers.toml` and `hand/`, builds the rules |
| `grammar.py` | the glyph grammar of values: `⇧⌃F13`, `↑`, `Vol↑`, `passthrough` ↔ Karabiner `to` |
| `keys.py` | key codes, the physical keys they sit on, glyphs |
| `shadow.py` | simulates Karabiner's first-match rule to find manipulators that can never fire |
| `tests/` | `pytest karabiner/generator/tests` |

The keyboard pictures, `lint.py`, `where.py` and `bridge.py` in `docs/keyboard/` import these
modules (`docs/keyboard/generator_path.py` puts them on the path) and ask `layers.all_rules()` for
the rules; nothing there reads `karabiner.json`.

## layers.toml
`[layer.<name>]` tables of `key = "output"` rows. A table opens with what it is, then a blank line,
then the rows:

| key | meaning |
|---|---|
| `rule = "NN-name"` | the rule the table goes to. Karabiner tries rules in name order, `hand/NN-name.json` sorted in with them, so `NN` is behaviour. Tables sharing a rule go into it in file order |
| `title = "…"` | the rule's name in Karabiner's UI; once per rule |
| `mandatory`, `optional` | Karabiner modifier names every row is pressed with (`["fn"]`, `["any"]`) |
| `when`, `unless` | a Karabiner variable that must be 1 / must not be 1 |

Nothing about a table lives in Python: a new rule is a new table.

- **Output grammar**: `⇪⇧⌃⌥⌘` prefix + a key glyph (`↑`, `⌦`, `PgUp`, `F1`, `a`, `/`, …), a media
  symbol (`⏮ ⏭ ▶/⏸ Vol↑ Vol↓ 🔆 🔅 ☀↑ ☀↓ ⏪ ⏩ Mute`), or `passthrough` (resend the pressed key,
  e.g. `⇧passthrough`). `⇪` in an output is the four right modifiers, every other glyph a left one.
  A value with spaces is several outputs sent in order (`s = "s e r v i t o l a"`); `sh: command`
  runs a shell command; `non_us_backslash` names that key when it is not the pressed one. A value
  the grammar cannot parse stops the build and names the layer and key.
- **Hyper layers** are the tables named `hyper` or `hyper_<shift|command|option|control>…` (rules
  `07`–`17`): held with Caps Lock plus those left modifiers, so they take no `mandatory`. The key
  is a Karabiner `key_code`. `[slots]` adds a manipulator for every slot letter the table does not
  map in that layer, after the table rows.
- **Tables with `mandatory`** are layers on other modifiers, without `[slots]`: `right_cmd` (right
  `⌘`), `left_all` (left `⇧⌃⌥⌘`), `fn` (`fn` mandatory, every other modifier optional).
- **Tables without `mandatory`** are chord tables: a row's key may carry its own modifiers,
  `"⌥⇧q" = "⇧⌦"`. Key grammar: `[⇪⇧⌃⌥⌘][(optional ⇧⌃⌥⌘)]key_code` — left modifiers, `⇪` the four
  right ones, bracketed ones optional (`"⌥(⇧)a"`), no prefix = pressed bare. Today `grave`, `misc`,
  `f_row` (`unless = "keyboard_disabled"`, same rule as `misc`) and `tab` (`when = "tab_modifier"`;
  the Tab key itself is `hand/raw/01-tab-modifier.json`).
- **`hand/raw/<rule>.json`** — escape hatch: a JSON list of manipulators appended verbatim to the
  generated rule of that name. Today `01` (the Tab key: `to_if_alone` + a variable) and `14` (the
  two `nowplayingseek` chords: `shell_command` + `to_after_key_up`). Lint `B4` warns when a raw one
  would fit the table.
- **Order is behaviour.** Karabiner runs the first manipulator that matches, across all rules in
  rule-name order (`00-…` first, generated and hand-written together), so moving a row to another
  table can change which one wins. A second mapping of the same chord in one rule is refused;
  across rules `shadow.py` simulates every key × modifiers × conditions and the build (and lint
  `G2`) fails on a manipulator that can never fire. It caught the old keyboard lock (left `⌃` +
  right `⌥` + `⌫` with `optional: any`) eating `⇪⌃⌫`, because Hyper holds the right `⌥`.

## Rules
`hand/` marks the five written by hand; the rest come from `layers.toml`.
```
00-keyboard-lock              hand/  the four corners → `hs -c 'toggleKeyboardLock()'` (hammerspoon/keyboard_lock.lua), see *Keyboard Lock*
01-tab-modifier                      Tab as modifier layer (hold Tab + key)
04-caps-lock-hyper            hand/  Caps Lock → all 4 right modifiers (Hyper)
05-grave-to-escape                   Grave/Tilde → Escape
07-hyper-only                        Hyper + key (no additional modifiers)
08-hyper-shift                       Hyper + Shift + key
09-hyper-command                     Hyper + Command + key
10-hyper-option                      Hyper + Option + key
11-hyper-control                     Hyper + Control + key
12-hyper-shift-command               Hyper + Shift + Command + key
13-hyper-shift-option                Hyper + Shift + Option + key
14-hyper-shift-control               Hyper + Shift + Control + key
15-hyper-command-option              Hyper + Command + Option + key
16-hyper-command-control             Hyper + Command + Control + key
17-hyper-option-control              Hyper + Option + Control + key
18-hyper-misc                        Left-modifier chords (delete, arrows, brightness, ⌥2 ⌥3 ⌥4) and the F-row; nothing Hyper despite the name
22-custom-right-cmd                  Right Command remappings
26-right-option-space-punto   hand/  Right Option + Space → Keypad 9 (Punto reconversion)
27-left-all-hide                     All left modifiers + W A S D → the same modifiers + arrows (focus sets)
29-mouse-ugreen-hold-to-browser hand/ UGREEN mouse forward button held → browser
30-fn-layer-mirror                   fn + left half of a row → right half of that row
32-swap-sides                 hand/  Ctrl+Alt + both arrows, or A and D, at once → Keypad 8 (swap two top windows)
```

## Keyboard Lock (the Four Corners)
Hold the bottom-left corner (`⌃` on the 60% board, `fn` on the built-in one), then press the other
three corners together: top-left (`` ` `` / `§` / `Esc`, whichever the keyboard has there), `⌫`
and `→`. Same chord unlocks. It is a `simultaneous` manipulator with a 200 ms window, six variants
(2 corner modifiers × 3 top-left key codes).

- The modifier is mandatory with nothing optional, so no Hyper chord can match it.
- Cost: with `⌃` or `fn` held alone, `⌫`, `→` and the top-left key wait up to 200 ms (or until
  key-up) for the rest of the chord.
- Karabiner sits below Hammerspoon's event tap, so the chord still arrives while the lock swallows
  everything else. If it ever does not: sleep and wake unlocks, and so does reloading Hammerspoon
  from its menu-bar icon.

## Core Remappings (Don't Break These)
- **Caps Lock → Hyper**: Maps to all 4 right modifiers (right_command, right_control, right_option, right_shift)
- **Tab as modifier layer**: Hold Tab + key for shortcuts, tap alone sends Tab
- **`fn` is left alone**: it used to be remapped to Left Control so the bottom-left key matched
  the 60% keyboard, and briefly it was swapped with Control. Both are gone — `fn` is the layer
  key now (see below) and has to stay a real `fn` on its own key. Cost of that: on the built-in
  keyboard `⌃` sits one key further right than on the 60% board.
- **Grave/Tilde → Escape**: Except when Hyper is held
- **Hyper layers are generated**: edit `layers.toml`, run `./build.sh`. A second mapping of the
  same key in one rule is refused, because Karabiner only ever runs the first

## fn Layer (Mirror the Left Half onto the Right)
Rule `30-fn-layer-mirror`, from `[layer.fn]` in `layers.toml`: holding `fn`, the i-th key of a row's left half sends the i-th key
of that row's right half, so the right hand's territory is typeable from the home position.

```json
"from": {"key_code": "1", "modifiers": {"mandatory": ["fn"], "optional": ["any"]}},
"to":   [{"key_code": "7"}]
```

`mandatory` consumes the `fn` so it never reaches the app; `optional: ["any"]` is what keeps
`fn`+`⌘`+`1` working as `⌘7`.

Not a uniform shift — the rows are different lengths, and they do not balance row by row:
number row 12 keys (6→6), bottom row 10 (5→5), but the top row has 13 (`qwerty` → `uiop[]\`,
seven targets for six sources) and the home row 11 (`asdfgh` → `jkl;'`, six sources for five
targets). The home row's spare `h` covers the top row's orphan, so `fn`+`h` sends `backslash`.
That is what makes the layer complete: every letter and symbol of the right-hand block is
reachable from the left hand.

All four rows are live. This deliberately eats the macOS 🌐-combos that land on mapped letters
(🌐+E emoji, 🌐+F fullscreen, 🌐+C Control Center, 🌐+Q Quick Note, 🌐+A, 🌐+D) — the owner
tried them and uses none. Do not "restore" them without asking. Arrows, delete and
the F-row stay untouched, as do 🌐+N and 🌐+M (right half, never mapped).

## Tab Modifier Pattern (Variable-Based Layer)
```json
"from": {"key_code": "tab"},
"to": [{"set_variable": {"name": "tab_modifier", "value": 1}}],
"to_after_key_up": [{"set_variable": {"name": "tab_modifier", "value": 0}}],
"to_if_alone": [{"key_code": "tab"}]
```
Then use conditions: `{"name": "tab_modifier", "type": "variable_if", "value": 1}`

## Bridge Slots (Hyper letters → F13–F20)
`hs.hotkey` cannot tell `⇪v` from `⇪⌘v` (both carry ⌘), so a Hyper letter that Hammerspoon
launches from and that has left-modifier variants is renamed to an F-key. Slots follow the
left-hand keyboard columns, left to right, top to bottom, skipping letters that need none:

| column | slot |
|---|---|
| q a z | `z = F13` |
| r f v | `r = F14`, `f = F15`, `v = F16` |
| t g b | `t = F17`, `g = F18`, `b = F19` |
| y h n | `h = F20` |

`⇪ [+left modifiers] X → [same modifiers] slot(X)` in every Hyper layer: `⇪v` → `F16`,
`⇪⌘v` → `⌘F16`, `⇪⇧⌥z` → `⇧⌥F13`. A table row or a `hand/raw/` manipulator for the letter in
that layer wins (`⇪⌘f` → `⌘o`, `⇪⌘z` → `/`, `⇪⌥z` → `⇧/`, `⇪⇧⌃z` → seek). So a new variant such
as `⇪⌥v` needs no Karabiner edit, only the Lua binding on `⌥F16`.

Presses no `hs.hotkey` chord can express keep a code on the top keypad row: `⌃⌥a+d` / `⌃⌥←+→`
(swap windows, rule `32`) → `keypad_8`, right `⌥␣` (Punto, rule `26`) → `keypad_9`, and the Tab
layer (rule `01`, a held Tab sets a variable, so it is a condition rather than a modifier): `⇥v` →
`keypad_1`, `⇥f` → `keypad_2`, `⇥t` → `keypad_3`; left `⌥4` (rule `18`) → `keypad_4`. `keypad_0` and
`5`–`7` stay free for more such chords or the next slot letters (next columns: `e d c`, `w s x`, `q a`, `y n`). Every such code is
a row of `EXCEPTIONS` in `docs/keyboard/bridges.py`.

- `python3 docs/keyboard/tools/bridge.py` prints the table with the chord and binding on every code.
- Lint `B2` fails on a layout binding of an F13–F20/keypad code that is neither a slot variant nor
  one of the `EXCEPTIONS` (`num1`–`num4`, `num8`, `num9`).
- `build.sh` runs the generator, which needs `python3` ≥ 3.11 (`tomllib`); the Apple `/usr/bin/python3` 3.9 is not enough — Homebrew's is on PATH first.

## References
- Full keyboard system: @../docs/keyboard-setup.md
