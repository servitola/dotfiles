return {
--    ╭—————╮
--    │  V  │    paste / browser
--    ╰—————╯
--
--         karabiner: ⇪v → F19
--
--————————— chord ┬ en | ru | el ┬ ┬
--           v    │ v    м    ω  │⋅│
--————————————————┼——————————————┼—┼——————————————————————————————————
--           ⇪v   │     F19      │k│ ↓
{ chord =  "F19",                    app = "Yandex" },
--           ⇧v   │ V    М    Ω  │⋅│
--           ⌃v   │              │⋅│ Terminal — paste
--                │              │ │ Claude Code — paste
--           ⌥v   │ ↓    ↓    ↓  │⋅│
--           ⌘v   │              │⋅│  — paste
--                │              │⋅│ Music — paste song information or artwork
--           ⇥v   │              │ │ ???
--————————————————┼——————————————┼—┼——————————————————————————————————
--          ⇪⇧v   │     ⇧F19     │k│ ↓
{ chord = "⇧F19",                    app = "Google Chrome" },
--          ⇪⌃v   │     ⌃F19     │k│ ↓
{ chord = "⌃F19",                    fn = "vpn.toggle_globalprotect" },
--          ⇪⌥v   │     ⌥F19     │k│ ???
--          ⇪⌘v   │     ⌘F19     │k│ ↓
{ chord = "⌘F19",                    fn = "browser_search_selected" },
--          ⇧⌃v   │              │⋅│ Terminal — used sometimesž
--          ⇧⌥v   │ ˇ    ˇ    ˇ  │⋅│
--          ⇧⌘v   │              │⋅│ Mail — paste text into email as quotation
{ chord =  "⌃⌥v",                    fn = "browser_youtube" },
--          ⌃⌘v   │              │ │ ???
--          ⌥⌘v   │              │⋅│ ℝ — extract variable
--————————————————┼——————————————┼—┼——————————————————————————————————
--         ⇪⇧⌃v   │              │ │
--         ⇪⇧⌥v   │              │ │
--         ⇪⇧⌘v   │              │ │
--         ⇪⌃⌥v   │              │ │
--         ⇪⌃⌘v   │              │ │
--         ⇪⌥⌘v   │              │ │
--         ⇧⌃⌥v   │              │ │
--         ⇧⌃⌘v   │              │ │
--         ⇧⌥⌘v   │              │ │
--         ⌃⌥⌘v   │              │ │
--                ┴              ┴ ┴
}
