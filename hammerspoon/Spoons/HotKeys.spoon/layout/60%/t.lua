return {
--    ╭—————╮
--    │  T  │    new tab / Telegram
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           t   │              │ t    е    τ  │   │       YouTube — Theatre mode
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪t   │     F17      │              │   │               ↓
{ chord = "F17",                           app = "@APP_TELEGRAM", window_default_position = "right" },
--          ⇧t   │              │ T    Е    Τ  │   │
--          ⌃t   │              │              │   │         Rider — refactor this
--               │              │              │   │   Claude Code — show todos
--          ⌥t   │              │      ™       │   │
--          ⌘t   │              │              │ ✓ │              — new tab
--               │              │              │   │         Music — turn visualizer on or off
--               │              │              │ ℝ │ Rider — Go to Test
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧t   │     ⇧F17     │              │   │               ↓
{ chord= "⇧F17",                           app = "zoom.us" },
--         ⇪⌃t   │     ⌃F17     │              │   │
--         ⇪⌥t   │     ⌥F17     │              │   │
--         ⇪⌘t   │     ⌘F17     │              │   │
--         ⇧⌃t   │              │              │   │
--         ⇧⌥t   │              │    #    #    │   │
--         ⇧⌘t   │              │              │ ✓ │              — reopen closed tab
--               │              │              │   │          Mail — format as Plain Text or Rich Format
--               │              │              │ ℝ │ Rider — Reopen Closed Tab
--         ⌃⌥t   │              │              │ ✓ │              — this window to TV / back
{ chord = "⌃⌥t",                            fn = "display.toggle_window_to_tv" },
--         ⌃⌘t   │              │              │   │
--         ⌥⌘t   │              │              │   │          Fork — hide/search toolbar
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃t   │    ⇧⌃F17     │              │   │
--        ⇪⇧⌥t   │    ⇧⌥F17     │              │   │
--        ⇪⇧⌘t   │    ⇧⌘F17     │              │   │
--        ⇪⌃⌥t   │    ⌃⌥F17     │              │   │
--        ⇪⌃⌘t   │    ⌃⌘F17     │              │   │
--        ⇪⌥⌘t   │    ⌥⌘F17     │              │   │
--        ⇧⌃⌥t   │              │              │ ✓ │              — display mode: mirror / extend
{ chord= "⇧⌃⌥t",                            fn = "display.toggle_mirror" },
--        ⇧⌃⌘t   │              │              │   │
--        ⇧⌥⌘t   │              │              │   │
--        ⌃⌥⌘t   │              │              │   │
--               ┴              ┴              ┴   ┴
}
