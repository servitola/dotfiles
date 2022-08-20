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