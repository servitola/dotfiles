return {
--    ╭—————╮
--    │  R  │    replace / refresh / IDE / P
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           r   │              │ r    к    ρ  │   │
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪r   │     F14      │              │   │ Rider
{ chord = "F14",                            app = "@APP_IDE" },
--          ⇧r   │              │ R    К    Ρ  │   │
--          ⌃r   │              │              │   │         Rider — run
--               │              │              │   │   Claude Code — reverse search history
--               │              │              │   │         Atuin — reverse search history
--          ⌥r   │              │      ®       │   │ WebStorm
{ chord = "⌥r",                             app = "WebStorm" },
--          ⌘r   │              │              │   │         Rider — replace in current file
--               │              │              │   │        VSCode — replace in current file
--               │              │              │   │          Mail — reply to email
--          ⇥r   │      ⌘p      │              │ ✓ │              — print
--               │              │              │   │         Music — play
--               │              │              │   │          Fork — show command palette
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧r   │     ⇧F14     │              │   │
--         ⇪⌃r   │     ⌃F14     │              │   │   Hammerspoon — Clip LLM
{ chord = "⌃F14",                           fn = "clipboard_llm" },
--         ⇪⌥r   │     ⌥F14     │              │   │
--         ⇪⌘r   │     ⌘F14     │              │   │ OrbStack
{ chord = "⌘F14",                           app = "OrbStack" },
--         ⇧⌃r   │              │              │   │         Rider — run Unit Tests
--         ⇧⌥r   │              │ ˚    ˚    Δ  │   │
--     ⇧⌥r ⇧⌥r   │              │              │   │ Birman Layout — double to add sign to previous symbol
--         ⇧⌘r   │              │              │   │         Rider — replace in files
--               │              │              │   │          Mail — reply all to email
--               │              │              │   │       Vivaldi — clear cache and reload page
--         ⌃⌥r   │              │              │   │
--         ⌃⌘r   │              │              │   │         Rider — rerun tests
--         ⌥⌘r   │              │              │   │         Rider — resume running (debugging)
--               │              │              │   │        VSCode — resume running (debugging)
--               │              │              │   │          Mail — show Reply-To field
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃r   │    ⇧⌃F14     │              │   │
--        ⇪⇧⌥r   │    ⇧⌥F14     │              │   │
--        ⇪⇧⌘r   │    ⇧⌘F14     │              │   │
--        ⇪⌃⌥r   │    ⌃⌥F14     │              │   │
--        ⇪⌃⌘r   │    ⌃⌘F14     │              │   │
--        ⇪⌥⌘r   │    ⌥⌘F14     │              │   │
--        ⇧⌃⌥r   │              │              │   │
--        ⇧⌃⌘r   │              │              │   │
--               │              │              │ ℝ │         Rider — Run…
--        ⇧⌥⌘r   │              │              │   │
--        ⌃⌥⌘r   │              │              │   │
--               ┴              ┴              ┴   ┴
}
