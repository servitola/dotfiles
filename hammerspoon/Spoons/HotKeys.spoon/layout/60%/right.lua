return {
--    ╭—————╮
--    │  →  │    right
--    ╰—————╯
--
--
--———————— chord ┬ en | ru | el ┬————————— app — function ————————————————————
--           →   │      →       │      YouTube — seek forward 5sec
--               │              │         IINA — seek forward 5sec
--———————————————┼——————————————┼——————————————————————————————————
--          ⇪→   │              │
--          ⇧→   │              │             — select one letter right
--          ⌃→   │              │             — jump to workspace to the right
--          ⌥→   │              │             — jump to next word
--          ⌘→   │              │
--———————————————┼——————————————┼——————————————————————————————————
--         ⇪⇧→   │              │
--         ⇪⌃→   │              │
--         ⇪⌥→   │              │
--         ⇪⌘→   │              │
--         ⇧⌃→   │              │
--         ⇧⌥→   │              │       VSCode — move line right
--         ⇧⌘→   │              │             — select line till the end
{ chord = "⌃⌥→",                            fn = "window.right" },
--         ⌃⌘→   │              │       VSCode — move editor to next group
--         ⌥⌘→   │              │       VSCode — navigate next tab
--               │              │        Music — seek forward
--———————————————┼——————————————┼——————————————————————————————————
--        ⇪⇧⌃→   │              │
--        ⇪⇧⌥→   │              │
--        ⇪⇧⌘→   │              │
--        ⇪⌃⌥→   │              │
--        ⇪⌃⌘→   │              │
--        ⇪⌥⌘→   │              │
{ chord= "⇧⌃⌥→",                            fn = "window.half_right" },
--        ⇧⌃⌘→   │              │
--        ⇧⌥⌘→   │              │
--  ⌃⌥⌘⇧→ → ⌃⌥F13 │              │              — focus comms apps (hide non-comms)
{ chord = "⌃⌥F13",                               fn = "window.focus_comms" },
--               ┴              ┴
}
