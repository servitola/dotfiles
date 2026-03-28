return {
--    ╭—————╮
--    │  V  │    paste / browser
--    ╰—————╯
--
--
--————————— chord ┬ en | ru | el ┬—————————— app — function ————————————————————
--           v    │ v    м    ω  │
--————————————————┼——————————————┼————————————————————————————————————
--           ⇪v   │     F19      │          ↓
{ chord =  "F19",                    app = "Yandex" },
--           ⇧v   │ V    М    Ω  │
--           ⌃v   │              │      Terminal — paste
--                │              │   Claude Code — paste
--           ⌥v   │ ↓    ↓    ↓  │
--           ⌘v   │              │              — paste
--                │              │         Music — paste song information or artwork
--           ⇥v   │              │ ???
--————————————————┼——————————————┼————————————————————————————————————
--          ⇪⇧v   │     ⇧F19     │                  ↓
{ chord = "⇧F19",                            app = "Google Chrome" },
--          ⇪⌃v   │     ⌃F19     │                  ↓
{ chord = "⌃F19",                             fn = "vpn.toggle_globalprotect" },
--          ⇪⌥v   │     ⌥F19     │         maccy — show buffer
--          ⇪⌘v   │     ⌘F19     │                  ↓
{ chord = "⌘F19",                             fn = "browser_search_selected" },
--          ⇧⌃v   │              │      Terminal — used sometimes
--          ⇧⌥v   │ ˇ    ˇ    ˇ  │
--          ⇧⌘v   │              │          Mail — paste text into email as quotation
{ chord =  "⌃⌥v",                             fn = "browser_youtube" },
{ chord = "⇧⌃⌥v",                             fn = "browser_youtube_playing" },
--          ⌃⌘v   │              │              — paste bypass (type clipboard for restricted fields)
{ chord =  "⌃⌘v",                             fn = "paste_bypass" },
--          ⌥⌘v   │              │         Rider — extract variable
--————————————————┼——————————————┼————————————————————————————————————
--         ⇪⇧⌃v   │              │
--         ⇪⇧⌥v   │              │
--         ⇪⇧⌘v   │              │
--         ⇪⌃⌥v   │              │
--         ⇪⌃⌘v   │              │
--         ⇪⌥⌘v   │              │
--         ⇧⌃⌥v   │              │      🌐 Yandex — focus playing YouTube tab
--         ⇧⌃⌘v   │              │
--         ⇧⌥⌘v   │              │
--         ⌃⌥⌘v   │              │
--                ┴              ┴
}
