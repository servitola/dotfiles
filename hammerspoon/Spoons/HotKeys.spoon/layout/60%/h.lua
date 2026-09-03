return {
--    ╭—————╮
--    │  H  │    hide / work browser (firefox / safari)
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           h   │              │ h    р    η  │   │
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪h   │              │              │   │ Firefox
{ chord =  "⇪h",                           app = "Firefox" },
--          ⇧h   │              │ H    Р    Η  │   │
--          ⌃h   │              │              │ ✓ │             — cut letter to the left
--          ⌥h   │              │ ₽    ₽    ₽  │   │
--          ⌘h   │              │              │ ✓ │ — minimize window, focus next (ours, replaces Hide)
{ chord = "⌘h",                                 fn = "window.minimize_and_focus_next" },
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--   ⇪⇧h → F16   │              │              │   │  ↓
{ chord = "F16",                           app = "Safari" },
--         ⇪⌃h   │              │              │   │
--         ⇪⌥h   │              │              │   │
--         ⇪⌘h   │              │              │   │
--         ⇧⌃h   │              │              │   │           Rider — hierarchy
--         ⇧⌥h   │              │     BIT      │   │  press double to adjust previous symbol
--         ⇧⌘h   │              │              │   │           Finder — go to $HOME
--         ⌃⌥h   │              │              │   │ Hammerspoon
{ chord = "⌃⌥h",                               app = "Hammerspoon", window_default_position = "right" },
--         ⌃⌘h   │              │              │   │ Heroes of the Storm
{ chord = "⌃⌘h",                               app = "Heroes of the Storm" },
--         ⌥⌘h   │              │              │ ✓ │                 — hide all other windows
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃h   │              │              │   │
--        ⇪⇧⌥h   │              │              │   │
--        ⇪⇧⌘h   │              │              │   │
--        ⇪⌃⌥h   │              │              │   │
--        ⇪⌃⌘h   │              │              │   │
--        ⇪⌥⌘h   │              │              │   │
{ chord = "⇧⌃⌥h",                               fn = "hammerspoon_reload" },
--        ⇧⌃⌥h   │              │              │ ✓ │             — reload Hammerspoon config
{ chord = "num1",                                 fn = "wallpaper_refresh" },
--⇧⌃⌥⌘h → num1   │              │              │ ✓ │             — refresh wallpaper
--        ⇧⌥⌘h   │              │              │   │        Fork — quick Stash
{ chord = "F13",                                 fn = "window.hide_current" },
--  ⌃⌥⌘h → F13   │              │              │ ✓ │             — hide current window only
--               ┴              ┴              ┴   ┴
}
