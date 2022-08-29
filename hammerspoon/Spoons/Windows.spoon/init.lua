local obj = {}
obj.__index = obj
obj.margin = 0.001
obj.vertical_line = 0.73
obj.horizontal_line = 0.76
obj.right_block_vertical_margin = 0.044

hs.window.animationDuration = 0
-----------------------------------------

right_side_app_titles = {}
bottom_side_app_titles = {}

function obj:add_right_window_type_app(title)
    table.insert(right_side_app_titles, title)
end

function obj:add_bottom_window_type_app(title)
    table.insert(bottom_side_app_titles, title)
end

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
        set_window(obj.vertical_line + obj.margin, 0, 1 - obj.vertical_line,
            obj.horizontal_line - obj.right_block_vertical_margin, window)
    end
end

function set_window_bottom(window)
    set_window(obj.vertical_line + obj.margin, obj.horizontal_line, 1 - obj.vertical_line, 1 - obj.horizontal_line,
        window)
end

function set_window_fullscreen(window)
    set_window(0, 0, 1, 1, window)
end

function set_all_windows_positions()
    local wins = hs.window.visibleWindows()

    local emulators_number = 0

    for _, window in ipairs(wins) do
        local window_title = window:title()
        local app_title = window:application():title()

        if hs.fnutils.contains(right_side_app_titles, app_title) then
            set_window_right(window)
        elseif is_yandex_external_video(window) then
            set_window_bottom(window)
        elseif is_music_mini_player(app_title, window_title) then
            set_window_bottom(window)
        elseif is_unresizable_window(window) then
            emulators_number = emulators_number + 1
        else
            if is_full_screen(window) then
                if window == hs.window.frontmostWindow() then
                    set_window_left(window)
                end
            else
                set_window_left(window)
            end
        end
    end

    local emulators_positioned = 0

    for _, window in ipairs(wins) do
        local window_title = window:title()
        local app_title = window:application():title()

        if app_title == "qemu-system-x86_64" and string.find(window_title, "Android Emulator") then
            local app = window:application()

            local screen_size = window:screen():fullFrame()
            local window_frame = window:frame()
            emulators_positioned = emulators_positioned + 1

            window:setFrame({
                x = screen_size.w / 2 - window_frame.w / 2,
                y = screen_size.h / 2 - window_frame.h / 2,
                h = window_frame.h,
                w = window_frame.w
            })

        end
    end
end

function is_unresizable_window(window)
    local window_title = window:title()
    local app_title = window:application():title()

    if app_title == "qemu-system-x86_64" or string.find(window_title, "Android Emulator") then
        return true
    else
        return false
    end
end

function is_music_mini_player(app_title, window_title)
    if app_title == "Music" and window_title == "Mini Player" then
        return true
    else
        return false
    end
end

function is_yandex_external_video(window)

    if window:title() == "Picture in Picture" then
        return true
    end

    if window:application():title() ~= "Yandex" then
        return false
    end

    local wins = hs.window.visibleWindows()
    local yandex_player_id = window:id()

    for _, window2 in ipairs(wins) do
        if window2:application():title() == "Yandex" then
            if yandex_player_id < window2:id() then
                yandex_player_id = window2:id()
            end
        end
    end

    if window:id() == yandex_player_id then
        return true
    else
        return false
    end
end

function is_full_screen(window)
    local window_frame = window:frame()
    local screen_size = window:screen():fullFrame()

    if window_frame.x == 0 and window_frame.y >= screen_size.y - 30 and window_frame.h >= screen_size.h - 30 and
        window_frame.w == screen_size.w then
        return true
    else
        return false
    end
end

function set_window(x, y, width, height, window)
    if window == null then
        window = hs.window.frontmostWindow()
    end

    if is_unresizable_window(window) then
        return
    end

    local screen_size = window:screen():fullFrame()

    window:setFrame({
        x = screen_size.w * x,
        y = screen_size.h * y,
        h = screen_size.h * height,
        w = screen_size.w * width
    })
end

return obj
