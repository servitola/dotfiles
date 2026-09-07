local frame_tolerance = 4

local function window_is_at(window, x, y, w, h)
    local screen = window:screen()
    if not screen then return false end
    local screen_frame = screen:frame()
    local frame = window:frame()

    return math.abs(frame.x - (screen_frame.x + screen_frame.w * x)) <= frame_tolerance
        and math.abs(frame.y - (screen_frame.y + screen_frame.h * y)) <= frame_tolerance
        and math.abs(frame.w - screen_frame.w * w) <= frame_tolerance
        and math.abs(frame.h - screen_frame.h * h) <= frame_tolerance
end

local function leave_fullscreen_then(window, place)
    window:setFullScreen(false)
    hs.timer.waitUntil(
        function() return not window:isFullScreen() end,
        function()
            hs.timer.doAfter(0.2, function() place(window) end)
        end,
        0.1)
end

function set_window_left_cycle(window)
    window = window or hs.window.frontmostWindow()
    if not window then return end

    if window:isFullScreen() then
        leave_fullscreen_then(window, set_window_left)
        return
    end

    if window_is_at(window, leftX, topY, vertical_line - spacing, bottomY - topY) then
        set_window_half_left(window)
    else
        set_window_left(window)
    end
end

function set_window_right_cycle(window)
    window = window or hs.window.frontmostWindow()
    if not window then return end

    if window:isFullScreen() then
        leave_fullscreen_then(window, set_window_right)
        return
    end

    if window_is_at(window, vertical_line, topY, rightX - vertical_line, horizontal_line - margin) then
        set_window_half_right(window)
    else
        set_window_right(window)
    end
end

function set_window_fullscreen_cycle(window)
    window = window or hs.window.frontmostWindow()
    if not window then return end
    if window:isFullScreen() then return end

    if window_is_at(window, leftX, topY, rightX - leftX, bottomY - topY) then
        window:setFullScreen(true)
    else
        set_window_fullscreen(window)
    end
end

function set_all_windows_positions_cycle()
    local window = hs.window.frontmostWindow()
    if window and window:isFullScreen() then
        window:setFullScreen(false)
        return
    end
    set_all_windows_positions()
end
