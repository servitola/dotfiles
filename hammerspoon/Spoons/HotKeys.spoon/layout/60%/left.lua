return {
--    ╭—————╮
--    │  ←  │    left
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           ←   │      ←       │              │   │    YouTube — seek backward 5sec
--               │              │              │   │       IINA — seek backward 5sec
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪←   │              │              │   │
--          ⇧←   │              │              │ ✓ │           — select one letter left
--          ⌃←   │              │              │ ✓ │           — jump to workspace to the left
--          ⌥←   │              │              │ ✓ │           — jump to previous word
--          ⌘←   │              │              │ ✓ │           — home
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧←   │              │              │   │
--         ⇪⌃←   │              │              │   │
--         ⇪⌥←   │              │              │   │
--         ⇪⌘←   │              │              │   │
--         ⇧⌃←   │              │              │   │
--         ⇧⌥←   │              │              │   │         📝 — move line left
--         ⇧⌘←   │              │              │ ✓ │           — select text to start of line
--         ⌃⌥←   │              │              │   │ Window ←, 2nd press ½ ←
{ chord = "⌃⌥←",                          fn = "window.left" },
--        ⌃⌥←→   │    ⌃⌥F14     │              │   │ Swap two top windows (both arrows at once, or ⌃⌥ + A and D)
{ chord = "⌃⌥F14",                         fn = "window.swap_sides" },
--         ⌃⌘←   │              │              │   │          📝 — move editor to previous group
--         ⌥⌘←   │              │              │   │          📝 — navigate to tab to the left
--               │              │              │   │       Music — seek backward
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃←   │              │              │   │
--        ⇪⇧⌥←   │              │              │   │
--        ⇪⇧⌘←   │              │              │   │
--        ⇪⌃⌥←   │              │              │   │
--        ⇪⌃⌘←   │              │              │   │
--        ⇪⌥⌘←   │              │              │   │
--        ⇧⌃⌥←   │              │              │   │ ½ Left
{ chord= "⇧⌃⌥←",                           fn = "window.half_left" },
--        ⇧⌃⌘←   │              │              │   │
--        ⇧⌥⌘←   │              │              │   │
--⇧⌃⌥⌘← → ⇧⌃F13  │              │              │ ✓ │              — focus personal apps (hide non-personal)
{ chord = "⇧⌃F13",                               fn = "window.focus_personal" },
--               ┴              ┴              ┴   ┴
}
