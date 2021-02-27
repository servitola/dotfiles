local obj = {}
obj.__index = obj
obj.vertical_line = 0.71
obj.horizontal_line = 0.73

right_side_app_titles = {'Telegram', 'Hammerspoon'}
bottom_side_app_titles = {'Elmedia Player' }

function obj:bind_window_left(modifier, key)
    hs.hotkey.bind(modifier, key, set_window_left)
end

function obj:bind_window_right(modifier, key)
    hs.hotkey.bind(modifier, key, set_window_right)
end

function obj:bind_window_fullscreen(modifier, key)
    hs.hotkey.bind(modifier, key, set_window_fullscreen)
end

function obj:bind_all_windows_to_default(modifier, key)
    hs.hotkey.bind(modifier, key, set_all_windows_positions)
end

function set_window_left(window)
    set_window(0, 0, obj.vertical_line, 1, window)
end

function set_window_right(window)
    if window == null then
        window = hs.window.frontmostWindow()
    end

    local app_title = window:application():title()    

    if hs.fnutils.contains(bottom_side_app_titles, app_title) then
        set_window_bottom(window)
    else
        set_window(obj.vertical_line, 0, 1 - obj.vertical_line, obj.horizontal_line - 0.022, window)
    end
end

function set_window_bottom(window)
    set_window(obj.vertical_line, obj.horizontal_line, 1 - obj.vertical_line, 1 - obj.horizontal_line, window)
end

function set_window_fullscreen(window)
    set_window(0, 0, 1, 1, window)
end

function set_all_windows_positions()
    local wins = hs.window.visibleWindows()

    for _, window in ipairs(wins) do
        local app = window:application()
        local window_title = window:title()
        local app_title = app:title()
        local window_id = window:id()

        log_window(window)

        if hs.fnutils.contains(right_side_app_titles, app_title) then
            set_window_right(window)
        elseif app_title == "Yandex" and window_title ~= "Untitled" and window_title ~= "YouTube" then
            set_window_bottom(window)
        elseif app_title == "qemu-system-x86_64" then
            --setWindow(4, 0, null, null, window)
            --moveWindow(4, 0, window)
        else
            cell = hs.grid.get(window, window:screen())
            if cell.x == 0 and cell.y == 0 and cell.h == obj.GRID.height and cell.w == obj.GRID.width then
                local active_window = hs.window.frontmostWindow()
                if active_window == window then
                    set_window_left(window)
                end
            else
                set_window_left(window)
            end
        end
    end
end

function set_window(x, y, width, height, window)
    if window == null then
        window = hs.window.frontmostWindow()
    end

    local screen_size = window:screen():fullFrame()

    window:setFrame({
        x = screen_size.w * x,
        y = screen_size.h * y,
        w = screen_size.w * width,
        h = screen_size.h * height
    })

end

function log_window(window)
    local logger = hs.logger.new("window", 'verbose')
    local app = window:application()
    logger.d(" ")
    logger.d("App Title: ")
    logger.d(app:title())
    logger.d("Bundle Id:")
    logger.d(app:bundleID())
    logger.d("Win Title:")
    logger.d(window:title())
    logger.d("Win Id:")
    logger.d(window:id())
    logger.d(" ")
end

return obj
