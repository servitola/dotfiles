return {
--    ╭—————╮
--    │  ↑  │    arrow up
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           ↑   │      ↑       │              │   │      Telegram — edit last message
--               │              │              │   │          IINA — sound up 5%
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪↑   │      ↑       │              │   │          IINA — sound up 5%
--          ⇧↑   │              │              │ ✓ │              — select text up one line
--          ⌃↑   │              │              │ ✓ │              — show windows of current app
--          ⌥↑   │              │              │ ✓ │              — move line up
--               │              │              │   │         Rider — extend selection
--          ⌘↑   │              │              │   │         Music — increase volume
--                              │        VSCode — jump to breadcumbs
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧↑   │              │              │   │
--         ⇪⌃↑   │              │              │   │
--         ⇪⌥↑   │              │              │   │
--         ⇪⌘↑   │              │              │   │
--         ⇧⌃↑   │              │              │   │ FIX!!! should up volume up
--         ⇧⌥↑   │              │              │   │        VSCode — move line up
--         ⇧⌘↑   │ key_light_up │              │ ✓ │  — increase keyboard light (illumination_increment)
--         ⌃⌥↑   │              │              │   │ Fullscr, 2nd press native fullscreen
{ chord = "⌃⌥↑",                             fn = "window.fullscreen" },
--         ⌃⌘↑   │              │              │   │
--         ⌥⌘↑   │              │              │   │        VSCode — create cursor up
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃↑   │              │              │   │
--        ⇪⇧⌥↑   │              │              │   │
--        ⇪⇧⌘↑   │              │              │   │
--        ⇪⌃⌥↑   │              │              │   │
--        ⇪⌃⌘↑   │              │              │   │
--        ⇪⌥⌘↑   │              │              │   │
--        ⇧⌃⌥↑   │              │              │   │ Top 60%
{ chord= "⇧⌃⌥↑",                            fn = "window.top_60" },
--        ⇧⌃⌘↑   │              │              │   │
--        ⇧⌥⌘↑   │              │              │   │
--⇧⌃⌥⌘↑ → ⌃F13   │              │              │ ✓ │              — focus work apps (hide non-work)
{ chord = "⌃F13",                                fn = "window.focus_work" },
--               ┴              ┴              ┴   ┴
}
