-- Displays arrive in steps (mirroring, resolution, arrangement): arrange once
-- they settle.
local SETTLE = 1

return function(powerWindows, geometry, rules, query)
    local function moveWindowToScreen(self, window, target)
        window = window or query.focused()
        if not window then return end
        if window:isFullScreen() then return end
        local from = window:screen()
        if not from then return end
        local to = target
        if target == "next" then
            to = from:next()
        elseif target == "prev" then
            to = from:previous()
        end
        if not to or to:id() == from:id() then return end
        local resolved = self:_resolveOr(window, "main")
        local config, screenFrame = self:_screenLayout(from)
        local detected = geometry.slotAt(
            config, screenFrame, window:frame(), self.config.tolerance
        )
        local slot = rules.carrySlot(detected, resolved)
        if slot ~= "stack" then
            return self:_place(window, resolved, slot, to)
        end
        -- _write, not animated _set: _placeStack picks windows by
        -- window:screen(), which follows the frame.
        -- Position only: a device window's aspect is read back from its size
        -- when the column is laid out.
        local toConfig, toFrame = self:_screenLayout(to)
        local column, frame =
            geometry.rect(toConfig, "column", toFrame), window:frame()
        self:_write(
            window, { x = column.x, y = column.y, w = frame.w, h = frame.h }
        )
        self:_placeStack(to)
        self:_placeStack(from)
    end

    --- PowerWindows:moveToScreen(target[, window])
    --- Method
    --- Moves `window` (default: focused) to `"next"`, `"prev"` or an
    --- `hs.screen`, keeping its slot.
    function powerWindows:moveToScreen(target, window)
        assert(
            target == "next" or target == "prev"
                or type(target) == "userdata" or type(target) == "table",
            "PowerWindows: moveToScreen target must be \"next\", \"prev\" \z
            or an hs.screen"
        )
        return moveWindowToScreen(self, window, target)
    end

    function powerWindows:_startScreenWatcher()
        if not self.config.rearrangeOnScreenChange then return end
        self._screenWatcher = hs.screen.watcher.new(function()
            self:_after(SETTLE, function() self:arrangeAllNow() end, "screens")
        end):start()
    end

    function powerWindows:_stopScreenWatcher()
        if self._screenWatcher then
            self._screenWatcher:stop()
            self._screenWatcher = nil
        end
        self:_cancel("screens")
    end
end
