return {
--    ╭—————╮
--    │  ←  │    left
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           ←   │              │              │   │          IINA — seek backward 5sec
--               │              │              │   │       YouTube — seek backward 5sec
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪←   │              │              │   │
--          ⇧←   │              │              │ ✓ │              — select one letter left
--          ⌃←   │              │              │ ✓ │              — jump to workspace to the left
--          ⌥←   │              │              │ ✓ │              — jump to previous word
--          ⌘←   │              │              │ ✓ │              — home
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧←   │              │              │   │
--         ⇪⌃←   │              │              │   │
--         ⇪⌥←   │              │              │   │
--         ⇪⌘←   │              │              │   │
--         ⇧⌃←   │              │              │   │
--         ⇧⌥←   │              │              │   │             📝 — move line left
--         ⇧⌘←   │              │              │ ✓ │              — select text to start of line
--         ⌃⌥←   │              │              │   │ Window ←, 2nd press ½ ←
{ chord = "⌃⌥←",                            fn = "window.left" },
--        ⌃⌥←→   │     num8     │              │   │ Swap two top windows (both arrows at once, or ⌃⌥ + A and D)
{ chord= "num8",                            fn = "window.swap_sides" },
--         ⌃⌘←   │              │              │   │             📝 — move editor to previous group
--         ⌥⌘←   │              │              │   │             📝 — navigate to tab to the left
--               │              │              │   │         Music — seek backward
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃←   │              │              │   │
--        ⇪⇧⌥←   │              │              │   │
--        ⇪⇧⌘←   │              │              │   │
--        ⇪⌃⌥←   │              │              │   │
--        ⇪⌃⌘←   │              │              │   │
--        ⇪⌥⌘←   │              │              │   │
--        ⇧⌃⌥←   │              │              │   │ ½ Left
{ chord= "⇧⌃⌥←",                            fn = "window.half_left" },
--        ⇧⌃⌘←   │              │              │   │
--        ⇧⌥⌘←   │              │              │   │
--        ⌃⌥⌘←   │              │              │   │ Window to previous screen
{ chord= "⌃⌥⌘←",                            fn = "window.screen_prev" },
--       ⇧⌃⌥⌘←   │              │              │ ✓ │              — focus personal apps (hide non-personal)
{ chord= "⇧⌃⌥⌘←",                           fn = "window.focus_personal" },
--               ┴              ┴              ┴   ┴
}
