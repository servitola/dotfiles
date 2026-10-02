return {
--    ╭—————╮
--    │  ↑  │    arrow up
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           ↑   │              │              │   │      Telegram — edit last message
--               │              │              │   │          IINA — sound up 5%
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪↑   │              │              │   │          IINA — sound up 5%
--          ⇧↑   │              │              │ ✓ │              — select text up one line
--          ⌃↑   │              │              │ ✓ │              — show windows of current app
--          ⌥↑   │              │              │ ✓ │              — move line up
--               │              │              │   │         Rider — extend selection
--          ⌘↑   │              │              │   │        VSCode — jump to breadcrumbs
--               │              │              │   │         Music — increase volume
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧↑   │              │              │   │
--         ⇪⌃↑   │              │              │   │
--         ⇪⌥↑   │              │              │   │
--         ⇪⌘↑   │              │              │   │
--         ⇧⌃↑   │              │              │   │
--         ⇧⌥↑   │              │              │   │        VSCode — move line up
--         ⇧⌘↑   │      🔆       │              │ ✓ │              — increase keyboard light (illumination_increment)
--         ⌃⌥↑   │              │              │   │ Fullscr, 2nd press native fullscreen
{ chord = "⌃⌥↑",                            fn = "window.fullscreen" },
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
--        ⌃⌥⌘↑   │              │              │   │
--       ⇧⌃⌥⌘↑   │              │              │ ✓ │              — focus work apps (hide non-work)
{ chord= "⇧⌃⌥⌘↑",                           fn = "window.focus_work" },
--               ┴              ┴              ┴   ┴
}
