function is_ios_simulator(window)
    return window:application():title() == "Simulator"
end

function is_activity_monitor_cpu_window(app_title, window_title)
    return app_title == "Activity Monitor" and
           (window_title == "CPU History" or window_title == "GPU History")
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

function is_winflow_recording_panel(app_title, window_title)
    if app_title == "Wispr Flow" and window_title == "Status" then
        return true
    else
        return false
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

function is_yandex_extra_panel(app_title, window_title, window)
    if not (app_title == "Yandex" and window_title) then
        return false
    end

    if window_title == "" then
        return true
    end

end

function is_yandex_video_player(app_title, window_title, window)
    if not (app_title == "Yandex" and window_title) then
        return false
    end

     if window_title == "" then
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
