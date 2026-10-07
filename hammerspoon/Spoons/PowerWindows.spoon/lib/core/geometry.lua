local geometry = {}

-- Right and bottom margins differ from the gap: tuned by eye.
local RIGHT_GAP_DIVISOR, BOTTOM_GAP_FACTOR = 1.5, 1.5

-- Gap in points becomes a share per axis, so every formula below stays in
-- fractions.
function geometry.gaps(config, screenFrame)
    if config.gap < 1 then return config.gap, config.gap end
    return config.gap / screenFrame.w, config.gap / screenFrame.h
end

local function edgesFor(config, screenFrame)
    local gapX, gapY = geometry.gaps(config, screenFrame)
    return {
        gapX = gapX, gapY = gapY, betweenX = gapX * 2, betweenY = gapY * 2,
        left = gapX, top = gapY,
        right = 1 - gapX / RIGHT_GAP_DIVISOR,
        bottom = 1 - gapY * BOTTOM_GAP_FACTOR,
    }
end

local function areaFraction(config, area, screenFrame)
    local edges = edgesFor(config, screenFrame)
    local split, side, top = config.split, config.sideHeight, config.topShare
    local left, upper, right, bottom =
        edges.left, edges.top, edges.right, edges.bottom
    local gapY, betweenX, betweenY = edges.gapY, edges.betweenX, edges.betweenY
    local rects = {
        main      = { left, upper, split - betweenX, bottom - upper },
        side      = { split, upper, right - split, side - gapY },
        corner    = {
            split, side + betweenY, right - split, 1 - side - betweenY,
        },
        video     = {
            split, side + betweenY, right - split, 1 - side - betweenY * 2,
        },
        full      = { left, upper, right - left, bottom - upper },
        halfLeft  = { left, upper, 0.5 - betweenX, bottom - upper },
        halfRight = { 0.5, upper, right - 0.5, bottom - upper },
        top60     = { left, upper, right - left, top - betweenY },
        bottom40  = { left, top, right - left, bottom - top },
        -- stack windows share it
        column    = { split, upper, right - split, bottom - upper },
    }
    local rect = assert(
        rects[area], "PowerWindows: unknown rect " .. tostring(area)
    )
    return { x = rect[1], y = rect[2], w = rect[3], h = rect[4] }
end

function geometry.rect(config, area, screenFrame)
    local fraction = areaFraction(config, area, screenFrame)
    return {
        x = screenFrame.x + screenFrame.w * fraction.x,
        y = screenFrame.y + screenFrame.h * fraction.y,
        w = screenFrame.w * fraction.w, h = screenFrame.h * fraction.h,
    }
end

function geometry.anchor(box, width, height, anchor)
    if anchor == "center" then
        return {
            x = box.x + (box.w - width) / 2, y = box.y + (box.h - height) / 2,
            w = width, h = height,
        }
    elseif anchor == "top" then
        -- Wider than the box (the app's minimum size): the right edge stays, or
        -- the window leaves the screen.
        return {
            x = box.x + math.min((box.w - width) / 2, box.w - width),
            y = box.y, w = width, h = height,
        }
    end
    return { x = box.x, y = box.y, w = width, h = height }
end

function geometry.fit(box, aspect, anchor)
    local width, height = box.w, box.w * aspect
    if height > box.h then
        height = box.h
        width = height / aspect
    end
    return geometry.anchor(box, width, height, anchor)
end

-- Sized off the screen, not a slot: the column is too narrow for a readable
-- phone.
function geometry.deviceSize(config, screenFrame, aspect)
    local width = screenFrame.w * config.device.width
    local height = width * aspect
    if height > screenFrame.h * config.device.maxHeight then
        height = screenFrame.h * config.device.maxHeight
        width = height / aspect
    end
    return width, height
end

function geometry.devicePlace(config, screenFrame, aspect, slot)
    local width, height = geometry.deviceSize(config, screenFrame, aspect)
    local gapX, gapY = geometry.gaps(config, screenFrame)
    local raise = screenFrame.h * config.device.raise
    local left, top
    if slot == "full" then
        left = screenFrame.x + (screenFrame.w - width) / 2
        top = screenFrame.y + (screenFrame.h - height) / 2 - raise
    elseif slot == "main" then
        left = screenFrame.x + screenFrame.w * gapX
        top = screenFrame.y + (screenFrame.h - height) / 2 - raise
    else
        left = screenFrame.x + screenFrame.w * config.split
        top = screenFrame.y + screenFrame.h * gapY
    end
    return { x = left, y = top, w = width, h = height }
end

function geometry.stackCells(config, screenFrame, count)
    local column = geometry.rect(config, "column", screenFrame)
    local _, gapY = geometry.gaps(config, screenFrame)
    local between = screenFrame.h * gapY * 2
    local height = (column.h - between * (count - 1)) / count
    local cells = {}
    for index = 1, count do
        local top = column.y + (index - 1) * (height + between)
        cells[index] = { x = column.x, y = top, w = column.w, h = height }
    end
    return cells
end

function geometry.smallDialog(config, screenFrame, current)
    local edges = edgesFor(config, screenFrame)
    local width = math.min(
        current.w,
        screenFrame.w * (edges.right - config.split) * config.dialog.width
    )
    local height = math.min(
        current.h, screenFrame.h * config.sideHeight * config.dialog.height
    )
    return {
        x = screenFrame.x + screenFrame.w * (1 - edges.gapX) - width,
        y = screenFrame.y + edges.top * screenFrame.h,
        w = width, h = height,
    }
end

-- Where a frame of this size goes to lie inside the area; the top left corner
-- wins when it is larger than the area.
function geometry.inside(frame, area)
    return {
        x = math.max(area.x, math.min(frame.x, area.x + area.w - frame.w)),
        y = math.max(area.y, math.min(frame.y, area.y + area.h - frame.h)),
    }
end

function geometry.contains(area, point)
    return point.x >= area.x and point.x < area.x + area.w
        and point.y >= area.y and point.y < area.y + area.h
end

function geometry.near(first, second, tolerance)
    return math.abs(first.x - second.x) <= tolerance
        and math.abs(first.y - second.y) <= tolerance
        and math.abs(first.w - second.w) <= tolerance
        and math.abs(first.h - second.h) <= tolerance
end

-- Terminal and iTerm snap their size to whole text cells, so a placed one can
-- fall short of its slot by up to a cell; the origin still has to match.
local CELL_SLACK = 24

function geometry.isAt(frame, rect, tolerance)
    local sizeTolerance = tolerance + CELL_SLACK
    return math.abs(frame.x - rect.x) <= tolerance
        and math.abs(frame.y - rect.y) <= tolerance
        and math.abs(frame.w - rect.w) <= sizeTolerance
        and math.abs(frame.h - rect.h) <= sizeTolerance
end

local KEPT_SLOTS = {
    "main", "side", "corner", "full", "halfLeft", "halfRight", "top60",
    "bottom40",
}

function geometry.slotAt(config, screenFrame, frame, tolerance)
    for _, slot in ipairs(KEPT_SLOTS) do
        if geometry.isAt(
            frame, geometry.rect(config, slot, screenFrame), tolerance
        ) then
            return slot
        end
    end
end

return geometry
