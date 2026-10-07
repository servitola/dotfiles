-- Longer than placing's wait (actions.lua): macOS refuses to minimize until
-- the Space animation ends.
local AFTER_FULLSCREEN = 0.6
local RETRY_INTERVAL, RETRIES = 0.3, 4
local MINIMIZED_POLL, MINIMIZED_TIMEOUT = 0.05, 2.5
local REFOCUS_DELAY = 0.35

return function(powerWindows, query)
    --- PowerWindows:minimizeCurrent()
    --- Method
    --- Minimizes the focused window.
    function powerWindows:minimizeCurrent()
        local window = query.focused()
        if window then window:minimize() end
    end

    local function firstCandidate(self, ordered, current, sameApp, screen)
        local application = current:application()
        local processId = application and application:pid()
        for _, window in ipairs(ordered) do
            if window:id() ~= current:id() and self:_isCandidate(window) then
                local owner = window:application()
                if owner and (owner:pid() == processId) == sameApp
                    and (screen == nil or query.isOnScreen(window, screen)) then
                    return window
                end
            end
        end
    end

    -- macOS does not pass focus on after minimize; Hide is no substitute:
    -- refused for the last visible app.
    local function pickNextWindow(self, window)
        local screen = window:screen()
        local ordered = hs.window.orderedWindows()
        return firstCandidate(self, ordered, window, true, screen)
            or firstCandidate(self, ordered, window, true, nil)
            or firstCandidate(self, ordered, window, false, screen)
            or firstCandidate(self, ordered, window, false, nil)
    end

    local function minimizeWithRetry(self, window)
        window:minimize()
        -- Rejected during the leave-fullscreen animation.
        local tries = 0
        self:_every(RETRY_INTERVAL, function()
            tries = tries + 1
            if window:isMinimized() or tries > RETRIES then return true end
            window:minimize()
        end)
    end

    local function handFocusTo(self, nextWindow, minimized)
        local function takeFocus()
            -- Bare focus() may raise another window of the app
            -- (Hammerspoon#370).
            local application = nextWindow:application()
            if application then application:activate(true) end
            nextWindow:raise():focus()
        end
        self:_waitUntil(
            function() return minimized:isMinimized() end,
            function()
                takeFocus()
                -- The minimize animation hands activation back to the previous
                -- app.
                self:_after(REFOCUS_DELAY, function()
                    local focused = query.focused()
                    if not focused or focused:id() ~= nextWindow:id() then
                        takeFocus()
                    end
                end)
            end,
            MINIMIZED_POLL, MINIMIZED_TIMEOUT)
    end

    --- PowerWindows:minimizeAndFocusNext([window])
    --- Method
    --- Minimizes `window` (default: focused) and focuses the next: same app
    --- before other apps, same screen first within each.
    function powerWindows:minimizeAndFocusNext(window)
        window = window or query.focused()
        if not window then return end
        -- Fullscreen owns its Space and cannot minimize.
        if window:isFullScreen() then
            return self:_leaveFullscreenThen(
                window, AFTER_FULLSCREEN,
                function() self:minimizeAndFocusNext(window) end
            )
        end
        local nextWindow = pickNextWindow(self, window)
        -- Minimize first: minimizing a background window silently fails.
        minimizeWithRetry(self, window)
        if nextWindow then handFocusTo(self, nextWindow, window) end
    end
end
