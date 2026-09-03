-- ⌃⌥ + ← and → at the same time: the two top windows swap sides. Catching that
-- "at the same time" is Karabiner's job (rules/32-swap-sides.json), which sends ⌃⌥F14 here —
-- hs.hotkey fires on the first key pressed and can't parse a chord like that.

function swap_side_windows()
    local focused = hs.window.focusedWindow()
    local screen = focused and focused:screen() or hs.screen.mainScreen()
    if not screen then return end
    local screen_id = screen:id()

    local top = {}
    for _, window in ipairs(hs.window.orderedWindows()) do
        if window:isStandard() and window:isVisible() and not is_decoration_window(window)
            and window:screen() and window:screen():id() == screen_id then
            top[#top + 1] = window
            if #top == 2 then break end
        end
    end
    if #top < 2 then return end

    local function center_x(window)
        local frame = window:frame()
        return frame.x + frame.w / 2
    end

    -- Sides are taken from actual coordinates, not stacking order: the windows could
    -- be anywhere, and the point of the gesture is "swap left with right".
    local left_window, right_window = top[1], top[2]
    if center_x(left_window) > center_x(right_window) then
        left_window, right_window = right_window, left_window
    end

    set_window_right(left_window)
    set_window_left(right_window)
end
