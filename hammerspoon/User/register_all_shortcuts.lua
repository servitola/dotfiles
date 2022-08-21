hyper = {"right_command", "right_control", "right_option", "right_shift"}

apps_list = {
    { modifier=hyper, chords={    
        { key="r", app_name="Rider" },
        { key="t", app_name="Telegram", window_default_position="right" },
        --{ key="y", app_name="" },
        { key="u", app_name="Transmission" },
        --{ key="i" },
        { key="p", app_name="Music" },
        { key="g", app_name="Fork" },
        { key="h", app_name="Finder" },
        { key="j", app_name="Safari" },
        { key="z", specific_function="set_russian_language"},
        { key="v", app_name="Firefox" },
        { key="b", app_name="iTerm" },
        { key="n", app_name="Visual Studio Code" },
        { key="m", app_name="Elmedia Player" },
    }}, 
    { modifier= {"left_control", "left_shift"}, chords={
        { key="escape", app_name="Activity Monitor" },
        -- { key="i", map="mouse_right_button" },
        -- { key="o", map="mouse_up" },
        -- { key="p", map="mouse_left_button" },
        -- { key="s", app_name="Simulator" },
        -- { key="d", app_name="Android Emulator" },
        -- { key="k", map="mouse_left" },
        -- { key="l", map="mouse_down" },
        -- { key=";", map="mouse_right" }
    }},
    { modifier={"left_control", "left_option"}, chords={
        { key="left", specific_function="window.left"},
        { key="right", specific_function="window.right"},
        { key="up", specific_function="window.fullscreen"},
        { key="down", specific_function="window.set_all_to_default"},
        { key="i", specific_function="info.show_shortcuts"},
        { key="s", specific_function="android.show_all"},
        { key="b", app_name="Android Studio"},
        { key="a", app_name="Ableton Live 11 Suite"},
        { key="h", app_name="Hammerspoon"},
        { key="x", app_name="XCode"}
    }},
 }

hideKSheetShortCut = hs.hotkey.new({}, "escape", function()
    spoon.KSheet:hide()
    ksheet = not ksheet
    hideKSheetShortCut:disable();
end)

for _, row in pairs(apps_list) do
    for _, chord_row in pairs(row.chords) do
        if chord_row.app_name then
            hs.hotkey.bind(row.modifier, chord_row.key, function()
                local app = hs.application.get(chord_row.app_name)
                if not app or app:isHidden() then
                    hs.application.launchOrFocus(chord_row.app_name)
                elseif hs.application.frontmostApplication() ~= app then
                    app:activate()
                else
                    app:hide()
                end
            end)
        elseif chord_row.specific_function then
            if chord_row.specific_function == "window.left" then
                spoon.Windows:bind_window_left(row.modifier, chord_row.key)
            elseif chord_row.specific_function == "window.right" then
                spoon.Windows:bind_window_right(row.modifier, chord_row.key)
            elseif chord_row.specific_function == "window.fullscreen" then
                spoon.Windows:bind_window_fullscreen(row.modifier, chord_row.key)
            elseif chord_row.specific_function == "window.set_all_to_default" then
                spoon.Windows:bind_all_windows_to_default(row.modifier, chord_row.key)
            elseif chord_row.specific_function == "android.show_all" then
                hs.hotkey.bind(row.modifier, chord_row.key, function()
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
                hs.hotkey.bind(row.modifier, chord_row.key, function()
                    if ksheet then
                        spoon.KSheet:hide()
                    else
                        hideKSheetShortCut:enable();
                        spoon.KSheet:show()
                    end

                    ksheet = not ksheet
                end)
            elseif chord_row.specific_function == "set_russian_language" then
                hs.hotkey.bind(row.modifier, chord_row.key, function()
                    hs.keycodes.setLayout(hs.keycodes.layouts()[2])
                end)
            end
        end
    end
end

