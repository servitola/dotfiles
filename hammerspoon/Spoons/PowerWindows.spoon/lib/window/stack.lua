-- A window not yet drawn has no size to take the shape from: a phone.
local FALLBACK_ASPECT = 2
-- seconds; an app may apply its minimum size late (Android Emulator: ~0.6 s,
-- measured), so the first read-back can be too small.
local SETTLE = 1
-- _place cancels these for a stack window: moved out, it must stay moved.
local STACK_TIMER = "stack:"

local axuielement = require("hs.axuielement")

return function(powerWindows, geometry, query)
    function powerWindows:_stackWindows(screen)
        local list = {}
        for _, window in ipairs(hs.window.visibleWindows()) do
            if query.isOnScreen(window, screen) and window:isStandard()
                and not self:_skipped(window) then
                local resolved = self:resolve(window)
                if resolved and resolved.slot == "stack" then
                    list[#list + 1] = { window = window, resolved = resolved }
                end
            end
        end
        table.sort(list, function(first, second)
            return first.window:id() < second.window:id()
        end)
        return list
    end

    -- The iOS Simulator with bezels: AXSize is read-only.
    local function resizable(window)
        local element = axuielement.windowElement(window)
        return element ~= nil and element:isAttributeSettable("AXSize")
    end

    local function measure(list)
        local sizes = {}
        for index, item in ipairs(list) do
            local frame = item.window:frame()
            sizes[index] = {
                w = frame.w, h = frame.h, toolbar = item.resolved.toolbar,
                fixed = not resizable(item.window),
            }
        end
        return sizes
    end

    -- Positions from the sizes the windows really have, so one that refuses
    -- or clamps its size still gets a free spot.
    local function arrange(self, screen, list)
        local config, screenFrame = self:_screenLayout(screen)
        local sizes = measure(list)
        local frames = geometry.stackCells(config, screenFrame, sizes)
        for index, item in ipairs(list) do
            local frame, cell = item.window:frame(), frames[index]
            if math.abs(frame.x - cell.x) > config.tolerance
                or math.abs(frame.y - cell.y) > config.tolerance then
                self:_write(item.window, {
                    x = cell.x, y = cell.y, w = frame.w, h = frame.h,
                })
            end
        end
    end

    local function grow(self, screen, list)
        local config, screenFrame = self:_screenLayout(screen)
        local sizes = measure(list)
        local grown = geometry.stackGrow(config, screenFrame, sizes)
        local frames = geometry.stackCells(config, screenFrame, grown)
        local changed = false
        for index, item in ipairs(list) do
            if grown[index].h > sizes[index].h + config.tolerance then
                self:_write(item.window, frames[index])
                changed = true
            end
        end
        return changed
    end

    -- Three passes: one height that fits the column; then, once the apps have
    -- settled on the sizes they accept, positions from those sizes and growth
    -- into the room left; positions again if anything grew.
    function powerWindows:_cancelStackTimers()
        self:_cancelPrefix(STACK_TIMER)
    end

    function powerWindows:_placeStack(screen)
        local list = self:_stackWindows(screen)
        if #list == 0 then return end
        local config, screenFrame = self:_screenLayout(screen)
        local items = {}
        for index, item in ipairs(list) do
            local frame = item.window:frame()
            items[index] = {
                aspect = frame.w > 0 and frame.h > 0 and frame.h / frame.w
                    or FALLBACK_ASPECT,
                toolbar = item.resolved.toolbar,
            }
        end
        local frames = geometry.stackPlan(config, screenFrame, items)
        for index, item in ipairs(frames and list or {}) do
            self:_write(item.window, frames[index])
        end
        arrange(self, screen, list)
        local key = STACK_TIMER .. tostring(screen:id())
        self:_after(SETTLE, function()
            local current = self:_stackWindows(screen)
            local grew = grow(self, screen, current)
            arrange(self, screen, current)
            if not grew then return end
            self:_after(SETTLE, function()
                arrange(self, screen, self:_stackWindows(screen))
            end, key)
        end, key)
    end
end
