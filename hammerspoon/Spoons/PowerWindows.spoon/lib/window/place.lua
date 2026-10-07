-- Video in the corner fits the video box, which keeps a gap above the bottom
-- edge.
local ASPECT_AREA = {
    main = "main", full = "full", corner = "video", side = "side",
}
local ASPECT_ANCHOR = {
    main = "topLeft", full = "center", corner = "top", side = "topLeft",
}

local axuielement = require("hs.axuielement")

-- points; sub-point differences are rounding
local SAME_SIZE_TOLERANCE = 0.5
-- points; a larger miss after a write was clamped
local CLAMP_TOLERANCE = 2
local ANIMATION_FRAME = 1 / 60

local function missed(got, rect)
    return math.abs(got.x - rect.x) > CLAMP_TOLERANCE
        or math.abs(got.y - rect.y) > CLAMP_TOLERANCE
        or math.abs(got.w - rect.w) > CLAMP_TOLERANCE
        or math.abs(got.h - rect.h) > CLAMP_TOLERANCE
end

-- One AX write per property: hs.window:setFrame always writes size, position,
-- size, and Telegram and Zap repaint for each (measured 2–3 frames over up to
-- 400 ms, against one). Grow = move first, shrink = resize first, so the window
-- is never oversized in the old spot.
local function writeFrame(window, element, rect, correct)
    local frame = window:frame()
    local position, size =
        { x = rect.x, y = rect.y }, { w = rect.w, h = rect.h }
    if math.abs(rect.w - frame.w) < SAME_SIZE_TOLERANCE
        and math.abs(rect.h - frame.h) < SAME_SIZE_TOLERANCE then
        element:setAttributeValue("AXPosition", position)
    elseif rect.w * rect.h > frame.w * frame.h then
        element:setAttributeValue("AXPosition", position)
        element:setAttributeValue("AXSize", size)
    else
        element:setAttributeValue("AXSize", size)
        element:setAttributeValue("AXPosition", position)
    end
    -- A frame clamped by the screen edge (size, or position moved by macOS on
    -- a screen change) lands on a retry, like setFrame's third step, but only
    -- when it is needed.
    if correct and missed(window:frame(), rect) then
        element:setAttributeValue("AXSize", size)
        element:setAttributeValue("AXPosition", position)
    end
end

-- Chromium and Electron animate every AX write while AXEnhancedUserInterface
-- is on; Rectangle, Amethyst, Phoenix and hs.window:setFrame lift it the same
-- way. Restored even when a write fails: left off, it breaks VoiceOver for
-- that app.
local function withPlainInterface(window, body)
    local application = window:application()
    if not application then return end
    local applicationElement = axuielement.applicationElement(application)
    local enhanced = applicationElement
        and applicationElement:attributeValue("AXEnhancedUserInterface")
    if enhanced then
        applicationElement:setAttributeValue("AXEnhancedUserInterface", false)
    end
    local written, problem = pcall(body, axuielement.windowElement(window))
    if enhanced then
        applicationElement:setAttributeValue("AXEnhancedUserInterface", true)
    end
    if not written then error(problem, 0) end
end

-- correct = false: skip the retry (animation steps, a size that is read back
-- anyway).
local function write(window, rect, correct)
    withPlainInterface(window, function(element)
        writeFrame(window, element, rect, correct ~= false)
    end)
end

local function writePosition(window, position)
    withPlainInterface(window, function(element)
        element:setAttributeValue("AXPosition", position)
    end)
end

