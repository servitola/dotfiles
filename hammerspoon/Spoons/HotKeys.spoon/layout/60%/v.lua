return {
--    ╭—————╮
--    │  V  │    paste / browser
--    ╰—————╯
--
--         karabiner: ⇪⇧v → F13
--                    ⇪⌃v → F19
--
--———————— chord ┬ en | ru | el ┬
--           v   │ v    м    ω  │
--———————————————┼——————————————┼——————————————————————————————————
{ chord =  "⇪v",                  app = "Yandex" },
--          ⇧v   │ V    М    Ω  │
--          ⌃v   │              │ Terminal — paste
--          ⌥v   │ ↓    ↓    ↓  │
--          ⌘v   │              │  — paste
--               │              │ Music — paste song information or artwork
--———————————————┼——————————————┼——————————————————————————————————
--   ⇪⇧v → F13   │              │
{ chord = "F13",                  app = "Google Chrome" },
--   ⇪⌃v → F19   │              │
{ chord = "F19",                  fn = "vpn.toggle_globalprotect" },
--         ⇪⌥v   │              │ ???
--         ⇪⌘v   │              │ ???
--         ⇧⌃v   │              │ ???
--         ⇧⌥v   │ ˇ    ˇ    ˇ  │
--         ⇧⌘v   │              │ Mail — paste text into email as quotation
{ chord = "⌃⌥v",                  fn = "browser_youtube" },
--         ⌃⌘v   │              │ ???
--         ⌥⌘v   │              │ ℝ — extract variable
--———————————————┼——————————————┼——————————————————————————————————
--        ⇪⇧⌃v   │              │
--        ⇪⇧⌥v   │              │
--        ⇪⇧⌘v   │              │
--        ⇪⌃⌥v   │              │
--        ⇪⌃⌘v   │              │
--        ⇪⌥⌘v   │              │
--        ⇧⌃⌥v   │              │
--        ⇧⌃⌘v   │              │
--        ⇧⌥⌘v   │              │
--        ⌃⌥⌘v   │              │
--               ┴              ┴
}
