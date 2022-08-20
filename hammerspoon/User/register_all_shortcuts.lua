spoon.HotKeys:bindOpenApp({"left_control", "left_shift"}, "escape", "/Applications/Activity Monitor.app")

apps_list = {
    { modifier="caps_lock", chords={
        -- {supported=true, key="1", map="F1" },
        -- {supported=true, key="2", map="F2" },
        -- {supported=true, key="3", map="F3" },
        -- {supported=true, key="4", map="F4" },
        -- {supported=true, key="5", map="F5" },
        -- {supported=true, key="6", map="F6" },
        -- {supported=true, key="7", map="F7" },
        -- {supported=true, key="8", map="F8" },
        -- {supported=true, key="9", map="F9" },
        -- {supported=true, key="0", map="F10" },
        {supported=true, key="-", app_name="" },
        --{supported=false, key="=" },
        --{supported=true, key="q", map="page_up" },
        --{supported=true, key="w", map="up_arrow" },
        --{supported=true, key="e", map="page_down" },  
        {supported=true, key="r", app_name="Rider" },
        {supported=true, key="t", app_name="Telegram", color="#2194CE", window_default_position="right" },
        {supported=true, key="y", app_name="Mail" },
        {supported=true, key="u", app_name="Transmission", app_nameWin="uTorrent" },
        --{supported=true, key="i" },
        --{supported=true, key="o", map="up_arrow" },
        {supported=true, key="p", app_name="Music", app_nameWin="MediaMonkey", hint="Player"},
        --{supported=true, key="[", map="previous_track"},
        --{supported=true, key="]", map="next_track" },
        --{supported=true, key="a", map="left_arrow" },
        --{supported=true, key="s", map="bottom_arrow"},
        --{supported=true, key="d", map="right_arrow" },
        -- set in app settings {supported=true, key="f", app_name="Alfred", app_nameWin="keypirinha", hint="Find"},
        {supported=true, key="g", app_name="Fork", hint="Git"},
        {supported=true, key="h", app_name="Finder", app_nameWin="File Explorer", hint="Hub" },
        {supported=true, key="j", app_name="Safari", hint="Job" },
        -- {supported=true, key="k", map="left_arrow" },
        -- {supported=true, key="l", map="bottom_arrow"},
        -- {supported=true, key=";", map="right_arrow" },
        --{supported=true, key="'", specific_function="volume_up" },
        {supported=true, key="z", app_name="Punto Switcher" },
        -- {supported=true, key="x", map="home" },
        -- {supported=true, key="c", map="end" },
        {supported=true, key="v", app_name="Firefox", hint="vi" },
        {supported=false, key="b", app_name="iTerm", app_nameWin="Terminal", hint="" },
        {supported=true, key="n", app_name="Visual Studio Code" },
        {supported=false, key="m", app_name="YouTube", hint="movies"},
        --{supported=false, key="/", specific_function="volume_down"},
        -- {supported=true, key="space", map="play_track" }
    }}, 
    { modifier="caps_lock_shift", chords={
        {supported=false, key="i", map="mouse_right_button" },
        {supported=false, key="o", map="mouse_up" },
        {supported=false, key="p", map="mouse_left_button" },
        --{supported=false, key="a", app_name="Android Studio" },
        --{supported=false, key="s", app_name="Simulator" },
        --{supported=false, key="d", app_name="Android Emulator", hint="droid" },
        --{supported=false, key="j", app_name="Zoom", hint="Job" },
        {supported=false, key="k", map="mouse_left" },
        {supported=false, key="l", map="mouse_down" },
        {supported=false, key=";", map="mouse_right" }
    }},
    { modifier="ctrl_alt", chords={
        {supported=true, key="left", specific_function="window.left"},
        {supported=true, key="right", specific_function="window.right"},
        {supported=true, key="up", specific_function="window.fullscreen"},
        {supported=true, key="down", specific_function="window.set_all_to_default"},
        {supported=true, key="i", specific_function="info.show_shortcuts"},
        {supported=true, key="s", specific_function="android.show_all"}
    }},
    { modifier="cmd_win", chords={
        {supported=true, key="q", specific_function="cmd.q", taps="2", hint="close app on double cmd+q"},
        {supported=true, key="w", specific_function="cmd.w"},
        {supported=true, key="t", specific_function="cmd.t"},
        {supported=true, key="h", specific_function="cmd.h"},
        {supported=true, key="c", specific_function="cmd.c"},
        {supported=true, key="v", specific_function="cmd.v"},
        {supported=true, key="x", specific_function="cmd.x"},
        {supported=true, key="z", specific_function="cmd.z"},
        {supported=true, key="s", specific_function="cmd.s"},
        {supported=true, key="n", specific_function="cmd.n"},
        {supported=true, key="d", specific_function="cmd.d"},
        {supported=true, key="o", specific_function="cmd.o"}
    }},
    { modifier="alt", chords={
        { }
    }}
 }

for _, row in pairs(apps_list) do
    modifier = hyper

    if row.modifier == "ctrl_alt" then
        modifier = ctrlAndAlt
    end

    for _, chord_row in pairs(row.chords) do
        if chord_row.app_name then
            spoon.HotKeys:bindOpenApp(modifier, chord_row.key, chord_row.app_name)
        elseif chord_row.specific_function then
            if chord_row.specific_function == "window.left" then
                spoon.Windows:bind_window_left(modifier, chord_row.key)
            elseif chord_row.specific_function == "window.right" then
                spoon.Windows:bind_window_right(modifier, chord_row.key)
            elseif chord_row.specific_function == "window.fullscreen" then
                spoon.Windows:bind_window_fullscreen(modifier, chord_row.key)
            elseif chord_row.specific_function == "window.set_all_to_default" then
                spoon.Windows:bind_all_windows_to_default(modifier, chord_row.key)
            elseif chord_row.specific_function == "android.show_all" then
                hs.hotkey.bind(modifier, chord_row.key, function()
                    local wins = hs.window.visibleWindows()
                    for _, window in ipairs(wins) do
                        local window_title = window:title()
                        local app_title = window:application():title()
                        if app_title == "qemu-system-x86_64" or string.find(window_title, "Android Emulator") then
                            window:focus()
                        end
                    end
                end)
            elseif chord_row.specific_function == "info.show_shortcuts" then
                hs.hotkey.bind(modifier, chord_row.key, function()
                    if ksheet then
                        spoon.KSheet:hide()
                    else
                        spoon.KSheet:show()
                    end

                    ksheet = not ksheet
                end)
            end
        end
    end
end

