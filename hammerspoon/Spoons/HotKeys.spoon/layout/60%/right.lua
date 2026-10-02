return {
--    ╭—————╮
--    │  →  │    right
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           →   │              │              │   │          IINA — seek forward 5sec
--               │              │              │   │       YouTube — seek forward 5sec
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪→   │              │              │   │
--          ⇧→   │              │              │ ✓ │              — select one letter right
--          ⌃→   │              │              │ ✓ │              — jump to workspace to the right
--          ⌥→   │              │              │ ✓ │              — jump to next word
--          ⌘→   │              │              │   │
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧→   │              │              │   │
--         ⇪⌃→   │              │              │   │
--         ⇪⌥→   │              │              │   │
--         ⇪⌘→   │              │              │   │
--         ⇧⌃→   │              │              │   │
--         ⇧⌥→   │              │              │   │        VSCode — move line right
--         ⇧⌘→   │              │              │ ✓ │              — select line till the end
--         ⌃⌥→   │              │              │   │ Window →, 2nd press ½ →
{ chord = "⌃⌥→",                            fn = "window.right" },
--        ⌃⌥←→   │     num8     │              │   │
--         ⌃⌘→   │              │              │   │        VSCode — move editor to next group
--         ⌥⌘→   │              │              │   │        VSCode — navigate next tab
--               │              │              │   │         Music — seek forward
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃→   │              │              │   │
--        ⇪⇧⌥→   │              │              │   │
--        ⇪⇧⌘→   │              │              │   │
--        ⇪⌃⌥→   │              │              │   │
--        ⇪⌃⌘→   │              │              │   │
--        ⇪⌥⌘→   │              │              │   │
--        ⇧⌃⌥→   │              │              │   │ ½ Right
{ chord= "⇧⌃⌥→",                            fn = "window.half_right" },
--        ⇧⌃⌘→   │              │              │   │
--        ⇧⌥⌘→   │              │              │   │
--        ⌃⌥⌘→   │              │              │   │ Window to next screen
{ chord= "⌃⌥⌘→",                            fn = "window.screen_next" },
--       ⇧⌃⌥⌘→   │              │              │ ✓ │              — focus comms apps (hide non-comms)
{ chord= "⇧⌃⌥⌘→",                           fn = "window.focus_comms" },
--               ┴              ┴              ┴   ┴
}
