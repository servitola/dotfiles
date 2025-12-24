local obj = {}

dofile("./Spoons/Windows.spoon/config.lua")
dofile("./Spoons/Windows.spoon/window_main_set_function.lua")
dofile("./Spoons/Windows.spoon/small_dialog_detector.lua")
dofile("./Spoons/Windows.spoon/get_right_panel_windows.lua")
dofile("./Spoons/Windows.spoon/window_set_bottom_function.lua")
dofile("./Spoons/Windows.spoon/window_set_right_function.lua")
dofile("./Spoons/Windows.spoon/dialog_set_right_function.lua")
dofile("./Spoons/Windows.spoon/windows_detection_functions.lua")
dofile("./Spoons/Windows.spoon/adjust_right_panel_for_dialogs.lua")
dofile("./Spoons/Windows.spoon/window_set_full_size_function.lua")
dofile("./Spoons/Windows.spoon/restore_right_panel_windows_function.lua")
dofile("./Spoons/Windows.spoon/window_set_to_default_place_function.lua")

local active_small_dialogs = {}
local right_panel_windows_adjusted = false
local right_panel_windows_positions = {}

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

function set_all_windows_positions()
    print("=== All Windows List ===")

    active_small_dialogs = {}
    right_panel_windows_adjusted = false

    local windows = hs.window.allWindows()
    local android_positioned = false
    local frontmost = hs.window.frontmostWindow()

    local screen_cache = {}
    local function get_cached_screen(window)
        local screen = window:screen()
        local screen_id = screen:id()
        if not screen_cache[screen_id] then
            screen_cache[screen_id] = screen:frame()
        end
        return screen_cache[screen_id]
    end

    for _, window in ipairs(windows) do
        if is_android_emulator(window) then
            local screen_frame = get_cached_screen(window)
            local frame = window:frame()
            local expected_x = screen_frame.x + (screen_frame.w * vertical_line)
            local expected_y = screen_frame.y + (screen_frame.h * topY)

            if math.abs(frame.x - expected_x) <= 1 and math.abs(frame.y - expected_y) <= 1 then
                print("Found Android Emulator window in correct position - will skip all android windows")
                android_positioned = true
                break
            end
        end
    end

    for _, window in ipairs(windows) do
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
            local screen_frame = get_cached_screen(window)

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
        elseif is_music_mini_player(app_title, window_title) or
                is_firefox_video_player(app_title, window_title) or
                is_yandex_video_player(app_title, window_title, window) or
                is_finder_copy_dialog(app_title, window_title, window) or
                is_activity_monitor_small_window(app_title, window_title, window) or
                is_activity_monitor_cpu_window(app_title, window_title) then
            set_window_bottom(window)
        elseif is_winflow_recording_panel(app_title, window_title) or
                is_yandex_extra_panel(app_title, window_title, window) then
            -- nothing
        else
            if is_full_screen(window) then
                if window == frontmost then
                    set_window_left(window)
                end
            else
                set_window_left(window)
            end
        end
    end
end

function obj:init()
    return self
end

return obj
