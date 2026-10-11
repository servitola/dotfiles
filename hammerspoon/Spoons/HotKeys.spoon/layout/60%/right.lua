return {
--    ╭—————╮
--    │  →  │    right
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           →   │              │              │   │          IINA — seek forward 5sec
--               │              │              │   │       YouTube — seek forward 5sec
--           →   │              │              │ ℝ │ Rider — Right
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪→   │              │              │   │
--          ⇧→   │              │              │ ✓ │              — select one letter right
--          ⌃→   │              │              │ ✓ │              — jump to workspace to the right
--          ⌥→   │              │              │ ✓ │              — jump to next word
--          ⌘→   │              │              │   │
--          ⌘→   │              │              │ ℝ │ Rider — Move Caret to Line End
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧→   │              │              │   │
--         ⇪⌃→   │              │              │   │
--         ⇪⌥→   │              │              │   │
--         ⇪⌘→   │              │              │   │
--         ⇧⌃→   │              │              │   │
--         ⇧⌥→   │              │              │   │        VSCode — move line right
--         ⇧⌘→   │              │              │ ✓ │              — select line till the end
--         ⌃⌥→   │              │              │   │ Window →, 2nd press ½ →
{ chord = "⌃⌥→",                            fn = "window.right", over = "Rider" },
--        ⌃⌥←→   │     num8     │              │   │
--         ⌃⌥→   │              │              │ℝ! │ Rider — Stretch to Right
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
{ chord= "⇧⌃⌥→",                            fn = "window.half_right", over = "Rider" },
--        ⇧⌃⌥→   │              │              │ℝ! │ Rider — Move Caret to Next Word with Selection in Different "CamelHumps" Mode
--               │              │              │ℝ! │ Rider — Move Element Right
--        ⇧⌃⌘→   │              │              │   │
--        ⇧⌥⌘→   │              │              │   │
--        ⌃⌥⌘→   │              │              │   │ Window to next screen
{ chord= "⌃⌥⌘→",                            fn = "window.screen_next" },
--       ⇧⌃⌥⌘→   │              │              │ ✓ │              — focus comms apps (hide non-comms)
{ chord= "⇧⌃⌥⌘→",                           fn = "window.focus_comms" },
--               ┴              ┴              ┴   ┴
}
