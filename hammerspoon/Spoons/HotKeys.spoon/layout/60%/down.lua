return {
--    ╭—————╮
--    │  ↓  │    down
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           ↓   │      ↓       │              │   │          IINA — sound down 5%
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪↓   │      ↓       │              │   │          IINA — sound down 5%
--          ⇧↓   │              │              │ ✓ │              — select text down one page
--          ⌃↓   │              │              │ ✓ │              — show windows of current app
--          ⌥↓   │              │              │ ✓ │              — move line down
--               │              │              │   │       YouTube — previous chapter in current video
--               │              │              │   │         Rider — shrink selection
--          ⌘↓   │              │              │   │         Music — decrease volume
--               │              │              │   │         Rider — edit source
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧↓   │              │              │   │
--         ⇪⌃↓   │              │              │   │
--         ⇪⌥↓   │              │              │   │
--         ⇪⌘↓   │              │              │   │
--         ⇧⌃↓   │              │              │   │
--         ⇧⌥↓   │              │              │   │        VSCode — move line down
--         ⇧⌘↓   │              │ key_light_dn │   │ illumination_decrement
--         ⌃⌥↓   │              │              │   │ Win Reset, or exit native fullscreen
{ chord = "⌃⌥↓",                             fn = "window.set_all_to_default" },
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
{ chord= "⇧⌃⌥↓",                              fn = "window.bottom_40" },
--        ⇧⌃⌘↓   │              │              │   │
--        ⇧⌥⌘↓   │              │              │   │
--⇧⌃⌥⌘↓ → ⇧F13   │              │              │ ✓ │              — hide all except Zap & Telegram
{ chord = "⇧F13",                               fn = "window.hide_all_except_work" },
--               ┴              ┴              ┴   ┴
}
