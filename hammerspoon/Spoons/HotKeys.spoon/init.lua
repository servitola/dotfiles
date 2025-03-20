local obj={}

-- Keyboard layers described in this document:

-- 1. Main English Layer
-- 2. Main Russian Layer
-- 3. Main Greek Layer

-- 4. Shift + English Layer (⇧)
-- 5. Shift + Russian Layer (⇧)
-- 6. Shift + Greek Layer (⇧)

-- 7. Alt Layer (⌥) -- Ilya Birman's layout
-- 8. Alt + Shift Layer (⌥⇧) -- Ilya Birman's layout

-- 9. Command Layer (⌘)
-- 10. Control Layer (⌃)

-- 11. Hyper Layer (⌘⌃⌥⇧)

-- 12. Command + Shift Layer (⌘⇧)
-- 13. Command + Alt Layer (⌘⌥)
-- 14. Command + Control Layer (⌘⌃)
-- 15. Control + Shift Layer (⌃⇧)
-- 16. Control + Alt Layer (⌃⌥)

-- 17. Control + Alt + Command Layer (⌃⌥⌘)
-- 18. Shift + Alt + Command Layer (⇧⌥⌘)
-- 19. Shift + Control + Command Layer (⇧⌃⌘)
-- 20. Shift + Control + Alt (⇧⌃⌥)

hyper = { "right_command", "right_control", "right_option", "right_shift" }

-- Icons used:
--  -- MacOS or common
-- 🌐 -- Browser
-- ℝ -- Rider IDE
-- 📁 -- Finder
-- 🔄 -- Git
-- 📝 -- Windsurf (VSCode)

-- ⚠️ —— HARD TO PRESS, don't use

-- ⌘ -- Command Key
-- ⌥ -- Option/Alt Key
-- ⌃ -- Control Key
-- ⇧ -- Shift Key
-- ⌫ -- Backspace Key
-- ⇥ -- Tab Key

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
-- q: 🌐 Vim — Go Website Root
-- t: YouTube - Theatre mode
-- i: YouTube - Minimize video
-- ]: 🌐 Vim - Go Website Root
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
-- │  ~  │  !  │  @  │  #  │  $  │  %  │  ^  │  &  │  *  │  (  │  )  │  _  │  +  │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  Q  │  W  │  E  │  R  │  T  │  Y  │  U  │  I  │  O  │  P  │  {  │  }  │   ↩  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  A  │  S  │  D  │  F  │  G  │  H  │  J  │  K  │  L  │  :  │  "  │  |  │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │  🟢🟢🟢  │  Z  │  X  │  C  │  V  │  B  │  N  │  M  │  <  │  >  │  ?  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │      │                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯

-- tab: selected text — move block left
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
-- │  Ё  │  !  │  "  │  №  │  ;  │  %  │  :  │  ?  │  *  │  (  │  )  │  _  │  +  │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  Й  │  Ц  │  У  │  К  │  Е  │  Н  │  Г  │  Ш  │  Щ  │  З  │  Х  │  Ъ  │   ↩  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  Ф  │  Ы  │  В  │  А  │  П  │  Р  │  О  │  Л  │  Д  │  Ж  │  Э  │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │  🟢🟢🟢  │  Я  │  Ч  │  С  │  М  │  И  │  Т  │  Ь  │  Б  │  Ю  │  ,  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │      │                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯

-- ╭—————╮__SHIFT_LAYER_GR_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │  ±  │  !  │  @  │  #  │  $  │  %  │  ^  │  &  │  *  │  (  │  )  │  _  │  +  │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  :  │  ΅  │  Ε  │  Ρ  │  Τ  │  Υ  │  Θ  │  Ι  │  Ο  │  Π  │  {  │  }  │   ↩  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  Α  │  Σ  │  Δ  │  Φ  │  Γ  │  Η  │  Ξ  │  Κ  │  Λ  │  ¨  │  "  │  |  │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │  🟢🟢🟢  │  Ζ  │  Χ  │  Ψ  │  Ω  │  Β  │  Ν  │  Μ  │  <  │  >  │  ?  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │      │                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯

