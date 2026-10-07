**English** · [Русский](migrating.ru.md)

# Moving from Birman's layout

Five minutes, and you can go back at any time.

1. **Add Apple's layouts.** System Settings → Keyboard → Input Sources: add *ABC* and, for Russian,
   *Russian – PC* (not plain *Russian*: Birman's Russian is the PC one). Add *Greek* if you need it.
2. **Install the Spoon** ([README](../README.md#install)) and give Hammerspoon the Accessibility permission.
3. **Try it**: right ⌥ + `c` types `©`, right ⌥ + `-` types `—`.
4. **Remove Birman's layout.** Delete his layouts from Input Sources, then delete
   `Ilya Birman Typography Layout.bundle` from `~/Library/Keyboard Layouts` (or `/Library/Keyboard Layouts`),
   as his own FAQ says. A restart may be needed.
5. **Adjust the two things that differ.**
   - His layout puts the characters on **both** ⌥ keys; the Spoon uses the right one only and leaves the
     left ⌥ to Apple, as on Windows. To get his behavior back: `layer.rightOptionOnly = false`.
   - He also moves a few plain keys (`` ` `` and `~` on the ISO `§` key, `\` beside left ⇧, `Ё` on ⇧`` ` ``).
     On an ISO keyboard, `layer.baseFixups = true` types those too; leave it off on ANSI.

Everything you type with ⌥ or ⇧⌥ stays the same: same characters, same dead keys, same stress mark. If
something differs, it is a bug: [docs/how-it-works.md](how-it-works.md) explains how that is checked.
