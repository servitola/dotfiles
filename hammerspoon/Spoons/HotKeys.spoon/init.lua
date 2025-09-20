local obj={}

-- Hyper is Caps Lock (⇪) remapped to Hyper in Karabiner-Elements
-- Keyboard layers described in this document:

-- 1. English
-- 2. Russian
-- 3. Greek

-- 4. Shift + English (⇧)
-- 5. Shift + Russian (⇧)
-- 6. Shift + Greek (⇧)

-- 7. Alt (⌥) -- Ilya Birman's layout
-- 8. Alt + Shift (⌥⇧) -- Ilya Birman's layout

-- 9. Command (⌘)
-- 10. Control (⌃)
-- 11. Hyper (⇪)

-- 12. Hyper + Alt (⇪ ⌥)
-- 13. Hyper + Command (⇪ ⌘)
-- 14. Hyper + Control (⇪ ⌃)
-- 15. Hyper + Shift (⇪ ⇧)
-- 16. Command + Shift (⌘ ⇧)
-- 17. Command + Alt (⌘ ⌥)
-- 18. Command + Control (⌘ ⌃)
-- 19. Control + Shift (⌃ ⇧)
-- 20. Control + Alt (⌃ ⌥)

-- 21. Hyper + Alt + Command (⇪ ⌥ ⌘)
-- 22. Hyper + Alt + Control (⇪ ⌥ ⌃)
-- 23. Hyper + Alt + Shift (⇪ ⌥ ⇧)
-- 24. Hyper + Command + Control (⇪ ⌘ ⌃)
-- 25. Hyper + Command + Shift (⇪ ⇧ ⌘)
-- 26. Hyper + Shift + Control (⇪ ⇧ ⌃)
-- 27. Control + Alt + Command (⌃ ⌥ ⌘)
-- 28. Control + Alt + Shift (⌃ ⌥ ⇧)
-- 29. Control + Shift + Command (⌃ ⇧ ⌘)
-- 30. Shift + Alt + Command (⇧ ⌥ ⌘)

hyper = { "right_command", "right_control", "right_option", "right_shift" }

-- Icons used:
--  — MacOS or common
-- 🌐 — Browser
-- ℝ — Rider IDE
-- 📁 — Finder
-- 🔄 — Git
-- 📝 — VSCode
-- 🔗 — Many apps but not macos itself

-- ⚠️ —— HARD TO PRESS, don't use

-- ⇪ -- Hyper (Caps Lock)
-- ⌘ -- Command
-- ⌥ -- Option/Alt
-- ⌃ -- Control
-- ⇧ -- Shift
-- ⌫ -- Backspace
-- ⇥ -- Tab
-- ↩ -- Return/Enter
-- ␣ -- Space
-- ⎋ -- Escape

