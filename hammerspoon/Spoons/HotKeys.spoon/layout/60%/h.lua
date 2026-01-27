return {
--    ╭—————╮
--    │  H  │    hide / work browser (safari / firefox)
--    ╰—————╯
--
--
--———————— chord ┬ en | ru | el ┬————————— app — function ————————————————————
--           h   │ h    р    η  │
--———————————————┼——————————————┼————————————————————————————————————
{ chord =  "⇪h",                           app = "Safari" },
--          ⇧h   │ H    Р    Η  │
--          ⌃h   │              │             — cut letter to the left
--          ⌥h   │ ₽    ₽    ₽  │
--          ⌘h   │              │             — hide current app
--———————————————┼——————————————┼————————————————————————————————————
--    ⇪⇧h → F16  │              │  ↓
{ chord = "F16",                           app = "Firefox" },
--         ⇪⌃h   │              │
--         ⇪⌥h   │              │
--         ⇪⌘h   │              │
--         ⇧⌃h   │              │           Rider — hierarchy
--         ⇧⌥h   │     BIT      │  press double to adjust previous symbol
--         ⇧⌘h   │              │           Finder — go to $HOME
{ chord = "⌃⌥h",                               app = "Hammerspoon", window_default_position = "right" },
{ chord = "⌃⌘h",                               app = "Heroes of the Storm" },
--         ⌥⌘h   │              │                 — hide all other windows
--———————————————┼——————————————┼————————————————————————————————————
--        ⇪⇧⌃h   │              │
--        ⇪⇧⌥h   │              │
--        ⇪⇧⌘h   │              │
--        ⇪⌃⌥h   │              │
--        ⇪⌃⌘h   │              │
--        ⇪⌥⌘h   │              │
--        ⇧⌃⌥h   │              │
--        ⇧⌃⌘h   │              │
--        ⇧⌥⌘h   │              │        Fork — quick Stash
--        ⌃⌥⌘h   │              │
--               ┴              ┴
}
