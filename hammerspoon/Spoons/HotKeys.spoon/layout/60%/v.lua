return {
--    ╭—————╮
--    │  V  │    paste / browser
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           v   │              │ v    м    ω  │   │
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪v   │     F16      │              │   │ Vivaldi
{ chord = "F16",                            app = "@APP_BROWSER" },
--          ⇧v   │              │ V    М    Ω  │   │
--          ⌃v   │              │              │   │   Claude Code — paste
--               │              │              │   │      Terminal — paste
--               │              │              │ ℝ │         Rider — VCS Operations Popup…
--          ⌥v   │              │      ↓       │   │
--          ⌘v   │              │              │ ✓ │              — paste
--               │              │              │   │         Music — paste song information or artwork
--          ⇥v   │     num1     │              │   │     🌐 Vivaldi — YouTube
{ chord = "num1",                           fn = "browser_youtube" },
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧v   │     ⇧F16     │              │   │ Google Chrome
{ chord = "⇧F16",                           app = "@APP_BROWSER_ALT" },
--         ⇪⌃v   │     ⌃F16     │              │   │   Hammerspoon — VPN
{ chord = "⌃F16",                           fn = "vpn.toggle_globalprotect" },
--         ⇪⌥v   │     ⌥F16     │              │   │
--               │              │              │ ◆ │         Maccy — popup
--         ⇪⌘v   │     ⌘F16     │              │   │   Hammerspoon — Search Sel
{ chord = "⌘F16",                           fn = "browser_search_selected" },
--         ⇧⌃v   │              │              │   │
--         ⇧⌥v   │              │ ˇ    ˇ    Ά  │   │
--         ⇧⌘v   │              │              │   │          Mail — paste text into email as quotation
--         ⌃⌥v   │              │              │   │
--               │              │              │ ℝ │         Rider — Introduce Variable…
--         ⌃⌘v   │              │              │   │   Hammerspoon — paste bypass (type clipboard for restricted fields)
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
{ chord = "⇧⌃⌥v",                           fn = "browser_youtube_playing" },
--        ⇧⌃⌘v   │              │              │   │
--        ⇧⌥⌘v   │              │              │   │
--        ⌃⌥⌘v   │              │              │   │
--               ┴              ┴              ┴   ┴
}
