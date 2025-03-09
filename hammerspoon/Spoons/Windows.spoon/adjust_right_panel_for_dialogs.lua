function adjust_right_panel_for_dialogs()
    if #active_small_dialogs == 0 or right_panel_windows_adjusted then
        return
    end

    right_panel_windows_adjusted = true
    local right_windows = get_right_panel_windows()

    right_panel_windows_positions = {}
    for _, window in ipairs(right_windows) do
        right_panel_windows_positions[window:id()] = window:frame()
    end

    local screen = hs.screen.mainScreen()
    local screen_frame = screen:frame()

    local tall_window_height = screen_frame.h * horizontal_line * 0.5
    local tall_window_y = screen_frame.y + screen_frame.h * horizontal_line * 0.45

    for _, window in ipairs(right_windows) do
        local current = window:frame()
        window:setFrame({
            x = current.x,
            y = tall_window_y,
            w = current.w,
            h = tall_window_height
        }, animation_duration)
    end
end
