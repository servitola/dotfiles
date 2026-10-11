return {
--    ╭—————╮
--    │  H  │    hide / work browser (firefox / safari)
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           h   │              │ h    р    η  │   │
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪h   │     F20      │              │   │ Firefox
{ chord = "F20",                            app = "@APP_BROWSER_WORK" },
--          ⇧h   │              │ H    Р    Η  │   │
--          ⌃h   │              │              │ ✓ │              — cut letter to the left
--          ⌥h   │              │      ₽       │   │
--          ⌘h   │              │              │ ✓ │               — hide app
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧h   │     ⇧F20     │              │   │ Safari
{ chord = "⇧F20",                           app = "Safari" },
--         ⇪⌃h   │     ⌃F20     │              │   │
--         ⇪⌥h   │     ⌥F20     │              │   │
--         ⇪⌘h   │     ⌘F20     │              │   │
--         ⇧⌃h   │              │              │ ◆ │      Services — Finder/Reveal (Finder)
--               │              │              │ ℝ │         Rider — Hierarchy
--         ⇧⌥h   │              │ ˝    ˝    ≠  │   │ Birman Layout — press double to adjust previous symbol
--         ⇧⌘h   │              │              │   │        Finder — go to $HOME
--               │              │              │ ◆ │  Boring Notch — toggleSneakPeek
--         ⌃⌥h   │              │              │   │ Hammerspoon
{ chord = "⌃⌥h",                            app = "Hammerspoon", window_default_position = "right" },
--         ⌃⌘h   │              │              │   │ Heroes of the Storm
{ chord = "⌃⌘h",                            app = "Heroes of the Storm" },
--         ⌥⌘h   │              │              │ ✓ │              — hide all other windows
--               │              │              │ ℝ │         Rider — Show in File Manager
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃h   │    ⇧⌃F20     │              │   │
--        ⇪⇧⌥h   │    ⇧⌥F20     │              │   │
--        ⇪⇧⌘h   │    ⇧⌘F20     │              │   │
--        ⇪⌃⌥h   │    ⌃⌥F20     │              │   │
--        ⇪⌃⌘h   │    ⌃⌘F20     │              │   │
--        ⇪⌥⌘h   │    ⌥⌘F20     │              │   │
--        ⇧⌃⌥h   │              │              │   │   Hammerspoon — reload Hammerspoon config
{ chord = "⇧⌃⌥h",                           fn = "hammerspoon_reload" },
--        ⇧⌃⌘h   │              │              │   │
--               │              │              │ ℝ │         Rider — Call Hierarchy
--        ⇧⌥⌘h   │              │              │   │          Fork — quick Stash
--        ⌃⌥⌘h   │              │              │   │   Hammerspoon — hide current window only
{ chord = "⌃⌥⌘h",                           fn = "window.hide_current" },
--       ⇧⌃⌥⌘h   │              │              │   │   Hammerspoon — refresh wallpaper
{ chord = "⇧⌃⌥⌘h",                          fn = "wallpaper_refresh" },
--               ┴              ┴              ┴   ┴
}
