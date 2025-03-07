local obj = {}

margin = 0.005
animation_duration = 0.1
horizontal_line = 0.70
vertical_line = 0.73

-----------------------------------------

top_bar_height = 25
spacing = margin * 2
leftX = margin
topY = margin
rightX = 1 - margin / 1.5
bottomY = 1 - margin * 1.5

right_side_app_titles = {}
bottom_side_app_titles = {"IINA", "Transmission"}

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

function obj:set_all_windows_positions()
    set_all_windows_positions()
end

function set_window_left(window)
    if window == nil then
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

        local x = screen_frame.x + margin
        local y = screen_frame.y + (screen_frame.h - target_height) / 2 - (screen_frame.h * 0.1)

        window:setFrame({
            x = x,
            y = y,
            w = target_width,
            h = target_height
        }, animation_duration)
        return
    end

    set_window(leftX, topY, vertical_line - spacing, bottomY - topY, window)
end

function set_window_right(window)
    if window == nil then
        window = hs.window.frontmostWindow()
    end

    local app_title = window:application():title()
    local window_title = window:title()

    if hs.fnutils.contains(bottom_side_app_titles, app_title) then
        set_window_bottom(window)
    elseif is_yandex_video_player(app_title, window_title, window) then
        set_window_bottom(window)
    elseif is_finder_copy_dialog(app_title, window_title, window) then
         set_window_bottom(window)
    elseif is_activity_monitor_small_window(app_title, window_title, window) and not is_activity_monitor_cpu_window(app_title, window_title) then
        set_window_bottom(window)
    elseif is_activity_monitor_cpu_window(app_title, window_title) then
        set_window(vertical_line, topY, rightX - vertical_line,
            horizontal_line - margin, window)
    else
        set_window(vertical_line, topY, rightX - vertical_line,
            horizontal_line - margin, window)
    end
end

function set_window_bottom(window)
    set_window(
        vertical_line,
        horizontal_line + spacing,
        rightX - vertical_line,
      1 - horizontal_line,
      window)
end

function set_window_fullscreen(window)
    if window == nil then
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

function set_all_windows_positions()
    print("=== All Windows List ===")

    local android_positioned = false
    local ios_positioned = false

    for _, window in ipairs(hs.window.allWindows()) do
        if is_android_emulator(window) then
            local screen = window:screen()
            local screen_frame = screen:frame()
            local frame = window:frame()
            local expected_x = screen_frame.x + (screen_frame.w * vertical_line)
            local expected_y = screen_frame.y + (screen_frame.h * topY)

            if math.abs(frame.x - expected_x) <= 1 and math.abs(frame.y - expected_y) <= 1 then
                print("Found Android Emulator window in correct position - will skip all android windows")
                android_positioned = true
            end
        end
    end

    for _, window in ipairs(hs.window.allWindows()) do
        local window_title = window:title()
        local app_title = window:application():title()
        print(string.format("Window: '%s', App: '%s'", window_title, app_title))

        if is_android_emulator(window) then
            if not android_positioned then
                print("Moving Android Emulator window to right side")
                set_window(vertical_line, topY, rightX - vertical_line, horizontal_line - margin, window)
            end
        elseif is_ios_simulator(window) then
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

            local x = screen_frame.x + screen_frame.w * vertical_line
            local y = screen_frame.y + (screen_frame.h * topY)

            window:setFrame({
                x = x,
                y = y,
                w = target_width,
                h = target_height
            }, animation_duration)
        elseif hs.fnutils.contains(right_side_app_titles, app_title) then
            set_window_right(window)
        elseif is_music_mini_player(app_title, window_title) then
            set_window_bottom(window)
        elseif is_firefox_video_player(app_title, window_title) then
            set_window_bottom(window)
        elseif is_yandex_video_player(app_title, window_title, window) then
            set_window_bottom(window)
        elseif is_finder_copy_dialog(app_title, window_title, window) then
            set_window_bottom(window)
        elseif is_activity_monitor_cpu_window(app_title, window_title) then
            set_window_right(window)
        elseif is_activity_monitor_small_window(app_title, window_title, window) then
            set_window_bottom(window)
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

function is_firefox_video_player(app_title, window_title)
  if app_title == "Firefox" and window_title == "Picture-in-Picture" then
      return true
  else
      return false
  end
end

function is_yandex_video_player(app_title, window_title, window)
    if not (app_title == "Yandex" and window_title) then
        return false
    end

    local suffix = string.char(226, 128, 148, 32, 89, 97, 110, 100, 101, 120, 194, 160, 66, 114, 111, 119, 115, 101, 114)
    local title_end = window_title:sub(-#suffix)

    local is_video = title_end ~= suffix

    return is_video
end

function is_finder_copy_dialog(app_title, window_title, window)
    if app_title ~= "Finder" then
        return false
    end
    local window_frame = window:frame()

    local is_copy = window_title:match("^Copy") or window_title:match("^Move")

    local is_small_window = window_frame.w < 600 and window_frame.h < 250

    return is_copy and is_small_window
end

function is_activity_monitor_small_window(app_title, window_title, window)
    if app_title ~= "Activity Monitor" then
        return false
    end

    local window_frame = window:frame()
    local is_small_window = window_frame.w < 600 and window_frame.h < 400
    local is_not_main = window_title ~= "Activity Monitor"

    return is_small_window and is_not_main
end

function is_activity_monitor_cpu_window(app_title, window_title)
    return app_title == "Activity Monitor" and
           (window_title == "CPU History" or window_title == "GPU History")
end

function is_full_screen(window)
    local window_frame = window:frame()
    local screen_size = window:screen():fullFrame()

    if math.floor(window_frame.h) == math.floor(screen_size.h * bottomY - screen_size.h * topY - top_bar_height)
        and math.floor(window_frame.w) == math.floor(screen_size.w * rightX - screen_size.w * leftX) then
        return true
    else
        return false
    end
end

function is_ios_simulator(window)
    local app_title = window:application():title()
    return app_title == "Simulator"
end

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

return obj
