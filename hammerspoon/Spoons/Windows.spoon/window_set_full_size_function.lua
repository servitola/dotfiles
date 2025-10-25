function set_window_fullscreen(window)
    if not window then
        window = hs.window.frontmostWindow()
    end

    if is_ios_simulator(window) then

        local current = window:frame()
        local aspect_ratio = current.h / current.w

        local screen = window:screen()
        local screen_frame = screen:frame()

        local target_width = screen_frame.w * 0.4
        local target_height = target_width * aspect_ratio

        if target_height > screen_frame.h * 0.7 then
            target_height = screen_frame.h * 0.7
            target_width = target_height / aspect_ratio
        end

        local x = screen_frame.x + (screen_frame.w - target_width) / 2
        local y = screen_frame.y + (screen_frame.h - target_height) / 2 - (screen_frame.h * 0.1)

        window:setFrame({
            x = x,
            y = y,
            w = target_width,
            h = target_height
        }, animation_duration)
        return
    end

    set_window(leftX, topY, rightX - leftX, bottomY - topY, window)
end
