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
{ chord = "⌃⌥↓",                            fn = "window.set_all_to_default" },
--         ⌃⌘↓   │              │              │   │
--         ⌥⌘↓   │              │              │   │        VSCode — create cursor down
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
--        ⇧⌥⌘↓   │              │              │   │
--        ⌃⌥⌘↓   │              │              │   │
--       ⇧⌃⌥⌘↓   │              │              │ ✓ │              — hide all except Zap & Telegram
{ chord= "⇧⌃⌥⌘↓",                           fn = "window.hide_all_except_work" },
--               ┴              ┴              ┴   ┴
}
