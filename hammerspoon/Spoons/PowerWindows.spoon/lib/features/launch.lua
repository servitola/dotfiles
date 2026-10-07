-- Timers keyed per pid / window id: concurrent launches must not cancel each
-- other.
-- Rider (JVM) shows its window slowly
local POLL_INTERVAL, POLL_TIMEOUT = 0.3, 30
-- Electron re-centers after load: put the window back once, later moves are
-- the user's.
local ENFORCE_INTERVAL, ENFORCE_DURATION = 0.5, 12
-- AX window list is unsettled at windowCreated.
local FINDER_SETTLE = 0.2

local function watch(powerWindows, geometry, options)
    local bundles = {}
    for _, bundle in ipairs(options.bundles) do bundles[bundle] = true end

    local function target(window)
        local resolved = powerWindows:resolve(window)
        local screen = window:screen()
        if not resolved or resolved.keepAspect or resolved.device
            or not screen then
            return nil
        end
        local slot = resolved.slot
        if slot == "stack" or slot == "dialog" then return nil end
        local config, screenFrame = powerWindows:_screenLayout(screen)
        return geometry.rect(config, slot, screenFrame)
    end

    -- Electron recreates the window after load and the old AX object dies:
    -- re-fetch each tick.
    local function enforce(application)
        local key, endKey =
            "launch:enforce:" .. application:pid(),
            "launch:enforceEnd:" .. application:pid()
        powerWindows:_cancel(endKey)
        powerWindows:_every(ENFORCE_INTERVAL, function()
            if not application:isRunning() then return true end
            local window = application:mainWindow()
            if not window or not window:isStandard() then return end
            local want = target(window)
            local frame = window:frame()
            if want and frame.w > 0 and not geometry.near(
                frame, want, powerWindows.config.tolerance
            ) then
                if not powerWindows:_skipped(window) then
                    powerWindows:placeDefault(window)
                end
                return true
            end
        end, key)
        powerWindows:_after(
            ENFORCE_DURATION, function() powerWindows:_cancel(key) end, endKey
        )
    end

    local function poll(application)
        local key, endKey =
            "launch:poll:" .. application:pid(),
            "launch:pollEnd:" .. application:pid()
        powerWindows:_cancel(endKey)
        powerWindows:_every(POLL_INTERVAL, function()
            local window = application:mainWindow()
            if not window or not window:isStandard() then return end
            powerWindows:_cancel(endKey)
            if not powerWindows:_skipped(window) then
                powerWindows:placeDefault(window)
            end
            enforce(application)
            return true
        end, key)
        powerWindows:_after(
            POLL_TIMEOUT, function() powerWindows:_cancel(key) end, endKey
        )
    end

    local watcher = hs.application.watcher.new(function(_, event, application)
        if event == hs.application.watcher.launched
            and application and bundles[application:bundleID()] then
            poll(application)
        end
    end):start()

    -- Finder never relaunches: place a window only when it is the only one.
    local finderFilter
    if options.finderFirstWindow then
        finderFilter = hs.window.filter.new("Finder")
        finderFilter:subscribe(hs.window.filter.windowCreated, function(window)
            powerWindows:_after(FINDER_SETTLE, function()
                if not window:isStandard() then return end
                local application = window:application()
                if not application then return end
                for _, other in ipairs(application:allWindows()) do
                    if other:isStandard() and other:id() ~= window:id() then
                        return
                    end
                end
                if not powerWindows:_skipped(window) then
                    powerWindows:placeDefault(window)
                end
            end, "launch:finder:" .. tostring(window:id()))
        end)
    end

    return {
        stop = function()
            watcher:stop()
            if finderFilter then finderFilter:delete() end
            powerWindows:_cancelPrefix("launch:")
        end,
    }
end

return function(powerWindows, geometry)
    function powerWindows:_startLaunch()
        local options = self.config.experimental.placeOnLaunch
        if options then self._launch = watch(self, geometry, options) end
    end

    function powerWindows:_stopLaunch()
        if self._launch then
            self._launch.stop()
            self._launch = nil
        end
    end
end
