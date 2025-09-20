return { modifier={"left_control", "alt"}, chords={
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
-- c: itsycal Calendar (custom in app)
{ key="v", specific_function="browser_youtube" },
{ key="left", specific_function="window.left"},
{ key="right", specific_function="window.right"},
{ key="up", specific_function="window.fullscreen"},
{ key="down", specific_function="window.set_all_to_default"},
}
}
