-- Parking a window on the external screen: pure geometry + a registry.
--
-- The module doesn't import hs.* and doesn't know about topology. A window
-- for it is an object with :id()/:frame()/:screen(), a frame is a
-- {x,y,w,h} table.
local P = {}

local function approx(a, b, tol)
    return math.abs(a - b) <= tol
end

-- Verify the actual result of setFrame.
--
-- Some windows accept the position but silently reject the size (Finder
-- copy dialogs — verified live: an AXStandardWindow that ignores setFrame,
-- setSize and setFrameCorrectness alike). Without this check, such a window
-- would end up a tiny rectangle in the corner of the TV, with the user
-- unable to tell why.
function P.classify_park_result(win_frame, target_frame, tolerance)
    local moved = approx(win_frame.x, target_frame.x, tolerance)
        and approx(win_frame.y, target_frame.y, tolerance)
    if not moved then return "wrong_screen" end

    local resized = approx(win_frame.w, target_frame.w, tolerance)
        and approx(win_frame.h, target_frame.h, tolerance)
    if not resized then return "size_rejected" end

    return "ok"
end

-- Where to put a window that refused to resize: centered on the screen,
-- keeping its own dimensions.
function P.centered_frame(win_frame, target_frame)
    return {
        x = target_frame.x + (target_frame.w - win_frame.w) / 2,
        y = target_frame.y + (target_frame.h - win_frame.h) / 2,
        w = win_frame.w,
        h = win_frame.h,
    }
end

-- Registry of parked windows. A factory, not a singleton: tests need a
-- clean registry on every run.
--
-- deps.get_window(id) -> window or nil. Defaults to hs.window.get.
function P.new_registry(deps)
    deps = deps or {}
    local get_window = deps.get_window or function(id) return hs.window.get(id) end

    local R = { entries = {} }

    -- Doesn't overwrite an existing entry: the window's original frame must
    -- survive repeated hotkey presses.
    function R:record(win)
        local id = win:id()
        if self.entries[id] then return self.entries[id] end
        self.entries[id] = {
            frame = win:frame(),
            screen_uuid = win:screen():getUUID(),
        }
        return self.entries[id]
    end

    function R:is_parked(win)
        if not win then return false end
        return self.entries[win:id()] ~= nil
    end

    function R:take(win)
        local id = win:id()
        local entry = self.entries[id]
        self.entries[id] = nil
        return entry
    end

    function R:forget(win)
        self.entries[win:id()] = nil
    end

    -- Lazy cleanup: no separate window-destruction watcher is set up.
    function R:prune()
        for id in pairs(self.entries) do
            if not get_window(id) then self.entries[id] = nil end
        end
    end

    function R:ids()
        local out = {}
        for id in pairs(self.entries) do table.insert(out, id) end
        table.sort(out)
        return out
    end

    return R
end

return P
