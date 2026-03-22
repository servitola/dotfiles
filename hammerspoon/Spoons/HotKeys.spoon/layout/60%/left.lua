return {
--    ╭—————╮
--    │  ←  │    left
--    ╰—————╯
--
--
--———————— chord ┬ en | ru | el ┬——————— app — function ————————————————————
--           ←   │      ←       │    YouTube — seek backward 5sec
--               │              │       IINA — seek backward 5sec
--———————————————┼——————————————┼——————————————————————————————————
--          ⇪←   │              │
--          ⇧←   │              │           — select one letter left
--          ⌃←   │              │           — jump to workspace to the left
--          ⌥←   │              │           — jump to previous word
--          ⌘←   │              │           — home
--———————————————┼——————————————┼——————————————————————————————————
--         ⇪⇧←   │              │
--         ⇪⌃←   │              │
--         ⇪⌥←   │              │
--         ⇪⌘←   │              │
--         ⇧⌃←   │              │
--         ⇧⌥←   │              │         📝 — move line left
--         ⇧⌘←   │              │           — select text to start of line
{ chord = "⌃⌥←",                          fn = "window.left" },
--         ⌃⌘←   │              │          📝 — move editor to previous group
--         ⌥⌘←   │              │          📝 — navigate to tab to the left
--               │              │       Music — seek backward
--———————————————┼——————————————┼——————————————————————————————————
--        ⇪⇧⌃←   │              │
--        ⇪⇧⌥←   │              │
--        ⇪⇧⌘←   │              │
--        ⇪⌃⌥←   │              │
--        ⇪⌃⌘←   │              │
--        ⇪⌥⌘←   │              │
{ chord= "⇧⌃⌥←",                           fn = "window.half_left" },
--        ⇧⌃⌘←   │              │
--        ⇧⌥⌘←   │              │
--        ⌃⌥⌘←   │              │
--               ┴              ┴
}
