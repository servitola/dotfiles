return {
--    ╭—————╮
--    │  ↓  │    down
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           ↓   │              │              │   │          IINA — sound down 5%
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪↓   │              │              │   │          IINA — sound down 5%
--          ⇧↓   │              │              │ ✓ │              — select text down one page
--          ⌃↓   │              │              │ ✓ │              — show windows of current app
--          ⌥↓   │              │              │ ✓ │              — move line down
--               │              │              │   │         Rider — shrink selection
--               │              │              │   │       YouTube — previous chapter in current video
--          ⌘↓   │              │              │   │         Rider — edit source
--               │              │              │   │         Music — decrease volume
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧↓   │              │              │   │
--         ⇪⌃↓   │              │              │   │
--         ⇪⌥↓   │              │              │   │
--         ⇪⌘↓   │              │              │   │
--         ⇧⌃↓   │              │              │   │
--         ⇧⌥↓   │              │              │   │        VSCode — move line down
--         ⇧⌘↓   │      🔅       │              │   │
--         ⌃⌥↓   │              │              │   │ Win Reset, or exit native fullscreen
--               │              │              │ℝ! │ Rider — Next Highlighted Usage
{ chord = "⌃⌥↓",                            fn = "window.set_all_to_default", over = "Rider" },
--         ⌃⌘↓   │              │              │   │
--               │              │              │ ℝ │ Rider — Next Method
--         ⌥⌘↓   │              │              │   │        VSCode — create cursor down
--               │              │              │ ℝ │ Rider — Next Occurrence
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃↓   │              │              │   │
--        ⇪⇧⌥↓   │              │              │   │
--        ⇪⇧⌘↓   │              │              │   │
--        ⇪⌃⌥↓   │              │              │   │
--        ⇪⌃⌘↓   │              │              │   │
--        ⇪⌥⌘↓   │              │              │   │
--        ⇧⌃⌥↓   │              │              │   │ Bot 40%
{ chord= "⇧⌃⌥↓",                            fn = "window.bottom_40" },
--        ⇧⌃⌘↓   │              │              │   │
--               │              │              │ ℝ │ Rider — Stretch to Bottom
--        ⇧⌥⌘↓   │              │              │   │
--        ⌃⌥⌘↓   │              │              │   │
--               │              │              │ ℝ │ Rider — Next Change
--       ⇧⌃⌥⌘↓   │              │              │ ✓ │              — hide all except Zap & Telegram
{ chord= "⇧⌃⌥⌘↓",                           fn = "window.hide_all_except_work" },
--               ┴              ┴              ┴   ┴
}
