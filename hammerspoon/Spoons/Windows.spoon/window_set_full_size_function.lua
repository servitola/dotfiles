function set_window_fullscreen(window)
    if not window then
        window = hs.window.frontmostWindow()
    end

    if is_ios_simulator(window) then
        local w, h, sf = get_ios_simulator_size(window)
        window:setFrame({
            x = sf.x + (sf.w - w) / 2,
            y = sf.y + (sf.h - h) / 2 - (sf.h * 0.1),
            w = w, h = h
        }, animation_duration)
        return
    end

    set_window(leftX, topY, rightX - leftX, bottomY - topY, window)
end
