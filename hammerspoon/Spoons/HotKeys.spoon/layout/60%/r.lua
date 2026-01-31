return {
--    ╭—————╮
--    │  R  │    replace / refresh / IDE
--    ╰—————╯
--
--
--————————— chord ┬ en | ru | el ┬————————— app — function ————————————————————
--            r   │ r    к    ρ  │
--————————————————┼——————————————┼————————————————————————————————————
--           ⇪r   │     F17      │                 ↓
{ chord =  "F17",                           app = "Rider" },
--           ⇧r   │ R    К    Ρ  │
--           ⌃r   │              │        Rider — run
--                │              │  Claude Code — reverse search history
--                │              │        Atuin — reverse search history
{ chord =   "⌥r",                           app = "WebStorm" },
--           ⌘r   │              │       VSCode — replace in current file
--                │              │        Rider — replace in current file
--                │              │         Mail — reply to email
--————————————————┼——————————————┼————————————————————————————————————
--          ⇪⇧r   │     ⇧F17     │                 ↓
{ chord = "⇧F17",                           app = "Android Studio" },
--          ⇪⌃r   │     ⌃F17     │ ???
--          ⇪⌥r   │     ⌥F17     │ ???
--          ⇪⌘r   │     ⌘F17     │ ???
--          ⇧⌃r   │              │        Rider — run Unit Tests
--          ⇧⌥r   │ ˚    ˚    Δ  │ ???
--      ⇧⌥r ⇧⌥r   │ s̊    ы̊    no │ double to add sign to previous symbol
--          ⇧⌘r   │              │         Mail — reply all to email
--                │              │        Rider — replace in files
--                │              │       Yandex — clear cache and reload page
{ chord =  "⌃⌥r",                           app = "WebStorm" },
--          ⌃⌘r   │              │        Rider — rerun tests
--          ⌥⌘r   │              │        Rider — resume running (debugging)
--                │              │       VSCode — resume running (debugging)
--                │              │         Mail — show Reply-To field
--————————————————┼——————————————┼————————————————————————————————————
--         ⇪⇧⌃r   │              │
--         ⇪⇧⌥r   │              │
--         ⇪⇧⌘r   │              │
--         ⇪⌃⌥r   │              │
--         ⇪⌃⌘r   │              │
--         ⇪⌥⌘r   │              │
--         ⇧⌃⌥r   │              │
--         ⇧⌃⌘r   │              │
--         ⇧⌥⌘r   │              │
--         ⌃⌥⌘r   │              │
--                ┴              ┴
}
