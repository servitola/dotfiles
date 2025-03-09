function set_window_top_right_small(window)
    if window == nil then
        window = hs.window.frontmostWindow()
    end

    local screen = window:screen()
    local screen_frame = screen:frame()
    local window_frame = window:frame()

    local dialog_width = math.min(window_frame.w, screen_frame.w * (rightX - vertical_line) * 0.9)
    local dialog_height = math.min(window_frame.h, screen_frame.h * horizontal_line * 0.4)

    local dialog_x = screen_frame.x + screen_frame.w - dialog_width - margin * screen_frame.w
    local dialog_y = screen_frame.y + topY * screen_frame.h

    window:setFrame({
        x = dialog_x,
        y = dialog_y,
        w = dialog_width,
        h = dialog_height
    }, animation_duration)

    if not hs.fnutils.contains(active_small_dialogs, window:id()) then
        table.insert(active_small_dialogs, window:id())
        adjust_right_panel_for_dialogs()
    end
end
