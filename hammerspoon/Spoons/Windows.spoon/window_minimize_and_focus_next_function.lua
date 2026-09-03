-- ⌘H is intercepted to mean "get this off the screen and give me the next one" — like
-- minimize on Windows. Native Hide doesn't fit: it hides the whole app, and on the last
-- unhidden app macOS refuses it outright (grays out the menu item, ⌘H just beeps).
-- minimize has no such restriction, but it doesn't hand off focus itself: on macOS this
-- is an operation on the window, not the program, so the app stays active. Hence everything below.

local function pick_next_window(ordered, current, same_app, screen_id)
    local current_app = current:application()
    local current_pid = current_app and current_app:pid()

    for _, window in ipairs(ordered) do
        if window:id() ~= current:id() and window:isStandard() and window:isVisible()
            and not is_decoration_window(window) then
            local app = window:application()
            local pid = app and app:pid()
            local app_matches
            if same_app then app_matches = pid == current_pid
            else app_matches = pid ~= current_pid end

            if app_matches
                and (screen_id == nil or (window:screen() and window:screen():id() == screen_id)) then
                return window
            end
        end
    end
end

-- focusedWindow, not frontmostWindow: the latter's "front window of the front app"
-- is the floating Picture in Picture, which stays on top of everything and never minimizes.
function minimize_and_focus_next(window)
    window = window or hs.window.focusedWindow()
    if not window then return end

    -- A fullscreen window doesn't minimize: it owns its own Space, and the yellow button there
    -- is disabled. So exit fullscreen first and retry — costs one animation.
    if window:isFullScreen() then
        window:setFullScreen(false)
        local waiter = hs.timer.waitUntil(
            function() return not window:isFullScreen() end,
            function()
                hs.timer.doAfter(0.6, function() minimize_and_focus_next(window) end)
            end,
            0.1)
        hs.timer.doAfter(3, function() waiter:stop() end)
        return
    end

    local screen = window:screen()
    local screen_id = screen and screen:id()
    local ordered = hs.window.orderedWindows()

    -- Own app first: while it still has windows, ⌘H cycles through them instead of kicking
    -- you out of the app. Once the app runs out of windows, move to the next one up top.
    local next_window = pick_next_window(ordered, window, true, screen_id)
        or pick_next_window(ordered, window, true, nil)
        or pick_next_window(ordered, window, false, screen_id)
        or pick_next_window(ordered, window, false, nil)

    -- Minimize must happen first: minimizing a background window silently fails (verified on
    -- Finder — focus moved away, but the window stayed on screen).
    window:minimize()
    -- Right after exiting fullscreen, macOS rejects minimize while its own animation is still
    -- playing out: the window stayed on screen. Retry until it actually minimizes.
    local tries, retry = 0, nil
    retry = hs.timer.doEvery(0.3, function()
        tries = tries + 1
        if window:isMinimized() or tries > 4 then
            retry:stop()
            return
        end
        window:minimize()
    end)

    if not next_window then return end

    local function take_focus()
        -- activate the app first: a lone focus() sometimes raises a different window
        -- of the same app (Hammerspoon#370)
        local app = next_window:application()
        if app then app:activate(true) end
        next_window:raise():focus()
    end

    local waiter = hs.timer.waitUntil(
        function() return window:isMinimized() end,
        function()
            take_focus()
            -- While the minimize animation is still running, macOS manages to hand activation
            -- back to the previous app over our focus. Retry once it's done.
            hs.timer.doAfter(0.35, function()
                local focused = hs.window.focusedWindow()
                if not focused or focused:id() ~= next_window:id() then take_focus() end
            end)
        end,
        0.05)
    -- The window may never minimize at all (floating player) — otherwise the poll would spin forever.
    hs.timer.doAfter(2.5, function() waiter:stop() end)
end