{ modifier=alt, chords={
-- ╭—————╮____ALT_LAYER____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │  `  │  ¹  │  ²  │  ³  │  $  │  ‰  │  ↑  │     │  ∞  │  ←  │  →  │  —  │  ≠  │       │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │  ⇥    │  ·  │  ✓  │  €  │  ®  │  ™  │  ѣ  │  ѵ  │  і  │  ѳ  │  ′  │  [  │  ]  │   ℝ  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  ≈  │  §  │  °  │  £  │     │  ₽  │  „  │  “  │  ”  │  ‘  │  ’  │  |  │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │     │  ×  │  ©  │  ↓  │  ß  │     │  −  │  «  │  »  │  …  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │🟢🟢🟢│      │    NON-BREAKABLE SPACE      │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- ⌫:  — remove word to the left
-- tab: switch the app windows with AltTab app
-- ↩: ℝ — Fix Suggestion popup
-- \: Copilot Suggestion
-- space: Music — Start Genious Shuffle
-- ↑: move line up
-- ↓: jump a word to the left
-- ←: move line down
-- →: jump a word to the right
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
-- │       │❌❌❌│  ✖  │  ℝ  │  ℝ  │  ℝ  │    │BrHist│  ℝ  │    │🖨️🖨️🖨️│     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬—————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │    │💾💾💾│    │🔎🔎🔎│  ℝ🔄│  ℝ  │     │    │     │  ℝ  │     │     │     │
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
-- q:  - close current app
-- w:  - close current tab
-- e: ℝ - recent files dialog
--    Telegram — toggle camera
-- r: ℝ - replace in current file
--    🌐 - refresh page
--    Telegram — record audio/video message
-- t:  - new tab
--    Telegram — toggle screen sharing
-- y: app - show all history
-- i: ℝ - show Codeium Command popup
--    Activity Manager — Inspect process
-- o:  - open file
-- p:  - print
-- [: ℝ - navigate back
--    📁 — navigate back
--    🌐 — navigate back
-- ]: ℝ - navigate forward
--    📁 — navigate forward
--    🌐 — navigate forward
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
-- k: Telegram — Focus search
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
-- │     │     │     │    │     │    │    │     │  ℝ  │     │     │     │     │        │
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
-- │       │PgUp │  ↑  │PhDn │  ℝ  │Telegram│YT New  │Torrent│     │  ↑  │Music│ ⏮  │  ⏭  │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬-—-———┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │  📁  │Fork🔄  │ Safari │YTTasks│  ←  │  ↓  │  →  │ 🔊  │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬——————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │  ↩  │home │ end │ 🌐  │ iTerm2 │Windsurf│ IINA  │home │ end │ 🔉   │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴————————┴————————┴———————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │      │        play/stop                 │      │         │
-- ╰————————┴—————┴——————┴——————————————————————————————————┴——————┴—————————╯
-- karabiner escape - tilda/ё
-- 1: F1
-- 2: F2
-- 3: F3
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
-- q: pageUp
-- w: up
-- e: pagedown
{ key="r", app="Rider" },
{ key="t", app="Telegram", window_default_position="right" },
{ key="y", specific_function="show_youtrack" },
{ key="u", app="Transmission", window_default_position="right" },
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
{ key="j", specific_function="show_youtrack_tasks" },
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
{ key="n", app="Windsurf - Next" },
{ key="m", app="Iina", window_default_position="bottom"},
-- ,: home
-- .: end
-- /: volume down
}},
{ modifier={"left_command", "left_shift"}, chords={
-- ╭—————╮_CMD_SHIFT_LAYER_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │     │     │     │Shotr│    │     │     │     │     │     │     │     │     ℝ  │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │    │    │  ℝ  │  ℝ  │  ℝ  │     │     │     │     │    │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │  📁 │  📁  │  📁 │  ℝ  │     │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │ 🟢🟢🟢   │    │     │     │     │     │     │     │     │     │  ℝ  │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │     │🟢🟢🟢 │                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- 4: Shotr - start getting screenshot
-- 5:   - record video from screen
-- F12: ℝ - hide all panels
-- ⌫: ℝ - go to last edit
-- delete: 📁 - empty trashcan
-- q:  - quit all applications
-- w:  - close window
-- e: ℝ - recent locations popup
--    🌐 - opened tabs dialog
-- r: ℝ - replace in files
--    📁 - Go to AirDrop
-- t:  - reopen closed tab
--    📁 - switch tabs bar visibility
-- p: Fork - open Push dialog
-- a: 📁 - Go to Applications
-- s: 📁 - Go to Shared
-- d: 📁 - Go to Desktop
-- f: ℝ - search in files
--    Fork - open Fetch dialog,
--    📁 - Go to Recent
--    Telegram — focus global search
-- g: 📁 - Go to GoTo dialog
-- h: 📁 - Go to $HOME
-- j:
-- k: 📁 - Got to Network
-- l: Fork - open Pull dialog
-- b: Fork - open Create Branch dialog
-- ;:
-- ':
-- z:  - redo
-- x:
-- c: 📁 - Go to Computer
-- n: 🌐 - Open new Private Window
--    📁 - Create New folder
--    Music — Create new playlist from selection
-- /: ℝ - comment
--
}},
{ modifier={"left_command", "alt"}, chords={
-- ╭—————╮__CMD_ALT_LAYER__╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │Fork │Fork │Fork │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │     │     │     │  ℝ  │     │     │     │     │     │     │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │     │     │    │  ℝ  │     │    │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │     │     │    │  ℝ  │  ℝ  │  ℝ  │  ℝ  │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │        │🟢🟢🟢│🟢🟢🟢 │                            │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- esc:  - force quit current app
-- F5:  — show accessibility controls
-- 1: Fork — Show commit details
-- 2: Fork — Show commit changes
-- 3: Fork — Show commit filetree
-- r: ℝ - resume running
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
-- ←: Music — seek backward
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
-- │ActMa│     │     │     │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │      │     │     │     │  ℝ  │     │     │     │     │     │    │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │     │     │  ℝ  │     │  ℝ🔄│     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │     │      │                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
{ key="escape", app="Activity Monitor" }, -- Like on Windows 📊
-- tab:  - go to previous tab
-- q:  - log out with dialogs
-- r: ℝ — Run Unit Tests
-- p: app - open private window
-- d: ℝ - Debug Unit Tests
-- g: ℝ🔄 - current file git history
-- h: ℝ - hierarchy
}},
{ modifier={"left_control", "alt"}, chords={
-- ╭—————╮__CONTROL_SHIFT_LAYER___╭————————┬——————┬————————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │       │     │          │        │      │        │     │     │     │     │     │     │        │
-- ├—————┴—┬—————┴—┬———┴———┬——————┴—┬——————┴—┬————┴—┬——————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │BTooth │Window^│Scarlet │        │      │        │     │     │     │     │     │     │      │
-- ├———————┴┬——————┴┬——————┴┬———————┴┬———————┴┬—————┴┬———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │        │Window←│Window↓│Window→ │Launcher│GitHub│HamSpoon│     │     │     │     │     │     │     │
-- ├————————┴┬——————┴┬——————┴┬———————┴┬———————┴┬—————┴┬———————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │       │ XCode │Calendar│YouTube │      │        │     │     │     │     │                │
-- ├————————┬┴——————┬┴———————┼————————┴————————┴——————┴————————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │ 🟢🟢🟢 │        │                                       │      │         │
-- ╰————————┴———————┴————————┴———————————————————————————————————————┴——————┴—————————╯
{ key="tab", specific_function="translate_to_english"},
{ key="q", specific_function="audio.bt"},
{ key="w", specific_function="window.fullscreen"},
{ key="e", specific_function="audio.external"},
{ key="i", specific_function="info.show_shortcuts"},
{ key="a", specific_function="window.left"},
{ key="s", specific_function="window.set_all_to_default" },
{ key="d", specific_function="window.right" },
{ key="f", app="LaunchPad" },
{ key="z", specific_function="translate_to_russian"},
{ key="g", specific_function="browser_git"},
{ key="h", app="Hammerspoon", window_default_position="right"},
{ key="x", app="XCode" },
{ key="c", app=""},
{ key="v", specific_function="browser_youtube" },
{ key="b", specific_function="audio.marshall"},
{ key="m", specific_function="audio.internal"},
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
-- │        │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │         │     │     │     │     │     │     │     │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │🟢🟢🟢│ 🟢🟢🟢│                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
-- o: ℝ - Recent projects popup
-- c: itsical 📅 Show Calendar
{ key="d", specific_function="press.delete"},
{ key="f", specific_function="press.backspace"}
}},
{ modifier={"left_shift", "alt", "left_command"}, chords={
-- ╭—————╮__SHIFT_ALT_COMMAND_LAYER____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │       │     │     │     │     │     │     │     │     │     │     │     │     │      │
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
}},
{ modifier={"left_shift", "left_control", "alt"}, chords={
-- ╭—————╮_SHIFT_CONTROL_COMMAND_LAYER_╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬————————╮
-- │ ⚠️  │     │     │     │     │     │     │     │     │     │     │     │     │        │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┤
-- │ ⚠️    │     │     │     │     │     │     │     │     │     │     │     │     │      │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮     │
-- │ ⚠️     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴—————┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │                │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴————┬┴————————————————╯
-- │ 🟢🟢🟢  │🟢🟢🟢│      │                             │      │         │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————————╯
}
}}

function unsubscribe()
    if hideKSheetShortCut then
        hideKSheetShortCut:disable();
   end
end

function obj:init()

    hideKSheetShortCut = hs.hotkey.new({}, "escape", function()
        spoon.KSheet:hide()
        ksheet = not ksheet
        unsubscribe()
    end)

    for _, layer in pairs(layers_list) do
        for _, chord_row in pairs(layer.chords) do
            if chord_row.app then
                hs.hotkey.bind(layer.modifier, chord_row.key, function()
                    local app = hs.application.find(chord_row.app)
                    if not app or app == nil or app:isHidden() then
                        hs.application.launchOrFocus(chord_row.app)
                    elseif hs.application.frontmostApplication() ~= app then
                        app:activate()
                    else
                        app:hide()
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
                elseif chord_row.specific_function == "press.backspace" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                      hs.eventtap.keyStroke({}, "forwarddelete")
                    end)
                elseif chord_row.specific_function == "press.delete" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        hs.eventtap.keyStroke({}, "delete")
                    end)
                elseif chord_row.specific_function == "browser_youtube" then
                    hs.hotkey.bind(layer.modifier, chord_row.key, function()
                        spoon.BrowserTabOpener:openTab("youtube.com")
                    end)
                end
            end
        end
    end
end

return obj
