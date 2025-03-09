function is_small_dialog(window)
    if window == nil then
        return false
    end

    local app_title = window:application():title()
    local window_title = window:title()
    local window_frame = window:frame()

    if is_finder_copy_dialog(app_title, window_title, window) then
        return true
    end

    if window_title:match("^Save") or window_title:match("^Open") or window_title:match("^Export") or window_title:match("^Import") then
        if window_frame.w < 800 and window_frame.h < 600 then
            return true
        end
    end

    if window_title:match("^Alert") or window_title:match("Dialog") or window_title:match("Warning") then
        if window_frame.w < 500 and window_frame.h < 300 then
            return true
        end
    end

    if window_title:match("^Print") then
        return true
    end

    local is_very_small = window_frame.w < 500 and window_frame.h < 300
    local has_small_title = window_title and #window_title < 30

    if app_title == "Safari" and window_title == "Downloads" then
        return true
    end

    if app_title == "Terminal" and window_title ~= "Terminal" and is_very_small then
        return true
    end

    local dialog_apps = {"Finder", "System Settings", "Disk Utility", "Preview", "TextEdit"}
    if hs.fnutils.contains(dialog_apps, app_title) and is_very_small and has_small_title then
        return true
    end

    return false
end
