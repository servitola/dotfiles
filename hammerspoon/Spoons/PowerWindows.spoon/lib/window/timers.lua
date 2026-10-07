-- Hammerspoon garbage-collects unreferenced timers mid-chain: hold each until
-- it ends.
-- A new timer under the same key cancels the old one.
local FULLSCREEN_POLL, FULLSCREEN_TIMEOUT = 0.1, 3

return function(powerWindows)
    local pending = {}
    local keyed = {}

    local function hold(timer, key)
        if key then keyed[key] = timer else pending[timer] = true end
    end

    local function drop(timer, key)
        if not key then
            pending[timer] = nil
        elseif keyed[key] == timer then
            keyed[key] = nil
        end
    end

    function powerWindows:_cancelAll()
        for timer in pairs(pending) do timer:stop() end
        for _, timer in pairs(keyed) do timer:stop() end
        pending, keyed = {}, {}
    end

    function powerWindows:_cancel(key)
        local timer = keyed[key]
        if timer then
            timer:stop()
            keyed[key] = nil
        end
    end

    function powerWindows:_cancelPrefix(prefix)
        for key in pairs(keyed) do
            if key:sub(1, #prefix) == prefix then self:_cancel(key) end
        end
    end

    function powerWindows:_after(delay, callback, key)
        if key then self:_cancel(key) end
        local timer
        timer = hs.timer.doAfter(delay, function()
            drop(timer, key)
            callback()
        end)
        hold(timer, key)
    end

    function powerWindows:_every(interval, callback, key)
        if key then self:_cancel(key) end
        local timer
        timer = hs.timer.doEvery(interval, function()
            local finished, result = pcall(callback)
            if not finished or result then
                timer:stop()
                drop(timer, key)
            end
            if not finished then error(result, 0) end
        end)
        hold(timer, key)
    end

    function powerWindows:_waitUntil(predicate, action, interval, timeout)
        local waiter = hs.timer.waitUntil(predicate, function(timer)
            drop(timer)
            action()
        end, interval)
        hold(waiter)
        self:_after(timeout, function()
            waiter:stop()
            drop(waiter)
        end)
    end

    function powerWindows:_leaveFullscreenThen(window, settle, callback)
        window:setFullScreen(false)
        self:_waitUntil(
            function() return not window:isFullScreen() end,
            function() self:_after(settle, callback) end,
            FULLSCREEN_POLL, FULLSCREEN_TIMEOUT)
    end
end
