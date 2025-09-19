local obj={}

-- Keyboard layers described in this document:

-- 1. English Layer
-- 2. Russian Layer
-- 3. Greek Layer

-- 4. Shift + English Layer (⇧)
-- 5. Shift + Russian Layer (⇧)
-- 6. Shift + Greek Layer (⇧)

-- 7. Alt Layer (⌥) -- Ilya Birman's layout
-- 8. Alt + Shift Layer (⌥⇧) -- Ilya Birman's layout

-- 9. Command Layer (⌘)
-- 10. Control Layer (⌃)
-- 11. Hyper Layer (⌘⌃⌥⇧)

-- 12. Hyper + Alt Layer (⌘⌃⌥⇧ + ⌥)
-- 13. Hyper + Command Layer (⌘⌃⌥⇧ + ⌘)
-- 14. Hyper + Control Layer (⌘⌃⌥⇧ + ⌃)
-- 15. Hyper + Shift Layer (⌘⌃⌥⇧ + ⇧)
-- 16. Command + Shift Layer (⌘⇧)
-- 17. Command + Alt Layer (⌘⌥)
-- 18. Command + Control Layer (⌘⌃)
-- 19. Control + Shift Layer (⌃⇧)
-- 20. Control + Alt Layer (⌃⌥)

-- 21. Control + Alt + Command Layer (⌃⌥⌘)
-- 22. Shift + Alt + Command Layer (⇧⌥⌘)
-- 23. Shift + Control + Command Layer (⇧⌃⌘)
-- 24. Shift + Control + Alt (⇧⌃⌥)

hyper = { "right_command", "right_control", "right_option", "right_shift" }

-- Icons used:
--  -- MacOS or common
-- 🌐 -- Browser
-- ℝ -- Rider IDE
-- 📁 -- Finder
-- 🔄 -- Git
-- 📝 -- VSCode

-- ⚠️ —— HARD TO PRESS, don't use

-- ⌘ -- Command Key
-- ⌥ -- Option/Alt Key
-- ⌃ -- Control Key
-- ⇧ -- Shift Key
-- ⌫ -- Backspace Key
-- ⇥ -- Tab Key
-- ↩ -- Return/Enter Key

