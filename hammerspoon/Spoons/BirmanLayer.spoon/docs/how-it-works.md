**English** · [Русский](how-it-works.ru.md)

# How it works

This is Ilya Birman's layout on the right ⌥, put there by an unofficial Spoon. The original is at
<https://ilyabirman.ru/typography-layout/>.

## The one difference from Birman's Mac layout

His layout replaces the ⌥ layer on **both** Option keys, because a Mac keyboard layout cannot tell them apart in practice (its format names a right Option, but Ukelele users [report](https://groups.google.com/g/ukelele-users/c/6jviMBPlqCY) that it does not work as a separate key). By default the Spoon puts it on the **right** one
only, the way Windows does with AltGr, and leaves the left ⌥ as Apple's own, so ⌥ shortcuts and Apple's ⌥
characters stay. Every character and dead key is Birman's; only the key that reaches them differs.

Switch it with `layer.rightOptionOnly`: `true` (default) is the Windows way, `false` is Birman's Mac way,
with the layer on both Option keys (then a bare ⌥ shortcut types Birman's character; ⌥ with ⌘ or ⌃ still
works as a shortcut).

## It does not care which layout is active

The layer itself is not keyed to an input source name; only the opt-in `baseFixups` names layouts (ABC, Russian – PC).

- The ⌥ layers are **positional**: the same physical key gives the same character whether ABC,
  Russian, Greek, German or Dvorak is active, exactly as on Windows.
- A dead key composes by **the character the next key types** in the active layout. After
  ⇧⌥`/` the `a` key of ABC gives `á`, the `к` key of any Russian layout gives `ќ`, and a layout the
  table has never heard of falls back to "accent, then the key". Add your own letters with
  [`overrides`](configuration.md#overrides).

Birman's own build has an English and a Russian layout. The Spoon reproduces both exactly, quirks
included, and uses the Russian differences whenever the active layout types Cyrillic (it asks the layout,
not its name). It adds nothing and corrects nothing: what you want different is an
[`overrides`](configuration.md#change-what-birman-did) entry.

## Data

`typography_table.lua` is Birman's layout, read from the two `.keylayout` files of his official
build — version 3.9 for Mac, `ilya-birman-typolayout-3.9-mac.zip` from
<https://ilyabirman.ru/typography-layout/>, SHA-256
`64b4f7b1421cc4275864c25941646ddf2d3075212a77e9ba1c2d27b726afe123` — and nothing else.
The previous build, 3.8, differs from 3.9 in one ⇧⌥ cell (`t`) and in the Russian cedilla compositions of `с` and `з`. Birman
publishes no Greek or other layout, and the Spoon invents none; add them with `overrides`.

`tests/official_cases.json` lists every press Birman's layouts define (about 3 700): each ⌥ and ⇧⌥ key
in both scripts, and every key pressed inside every dead state. `tests/test_birman_layer.lua` replays all
of them through the Spoon (`hs -c 'return dofile("<path>/tests/test_birman_layer.lua")' </dev/null`)
and expects the layout's own output.

Nothing is added, changed or fixed on top of that; the Spoon types what his layouts type.

## Versions

The version is Birman's Mac layout version the data was read from, plus a patch number of ours: `3.9.0`,
`3.9.1`, … Birman's next release is `4.0.0` here after the data is regenerated from it.

## Speed, and why not Karabiner

Measured end to end with `tests/bench_endtoend.lua` (Apple M3 Pro, macOS 26.6, Hammerspoon 1.1.1): 100 presses per line,
from the trigger to the character arriving in a text field. First number idle, second with 10 busy processes.

| Route | Median | 95th percentile | Bad results (of 100) |
| --- | --- | --- | --- |
| a Unicode key event posted directly, no Spoon (the floor: the OS and the app) | 10 / 6 ms | 19 / 15 ms | 3 / 1 |
| **BirmanLayer**, right ⌥ + `c` | **16 / 12 ms** | 25 / 21 ms | 0 / 0 |
| Karabiner-style: shell `pbcopy`, 30 ms hold, ⌘V | 44 / 40 ms | 56 / 50 ms | 5 / 8 |

Karabiner-Elements has no Unicode output (its documented outputs are `key_code`, `consumer_key_code`,
`pointing_button`, `shell_command`, `select_input_source`, `set_variable`, `mouse_key`, `sticky_modifier`,
`software_function`, `send_user_command`), so text has to go through `shell_command`. The last line replays that route:
the same kind of shell command, then a 30 ms wait for the clipboard to fill, then ⌘V. It is not Karabiner itself,
which reacts only to a physical keyboard and cannot be driven from software, so Karabiner's own dispatch time is not in the
number.

What the table says:

- The Spoon's 16 ms is mostly the OS: a directly posted event already takes 10 ms in this setup. About 6 ms is the Spoon
  (catching the key through the event tap and posting the Unicode event); its own decision takes about 1 µs.
- The shell route is about 28 ms slower at the median (44 ms), because it must wait: the shell runs asynchronously, so a fixed
  pause stands in for "the clipboard is ready". About two screen frames; you can notice it when typing fast.
- The pause is a guess, and under load it is sometimes too short: in 8 of 100 runs the ⌘V pasted the previous clipboard
  contents or nothing. That is a wrong or missing character, which you will notice more than the delay.
- The clipboard is overwritten on every press.
- "Bad results" also contain harness noise: the floor line, which cannot really fail, shows 3 and 1.

Inside the Spoon, `tests/bench.lua` gives about 1 µs to decide what to do with right ⌥ + `c`, 0.6 µs to pass an ordinary key
through, and 3 µs to build the two Unicode key events.

Karabiner and this Spoon coexist well: Karabiner is the right tool for turning one key into another, and Hammerspoon for typing text.

## Limitations

- Hammerspoon needs the **Accessibility** permission.
- Nothing is typed while macOS **secure input** is on (password fields, some terminals
  with "Secure Keyboard Entry").
- Apps that read **key codes** instead of text (games, VMs, remote desktops) see the typed
  character as an unknown key; list them in `excludedBundles`.
- Positions are Birman's: he drew the ⌥ layer for a QWERTY keyboard. On Dvorak or Colemak the
  characters sit on the keys' QWERTY positions, and override key names are QWERTY positions too.
- The layer key is taken over completely (the right ⌥, or both with `rightOptionOnly = false`); apps that use
  it for something else (Emacs Meta) get nothing.
