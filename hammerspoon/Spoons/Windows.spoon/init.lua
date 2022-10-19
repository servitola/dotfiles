local obj = {}

leftX = 0.005
topY = 0.005
spacing = 0.01
rightX = 0.995
bottomY = 0.99

vertical_line = 0.74
right_block_vertical_margin = 0.044
horizontal_line = 0.7

hs.window.animationDuration = 0.1
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
    set_window(leftX, topY, vertical_line - spacing, bottomY - topY, window)
end

function set_window_right(window)
    if window == null then
        window = hs.window.frontmostWindow()
    end

    local app_title = window:application():title()

    if hs.fnutils.contains(bottom_side_app_titles, app_title) then
        set_window_bottom(window)
    else
        set_window(vertical_line, topY, rightX - vertical_line,
            horizontal_line - right_block_vertical_margin, window)
    end
end

function set_window_bottom(window)
    set_window(vertical_line, horizontal_line, rightX - vertical_line, rightY - horizontal_line,
        window)
end

function set_window_fullscreen(window)
    set_window(leftX, topY, rightX - leftX, bottomY - topY, window)
end

function set_all_windows_positions()
    local emulators_number = 0
    local emulators_positioned = 0

    for _, window in ipairs(hs.window.allWindows()) do
        local window_title = window:title()
        local app_title = window:application():title()

        if hs.fnutils.contains(right_side_app_titles, app_title) then
            set_window_right(window)
        elseif is_music_mini_player(app_title, window_title) then
            set_window_bottom(window)
        elseif is_android_emulator(window) then
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

        if is_android_emulator(window) then
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

function is_android_emulator(window)
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

    if is_android_emulator(window) then
        return
    end

    window:moveToUnit({x, y, width, height}, 0.1)
end

return obj
