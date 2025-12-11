return {
--    ╭—————╮
--    │  V  │    paste / browser
--    ╰—————╯
--
--         karabiner: ⇪⇧v → F13
--
--———————— chord ┬ en | ru | el ┬
--           v   │ v    м    ω  │
--———————————————┼——————————————┼——————————————————————————————————
{ chord =  "⇪v",                  app = "Yandex" },
--          ⇧v   │ V    М    Ω  │
--          ⌃v   │              │
--          ⌥v   │ ↓    ↓    ↓  │
--          ⌘v   │              │  — paste
--               │              │ Music — paste song information or artwork
--———————————————┼——————————————┼——————————————————————————————————
--   ⇪⇧v → F13   │              │
{ chord = "F13",                  app = "Google Chrome" },
--         ⇪⌃v   │              │
--         ⇪⌥v   │              │
--         ⇪⌘v   │              │
--         ⇧⌃v   │              │
--         ⇧⌥v   │ ˇ    ˇ    ˇ  │
--         ⇧⌘v   │              │ Mail — paste text into email as quotation
{ chord = "⌃⌥v",                  fn = "browser_youtube" },
--         ⌃⌘v   │              │
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
