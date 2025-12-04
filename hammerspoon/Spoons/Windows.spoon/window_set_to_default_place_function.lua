function set_window_default(window)
    if window == nil then
        window = hs.window.frontmostWindow()
    end

    local app_title = window:application():title()
    local window_title = window:title()

    if is_small_dialog(window) then
        set_window_top_right_small(window)
    elseif hs.fnutils.contains(right_side_app_titles, app_title) then
        set_window_right(window)
    elseif hs.fnutils.contains(bottom_side_app_titles, app_title) then
        set_window_bottom(window)
    elseif is_android_emulator(window) then
        set_window_right(window)
    elseif is_ios_simulator(window) then
        set_window_right(window)
    elseif is_music_mini_player(app_title, window_title) then
        set_window_bottom(window)
    elseif is_firefox_video_player(app_title, window_title) then
        set_window_bottom(window)
    elseif is_yandex_video_player(app_title, window_title, window) then
        set_window_bottom(window)
    elseif is_activity_monitor_cpu_window(app_title, window_title) then
        set_window_right(window)
    elseif is_activity_monitor_small_window(app_title, window_title, window) then
        set_window_bottom(window)
    elseif is_winflow_recording_panel(app_title, window_title) then
        -- nothing
    else
        set_window_left(window)
    end
end
