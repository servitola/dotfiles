local axuielement = require("hs.axuielement")

return function(powerWindows, settings)
    local query = {}

    function query.focused() return hs.window.focusedWindow() end

    function query.isOnScreen(window, screen)
        local windowScreen = window:screen()
        return windowScreen ~= nil and windowScreen:id() == screen:id()
    end

    function powerWindows:_screenLayout(screen)
        local full = screen:fullFrame()
        return settings.forScreen(
            self.config, { name = screen:name(), w = full.w, h = full.h }
        ), screen:frame()
    end

    function powerWindows:_screenLayoutOf(window, screen)
        screen = screen or window:screen()
        if screen then return self:_screenLayout(screen) end
    end

    function query.info(window)
        local application = window:application()
        local frame = window:frame()
        local element = axuielement.windowElement(window)
        return {
            bundle = application and application:bundleID(),
            app = application and application:title() or "",
            title = window:title() or "", w = frame.w, h = frame.h,
            identifier = element and element:attributeValue("AXIdentifier"),
        }
    end

    function powerWindows:_skipped(window)
        for _, predicate in ipairs(self._skip) do
            local ok, skip = pcall(predicate, window)
            if not ok then
                print("PowerWindows: skip predicate: " .. tostring(skip))
            elseif skip then
                return true
            end
        end
        return false
    end

    --- PowerWindows:isDecoration([window]) -> boolean
    --- Method
    --- True for never-touched windows and fitted corner video (PiP); swaps and
    --- focus-next skip them.
    function powerWindows:isDecoration(window)
        window = window or query.focused()
        if not window then return false end
        local resolved = self:resolve(window)
        return resolved == false
            or (resolved.slot == "corner" and resolved.keepAspect == true)
    end

    function powerWindows:_isCandidate(window)
        return window:isStandard() and window:isVisible()
            and not self:isDecoration(window)
    end

    return query
end