layers_list =
{

-- ╭—————╮__1.ENGLISH______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬———————╮
-- │  `  │  1  │  2  │  3  │  4  │  5  │  6  │  7  │  8  │  9  │  0  │  -  │  =  │    ⌫  │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬—————┤
-- │  ⇥    │  q  │  w  │  e  │  r  │  t  │  y  │  u  │  i  │  o  │  p  │  [  │  ]  │  ↩  │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮    │
-- │  ⇪     │  a  │  s  │  d  │  f  │  g  │  h  │  j  │  k  │  l  │  ;  │  '  │  \  │    │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴————┤
-- │  ⇧      │  z  │  x  │  c  │  v  │  b  │  n  │  m  │  ,  │  .  │  /  │            ⇧  │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴———————————————╯
-- │  ⌃     │  ⌥  │   ⌘  │             ␣               │  ⌘   │  ⌥  │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- 0: YouTube — Navigate to 0% of video
-- 1: YouTube — Navigate to 10% of video
-- 2: YouTube — Navigate to 20% of video
-- 3: YouTube — Navigate to 30% of video
-- 4: YouTube — Navigate to 40% of video
-- 5: YouTube — Navigate to 50% of video
-- 6: YouTube — Navigate to 60% of video
-- 7: YouTube — Navigate to 70% of video
-- 8: YouTube — Navigate to 80% of video
-- 9: YouTube — Navigate to 90% of video
-- t: YouTube — Theatre mode
-- i: YouTube — Minimize video
-- ↩: Music — Play selected song from beginning
-- f: 🌐 — Go Full Screen Video
-- g + g: 🌐 Vim — Go Window Top
-- j: YouTube — 10sec back
-- k: YouTube — play/pause
-- l: YouTube — 10sec forward
-- z: 🌐 Vim — Mark Links
-- x: 🌐 Vim — Focus text input
-- c: YouTube — subtitles
-- m: 🌐 Vim — Mute Tab
-- ␣: 📁 — Show Preview
--    Music — Play/Pause
--    Fork — Show changes Preview
-- double ⇧: ℝ — Command Pallette
-- ↑: Telegram — edit last message
--    Iina — sound up 5%
-- ↓: Iina — sound down 5%
-- →: YouTube — seek forward 5sec
--    Iina — seek forward 5sec
-- ←: YouTube — seek backward 5sec
--    Iina — seek backward 5sec

-- ╭—————╮__2.RUSSIAN______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬——————╮
-- │  ё  │  1  │  2  │  3  │  4  │  5  │  6  │  7  │  8  │  9  │  0  │  -  │  =  │    ⌫ │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
-- │  ⇥    │  й  │  ц  │  у  │  к  │  е  │  н  │  г  │  ш  │  щ  │  з  │  х  │  ъ  │  ↩ │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
-- │  ⇪     │  ф  │  ы  │  в  │  а  │  п  │  р  │  о  │  л  │  д  │  ж  │  э  │  \  │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
-- │  ⇧      │  я  │  ч  │  с  │  м  │  и  │  т  │  ь  │  б  │  ю  │  .  │            ⇧ │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴——————————————╯
-- │  ⌃     │  ⌥  │   ⌘  │             ␣               │  ⌘   │  ⌥  │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯

-- ╭—————╮__3.GREEK________╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬——————╮
-- │  §  │  1  │  2  │  3  │  4  │  5  │  6  │  7  │  8  │  9  │  0  │  -  │  =  │    ⌫ │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
-- │  ⇥    │  ;  │  ς  │  ε  │  ρ  │  τ  │  υ  │  θ  │  ι  │  ο  │  π  │  [  │  ]  │  ↩ │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
-- │  ⇪     │  α  │  σ  │  δ  │  φ  │  γ  │  η  │  ξ  │  κ  │  λ  │  ΄  │  '  │  \  │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
-- │  ⇧      │  ζ  │  χ  │  ψ  │  ω  │  β  │  ν  │  μ  │  ,  │  .  │  /  │            ⇧ │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴——————————————╯
-- │  ⌃     │  ⌥  │   ⌘  │             ␣               │  ⌘   │  ⌥  │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯

-- ╭—————╮__4.SHIFT_ENGLISH______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬——————╮
-- │  ~  │  !  │  @  │  #  │  $  │  %  │  ^  │  &  │  *  │  (  │  )  │  _  │  +  │      │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
-- │  ⇥    │  Q  │  W  │  E  │  R  │  T  │  Y  │  U  │  I  │  O  │  P  │  {  │  }  │  ↩ │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
-- │        │  A  │  S  │  D  │  F  │  G  │  H  │  J  │  K  │  L  │  :  │  "  │  |  │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
-- │  🟢🟢🟢  │  Z  │  X  │  C  │  V  │  B  │  N  │  M  │  <  │  >  │  ?  │              │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴——————————————╯
-- │        │     │      │             ␣               │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- ⇥: select previous element, or move text block left
-- Q: 🌐 Vim — go website root
-- P: YouTube — previous video
-- G: 🌐 Vim — go window bottom
-- C: 🌐 Vim — copy current URL
-- N: YouTube — next video
-- <: YouTube — speed down
-- >: YouTube — speed up

-- ╭—————╮__5.SHIFT_RUSSIAN______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬——————╮
-- │  Ё  │  !  │  "  │  №  │  ;  │  %  │  :  │  ?  │  *  │  (  │  )  │  _  │  +  │      │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
-- │  ⇥    │  Й  │  Ц  │  У  │  К  │  Е  │  Н  │  Г  │  Ш  │  Щ  │  З  │  Х  │  Ъ  │  ↩ │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
-- │        │  Ф  │  Ы  │  В  │  А  │  П  │  Р  │  О  │  Л  │  Д  │  Ж  │  Э  │     │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
-- │  🟢🟢🟢  │  Я  │  Ч  │  С  │  М  │  И  │  Т  │  Ь  │  Б  │  Ю  │  ,  │              │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴——————————————╯
-- │        │     │      │           ␣                 │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯

-- ╭—————╮__6.SHIFT_GREEK__╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬——————╮
-- │  ±  │  !  │  @  │  #  │  $  │  %  │  ^  │  &  │  *  │  (  │  )  │  _  │  +  │      │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
-- │  ⇥    │  :  │  ΅  │  Ε  │  Ρ  │  Τ  │  Υ  │  Θ  │  Ι  │  Ο  │  Π  │  {  │  }  │  ↩ │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
-- │        │  Α  │  Σ  │  Δ  │  Φ  │  Γ  │  Η  │  Ξ  │  Κ  │  Λ  │  ¨  │  "  │  |  │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
-- │  🟢🟢🟢  │  Ζ  │  Χ  │  Ψ  │  Ω  │  Β  │  Ν  │  Μ  │  <  │  >  │  ?  │              │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴——————————————╯
-- │        │     │      │            ␣                │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯

{ modifier=alt, chords={
-- ╭—————╮__7.ALT____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬——————╮
-- │  `  │  ¹  │  ²  │  ³  │  $  │  ‰  │  ↑  │     │  ∞  │  ←  │  →  │  —  │  ≠  │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
-- │  ⇥    │  ·  │  ✓  │  €  │  ®  │  ™  │  ѣ  │  ѵ  │  і  │  ѳ  │  ′  │  [  │  ]  │  ℝ │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
-- │        │  ≈  │  §  │  °  │  £  │     │  ₽  │  „  │  “  │  ”  │  ‘  │  ’  │  |  │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
-- │         │ 📝  │  ×  │  ©  │  ↓  │  ß  │     │  −  │  «  │  »  │  …  │              │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴——————————————╯
-- │        │🟢🟢🟢│      │    NON-BREAKABLE SPACE      │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- ⌫:  — remove word to the left
-- ⇥: switch the app windows with AltTab app
-- ↩: ℝ — show intention actions and quick-fixes popup
--    🌐 — open address in new tab
-- \: Copilot Suggestion
-- z: 📝 — toggle wordwrap
-- ␣: Music — Start Genious Shuffle
}},
{ modifier={"alt", "left_shift"}, chords={
-- ╭—————╮__8.ALT_SHIFT____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │  `  │  ¡  │ ¹⁄₂ │ ¹⁄₃ │ ¹⁄₄ │     │  ˆ  │  ¿  │     │  ‹  │  ›  │  –  │  ±  │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │  ˘  │  ⌃  │  ⌥  │  ˚  │  #  │  Ѣ  │  Ѵ  │     │  Ѳ  │  ″  │  {  │  }  │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │        │  ⌘  │  ⇧  │  ⌀  │     │    │  ˝  │     │  ‘  │  ’  │  ¨  │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │ 🟢🟢🟢   │  ¸  │  ·  │  ¢  │  ˇ  │  ẞ  │  ˜  │  •  │  „  │  “  │  ´  │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │        │🟢🟢🟢│      │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- double tap '/': set accent to previous letter (Birman's keyboard layout)
}},
{ modifier=left_command, chords={
-- ╭—————╮__9.CMD____╭—————┬—————┬—————┬—————┬——————┬—————┬—————┬—————┬—————┬—————┬———————╮
-- │    │  🔗 │  🔗  │  🔗 │  🔗 │  🔗  │  🔗 │  🔗  │  🔗  │  🔗 │  🔗 │  🌐ℝ │ 🌐ℝ │    ℝ  │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬—————┤
-- │      │    │  🔗 │ ℝ/T │  ℝ  │  ℝ  │    │BrHist│    │    │ 🖨️  │  ℝ🌐 │ ℝ🌐 │    │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬—————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮    │
-- │        │  🔗 │ 🔗  │ 🔗 │  🔎  │  ℝ🔄│  ℝ  │     │    │  📝 │  ℝ  │     │     │    │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬—————┴┬————┴┬————┴┬————┴┬————┴—————┴————┤
-- │         │    │    │    │    │  ℝ  │    │     │    │  ℝ  │  ℝ  │               │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴——————┼—————┴┬————┴┬————┴———————————————╯
-- │        │     │🟢🟢🟢 │         Raycast              │      │     │
-- ╰————————┴—————┴——————┴——————————————————————————————┴——————┴—————╯
-- swipe: changing zoom
-- `:  — switch between windows of current app
-- 1: ℝ — focus solution explorer
--    📁 — View as icons
--    🌐 — Open 1st tab
--    Fork — Focus changes window
--    Activity Manager — Focus main window
--    Telegram — focus 1st folder or chat
-- 2: ℝ — focus debug window
--    📁 — View as list
--    🌐 — Open 2nd tab
--    Fork — Focus All commits window
--    Activity Manager — Open/focus CPU usage window
--    Telegram — focus 2nd folder or chat
-- 3: ℝ — focus unit tests explorer
--    📁 — View in columns
--    🌐 — Open 3rd tab
--    Activity Manager — Open/focus CPU history window
--    Telegram — focus 3rd folder or chat
-- 4: ℝ — focus build window
--    📁 — View in gallery
--    🌐 — Open 4th tab
--    Activity Manager — Open/focus GPU history window
--    Telegram — focus 4th folder or chat
-- 5: ℝ — focus problems window
--    🌐 — Open 5th tab
--    Telegram — focus 5th folder or chat
-- 6: 🌐 — Open 6th tab
--    Telegram — focus 6th folder or chat
-- 7: 🌐 — Open 7th tab
--    Telegram — focus 7th folder or chat
-- 8: ℝ — focus logcat (custom)
--    🌐 — Open 8th tab
--    Telegram — focus 8th folder or chat
-- 9: 🌐 — Open Last tab
--    Telegram — focus 9th folder or chat
-- 0: 🌐 — Reset zoom
--    Telegram — focus Saved Messages
--    Music — Show/Hide Music window
--    Fork — navigate to HEAD
-- -: 🌐 — Zoom out
--    ℝ — collapse code block
-- =: 🌐 — Zoom in
--    ℝ — expand code block
-- ⌫: ℝ — delete line
--     dialog — choose Delete option
-- ⇥:  — switch between open windows
-- q:  — close current app
-- w:  — close current tab
-- e: ℝ — recent files dialog
--    Telegram — toggle camera
--    📝 — find with selection
-- r: ℝ — replace in current file
--    🌐 — refresh page
--    Telegram — record audio/video message
-- t:  — new tab
--    Telegram — toggle screen sharing
--    Music — visualizer
-- y: 🌐 — show all history
-- u: Telegram — toggle underline for text
--    Mail — toggle underline for text
-- i: Activity Manager — Inspect process
--    Music — show info about current song
--    Telegram — toggle italic for text
--    Mail — toggle italic for text
-- o:  — open file
--    Telegram — attach file
-- p:  — print
--    Fork — open Command palette search
--    ℝ — parameter info
-- [: ℝ — navigate back
--    📁 — navigate back
--    🌐 — navigate back
-- ]: ℝ — navigate forward
--    📁 — navigate forward
--    🌐 — navigate forward
-- ↩:  — aggre or apply, send message
--    Fork — commit changes
-- a: select all
-- s:  — save
--     dialog — choose Save option
--    Fork — move file to 'staged'
-- d: ℝ — duplicate line
--    ℝ — debug unit test
--    📁 — duplicate file
--     dialog — choose Don't Save option
--    🌐 — add page to bookmarks
--    iTerm — split pane vertically
-- f: find
-- g: ℝ🔄 — git operations popup (custom)
--    🌐 — find or find next
-- h:  — hide current app
-- j: Music — Show soring options
--    📝 — toggle sidebar Visibility
-- k: Telegram — Focus search
--    Telegram — create link
--    Claude Desktop — New chat
-- l: ℝ — go to line
--    🌐 — Focus Url Line
--    Music — Go to Current song
--    Telegram — lock Telegram
-- ;: ℝ — run unit test
-- z: undo
-- x: cut
-- c: copy
-- v: paste
-- b: ℝ — go to declaration
--    Telegram — toggle Bold for text
--    Mail — toggle Bold for text
-- n:  — new window
--    📝 — new empty file
--    Music — new playlist
--    ℝ — generate code
--    Mail — start new letter
-- m:  — minimize window
-- ,:  —  show settings ⚙️ of current app
-- .: ℝ — expand #region
-- /: ℝ — comment line
--    Music — Show/hide status bar
-- ␣: Raycast
}},
{ modifier=left_control, chords={
-- ╭—————╮__10.CONTROL_____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬——————╮
-- │  📝 │  📝  │  📝 │ 📝  │ 📝   │  📝 │  📝 │  📝  │ 📝  │  📝 │  📝  │ 📝  │  📝 │      │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
-- │      │  ℝ  │  ℝ  │  ℝ  │  ℝ  │  ℝ  │     │     │     │     │  ℝ  │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
-- │        │  ℝ  │  ℝ  │  ℝ  │  ℝ  │  ℝ  │     │     │     │    │iTerm│     │     │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
-- │         │     │     │     │     │     │     │     │     │     │     │              │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴——————————————╯
-- │ 🟢🟢🟢  │     │      │                            │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- `: 📝 — toggle terminal
-- 1: 📝 — go to tab 1
-- 2: 📝 — go to tab 2
-- 3: 📝 — go to tab 3
-- 4: 📝 — go to tab 4
-- 5: ℝ — go to Bookmark 5
--    📝 — go to tab 5
-- 6: ℝ — go to Bookmark 6
--    📝 — go to tab 6
-- 7: ℝ — go to Bookmark 7
--    📝 — go to tab 7
-- 8: ℝ — go to Bookmark 8
--    📝 — go to tab 8
-- 9: 📝 — go to tab 9
-- 0: 📝 — go to last tab
-- ⇥:  — switch tab forward
-- q: ℝ — stop all
--    📝 — switch between panels
-- w: ℝ — close all notifications
-- e: ℝ — find usages (custom)
-- r: ℝ — run
-- t: ℝ — refactor this
-- o: ℝ — override
-- ↩:  — open context menu
--    ℝ — generate (alternative to cmd + n)
-- a: ℝ🔄 — git annotate (blame) (custom)
-- s: ℝ — save with format (idea + custom macros)
-- d: ℝ — debug (idea)
--     — delete letter to the right
-- f: ℝ — focus Find panel
-- g: ℝ🔄 — focus Git panel
-- h:  — delete letter to the left
-- k:  — delete all text till the end of line
-- l: iTerm — Clear window
-- ␣:  — change language layout
}},
{ modifier=hyper, chords={
-- ╭—————╮__11.HYPER_______╭—————┬————————┬————————┬——————┬—————┬—————┬—————┬—————┬—————┬——————╮
-- │  ⎋  │ F1  │ F2  │ F3  │ F4  │   F5   │   F6   │  F7  │ F8  │ F9  │ F10 │ F11 │ F12 │    ⌦ │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┴—┬——————┴—┬————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
-- │  AI   │PgUp │  ↑  │PgDn │  ℝ  │Telegram│  IINA  │      │     │  ↑  │Music│ ⏮  │  ⏭  │    │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬—————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │  📁  │Fork🔄  │ Safari │      │  ←  │  ↓  │  →  │ 🔊  │     │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬—————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
-- │         │  ↩  │home │ end │ 🌐  │ iTerm2 │   📝    │      │home │ end │ 🔉  │              │
-- ├————————┬┴————┬┴—————┼—————┴—————┴————————┴————————┴——————┼—————┴┬————┴┬————┴——————————————╯
-- │        │     │      │           play/stop                │      │     │
-- ╰————————┴—————┴——————┴————————————————————————————————————┴——————┴—————╯
-- karabiner ⎋ — tilda/ё
-- 1: F1 — 📝 — open commands palette
-- 2: F2 — ℝ — next error in file
-- 3: F3 —  — find next (in file)
-- 4: F4
-- 5: F5
-- 6: F6 — ℝ — move
-- 7: F7 — ℝ — step into (debugging)
--         🌐 — turn on caret browsing
-- 8: F8 — ℝ — step over (debugging)
-- 9: F9 — ℝ — resume program (debugging)
-- 0: F10
-- -: F11 —  — show desktop
-- =: F12
-- ⌫: ⌦
-- alt + ⌫: maccy delete row
{ key="tab", app="opcode", window_default_position="right" },
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
-- ╭—————╮__12.HYPER_ALT___╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │     │     │     │  ℝ  │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │     │  ↑  │     │     │     │     │     │     │  ↑  │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │     │     │     │     │  ←  │  ↓  │  →  │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │         │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │        │🟢🟢🟢│      │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- 9 (F9) ℝ — run till cursor (debugging)
-- w (↑): move line up
--        YouTube — skip 5sec
--        ℝ — extend selection
-- a (←): jump a word to the left
--        YouTube — skip 5sec backwards
-- s (↓): move line down
--        YouTube — previous chapter in current video
--        ℝ — shrink selection
-- d (→): jump a word to the right
--        YouTube — next chapter in current video
}},
{ modifier={"hyper", "left_command"}, chords={
-- ╭—————╮__13.HYPER_CMD___╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬——————╮
-- │     │     │  ℝ  │  ℝ  │     │    │     │     │     │     │     │     │     │      │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
-- │       │PgDn │  ↑  │PgUp │     │     │     │     │     │  ↑  │     │     │     │    │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │     │     │     │     │  ←  │  ↓  │  →  │     │     │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
-- │         │  ↩  │     │     │     │     │     │     │     │     │     │              │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴——————————————╯
-- │        │     │🟢🟢🟢 │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
--
-- 2 (F2): ℝ — stop
-- 3 (F3): ℝ — show bookmarks
-- 5 (F5):  — turn voiceOver on or off
-- 6 (F6): ℝ — change signature
-- 8 (F8): ℝ — toggle breakpoint
-- q (PgUp): 📝 — scroll up (without moving caret)
-- w (↑):  — go to the begining of the document
--        Music — raise volume
-- e (PgDn): 📝 — scroll down (without moving caret)
-- o (↑):  — go to the begining of the document
--        Music — raise volume
--        Telegram — reply to message (press several times to reply to the message in thread)
-- a (←):  — home
--        Music — play previous song or move to the begging
-- s (↓):  — go to the end of the document
--        Music — down volume
-- d (→):  — end
--        Music — play next song
-- k (←):  — home
--        Music — play previous song or move to the begging
-- l (↓):  — go to the end of the document
--        Music — down volume
-- ; (→):  — end
--        Music — play next song
-- z (↩):  — aggre or apply, send message
--        Fork — commit changes
--
}},
{ modifier={"hyper", "left_control"}, chords={
-- ╭—————╮__14.HYPER_CTRL__╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │    │    │     │    │    │    │    │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │PgUp │  ↑  │PgDn │     │     │     │     │     │  ↑  │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │     │     │     │     │  ←  │  ↓  │  →  │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │         │  ↩  │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │ 🟢🟢🟢  │     │      │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
--
-- 2 (F2):  — move focus to the menu bar
-- 3 (F3):  — move focus to Dock
-- 5 (F5):  — move focus to Window's Toolbar
-- 6 (F6):  — move focus to Floating Win
-- 7 (F7):  — change the way Tab moves focus—between navigation of all controls on the screen, or only text boxes and lists.
-- 8 (F8):  — move focus to the status menu in the menu bar
-- q (PgUp): 📝 — scroll up (without moving caret)
--           🌐 — go to tab to the left
-- w (↑):  — show all windows
-- e (PgDn): 📝 — scroll down (without moving caret)
--           🌐 — go to tab to the right
-- o (↑):  — show all windows
-- a (←):  — move to left workspace
-- s (↓):  — show all windows of current app
-- d (→):  — move to right workspace
-- k (←):  — move to left workspace
-- l (↓):  — show all windows of current app
-- ; (→):  — move to right workspace
-- z (↩):  — open context menu
--        ℝ — generate (alternative to cmd + n)
}},
{ modifier={"hyper", "left_shift"}, chords={
-- ╭—————╮__15.HYPER_SHIFT_______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │  ℝ  │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │PgUp │  ↑  │PgDn │     │     │     │     │     │  ↑  │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │     │     │     │     │  ←  │  ↓  │  →  │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │ 🟢🟢🟢   │     │home │ end │     │     │     │     │home │ end │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │        │     │      │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
--
-- 6 (F6): ℝ — rename
-- 7 (F7): ℝ — smart step into
-- 8 (F8): ℝ — step out
-- q (PgUp): select page up
-- w (↑): move caret up and select text from the initial position
-- e (PgDn): select page down
-- o (↑): move caret up and select text from the initial position
-- a (←): select letter to the left
-- s (↓): move caret down and select text from the initial position
-- d (→): select letter to the right
-- k (←): select letter to the left
-- l (↓): move caret down and select text from the initial position
-- ; (→): select letter to the right
-- x (home): select to the beginning of the line
-- c (end): select to the end of the line
-- , (home): select to the beginning of the line
-- . (end): select to the end of the line
--
}},
{ modifier={"left_command", "left_shift"}, chords={
-- ╭—————╮__16.CMD_SHIFT___╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬————┬——————╮
-- │    │  📝 │Shotr│Shotr│Shotr│    │     │     │     │     │     │     │    │   ℝ  │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——┴—┬————┤
-- │       │    │    │  ℝ  │  ℝ  │  ℝ  │     │     │     │     │    │     │    │  ℝ │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬———┴╮   │
-- │        │  📁 │  📁  │ 📝📁 │ 📝ℝ │     │     │     │     │     │     │     │    │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴————┴———┤
-- │ 🟢🟢🟢   │ReDO│ 📝  │ 📝📁 │     │     │ 🌐  │     │     │     │  ℝ  │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬┴—————————————╯
-- │        │     │🟢🟢🟢 │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- `:  — switch between windows of the current app (backward)
{ key="1", app="Visual Studio Code" },
-- 2: Shotr — OCR from screen
-- 3: Shotr — save screenshot of window ( native screenshot replaced)
-- 4: Shotr — start getting screenshot ( native screenshot replaced)
-- 5:  — record video from screen
-- ⌫: ℝ — go to last edit
-- q:  — log out from account with closing of all apps
-- w: ℝ — close other tabs
--     — close window
-- e: ℝ — recent locations popup
--    🌐 — opened tabs dialog
-- r: ℝ — replace in files
--    📁 — go to AirDrop
-- t:  — reopen closed tab
--    🌐 — reopen closed tab
--    📁 — switch tabs bar visibility
-- u: ℝ — toggle case of text
-- o: ℝ — go to file
-- p: Fork — open Push dialog
-- ↩: ℝ — complete current statement
-- a: 📁 — go to Applications
--    Fork — filter by active branch
-- s: 📁 — go to Shared
-- d: 📁 — go to Desktop
--    Fork — revert file changes
--    📝 — show debug callstack
--    iTerm — split pane horizontally
-- f: ℝ — search in files
--    Fork — open Fetch dialog,
--    📁 — go to Recent
--    Telegram — focus global search
-- g: 📁 — go to GoTo dialog
-- h: 📁 — go to $HOME
--    Fork — save Stash
-- k: 📁 — go to Network
-- l: Fork — open Pull dialog
-- b: Fork — open Create Branch dialog
-- z:  — redo
-- x: 📝 — open Extensions
--    Telegram — toggle Strikethrough for text
-- c: 📁 — go to Computer
--    📝 — open Terminal
-- n: 🌐 — open new Private Window
--    📁 — create New folder
--    Music — create new playlist from selection
--    Fork — clone repository
--    Mail — check for new mail
-- /: ℝ — comment
--
}},
{ modifier={"left_command", "alt"}, chords={
-- ╭—————╮__17.CMD_ALT______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │    │Fork │Fork │Fork │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │     │     │Music│  ℝ  │Fork │ 🌐  │  🌐  │     │     │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │        │     │     │    │  ℝ  │     │    │     │     │  🌐 │     │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │         │     │     │    │  ℝ  │  ℝ  │  ℝ  │  ℝ  │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │        │🟢🟢🟢│ 🟢🟢🟢│                            │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- ⎋:  — force quit current app
-- 1: Fork — show commit details
-- 2: Fork — show commit changes
-- 3: Fork — show commit filetree
-- e: Music — show equalizer
-- r: ℝ — resume running
-- t: Fork — hide/search toolbar
-- u: Music — Show playing next queue
--    🌐 — view source code
-- i: 🌐 — open Developer Tools
-- ↩: Fork — commit and push changes
-- d:  — show/hide Dock
-- f: ℝ — extract field
--    Activity Monitor — filter processes
-- h:  — hide all other windows
-- l: 📁 — downloads
--    🌐 — downloads
-- c: ℝ — introduce constant
--    📁 — Copy file's path
-- v: ℝ — extract variable
--    📁 — move items here
-- b: ℝ — go to implementation
-- n: ℝ — inline
-- m: ℝ — extract method
-- ␣:  — open Finder and focus Search this Mac
}},
{ modifier={"left_command", "left_control"}, chords={
-- ╭—————╮__18.CMD_CONTROL_______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │    │     │  ℝ  │  ℝ  │     │     │     │     │     │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │        │  ℝ  │    │    │    │     │     │     │     │     │     │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │         │     │  ℝ  │  ℝ  │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │ 🟢🟢🟢  │     │🟢🟢🟢 │                            │            │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- q: logout
-- e: ℝ — show list of tabs of current panel
-- r: ℝ — rerun tests
-- a: ℝ — show all affected files
--    Mail — archive message
-- f:  — toggle fullscreen of current app
-- g: ℝ — select all occurances
-- s: 📁 — Toggle SideBar
--    ℝ — Toggle Sidebar
-- d:  — look up the selected word
-- x: ℝ — scroll to Top
-- c: ℝ — scroll to Bottom
-- ␣:  — emogies
}},
{ modifier= {"left_control", "left_shift"}, chords={
-- ╭—————╮__19.CTRL_SHIFT__╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │ 📊  │  ℝ  │  ℝ  │  ℝ  │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │      │    │  ⌫  │  ⌦  │  ℝ  │     │     │     │     │     │    │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │        │    │     │  ℝ  │     │  ℝ🔄│     │     │     │     │     │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │ 🟢🟢🟢  │     │      │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
{ key="escape", app="Activity Monitor" }, -- Like on Windows 📊
-- 1: ℝ — toggle bookmark 1
-- 2: ℝ — toggle bookmark 2
-- 3: ℝ — toggle bookmark 3
-- ⇥:  — go to previous tab
-- q:  — log out with dialogs
-- w: ⌫ (backspace)
-- e: ⌦ (delete)
-- r: ℝ — run Unit Tests
-- p:  — open private window
-- a:  — select line to the left
-- d: ℝ — debug Unit Tests
-- g: ℝ🔄 — current file git history
-- h: ℝ — hierarchy
}},
{ modifier={"left_control", "alt"}, chords={
-- ╭—————╮__20.CONTROL_ALT________╭————————┬——————┬————————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │Intrnal│BTooth│HeadPhnes│Scarlett│      │        │     │     │     │     │     │     │     │
-- ├—————┴—┬—————┴—┬————┴——┬——————┴—┬——————┴—┬————┴—┬——————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │ Music │Window^│        │WebStorm│      │        │     │info │     │     │     │     │   │
-- ├———————┴┬——————┴┬——————┴┬———————┴┬———————┴┬—————┴┬———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │        │Window←│Window↓│Window→ │        │GitHub│HamSpoon│     │     │     │     │     │     │  │
-- ├————————┴┬——————┴┬——————┴┬———————┴┬———————┴┬—————┴┬———————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │         │ toRu  │ XCode │Calendar│YouTube │      │        │     │     │     │     │             │
-- ├————————┬┴——————┬┴———————┼————————┴————————┴——————┴————————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │ 🟢🟢🟢  │ 🟢🟢🟢 │        │                                       │      │     │
-- ╰————————┴———————┴————————┴———————————————————————————————————————┴——————┴—————╯
{ key="1", specific_function="audio.internal"},
{ key="2", specific_function="audio.bt"},
{ key="3", specific_function="audio.marshall"},
{ key="4", specific_function="audio.external"},
{ key="tab", specific_function="translate_to_english"},
{ key="q", app="Music"},
{ key="w", specific_function="window.fullscreen"},
{ key="r", app="WebStorm"},
{ key="y", specific_function="youtube_stream" },
{ key="i", specific_function="info.show_shortcuts"},
{ key="a", specific_function="window.left"},
{ key="s", specific_function="window.set_all_to_default" },
{ key="d", specific_function="window.right" },
{ key="g", specific_function="browser_git"},
{ key="h", app="Hammerspoon", window_default_position="right"},
{ key="z", specific_function="translate_to_russian"},
{ key="x", app="XCode" },
-- c: itsycal Calendar
{ key="v", specific_function="browser_youtube" },
{ key="left", specific_function="window.left"},
{ key="right", specific_function="window.right"},
{ key="up", specific_function="window.fullscreen"},
{ key="down", specific_function="window.set_all_to_default"},
}},
{ modifier={"hyper", "alt", "left_command"}, chords={
-- ╭—————╮__21.HYPER_ALT_CMD_____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │    │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │     │  ↑  │     │     │     │     │     │     │  ↑  │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │     │     │     │     │  ←  │  ↓  │  →  │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │         │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │        │🟢🟢🟢│🟢🟢🟢 │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- `:  — show force quit dialog
-- 5 (F5):  — show accessibility controls
-- w (↑): 📝 — clone caret up
--        iTerm — focus pane above
-- o (↑): 📝 — clone caret up
--        iTerm — focus pane above
-- a (←): Music — seek backward
--        📝 — go to previous tab
--        iTerm — focus pane to the left
-- s (↓): 📝 — clone caret down
--        iTerm — focus pane below
-- d (→): Music — seek forward
--        📝 — go to next tab
--        iTerm — focus pane to the right
-- k (←): Music — seek backward
--        📝 — go to previous tab
--        iTerm — focus pane to the left
-- l (↓): 📝 — clone caret down
--        iTerm — focus pane below
-- ; (→): Music — seek forward
--        📝 — go to next tab
--        iTerm — focus pane to the right
-- z (↩): Fork — commit and push changes
}},
{ modifier={"hyper", "alt", "left_control"}, chords={
-- ╭—————╮__22.HYPER_CONTROL_ALT_______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │     │     │     │     │     │     │     │     │     │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │ 🟢🟢🟢  │     │     │     │     │     │     │     │     │     │     │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │         │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │ 🟢🟢🟢  │🟢🟢🟢│      │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
}},
{ modifier={"hyper", "alt", "left_shift"}, chords={
-- ╭—————╮__23.HYPER_SHIFT_ALT___╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │     │     │     │     │     │     │     │     │     │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │ 🟢🟢🟢  │  ←  │     │  →  │     │     │     │     │     │  ←  │     │  →  │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │        │🟢🟢🟢│      │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- a (←): select word to the left
-- d (→): select word to the right
-- k (←): select word to the left
-- ; (→): select word to the right
}},
{ modifier={"hyper", "left_control", "left_command"}, chords={
-- ╭—————╮__24.HYPER_CONTROL_CMD_______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │ ⚠️  │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │ ⚠️    │     │  ↑  │     │     │     │     │     │     │     │  ↑  │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │     │     │     │     │     │  ←  │  ↓  │  →  │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │         │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │ 🟢🟢🟢  │     │ 🟢🟢🟢│                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- w (↑) — ℝ — navigate to up method
-- o (↑) — ℝ — navigate to up method
-- a (←) — 📝 — move tab to panel to the left
-- s (↓) — ℝ — navigate to down method
-- d (→) — 📝 — move tab to panel to the right
-- k (←) — 📝 — move tab to panel to the left
-- l (↓) — ℝ — navigate to down method
-- ; (→) — 📝 — move tab to panel to the right
}},
{ modifier={"hyper", "left_command", "left_shift"}, chords={
-- ╭—————╮__25.HYPER_CMD_SHIFT___╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │    │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │     │     │     │     │     │     │     │     │     │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │ 🟢🟢🟢  │     │     │     │     │     │     │     │     │     │     │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │        │     │🟢🟢🟢 │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- + (F12): ℝ — hide all panels
-- ⌫ (⌦ delete): 📁 — empty trashcan
}},
{ modifier={"hyper", "left_shift", "left_control"}, chords={
-- ╭—————╮__26.HYPER_SHIFT_CONTROL_____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │     │     │     │     │     │     │     │     │     │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │ 🟢🟢🟢  │     │     │     │     │     │     │     │     │     │     │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │ 🟢🟢🟢  │     │      │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
}},
{ modifier={"left_control", "alt", "left_command"}, chords={
-- ╭—————╮__27.CONTROL_ALT_CMD___╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │     │     │     │     │     │     │     │     │  ℝ  │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │        │     │     │     │     │     │     │     │     │     │     │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │         │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │ 🟢🟢🟢  │🟢🟢🟢│ 🟢🟢🟢│                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- o: ℝ — Recent projects popup
}},
{ modifier={"left_shift", "left_control", "alt"}, chords={
-- ╭—————╮__28.SHIFT_CONTROL_ALT_______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │     │     │     │     │     │     │     │     │     │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │        │     │     │     │     │     │     │     │     │     │     │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │ 🟢🟢🟢  │🟢🟢🟢│      │                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
}},
{ modifier={"left_shift", "left_control", "left_command"}, chords={
-- ╭—————╮__29.SHIFT_CONTROL_CMD_______╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │     │     │     │     │     │     │     │     │     │     │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │        │     │     │     │     │     │     │     │     │     │     │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │  ℝ  │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │ 🟢🟢🟢  │     │ 🟢🟢🟢│                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- m: ℝ — new project window
}},
{ modifier={"left_shift", "alt", "left_command"}, chords={
-- ╭—————╮__30.SHIFT_ALT_CMD_____╭—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————┬—————╮
-- │     │     │     │     │     │     │     │     │     │     │     │     │     │     │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┤
-- │       │    │     │     │     │     │     │     │     │Fork │Fork │     │     │   │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮  │
-- │        │     │Fork │     │Fork │     │Fork │     │     │Fork │     │     │     │  │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴┬————┴—————┴——┤
-- │ 🟢🟢🟢   │     │     │     │     │     │     │     │     │     │     │             │
-- ├————————┬┴————┬┴—————┼—————┴—————┴—————┴—————┴—————┼—————┴┬————┴┬————┴—————————————╯
-- │        │🟢🟢🟢│ 🟢🟢🟢│                             │      │     │
-- ╰————————┴—————┴——————┴—————————————————————————————┴——————┴—————╯
-- q:  — close all other apps
-- o: Fork — open file
-- p: Fork — quick Push
-- s: Fork — send all files to staged/unstaged
-- f: Fork — quick Fetch
-- h: Fork — quick Stash
-- l: Fork — quick Pull
}}
}

function unsubscribe()
    if hideKSheetShortCut then
        hideKSheetShortCut:disable();
   end
end

local appSpecificHotkeys = {
    ["Fork"] = {
        { from = {"cmd", "shift"}, key = "e", to = {"cmd", "shift"}, target_key = "l" },
        { from = {"ctrl"}, key = "1", to = { "cmd", "option" }, target_key = "1"},
        { from = {"ctrl"}, key = "2", to = { "cmd", "option" }, target_key = "2"},
        { from = {"ctrl"}, key = "3", to = { "cmd", "option" }, target_key = "3"}
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
