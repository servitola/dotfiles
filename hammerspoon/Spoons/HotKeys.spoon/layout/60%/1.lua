return {
--    ╭—————╮
--    │  1  │    1st / F1
--    ╰—————╯
--
--
--———————— chord ┬ en | ru | el ┬————————————— app — function ————————————————————
--           1   │      1       │          YouTube — Navigate to 10% of video
--———————————————┼——————————————┼————————————————————————————————————
--          ⇪1   │     F1       │            Rider — quick documentation
--          ⇧1   │ !    !    !  │
--          ⌃1   │              │           VSCode — go to tab 1
--               │              │            Rider — focus file in solution explorer
{ chord =  "⌥1",                               app = "Visual Studio Code" },
--          ⌘1   │              │            Rider — focus solution explorer
--               │              │           VSCode — focus solution explorer
--               │              │           Finder — View as icons
--               │              │          Browser — Open 1st tab
--               │              │             Fork — Focus changes window
--               │              │ Activity Manager — Focus main window
--               │              │         Telegram — focus 1st folder or chat
--               │              │             IINA — set window-scale 1
--          ⇥1   │     ⌘9       │          Browser — open last tab
--               │              │         Telegram — focus 9th folder or chat
--———————————————┼——————————————┼————————————————————————————————————
--         ⇪⇧1   │     ⇧F1      │            Rider — external documentation
--         ⇪⌃1   │     ⌃F1      │ ???
--         ⇪⌥1   │     ⌥F1      │            Rider — show 'Select in' dialog
--         ⇪⌘1   │     ⌘F1      │           VSCode — show errors/warnings
{ chord = "⇧⌘1",                                fn = "vscode.dotfiles" },
--         ⇧⌃1   │              │            Rider — toggle bookmark 1
--         ⇧⌥1   │ ¡    ¡    έ  │
{ chord = "⌃⌥1",                                fn = "audio.internal" },
--         ⌃⌘1   │              │
--         ⌥⌘1   │              │ Fork — show commit details
--———————————————┼——————————————┼————————————————————————————————————
--        ⇪⇧⌃1   │              │
--        ⇪⇧⌥1   │              │
--        ⇪⇧⌘1   │              │
--        ⇪⌃⌥1   │              │
--        ⇪⌃⌘1   │              │
--        ⇪⌥⌘1   │              │
--        ⇧⌃⌥1   │              │
--        ⇧⌃⌘1   │              │
--        ⇧⌥⌘1   │              │
--        ⌃⌥⌘1   │              │
--               ┴              ┴
}
