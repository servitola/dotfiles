return { modifier=hyper, chords={
-- ╭—————╮__11.HYPER_______╭—————┬————————┬————————┬——————┬—————┬—————┬—————┬—————┬—————┬——————╮
-- │  `  │ F1  │ F2  │ F3  │ F4  │   F5   │   F6   │  F7  │ F8  │ F9  │ F10 │ F11 │ F12 │    ⌦ │
-- ├—————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬——————┴—┬——————┴—┬————┴—┬———┴—┬———┴—┬———┴—┬———┴—┬———┴—┬————┤
-- │  ↩    │PgUp │  ↑  │PgDn │  ℝ  │Telegram│  IINA  │      │     │  ↑  │Music│ ⏮  │  ⏭  │    │
-- ├———————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬—————┴┬————┴┬————┴┬————┴┬————┴┬————┴╮   │
-- │ 🟢🟢🟢  │  ←  │  ↓  │  →  │  📁  │Fork🔄  │ Safari │      │  ←  │  ↓  │  →  │ 🔊  │     │   │
-- ├————————┴┬————┴┬————┴┬————┴┬————┴┬———————┴┬———————┴┬—————┴┬————┴┬————┴┬————┴┬————┴—————┴———┤
-- │         │ AI  │home │ end │ 🌐  │ iTerm2 │   📝    │      │home │ end │ 🔉  │              │
-- ├————————┬┴————┬┴—————┼—————┴—————┴————————┴————————┴——————┼—————┴┬————┴┬————┴——————————————╯
-- │        │     │      │           play/stop                │      │     │
-- ╰————————┴—————┴——————┴————————————————————————————————————┴——————┴—————╯
-- ⎋: ` (ё in russian layout)
-- 1: F1 — 📝 — open commands palette
-- 2: F2 — ℝ — next error in file
-- 3: F3 —  — find next (in file)
-- 4: F4 — 📝 — go to next found occurrence
-- 5: F5
-- 6: F6 — ℝ — move
-- 7: F7 — ℝ — step into (debugging)
--         🌐 — turn on caret browsing
-- 8: F8 — ℝ — step over (debugging)
-- 9: F9 — ℝ — resume program (debugging)
-- 0: F10
-- -: F11 —  — show desktop
-- =: F12 — 📝 — go to definition
-- ⌫: ⌦ (delete)
-- ⇥: ↩ (enter)
-- q: pageUp
-- w: up
-- e: pagedown
{ key="r", app="Rider" },
{ key="t", app="Telegram", window_default_position="right" },
{ key="y", app="Iina", window_default_position="bottom" },
-- { key="i", specific_function="voice_dictation.toggle" },
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
{ key="z", app="opcode", window_default_position="right" },
-- x: home
-- c: end
{ key="v", app="Yandex" },
{ key="b", app="Warp" },
{ key="n", app="Visual Studio Code" },
-- ,: home
-- .: end
-- /: volume down
-- ␣: play/pause
}
}
