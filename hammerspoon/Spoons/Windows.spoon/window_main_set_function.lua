function set_window(x, y, width, height, window)
    if not window then
        window = hs.window.frontmostWindow()
    end
    if not window then return end
    local app = window:application()
    local screen = window:screen()
    if not screen then return end
    local screen_frame = screen:frame()

    local app_title = app and app:title() or ""
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