return function(powerWindows, geometry, query)
    local function moveKey(window) return "move:" .. tostring(window:id()) end

    -- By window id: the rect asked for and the frame the window was left
    -- with, when its app refused the size.
    local refused = {}

    -- An app that refuses the size (its minimum is larger) hangs over the
    -- screen edge in the right column: the last write of a move pulls the
    -- window back inside, by position only.
    local function writeKeepingOnScreen(window, rect)
        write(window, rect)
        local id, frame = window:id(), window:frame()
        if id then refused[id] = nil end
        if frame.w <= rect.w + CLAMP_TOLERANCE
            and frame.h <= rect.h + CLAMP_TOLERANCE then
            return
        end
        for _, screen in ipairs(hs.screen.allScreens()) do
            if geometry.contains(screen:fullFrame(), rect) then
                writePosition(window, geometry.inside(frame, screen:frame()))
                if id then
                    refused[id] = { rect = rect, frame = window:frame() }
                end
                return
            end
        end
    end

    -- Asked again for the slot it could not shrink into, the window would
    -- slide out over the edge and back.
    local function restsRefused(window, rect, frame)
        local before = refused[window:id() or false]
        return before ~= nil
            and geometry.near(before.rect, rect, SAME_SIZE_TOLERANCE)
            and geometry.near(before.frame, frame, CLAMP_TOLERANCE)
    end

    -- Every direct write first stops a running animation, or its next step
    -- drags the window back.
    function powerWindows:_write(window, rect)
        self:_cancel(moveKey(window))
        writeKeepingOnScreen(window, rect)
    end

    -- Time-based, so a slow app drops steps instead of stretching the move;
    -- every step is one ordered write, and a new move of the same window
    -- cancels the old one.
    function powerWindows:_set(window, rect)
        local key = moveKey(window)
        self:_cancel(key)
        local from = window:frame()
        if geometry.near(from, rect, SAME_SIZE_TOLERANCE) then return end
        if restsRefused(window, rect, from) then return end
        local duration = self.config.animation
        if duration <= 0 then return writeKeepingOnScreen(window, rect) end
        local start = hs.timer.secondsSinceEpoch()
        self:_every(ANIMATION_FRAME, function()
            local progress = math.min(
                1, (hs.timer.secondsSinceEpoch() - start) / duration
            )
            local eased = 1 - (1 - progress) ^ 3
            if progress >= 1 then
                writeKeepingOnScreen(window, rect)
                return true
            end
            write(window, {
                x = from.x + (rect.x - from.x) * eased,
                y = from.y + (rect.y - from.y) * eased,
                w = from.w + (rect.w - from.w) * eased,
                h = from.h + (rect.h - from.h) * eased,
            }, false)
        end, key)
    end

    -- Chromium PiP caps at ~80% of the requested area but keeps the top-left:
    -- size, read back, position.
    function powerWindows:_fit(window, box, anchor)
        local current = window:frame()
        if current.w == 0 or current.h == 0 then return end
        self:_cancel(moveKey(window))
        write(
            window, geometry.fit(box, current.h / current.w, anchor), false
        )
        local actual = window:frame()
        write(window, geometry.anchor(box, actual.w, actual.h, anchor))
    end

    function powerWindows:_placeDevice(window, config, screenFrame, slot)
        local current = window:frame()
        if current.w == 0 or current.h == 0 then return end
        self:_set(window, geometry.devicePlace(
            config, screenFrame, current.h / current.w, slot
        ))
    end

    function powerWindows:_place(window, resolved, slot, screen)
        local config, screenFrame = self:_screenLayoutOf(window, screen)
        if not screenFrame then return end
        slot = slot or resolved.slot
        if slot == "dialog" then
            self:_set(window, geometry.smallDialog(
                config, screenFrame, window:frame()
            ))
        elseif resolved.device then
            self:_placeDevice(window, config, screenFrame, slot)
        elseif slot == "stack" and resolved.keepAspect then
            self:_fit(
                window, geometry.rect(config, "side", screenFrame), "topLeft"
            )
        elseif slot == "stack" then
            self:_set(window, geometry.rect(config, "side", screenFrame))
        elseif resolved.keepAspect then
            self:_fit(
                window, geometry.rect(config, ASPECT_AREA[slot], screenFrame),
                ASPECT_ANCHOR[slot]
            )
        else
            self:_set(window, geometry.rect(config, slot, screenFrame))
        end
    end

    local function restackColumnOf(self, window)
        local screen = window:screen()
        if screen then self:_placeStack(screen) end
    end

    function powerWindows:_resolveOr(window, slot)
        return self:resolve(window) or { slot = slot }
    end

    --- PowerWindows:placeDefault([window])
    --- Method
    --- Puts `window` (default: focused) in its slot; a stack window re-lays the
    --- column.
    function powerWindows:placeDefault(window)
        window = window or query.focused()
        if not window then return end
        local resolved = self:resolve(window)
        if not resolved then return end
        if resolved.slot == "stack" then
            return restackColumnOf(self, window)
        end
        self:_place(window, resolved)
    end

    --- PowerWindows:moveLeft([window])
    --- Method
    --- Puts `window` (default: focused) into the big left slot.
    function powerWindows:moveLeft(window)
        window = window or query.focused()
        if not window then return end
        self:_place(window, self:_resolveOr(window, "main"), "main")
    end

    --- PowerWindows:moveRight([window])
    --- Method
    --- Puts `window` (default: focused) into the right column; corner and
    --- dialog keep their slot, a stack window re-lays the column.
    function powerWindows:moveRight(window)
        window = window or query.focused()
        if not window then return end
        local resolved = self:_resolveOr(window, "side")
        if resolved.slot == "stack" then
            return restackColumnOf(self, window)
        end
        local slot = (resolved.slot == "corner" or resolved.slot == "dialog")
            and resolved.slot or "side"
        self:_place(window, resolved, slot)
    end

    --- PowerWindows:moveFull([window])
    --- Method
    --- Stretches `window` (default: focused) over the screen with gaps; not
    --- native fullscreen.
    function powerWindows:moveFull(window)
        window = window or query.focused()
        if not window then return end
        self:_place(window, self:_resolveOr(window, "main"), "full")
    end

    function powerWindows:_isAt(window, area)
        local config, screenFrame = self:_screenLayoutOf(window)
        return screenFrame ~= nil
            and geometry.isAt(
                window:frame(), geometry.rect(config, area, screenFrame),
                self.config.tolerance
            )
    end
end
