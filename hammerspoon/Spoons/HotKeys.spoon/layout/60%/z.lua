return {
--    ╭—————╮
--    │  Z  │    undo / suspend
--    ╰—————╯
--
--
--———————— chord ┬ en | ru | el ┬—————————— app — function ————————————————————
--           z   │ z    я    ζ  │   Browser Vim — Mark Links
--———————————————┼——————————————┼——————————————————————————————————
--          ⇪z   │     F20      │
{ chord = "F20",                             fn = "android.show_all" },
--          ⇧z   │ Z    Я    Ζ  │          IINA — add sub-delay -0.5s
--          ⌃z   │              │ Unix Terminal — suspend (background)
--          ⌥z   │              │        VSCode — toggle wordwrap
--               │              │          Warp — type "/new" (Claude Code shortcut) HAMMERSPOON CUSTOM
--               │              │        Finder — go to Downloads (⇧⌘L) HAMMERSPOON CUSTOM
--          ⌘z   │              │              — undo
--          ⇥z   │      ⌘/      │         Rider — comment line
--               │              │        VSCode — toggle comment line
--               │              │         Music — show or hide the status bar
--———————————————┼——————————————┼————————————————————————————————————
--         ⇪⇧z   │     ⇧F20     │ ???
--         ⇪⌃z   │     ⌃F20     │ ???
--         ⇪⌥z   │     ⌥F20     │ ???
--         ⇪⌘z   │     ⌘F20     │ ???
--         ⇧⌃z   │              │      VoiceInk — start/stop recoding
{ chord = "⇧⌥z",                            app = "Simulator" },
--         ⇧⌘z   │              │              — redo
--               │              │          Mail — unsend email
--         ⌃⌥z   │              │ ???
{ chord = "⌃⌘z",                            app = "Simulator" },
--         ⌥⌘z   │              │        VSCOde — revert selected in git
--———————————————┼——————————————┼————————————————————————————————————
--        ⇪⇧⌃z   │    rewind    │              — rewind
--        ⇪⇧⌥z   │              │
--        ⇪⇧⌘z   │              │
--        ⇪⌃⌥z   │              │
--        ⇪⌃⌘z   │              │
--        ⇪⌥⌘z   │              │
--        ⇧⌃⌥z   │              │
--        ⇧⌃⌘z   │              │
--        ⇧⌥⌘z   │              │
--        ⌃⌥⌘z   │              │
--               ┴              ┴
}