layers_list =
{

-- ╭—————╮__MAIN_LAYER_EN__╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │  `  │  1  │  2  │  3  │  4  │  5  │  6  │  7  │  8  │  9  │  0  │  -  │  =  │     ⌫  │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  q  │  w  │  e  │  r  │  t  │  y  │  u  │  i  │  o  │  p  │  [  │  ]  │   ↩  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ HYPER  │  a  │  s  │  d  │  f  │  g  │  h  │  j  │  k  │  l  │  ;  │  '  │  \  │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │  ⇧      │  z  │  x  │  c  │  v  │  b  │  n  │  m  │  ,  │  .  │  /  │             ⇧  │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │  ⌃     │  ⌥  │   ⌘  │           SPACE             │  ⌘   │    ⌥    │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- t: YouTube - Theatre mode
-- i: YouTube - Minimize video
-- f: 🌐 - Go Full Screen Video
-- g + g: 🌐 Vim - Go Window Top
-- j: YouTube - 10sec back
-- k: YouTube - play/pause
-- l: YouTube - 10sec forward
-- z: 🌐 Vim - Mark Links
-- x: 🌐 Vim - Focus text input
-- c: YouTube - subtitles
-- m: 🌐 Vim - Mute Tab
-- space: 📁 - Show Preview
-- shift + shift: ℝ - Command Pallette
-- ↑: Telegram — edit last message
--    Iina - sound up 5%
-- ↓: Iina - sound down 5%
-- →: YouTube - seek forward 5sec
--    Iina - seek forward 5sec
-- ←: YouTube - seek backward 5sec
--    Iina - seek backward 5sec

-- ╭—————╮__MAIN_LAYER_RU__╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │  ё  │  1  │  2  │  3  │  4  │  5  │  6  │  7  │  8  │  9  │  0  │  -  │  =  │     ⌫  │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  й  │  ц  │  у  │  к  │  е  │  н  │  г  │  ш  │  щ  │  з  │  х  │  ъ  │   ↩  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ HYPER  │  ф  │  ы  │  в  │  а  │  п  │  р  │  о  │  л  │  д  │  ж  │  э  │  \  │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │  ⇧      │  я  │  ч  │  с  │  м  │  и  │  т  │  ь  │  б  │  ю  │  .  │             ⇧  │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │  ⌃     │  ⌥  │   ⌘  │           SPACE             │  ⌘   │    ⌥    │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯

-- ╭—————╮__MAIN_LAYER_GR__╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │  §  │  1  │  2  │  3  │  4  │  5  │  6  │  7  │  8  │  9  │  0  │  -  │  =  │     ⌫  │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  ;  │  ς  │  ε  │  ρ  │  τ  │  υ  │  θ  │  ι  │  ο  │  π  │  [  │  ]  │   ↩  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ HYPER  │  α  │  σ  │  δ  │  φ  │  γ  │  η  │  ξ  │  κ  │  λ  │  ΄  │  '  │  \  │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │  ⇧      │  ζ  │  χ  │  ψ  │  ω  │  β  │  ν  │  μ  │  ,  │  .  │  /  │             ⇧  │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │  ⌃     │  ⌥  │   ⌘  │           SPACE             │  ⌘   │    ⌥    │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯

-- ╭—————╮__SHIFT_LAYER_EN_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │  ~  │  !  │  @  │  #  │  $  │  %  │  ^  │  &  │  *  │  (  │  )  │  _  │  +  │     ⌫  │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  Q  │  W  │  E  │  R  │  T  │  Y  │  U  │  I  │  O  │  P  │  {  │  }  │   ↩  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  A  │  S  │  D  │  F  │  G  │  H  │  J  │  K  │  L  │  :  │  "  │  |  │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │  🟢🟢🟢  │  Z  │  X  │  C  │  V  │  B  │  N  │  M  │  <  │  >  │  ?  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │      │           SPACE             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- tab: selected text — move block left
-- Q: 🌐 Vim — Go Website Root
-- P: YouTube - Previous video
-- G: 🌐 Vim - Go Window Bottom
-- N: YouTube - Next video
-- <: YouTube - Speed down
-- >: YouTube - Speed up
-- ←: select letter to the left
-- →: select letter to the right
-- ↑: move caret up and select text from the initial position
-- ↓: move caret down and select text from the initial position

-- ╭—————╮__SHIFT_LAYER_RU_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │  Ё  │  !  │  "  │  №  │  ;  │  %  │  :  │  ?  │  *  │  (  │  )  │  _  │  +  │    ⌫   │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  Й  │  Ц  │  У  │  К  │  Е  │  Н  │  Г  │  Ш  │  Щ  │  З  │  Х  │  Ъ  │   ↩  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  Ф  │  Ы  │  В  │  А  │  П  │  Р  │  О  │  Л  │  Д  │  Ж  │  Э  │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │  🟢🟢🟢  │  Я  │  Ч  │  С  │  М  │  И  │  Т  │  Ь  │  Б  │  Ю  │  ,  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │      │         SPACE               │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯

-- ╭—————╮__SHIFT_LAYER_GR_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │  ±  │  !  │  @  │  #  │  $  │  %  │  ^  │  &  │  *  │  (  │  )  │  _  │  +  │    ⌫   │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  :  │  ΅  │  Ε  │  Ρ  │  Τ  │  Υ  │  Θ  │  Ι  │  Ο  │  Π  │  {  │  }  │   ↩  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  Α  │  Σ  │  Δ  │  Φ  │  Γ  │  Η  │  Ξ  │  Κ  │  Λ  │  ¨  │  "  │  |  │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │  🟢🟢🟢  │  Ζ  │  Χ  │  Ψ  │  Ω  │  Β  │  Ν  │  Μ  │  <  │  >  │  ?  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │      │          SPACE              │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯

{ modifier=alt, chords={
-- ╭—————╮____ALT_LAYER____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │  `  │  ¹  │  ²  │  ³  │  $  │  ‰  │  ↑  │     │  ∞  │  ←  │  →  │  —  │  ≠  │       │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  ·  │  ✓  │  €  │  ®  │  ™  │  ѣ  │  ѵ  │  і  │  ѳ  │  ′  │  [  │  ]  │   ℝ  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  ≈  │  §  │  °  │  £  │     │  ₽  │  „  │  “  │  ”  │  ‘  │  ’  │  |  │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │ 📝  │  ×  │  ©  │  ↓  │  ß  │     │  −  │  «  │  »  │  …  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │🟢🟢🟢│      │    NON-BREAKABLE SPACE      │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- ⌫:  — remove word to the left
-- tab: switch the app windows with AltTab app
-- ↩: ℝ — Fix Suggestion popup
-- \: Copilot Suggestion
-- z: VSCode - toggle wordwrap
-- space: Music — Start Genious Shuffle
}},
{ modifier={"alt", "left_shift"}, chords={
-- ╭—————╮_ALT_SHIFT_LAYER_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │  `  │  ¡  │ ¹⁄₂ │ ¹⁄₃ │ ¹⁄₄ │     │  ˆ  │  ¿  │     │  ‹  │  ›  │  –  │  ±  │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │  ˘  │  ⌃  │  ⌥  │  ˚  │  #  │  Ѣ  │  Ѵ  │     │  Ѳ  │  ″  │  {  │  }  │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  ⌘  │  ⇧  │  ⌀  │     │    │  ˝  │     │  ‘  │  ’  │  ¨  │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │ 🟢🟢🟢   │  ¸  │  ·  │  ¢  │  ˇ  │  ẞ  │  ˜  │  •  │  „  │  “  │  ´  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │🟢🟢🟢│      │                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- / + /: set accent to previous letter (Birman's keyboard layout)
-- ←: select word to the left
-- →: select word to the right
}},
{ modifier=left_command, chords={
-- ╭—————╮____CMD_LAYER____╭—————┬—————┬—————┬——————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │  ℝ  │  ℝ  │  ℝ  │  ℝ  │  ℝ  │     │      │  ℝ  │     │    │    │    │     ℝ  │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │      │❌❌❌│  ✖  │ ℝ/T │  ℝ  │  ℝ  │    │BrHist│  ℝ  │    │🖨️🖨️🖨️│     │     │     │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬—————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │    │💾💾💾│    │🔎🔎🔎│  ℝ🔄│  ℝ  │     │    │  📝  │  ℝ  │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬—————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │    │    │    │    │  ℝ  │    │     │    │     │  ℝ  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴——————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │🟢🟢🟢 │         Raycast              │      │         │
-- ╰————————┴—————┴——————┴——————————————————————————————┴——————┴—————————╯
-- swipe: changing zoom
-- F2: ℝ - Stop
-- F3: ℝ - Show bookmarks
-- F5:  — Turn voiceOver on or off
-- 1: ℝ - focus solution explorer
--    📁 - View as icons
--    🌐 - Open 1st tab
--    Fork — Focus changes window
--    Activity Manager — Focus main window
--    Telegram — focus 1st folder or chat
-- 2: ℝ - focus debug window
--    📁 - View as list
--    🌐 - Open 2nd tab
--    Fork — Focus All commits window
--    Activity Manager — Open/focus CPU usage window
--    Telegram — focus 2nd folder or chat
-- 3: ℝ - focus unit tests explorer
--    📁 - View in columns
--    🌐 - Open 3rd tab
--    Activity Manager — Open/focus CPU history window
--    Telegram — focus 3rd folder or chat
-- 4: ℝ - focus build window
--    📁 - View in gallery
--    🌐 - Open 4th tab
--    Activity Manager - Open/focus GPU history window
--    Telegram — focus 4th folder or chat
-- 5: ℝ - focus problems window
--    🌐 - Open 5th tab
--    Telegram — focus 5th folder or chat
-- 6: 🌐 - Open 6th tab
--    Telegram — focus 6th folder or chat
-- 7: 🌐 - Open 7th tab
--    Telegram — focus 7th folder or chat
-- 8: ℝ - focus logcat
--    🌐 - Open 8th tab
--    Telegram — focus 8th folder or chat
-- 9: 🌐 - Open Last tab
--    Telegram — focus 9th folder or chat
-- 0: app - Reset zoom
--    Telegram — focus Saved Messages
-- -: app - Zoom out
-- =: app - Zoom in
-- ⌫: ℝ - delete line
--     dialog — choose Delete option
-- tab:  - switch between open windows
-- q:  - close current app
-- w:  - close current tab
-- e: ℝ - recent files dialog
--    Telegram — toggle camera
--    VSCode - find with selection
-- r: ℝ - replace in current file
--    🌐 - refresh page
--    Telegram — record audio/video message
-- t:  - new tab
--    Telegram — toggle screen sharing
--    Music - visualizer
-- y: app - show all history
-- i: ℝ - show Codeium Command popup
--    Activity Manager — Inspect process
-- o:  - open file
-- p:  - print
--    Fork - open Command palette search
-- [: ℝ - navigate back
--    📁 — navigate back
--    🌐 — navigate back
-- ]: ℝ - navigate forward
--    📁 — navigate forward
--    🌐 — navigate forward
-- ↩:  - aggre or apply, send message
-- a: select all
-- s: save
--     dialog — choose Save option
-- d: ℝ - duplicate line
--    ℝ - debug unit test
--    📁 - duplicate file
--     dialog — choose Don't Save option
--    🌐 - add page to bookmarks
-- f: find
-- g: ℝ🔄 - git operations popup
--    🌐 - find or find next
-- h:  - hide current app
-- j: Music — Show soring options
--    VSCode - toggle sidebar Visibility
-- k: Telegram — Focus search
--    Claude Desktop — New chat
-- l: 🌐 - Focus Url Line
--    Music — Go to Current song
-- ;: ℝ - run unit test
-- z: undo
-- x: cut
-- c: copy
-- v: paste
-- b: ℝ - go to declaration
-- n:  - new window
--    📝 - new empty file
--    Music — new playlist
-- m:  - minimize window
-- ,:  -  show settings ⚙️ of current app
-- /: ℝ — comment line
--    Music — Show/hide status bar
-- space: Raycast
-- ↑: Music — raise volume
-- ↓: Music — down volume
-- ←: Music - play previous song or move to the begging
-- →: Music — play next son
}},
{ modifier=left_control, chords={
-- ╭—————╮__CONTROL_LAYER__╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │  📝 │    │    │     │    │    │     │  ℝ  │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │      │  ℝ  │  ℝ  │  ℝ  │  ℝ  │  ℝ  │     │     │     │     │  ℝ  │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  ℝ  │  ℝ  │  ℝ  │  ℝ  │  ℝ  │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │     │     │     │     │     │     │     │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │     │      │                            │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- F2:  — Move focus to the menu bar
-- F3:  - Move focus to Dock
-- F5:  - Move focus to Window's Toolbar
-- F6:  - Move focus to Floating Win
-- F7:  — Change the way Tab moves focus—between navigation of all controls on the screen, or only text boxes and lists.
-- F8:  — Move focus to the status menu in the menu bar
-- 1: VSCode - Go to tab 1
-- 8: ℝ - Go to Bookmark 8
-- tab:  - switch tab forward
-- q: ℝ - Stop all
-- w: ℝ - close all notifications
-- e: ℝ - Find Usages
-- r: ℝ - Run
-- o: ℝ - Override
-- a: ℝ🔄 - Git Annotate (Blame)
-- s: ℝ - Save with format
-- d: ℝ - Debug
--     — delete letter to the right
-- f: ℝ - Focus Find Window
-- g: ℝ🔄 - Focus Git Window
-- h:  — delete letter to the left
-- k:  — delete all text till the end of line
-- space:  - change language layout
}},
{ modifier=hyper, chords={
-- ╭—————╮__HYPER_LAYER____╭—————┬————————┬————————┬———————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │ ESC │ F1  │ F2  │ F3  │ F4  │   F5   │   F6   │  F7   │ F8  │ F9  │ F10 │ F11 │ F12 │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┴—┬——————┴—┬—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  AI   │PgUp │  ↑  │PgDn │  ℝ  │Telegram│  IINA  │       │     │  ↑  │Music│ ⏮  │  ⏭  │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬-—-———┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │  📁  │Fork🔄  │ Safari │       │  ←  │  ↓  │  →  │ 🔊  │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬——————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │  ↩  │home │ end │ 🌐  │ iTerm2 │ VSCode │       │home │ end │ 🔉   │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴————————┴————————┴———————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │      │           play/stop                 │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————————————┴——————┴—————————╯
-- karabiner escape - tilda/ё
-- 1: F1 - 📝 - open commands palette
-- 2: F2 - ℝ - next error in file
-- 3: F3 -  - find next (in file)
-- 4: F4
-- 5: F5
-- 6: F6
-- 7: F7 - 🌐 - Turn on caret browsing-- 8: F8
-- 9: F9
-- 0: F10
-- -: F11 -  - Show Desktop
-- =: F12
-- ⌫: delete
-- alt + ⌫: maccy delete row
{ key="tab", app="Claude", window_default_position="right" },
-- q: pageUp
-- w: up
-- e: pagedown
{ key="r", app="Rider" },
{ key="t", app="Telegram", window_default_position="right" },
{ key="y", app="Iina", window_default_position="bottom"},
-- o: up
{ key="p", app="Music" },
-- [: previous track
-- ]: next track
-- a: left
-- s: down
-- d: right
{ key="f", app="Finder" },
{ key="g", app="Fork" },
{ key="h", app="Safari" },
-- k: left
-- l: down
-- ;: right
-- ': volume up
-- return: Day One
-- z: ↩
{ key="z", specific_function="press_return" },
-- x: home
-- c: end
{ key="v", app="Yandex" },
{ key="b", app="iTerm" },
{ key="n", app="Visual Studio Code" },
-- ,: home
-- .: end
-- /: volume down
}},
{ modifier={"hyper", "alt"}, chords={
-- ╭—————╮__HYPER_LAYER____╭—————┬————————┬————————┬———————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │     │     │     │     │    ⚠️  │        │       │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┴—┬——————┴—┬—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │     │  ↑  │     │     │   ⚠️   │        │       │     │  ↑  │     │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬-—-———┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │     │   ⚠️    │       │       │  ←  │  ↓  │  →  │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬——————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │     │     │     │     │   ⚠️    │        │       │    │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴————————┴————————┴———————┼—————┴┬————┴————┬┴————————————————╯
-- │        │🟢🟢🟢│  ⚠️  │           ⚠️                        │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————————————┴——————┴—————————╯
--
-- ↑: move line up
--    YouTube - skip 5sec
-- ←: jump a word to the left
--    YouTube - skip 5sec backwards
-- ↓: move line down
--    YouTube - previous chapter in current video
-- →: jump a word to the right
--    YouTube - next chapter in current video
--
}},
{ modifier={"hyper", "left_command"}, chords={
-- ╭—————╮__HYPER_LAYER____╭—————┬————————┬————————┬———————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │     │     │     │     │    ⚠️  │        │       │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┴—┬——————┴—┬—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │     │  ↑  │     │     │   ⚠️   │        │       │     │  ↑  │     │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬-—-———┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │     │   ⚠️    │       │       │  ←  │  ↓  │  →  │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬——————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │     │     │     │     │   ⚠️    │        │       │    │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴————————┴————————┴———————┼—————┴┬————┴————┬┴————————————————╯
-- │   ⚠️   │ ⚠️  │🟢🟢🟢  │                                     │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————————————┴——————┴—————————╯
--
-- ↑: go to the begining of the document
-- ↓: go to the end of the document
-- ←: home
-- →: end
--
}},
{ modifier={"left_command", "left_shift"}, chords={
-- ╭—————╮_CMD_SHIFT_LAYER_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │  📝 │Shotr│Shotr│Shotr│    │     │     │     │     │     │     │     │     ℝ  │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │    │    │  ℝ  │  ℝ  │  ℝ  │     │     │     │     │    │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  📁 │  📁  │ 📝📁 │ 📝ℝ │     │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │ 🟢🟢🟢   │ReDO│ 📝  │ 📝📁 │     │     │     │     │     │     │  ℝ  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │🟢🟢🟢 │                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
{ key="1", app="Visual Studio Code" },
-- 2: Shotr - OCR from screen
-- 3: Shotr - save screenshot of window ( native screenshot replaced)
-- 4: Shotr - start getting screenshot ( native screenshot replaced)
-- 5:   - record video from screen
-- F12: ℝ - hide all panels
-- ⌫: ℝ - go to last edit
-- delete: 📁 - empty trashcan
-- q:  - quit all applications
-- w:  - close window
-- e: ℝ - recent locations popup
--    🌐 - opened tabs dialog
-- r: ℝ - replace in files
--    📁 - go to AirDrop
-- t:  - reopen closed tab
--    📁 - switch tabs bar visibility
-- p: Fork - open Push dialog
-- a: 📁 - go to Applications
-- s: 📁 - go to Shared
-- d: 📁 - go to Desktop
--    Fork - revert file changes
--    📝 - show debug callstack
-- f: ℝ - search in files
--    Fork - open Fetch dialog,
--    📁 - go to Recent
--    Telegram — focus global search
-- g: 📁 - go to GoTo dialog
-- h: 📁 - go to $HOME
--    Fork - save Stash
-- j:
-- k: 📁 - go to Network
-- l: Fork - open Pull dialog
-- b: Fork - open Create Branch dialog
-- ;:
-- ':
-- z:  - redo
-- x: 📝 - open Extensions
-- c: 📁 - go to Computer
--    📝 - open Terminal
-- n: 🌐 - open new Private Window
--    📁 - create New folder
--    Music — create new playlist from selection
-- /: ℝ - comment
--
}},
{ modifier={"left_command", "alt"}, chords={
-- ╭—————╮__CMD_ALT_LAYER___╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │    │Fork  │Fork │Fork │     │    │     │     │     │     │     │     │     │        │
-- ├—————┴—┬————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │      │     │Music│  ℝ  │Fork │     │     │     │     │     │     │     │      │
-- ├———————┴┬—————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │      │     │    │  ℝ  │     │    │     │     │     │     │     │     │     │
-- ├————————┴┬—————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │      │     │    │  ℝ  │  ℝ  │  ℝ  │  ℝ  │     │     │     │                │
-- ├————————┬┴—————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │🟢🟢🟢 │🟢🟢🟢 │                            │      │         │
-- ╰————————┴——————┴——————┴—————————————————————————————┴——————┴—————————╯
-- esc:  - force quit current app
-- F5:  — show accessibility controls
-- 1: Fork — Show commit details
-- 2: Fork — Show commit changes
-- 3: Fork — Show commit filetree
-- e: Music - show equalizer
-- r: ℝ - resume running
-- t: Fork - hide/search toolbar
-- u: Music — Show playing next queue
-- i: 🌐 — Developer Tools
-- d:  - show/hide Dock
-- f: ℝ - extract field
--    Activity Monitor — filter processes
-- h:  - hide all other windows
-- l: 📁 — downloads
--    🌐 — downloads
-- c: ℝ - introduce constant
--    📁 — Copy file's path
-- v: ℝ - extract variable
--    📁 — move items here
-- b: ℝ - go to implementation
-- n: ℝ - inline
-- m: ℝ - extract method
-- space:  - open Finder and focus Search this Mac
-- →: Music — seek forward
--    📝 — go to next tab
-- ←: Music — seek backward
--    📝 — go to previous tab
}},
{ modifier={"left_command", "left_control"}, chords={
-- ╭—————╮__CONTROL_CMD_LAYER____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │    │     │  ℝ  │  ℝ  │     │     │     │     │     │     │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  ℝ  │    │    │    │     │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │     │  ℝ  │  ℝ  │     │     │     │     │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │     │🟢🟢🟢 │                            │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- q: logout
-- e: ℝ — Show list of tabs of current panel
-- r: ℝ — Rerun tests
-- a: ℝ — Show all affected files
--    Mail — archive message
-- f: toggle fullscreen of current app
-- g: ℝ — Select all occurances
-- s: 📁 — Toggle SideBar
--    ℝ — Toggle Sidebar
-- d:  - look up the selected word
-- x: ℝ — Scroll to Top
-- c: ℝ — Scroll to Bottom
-- space:  - emogies
}},
{ modifier= {"left_control", "left_shift"}, chords={
-- ╭—————╮__CONTROL_SHIFT_LAYER__╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │ActMa│  ℝ  │  ℝ  │  ℝ  │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │      │    │  ⌫  │ del │  ℝ  │     │     │     │     │     │    │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │    │     │  ℝ  │     │  ℝ🔄│     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │     │      │                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
{ key="escape", app="Activity Monitor" }, -- Like on Windows 📊
-- 1: ℝ — Toggle bookmark 1
-- 2: ℝ — Toggle bookmark 2
-- 3: ℝ — Toggle bookmark 3
-- tab:  - go to previous tab
-- q:   - log out with dialogs
-- w: backspace
-- e: delete
-- r: ℝ — Run Unit Tests
-- p: app - open private window
-- a:  - select line to the left
-- d: ℝ - Debug Unit Tests
-- g: ℝ🔄 - current file git history
-- h: ℝ - hierarchy
}},
{ modifier={"left_control", "alt"}, chords={
-- ╭—————╮__CONTROL_SHIFT_LAYER___╭————————┬——————┬————————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │Intrnal│BTooth│HeadPhnes│Scarlett│      │        │     │     │     │     │     │     │        │
-- ├—————┴—┬—————┴—┬————┴——┬——————┴—┬——————┴—┬————┴—┬——————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │ Music │Window^│        │WebStorm│      │        │     │info │     │     │     │     │      │
-- ├———————┴┬——————┴┬——————┴┬———————┴┬———————┴┬—————┴┬———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │Window←│Window↓│Window→ │        │GitHub│HamSpoon│     │     │     │     │     │     │     │
-- ├————————┴┬——————┴┬——————┴┬———————┴┬———————┴┬—————┴┬———————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │ toRu  │ XCode │Calendar│YouTube │      │        │     │     │     │     │                │
-- ├————————┬┴——————┬┴———————┼————————┴————————┴——————┴————————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │ 🟢🟢🟢 │        │                                       │      │         │
-- ╰————————┴———————┴————————┴———————————————————————————————————————┴——————┴—————————╯
{ key="1", specific_function="audio.internal"},
{ key="2", specific_function="audio.bt"},
{ key="3", specific_function="audio.marshall"},
{ key="4", specific_function="audio.external"},
{ key="tab", specific_function="translate_to_english"},
{ key="q", app="Music"},
{ key="w", specific_function="window.fullscreen"},
{ key="r", app="WebStorm"},
{ key="i", specific_function="info.show_shortcuts"},
{ key="a", specific_function="window.left"},
{ key="s", specific_function="window.set_all_to_default" },
{ key="d", specific_function="window.right" },
{ key="z", specific_function="translate_to_russian"},
{ key="g", specific_function="browser_git"},
{ key="h", app="Hammerspoon", window_default_position="right"},
{ key="x", app="XCode" },
{ key="v", specific_function="browser_youtube" },
{ key="y", specific_function="youtube_stream" },
{ key="left", specific_function="window.left"},
{ key="right", specific_function="window.right"},
{ key="up", specific_function="window.fullscreen"},
{ key="down", specific_function="window.set_all_to_default"},
}},
{ modifier={"left_control", "alt", "left_command"}, chords={
-- ╭—————╮_CONTROL_ALT_COMMAND_LAYER___╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │     │     │     │     │     │     │     │     │  ℝ  │     │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  ⚠️  │    │     │     │     │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │     │     │     │     │     │     │     │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │🟢🟢🟢│ 🟢🟢🟢│                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- o: ℝ - Recent projects popup
-- c: itsical 📅 Show Calendar
-- a: ⚠️
}},
{ modifier={"left_shift", "alt", "left_command"}, chords={
-- ╭—————╮__SHIFT_ALT_COMMAND_LAYER____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⚠️   │     │     │     │     │     │     │     │     │     │     │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │🟢🟢🟢│ 🟢🟢🟢│                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
}},
{ modifier={"left_shift", "left_control", "left_command"}, chords={
-- ╭—————╮_SHIFT_CONTROL_COMMAND_LAYER_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │ ⚠️  │     │     │     │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │ ⚠️    │     │     │     │     │     │     │     │     │     │     │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ ⚠️     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │  ℝ  │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │     │ 🟢🟢🟢│                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- m: ℝ - New project window
-- tab: ⚠️
}},
{ modifier={"hyper", "left_control", "left_command"}, chords={
-- ╭—————╮_SHIFT_CONTROL_COMMAND_LAYER_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │ ⚠️  │     │     │     │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │ ⚠️    │     │  ↑  │     │     │     │     │     │     │     │     │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ 🟢🟢🟢  │     │  ↓  │     │     │     │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │     │     │     │     │     │     │  ℝ  │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │     │ 🟢🟢🟢│                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- ↑ — ℝ — navigate to up method
-- ↓ — ℝ — navigate to down method
}},
{ modifier={"left_shift", "left_control", "alt"}, chords={
-- ╭—————╮_SHIFT_CONTROL_COMMAND_LAYER_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │ ⚠️  │     │     │     │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │ ⚠️    │     │  ⌫  │ del │     │     │     │     │     │     │     │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ ⚠️     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │🟢🟢🟢│      │                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- tab: ⚠️
-- w: remove word to the left (alt + backspace)
-- e: remove word to the right (alt + delete)
}}}

function unsubscribe()
    if hideKSheetShortCut then
        hideKSheetShortCut:disable();
   end
end

local appSpecificHotkeys = {
    ["Fork"] = {
        { from = {"cmd", "shift"}, key = "e", to = {"cmd", "shift"}, target_key = "l" }
    },
    ["*"] = {
        { from = {"ctrl", "alt", "cmd"}, key = "x", to = {"cmd"}, target_key = "[" },
        { from = {"ctrl", "alt", "cmd"}, key = "c", to = {"cmd"}, target_key = "]" }
    }
}

local spoonPath = debug.getinfo(1, "S").source:match("@(.*/)")
local appSpecificHelper = dofile(spoonPath .. "app_specific_hotkeys.lua")

function obj:init()

    hideKSheetShortCut = hs.hotkey.new({}, "escape", function()
        spoon.KSheet:hide()
        ksheet = not ksheet
        unsubscribe()
    end)

    appSpecificHelper.init(appSpecificHotkeys)

    for _, layer in pairs(layers_list) do
        for _, chord_row in pairs(layer.chords) do
            if chord_row.app then
                hs.hotkey.bind(layer.modifier, chord_row.key, function()

                    print("Hotkey triggered: " .. table.concat(layer.modifier, "+") .. "+" .. chord_row.key .. " → " .. chord_row.app)

                    local found = hs.application.find(chord_row.app)
                    local app = found

                    if found and tostring(found):match("hs.window:") then
                        app = found:application()
                        print("Found window, getting application: " .. tostring(app))
                    end

                    if not app or (app and app.isHidden and app:isHidden()) then
                        print("Launching/focusing app: " .. chord_row.app)
                        hs.application.launchOrFocus(chord_row.app)
                    elseif hs.application.frontmostApplication() ~= app then
                        print("Activating app: " .. chord_row.app)
                        if app and app.activate then
                            hs.application.launchOrFocus(chord_row.app)
                        end
                    else
                        print("Hiding app: " .. chord_row.app)
                        if app and app.hide then
                            app:hide()
                        end
                    end
                end)
                if chord_row.window_default_position then
                    if chord_row.window_default_position == "right" then
                        spoon.Windows:add_right_window_type_app(chord_row.app)
                    elseif chord_row.window_default_position == "bottom" then
                        spoon.Windows:add_bottom_window_type_app(chord_row.app)
                    end
                end
            elseif chord_row.sendKey then
                hs.hotkey.bind(layer.modifier, chord_row.key, function()
                    hs.eventtap.keyStrokes(chord_row.sendKey)
                end)
            elseif chord_row.specific_function then
                if chord_row.specific_function == "window.left" then
                    spoon.Windows:bind_window_left(layer.modifier, chord_row.key)
                elseif chord_row.specific_function == "window.right" then
                    spoon.Windows:bind_window_right(layer.modifier, chord_row.key)
                elseif chord_row.specific_function == "window.fullscreen" then
                    spoon.Windows:bind_window_fullscreen(layer.modifier, chord_row.key)
                elseif chord_row.specific_function == "window.set_all_to_default" then
                    spoon.Windows:bind_all_windows_to_default(layer.modifier, chord_row.key)
                elseif chord_row.specific_function == "android.show_all" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        for _, window in ipairs(hs.window.allWindows()) do
                            local window_title = window:title()
                            local app_title = window:application():title()
                            for _, app in ipairs(chord_row.layers_list) do
                                if app_title == app or string.find(window_title, app) then
                                    window:focus()
                                end
                            end
                        end
                    end)
                elseif chord_row.specific_function == "info.show_shortcuts" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        if ksheet then
                            spoon.KSheet:hide()
                        else
                            hideKSheetShortCut:enable();
                            spoon.KSheet:show()
                        end

                        ksheet = not ksheet
                    end)
                elseif chord_row.specific_function == "set_russian_language" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        hs.keycodes.setLayout("Russian – Ilya Birman Typography")
                    end)
                elseif chord_row.specific_function == "set_english_language" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        hs.keycodes.setLayout("English - Ilya Birman Typography")
                    end)
                elseif chord_row.specific_function == "translate_to_russian" then
                    spoon.PopupTranslateSelection:bindHotkeys({
                        translate_to_ru = {layer.modifier, chord_row.key},
                    })
                elseif chord_row.specific_function == "translate_to_english" then
                    spoon.PopupTranslateSelection:bindHotkeys({
                        translate_to_en = {layer.modifier, chord_row.key},
                    })
                elseif chord_row.specific_function == "translate_to_greek" then
                    spoon.PopupTranslateSelection:bindHotkeys({
                        translate_to_el = {layer.modifier, chord_row.key},
                    })
                elseif chord_row.specific_function == "audio.internal" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        spoon.AudioSwitcher:switchToInternal()
                    end)
                elseif chord_row.specific_function == "audio.external" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        spoon.AudioSwitcher:switchToExternal()
                    end)
                elseif chord_row.specific_function == "audio.marshall" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        spoon.AudioSwitcher:switchToMarshall()
                    end)
                elseif chord_row.specific_function == "audio.bt" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        spoon.AudioSwitcher:switchToBT()
                    end)
                elseif chord_row.specific_function == "show_youtrack" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        spoon.YouTrackTicket:toggle()
                    end)
                elseif chord_row.specific_function == "show_youtrack_tasks" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        spoon.YouTrackTasks:toggle()
                    end)
                elseif chord_row.specific_function == "browser_git" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        spoon.BrowserTabOpener:openTab("github.com")
                    end)
                elseif chord_row.specific_function == "press_return" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        hs.eventtap.keyStroke({}, "return")
                    end)
                elseif chord_row.specific_function == "browser_youtube" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        spoon.BrowserTabOpener:openTab("youtube.com")
                    end)
                elseif chord_row.specific_function == "youtube_stream" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        spoon.YouTubeStream:toggle()
                    end)
                end
            end
        end
    end
end

return obj
