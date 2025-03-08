function set_window(x, y, width, height, window)
    if window == nil then
        window = hs.window.frontmostWindow()
    end

    local screen = window:screen()
    local screen_frame = screen:frame()

    local app_title = window:application():title()
    local window_title = window:title()

    if app_title == "Yandex" and string.find(window_title, "video") then
        window:moveToUnit({x, y, width, height})
        return
    end

    window:setFrame({
        x = screen_frame.x + (screen_frame.w * x),
        y = screen_frame.y + (screen_frame.h * y),
        w = screen_frame.w * width,
        h = screen_frame.h * height
    }, animation_duration)
end
