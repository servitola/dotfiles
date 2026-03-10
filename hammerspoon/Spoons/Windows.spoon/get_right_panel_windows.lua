function get_right_panel_windows()
    local right_windows = {}

    -- Performance: Use cached visible windows instead of allWindows()
    for _, window in ipairs(get_visible_windows()) do
        -- Performance: Skip small dialogs early
        if not is_small_dialog(window) then
            local window_frame = window:frame()
            local screen = window:screen()
            local screen_frame = screen:frame()

            -- Performance: Calculate bounds once
            local right_panel_left = screen_frame.x + screen_frame.w * vertical_line * 0.9
            local right_edge = screen_frame.x + screen_frame.w
            local vertical_limit = screen_frame.y + screen_frame.h * horizontal_line * 0.5

            -- Performance: Early exit if window is clearly not in right panel
            if window_frame.x > right_panel_left and
               window_frame.x < right_edge and
               window_frame.y < vertical_limit then
                table.insert(right_windows, window)
            end
        end
    end

    return right_windows
end
