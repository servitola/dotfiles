return {
--    ╭—————╮
--    │  G  │    git / go to
--    ╰—————╯
--
--
--————————— chord ┬ en | ru | el ┬————————— app — function ————————————————————
--            g   │ g    п    γ  │
--————————————————┼——————————————┼————————————————————————————————————
{ chord =   "⇪g",                           app = "Fork" },
--           ⇧g   │ G    П    Γ  │
--           ⌃g   │              │        Rider — focus Git panel
{ chord =   "⌥g",                            fn = "browser_git" },
--           ⌘g   │              │        Rider — git operations popup
--           ⇥g   │              │ ???
--————————————————┼——————————————┼————————————————————————————————————
--          ⇪⇧g   │              │
--          ⇪⌃g   │              │
--          ⇪⌥g   │     ⌥F13     │                  ↓
{ chord = "⌥F13",                            fn = "fork.workprojectdev" },
--          ⇪⌘g   │     ⌘F13     │                  ↓
{ chord = "⌘F13",                            fn = "fork.dotfiles" },
--                │              │
--          ⇧⌃g   │              │        Rider — current file git history
--          ⇧⌥g   │         Ϊ  │
--          ⇧⌘g   │              │       Finder — go to GoTo dialog
{ chord =  "⌃⌥g",                            fn = "browser_git" },
{ chord = "⇧⌃⌥g",                            fn = "browser_git_dotfiles" },
--          ⌃⌘g   │              │        Rider — select all occurances
--          ⌥⌘g   │              │
--————————————————┼——————————————┼————————————————————————————————————
--         ⇪⇧⌃g   │              │
--         ⇪⇧⌥g   │              │
--         ⇪⇧⌘g   │              │
--         ⇪⌃⌥g   │              │
--         ⇪⌃⌘g   │              │
--         ⇪⌥⌘g   │              │
--         ⇧⌃⌥g   │              │ 🌐 Yandex — focus dotfiles GitHub tab
--         ⇧⌃⌘g   │              │
--         ⇧⌥⌘g   │              │
--         ⌃⌥⌘g   │              │
--                ┴              ┴
}
