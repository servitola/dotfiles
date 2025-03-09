function set_window_right(window)
    if window == nil then
        window = hs.window.frontmostWindow()
    end

    local app_title = window:application():title()
    local window_title = window:title()

    if hs.fnutils.contains(bottom_side_app_titles, app_title) then
        set_window_bottom(window)
    elseif is_yandex_video_player(app_title, window_title, window) then
        set_window_bottom(window)
    elseif is_activity_monitor_small_window(app_title, window_title, window) and not is_activity_monitor_cpu_window(app_title, window_title) then
        set_window_bottom(window)
    elseif is_small_dialog(window) then
        set_window_top_right_small(window)
    elseif is_activity_monitor_cpu_window(app_title, window_title) then
        set_window(vertical_line, topY, rightX - vertical_line,
            horizontal_line - margin, window)
    else
        set_window(vertical_line, topY, rightX - vertical_line,
            horizontal_line - margin, window)
    end
end
