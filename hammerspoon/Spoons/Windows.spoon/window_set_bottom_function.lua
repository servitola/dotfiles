function set_window_bottom(window)
    if not window then
        window = hs.window.frontmostWindow()
    end

    local screen = window:screen()
    local screen_frame = screen:frame()

    local app_title = window:application():title()
    local window_title = window:title()

    local x = screen_frame.x + (screen_frame.w * vertical_line)
    local y = screen_frame.y + (screen_frame.h * (horizontal_line + spacing))
    local width = screen_frame.w * (rightX - vertical_line)
    local height = screen_frame.h * (1 - horizontal_line - spacing)

    local is_video = is_yandex_video_player(app_title, window_title, window) or
                    is_firefox_video_player(app_title, window_title) or
                    app_title == "IINA" or
                     (window_title and (
                         string.find(window_title, "YouTube") or
                         string.find(window_title, "video")
                     ))

    if is_video then
        local current = window:frame()
        local aspect_ratio = current.h / current.w
        local max_available_height = screen_frame.h * (1 - horizontal_line - spacing * 2)

        if height > max_available_height or aspect_ratio > 1.2 then
            height = max_available_height
            width = height / aspect_ratio

            if width > screen_frame.w * (rightX - vertical_line) then
                width = screen_frame.w * (rightX - vertical_line)
                height = width * aspect_ratio
            end

            local available_width = screen_frame.w * (rightX - vertical_line)
            x = screen_frame.x + (screen_frame.w * vertical_line) + (available_width - width) / 2
        end

        window:setFrame({
            x = x,
            y = y,
            w = width,
            h = height
        }, animation_duration)
    else
        set_window(
            vertical_line,
            horizontal_line + spacing,
            rightX - vertical_line,
            1 - horizontal_line - spacing,
            window)
    end
end
