return {
--    ╭—————╮
--    │  V  │    paste / browser
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           v   │              │ v    м    ω  │   │
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪v   │     F16      │              │   │               ↓
{ chord = "F16",                           app = "@APP_BROWSER" },
--          ⇧v   │              │ V    М    Ω  │   │
--          ⌃v   │              │              │   │   Claude Code — paste
--               │              │              │   │      Terminal — paste
--          ⌥v   │              │      ↓       │   │
--          ⌘v   │              │              │ ✓ │              — paste
--               │              │              │   │         Music — paste song information or artwork
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧v   │     ⇧F16     │              │   │               ↓
{ chord= "⇧F16",                           app = "@APP_BROWSER_ALT" },
--         ⇪⌃v   │     ⌃F16     │              │   │               ↓
{ chord= "⌃F16",                            fn = "vpn.toggle" },
--         ⇪⌥v   │     ⌥F16     │              │   │         maccy — show buffer
--         ⇪⌘v   │     ⌘F16     │              │   │               ↓
{ chord= "⌘F16",                            fn = "browser_search_selected" },
--         ⇧⌃v   │              │              │   │      Terminal — used sometimes
--         ⇧⌥v   │              │ ˇ    ˇ    Ά  │   │
--         ⇧⌘v   │              │              │   │          Mail — paste text into email as quotation
--         ⌃⌥v   │              │              │   │ YouTube
{ chord = "⌃⌥v",                            fn = "browser_youtube" },
--         ⌃⌘v   │              │              │ ✓ │              — paste bypass (type clipboard for restricted fields)
{ chord = "⌃⌘v",                            fn = "paste_bypass" },
--         ⌥⌘v   │              │              │   │         Rider — extract variable
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃v   │    ⇧⌃F16     │              │   │
--        ⇪⇧⌥v   │    ⇧⌥F16     │              │   │
--        ⇪⇧⌘v   │    ⇧⌘F16     │              │   │
--        ⇪⌃⌥v   │    ⌃⌥F16     │              │   │
--        ⇪⌃⌘v   │    ⌃⌘F16     │              │   │
--        ⇪⌥⌘v   │    ⌥⌘F16     │              │   │
--        ⇧⌃⌥v   │              │              │   │     🌐 Vivaldi — focus playing YouTube tab
{ chord= "⇧⌃⌥v",                            fn = "browser_youtube_playing" },
--        ⇧⌃⌘v   │              │              │   │
--        ⇧⌥⌘v   │              │              │   │
--        ⌃⌥⌘v   │              │              │   │
--               ┴              ┴              ┴   ┴
}
