return {
--    ╭—————╮
--    │  G  │    git / go to
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           g   │              │ g    п    γ  │   │
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪g   │     F18      │              │   │               ↓
{ chord = "F18",                           app = "@APP_GIT_GUI" },
--          ⇧g   │              │ G    П    Γ  │   │
--          ⌃g   │              │              │   │         Rider — focus Git panel
--          ⌥g   │              │      ©       │   │ GitHub
{ chord =  "⌥g",                            fn = "browser_git" },
--          ⌘g   │              │              │   │         Rider — git operations popup
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧g   │     ⇧F18     │              │   │
--         ⇪⌃g   │     ⌃F18     │              │   │
--         ⇪⌥g   │     ⌥F18     │              │   │               ↓
{ chord= "⌥F18",                            fn = "fork.workprojectdev" },
--         ⇪⌘g   │     ⌘F18     │              │   │               ↓
{ chord= "⌘F18",                            fn = "fork.dotfiles" },
--         ⇧⌃g   │              │              │   │         Rider — current file git history
--         ⇧⌥g   │              │         Ϊ  │   │
--         ⇧⌘g   │              │              │   │        Finder — go to GoTo dialog
--         ⌃⌥g   │              │              │   │ GitHub
{ chord = "⌃⌥g",                            fn = "browser_git" },
--         ⌃⌘g   │              │              │   │         Rider — select all occurances
--         ⌥⌘g   │              │              │   │
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--        ⇪⇧⌃g   │    ⇧⌃F18     │              │   │
--        ⇪⇧⌥g   │    ⇧⌥F18     │              │   │
--        ⇪⇧⌘g   │    ⇧⌘F18     │              │   │
--        ⇪⌃⌥g   │    ⌃⌥F18     │              │   │
--        ⇪⌃⌘g   │    ⌃⌘F18     │              │   │
--        ⇪⌥⌘g   │    ⌥⌘F18     │              │   │
--        ⇧⌃⌥g   │              │              │   │     🌐 Vivaldi — focus dotfiles GitHub tab
{ chord= "⇧⌃⌥g",                            fn = "browser_git_dotfiles" },
--        ⇧⌃⌘g   │              │              │   │
--        ⇧⌥⌘g   │              │              │   │
--        ⌃⌥⌘g   │              │              │   │
--               ┴              ┴              ┴   ┴
}
