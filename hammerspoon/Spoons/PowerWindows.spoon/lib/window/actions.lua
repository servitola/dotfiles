-- Placing needs only the frame back; minimize (minimize.lua) waits longer.
local AFTER_FULLSCREEN = 0.1

return function(powerWindows, geometry, query)
    local function toggleSide(self, window, homeSlot, halfAction, moveAction)
        window = window or query.focused()
        if not window then return end
        if window:isFullScreen() then
            return self:_leaveFullscreenThen(
                window, AFTER_FULLSCREEN,
                function() self[moveAction](self, window) end
            )
        end
        if self.config.cycle and self:_isAt(window, homeSlot) then
            self[halfAction](self, window)
        else
            self[moveAction](self, window)
        end
    end

    --- PowerWindows:left([window])
    --- Method
    --- Left column; with `cycle`, again (already there) = left half. Leaves
    --- native fullscreen first.
    function powerWindows:left(window)
        return toggleSide(self, window, "main", "halfLeft", "moveLeft")
    end

    --- PowerWindows:right([window])
    --- Method
    --- Right column; with `cycle`, again = right half. Leaves native
    --- fullscreen first.
    function powerWindows:right(window)
        return toggleSide(self, window, "side", "halfRight", "moveRight")
    end

    --- PowerWindows:fullscreen([window])
    --- Method
    --- Whole screen with gaps; with `cycle`, again = native fullscreen.
    function powerWindows:fullscreen(window)
        window = window or query.focused()
        if not window then return end
        if window:isFullScreen() then return end
        if self.config.cycle and self:_isAt(window, "full") then
            window:setFullScreen(true)
        else
            self:moveFull(window)
        end
    end

    local function simpleMove(self, window, area)
        window = window or query.focused()
        if not window or window:isFullScreen() then return end
        local config, screenFrame = self:_screenLayoutOf(window)
        if screenFrame then
            self:_set(window, geometry.rect(config, area, screenFrame))
        end
    end

    --- PowerWindows:halfLeft([window])
    --- Method
    --- Left half of the screen.
    function powerWindows:halfLeft(window)
        return simpleMove(self, window, "halfLeft")
    end

    --- PowerWindows:halfRight([window])
    --- Method
    --- Right half of the screen.
    function powerWindows:halfRight(window)
        return simpleMove(self, window, "halfRight")
    end

    --- PowerWindows:top60([window])
    --- Method
    --- Top part, `topShare` of the height.
    function powerWindows:top60(window)
        return simpleMove(self, window, "top60")
    end

    --- PowerWindows:bottom40([window])
    --- Method
    --- Bottom part, below `topShare`.
    function powerWindows:bottom40(window)
        return simpleMove(self, window, "bottom40")
    end

    --- PowerWindows:center([window])
    --- Method
    --- Centers the window, size kept.
    function powerWindows:center(window)
        window = window or query.focused()
        if not window or window:isFullScreen() then return end
        local _, screenFrame = self:_screenLayoutOf(window)
        if not screenFrame then return end
        local frame = window:frame()
        frame.x = screenFrame.x + (screenFrame.w - frame.w) / 2
        frame.y = screenFrame.y + (screenFrame.h - frame.h) / 2
        self:_write(window, frame)
    end

    --- PowerWindows:arrangeAll()
    --- Method
    --- Puts every window in its slot; a focused window in native
    --- fullscreen only leaves it.
    function powerWindows:arrangeAll()
        local window = query.focused()
        if window and window:isFullScreen() then
            window:setFullScreen(false)
            return
        end
        self:arrangeAllNow()
    end

    local function isBackgroundStretched(self, window, resolved, focusedWindow)
        return resolved.slot == "main" and window ~= focusedWindow
            and self:_isAt(window, "full")
    end

    --- PowerWindows:arrangeAllNow()
    --- Method
    --- Same, without the fullscreen check; skips minimized windows, hidden apps
    --- and background windows stretched full.
    function powerWindows:arrangeAllNow()
        local focusedWindow = query.focused()
        local stackScreens = {}
        -- Not isStandard: some players (Telegram's) are non-standard windows
        -- with a slot.
        for _, window in ipairs(hs.window.allWindows()) do
            if window:isVisible() and not window:isFullScreen()
                and not self:_skipped(window) then
                local resolved = self:resolve(window)
                if resolved and resolved.slot == "stack" then
                    local screen = window:screen()
                    if screen then stackScreens[screen:id()] = screen end
                elseif resolved and not isBackgroundStretched(
                    self, window, resolved, focusedWindow
                ) then
                    self:_place(window, resolved)
                end
            end
        end
        for _, screen in pairs(stackScreens) do self:_placeStack(screen) end
    end

    --- PowerWindows:swapSides()
    --- Method
    --- Swaps the two topmost windows of the focused screen, left and right.
    function powerWindows:swapSides()
        local focusedWindow = query.focused()
        local screen = focusedWindow and focusedWindow:screen()
            or hs.screen.mainScreen()
        if not screen then return end
        local top = {}
        for _, window in ipairs(hs.window.orderedWindows()) do
            if self:_isCandidate(window)
                and query.isOnScreen(window, screen) then
                top[#top + 1] = window
                if #top == 2 then break end
            end
        end
        if #top < 2 then return end
        local function centerX(window)
            local frame = window:frame()
            return frame.x + frame.w / 2
        end
        local leftWindow, rightWindow = top[1], top[2]
        if centerX(leftWindow) > centerX(rightWindow) then
            leftWindow, rightWindow = rightWindow, leftWindow
        end
        self:moveRight(leftWindow)
        self:moveLeft(rightWindow)
    end
end
