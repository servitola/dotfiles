function get_right_panel_windows()
    local right_windows = {}

    for _, window in ipairs(hs.window.allWindows()) do
        if window:isVisible() and not is_small_dialog(window) then
            local app_title = window:application():title()
            local window_frame = window:frame()
            local screen = window:screen()
            local screen_frame = screen:frame()

            local right_edge = screen_frame.x + screen_frame.w
            local is_in_right_panel = window_frame.x > (screen_frame.x + screen_frame.w * vertical_line * 0.9) and
                                     window_frame.x < right_edge and
                                     window_frame.y < (screen_frame.y + screen_frame.h * horizontal_line * 0.5)

            if is_in_right_panel then
                table.insert(right_windows, window)
            end
        end
    end

    return right_windows
end
