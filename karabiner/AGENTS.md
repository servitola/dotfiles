# Karabiner Configuration Rules

## Build System
`karabiner.json` is **generated** — do NOT edit it directly!

- **Edit**: `layers.toml` for every rule that has a table there; `rules/*.json` by hand only for
  the five that have none — `00`, `04`, `26`, `29`, `32`
- **Build**: Run `./build.sh` to regenerate `karabiner.json`
- **Template**: `karabiner-template.json` has global settings, profiles, and empty rules array
- **Bridge slots**: `[slots]` in `layers.toml` gives eight Hyper letters an F-key each; the
  generator sends every modifier variant of the letter as the same variant of its F-key. The only
  other keys emitted for Hammerspoon are `keypad_8` (rule `32`) and `keypad_9` (rule `26`), plus
  the UGREEN mouse on `f16` (rule `29`). See *Bridge Slots* below

The build script first runs `docs/keyboard/tools/gen_layers.py`, then uses `jq` to merge the
template with all rule files in sorted order.

## Generated Rules
Every rule but `00`, `04`, `26`, `29`, `32` is written by `gen_layers.py` from two inputs; never
edit a generated file by hand (lint `G1` and the
`hyper-layers-generated` pre-commit hook fail on drift):

- `layers.toml` — one `[layer.<name>]` table per file, `key_code = "output"`. Output grammar:
  `⇪⇧⌃⌥⌘` prefix + a key glyph (`↑`, `⌦`, `PgUp`, `F1`, `a`, `/`, …), a media symbol
  (`⏮ ⏭ ▶/⏸ Vol↑ Vol↓ 🔆 🔅`), or `passthrough` (resend the pressed key, e.g. `⇧passthrough`).
  `⇪` in an output is the four right modifiers, every other glyph a left one. The grammar
  lives in `bridges.parse_to` / `output_entry`; a value it cannot parse stops the build and
  names the layer and key.
  `[slots]` (see below) adds a manipulator for every slot letter the table does not map in that
  layer, after the table rows.
- `layers.raw/<rule>.json` — escape hatch: a JSON list of manipulators appended verbatim, for
  what the table cannot express. Today `01` (the Tab key) and `14`: the two `nowplayingseek` chords
  (`shell_command` + `to_after_key_up`). Lint `B4` warns when a raw one would fit the table.

- **Layers not on Hyper** are written the same way, without `[slots]`: `[layer.tab]` → `01`
  (condition `tab_modifier`; the Tab key itself is `layers.raw/01-tab-modifier.json`),
  `[layer.right_cmd]` → `22` (right `⌘`), `[layer.left_all]` → `27` (left `⇧⌃⌥⌘`), `[layer.fn]` → `30`
  (`fn` mandatory, every other modifier optional).
- **Chord tables** hold rules whose rows do not share modifiers; the key carries them:
  `"⌥⇧q" = "⇧⌦"`. Key grammar: `[⇪⇧⌃⌥⌘][(optional ⇧⌃⌥⌘)]key_code` — left modifiers, `⇪` the four
  right ones, bracketed ones optional (`"⌥(⇧)a"`), no prefix = pressed bare. Tables: `grave` → `05`,
  `misc` then `f_row` → `18` (`f_row` carries the `keyboard_disabled` condition).
- Which rule file, description, modifiers and condition a table has is its row of `PLAIN` in
  `docs/keyboard/layers.py`. A new rule = a row there plus a table.
- Extra output forms: a value with spaces is several outputs sent in order
  (`s = "s e r v i t o l a"`); `sh: command` runs a shell command; `☀↑ ☀↓ ⏪ ⏩ Mute` are the
  F-row media keys; `non_us_backslash` names that key when it is not the pressed one.
- **Order is behaviour.** Karabiner runs the first manipulator that matches, across all rules in
  file-name order, so moving a row to another table can change which one wins. `gen_layers.py`
  (and lint `G2`) simulates every key × modifiers × conditions (`docs/keyboard/shadow.py`) and
  fails on a manipulator that can never fire. It caught the old keyboard lock (left `⌃` + right `⌥`
  + `⌫` with `optional: any`) eating `⇪⌃⌫`, because Hyper holds the right `⌥`.
- A rule file that is neither generated nor in `layers.HAND_WRITTEN` stops the build: Karabiner
  would keep loading it after its table is gone.

`gen_layers.py --check` exits 1 with a diff on drift. After writing, the generator runs
`karabiner_cli --lint-complex-modifications` on the generated files.

## Rule Files (rules/)
Hand-written: `00`, `04`, `26`, `29`, `32`. The rest are generated.
```
00-keyboard-lock.json        — the four corners → `hs -c 'toggleKeyboardLock()'` (hammerspoon/keyboard_lock.lua), see *Keyboard Lock*
01-tab-modifier.json         — Tab as modifier layer (hold Tab + key)
04-caps-lock-hyper.json      — Caps Lock → all 4 right modifiers (Hyper)
05-grave-to-escape.json      — Grave/Tilde → Escape (pass-through with Hyper)
07-hyper-only.json           — Hyper + key (no additional modifiers)
08-hyper-shift.json          — Hyper + Shift + key
09-hyper-command.json        — Hyper + Command + key
10-hyper-option.json         — Hyper + Option + key
11-hyper-control.json        — Hyper + Control + key
12-hyper-shift-command.json  — Hyper + Shift + Command + key
13-hyper-shift-option.json   — Hyper + Shift + Option + key
14-hyper-shift-control.json  — Hyper + Shift + Control + key
15-hyper-command-option.json — Hyper + Command + Option + key
16-hyper-command-control.json— Hyper + Command + Control + key
17-hyper-option-control.json — Hyper + Option + Control + key
18-hyper-misc.json           — Left-modifier chords (delete, arrows, brightness, ⌥2 ⌥3 ⌥4) and the F-row; nothing Hyper despite the name
22-custom-right-cmd.json     — Right Command remappings
26-right-option-space-punto.json — Right Option + Space → Keypad 9 (Punto reconversion)
27-left-all-hide.json        — All left modifiers + W A S D → the same modifiers + arrows (focus sets)
29-mouse-ugreen-hold-to-browser.json — UGREEN mouse forward button held → browser
30-fn-layer-mirror.json      — fn + left half of a row → right half of that row
32-swap-sides.json           — Ctrl+Alt + both arrows, or A and D, at once → Keypad 8 (swap two top windows)
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
  same key in one layer file is refused, because Karabiner only ever runs the first

## fn Layer (Mirror the Left Half onto the Right)
`30-fn-layer-mirror.json`, generated from `[layer.fn]` in `layers.toml`: holding `fn`, the i-th key of a row's left half sends the i-th key
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
`⇪⌘v` → `⌘F16`, `⇪⇧⌥z` → `⇧⌥F13`. A table row or a `layers.raw/` manipulator for the letter in
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
