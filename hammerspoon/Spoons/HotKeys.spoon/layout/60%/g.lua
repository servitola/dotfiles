return {
--    ╭—————╮
--    │  G  │    git / go to
--    ╰—————╯
--
--
--———————— chord ┬  karabiner   ┬ en | ru | el ┬ G ┬——————————— app — function ————————————————————————————————————
--           g   │              │ g    п    γ  │   │
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--          ⇪g   │     F18      │              │   │ Fork
{ chord = "F18",                            app = "@APP_GIT_GUI" },
--          ⇧g   │              │ G    П    Γ  │   │
--          ⌃g   │              │              │ ℝ │         Rider — Activate Version Control Tool Window
--          ⌥g   │              │      ©       │   │ GitHub
{ chord = "⌥g",                             fn = "browser_git" },
--          ⌘g   │              │              │ ℝ │         Rider — VCS Operations Popup…
--———————————————┼——————————————┼——————————————┼———┼——————————————————————————————————————————————
--         ⇪⇧g   │     ⇧F18     │              │   │
--         ⇪⌃g   │     ⌃F18     │              │   │
--         ⇪⌥g   │     ⌥F18     │              │   │   Hammerspoon — Fork Work
{ chord = "⌥F18",                           fn = "fork.work" },
--         ⇪⌘g   │     ⌘F18     │              │   │   Hammerspoon — Fork Dots
{ chord = "⌘F18",                           fn = "fork.dotfiles" },
--         ⇧⌃g   │              │              │ ℝ │         Rider — Open Inline Chat Action
--               │              │              │ ℝ │         Rider — Show History
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
{ chord = "⇧⌃⌥g",                           fn = "browser_git_dotfiles" },
--        ⇧⌃⌘g   │              │              │   │
--        ⇧⌥⌘g   │              │              │   │
--        ⌃⌥⌘g   │              │              │   │
--               ┴              ┴              ┴   ┴
}
