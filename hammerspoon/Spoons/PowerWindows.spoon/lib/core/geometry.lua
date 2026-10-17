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

-- A toolbar docked to the right of a window takes { width, height from the
-- window's top } beside it. sizes: { w, h, toolbar }.
local function cellsOf(sizes)
    local cells = {}
    for index, size in ipairs(sizes) do
        local toolbar = size.toolbar or { 0, 0 }
        cells[index] = {
            w = size.w + toolbar[1], h = math.max(size.h, toolbar[2]),
        }
    end
    return cells
end


-- Rows from the top, each filled from the right edge leftwards. Windows with
-- a toolbar first, so they share rows, the rest in the given order. Not by
-- current height: a window that grows would change rows on the next pass.
-- Returns the windows' frames (the toolbar stays free beside each), the rows
-- ({ top, height, members }) and whether everything fits the area, give or
-- take `slack` points.
local function shelves(area, sizes, betweenX, betweenY, slack)
    slack = slack or 0
    local cells = cellsOf(sizes)
    local order = {}
    for index in ipairs(sizes) do order[index] = index end
    local function toolbarHeight(index)
        return sizes[index].toolbar and sizes[index].toolbar[2] or 0
    end
    table.sort(order, function(first, second)
        if toolbarHeight(first) ~= toolbarHeight(second) then
            return toolbarHeight(first) > toolbarHeight(second)
        end
        return first < second
    end)
    local frames, rows, right = {}, {}, area.x + area.w
    local x, row, fits = right, nil, true
    for _, index in ipairs(order) do
        local cell = cells[index]
        if not row or (x < right and x - cell.w < area.x - slack) then
            local top = row and row.top + row.height + betweenY or area.y
            row = { top = top, height = 0, members = {} }
            rows[#rows + 1], x = row, right
        end
        frames[index] = {
            x = x - cell.w, y = row.top, w = sizes[index].w, h = sizes[index].h,
        }
        fits = fits and x - cell.w >= area.x - slack
        x = x - cell.w - betweenX
        row.height = math.max(row.height, cell.h)
        row.members[#row.members + 1] = index
    end
    fits = fits
        and (not row or row.top + row.height <= area.y + area.h + slack)
    return frames, rows, fits
end

local function stackSpacing(config, screenFrame)
    local gapX, gapY = geometry.gaps(config, screenFrame)
    return screenFrame.w * gapX * 2, screenFrame.h * gapY * 2
end

-- Enough halvings to land within a fraction of a point on any screen.
local SEARCH_STEPS = 40

-- The largest value in [low, high] that `fits` accepts, for a monotonic test.
local function largest(low, high, fits)
    if fits(high) then return high end
    for _ = 1, SEARCH_STEPS do
        local middle = (low + high) / 2
        if fits(middle) then low = middle else high = middle end
    end
    return low
end

-- One height for every window, the largest at which all of them fit the
-- column: few windows stay large (up to device.maxHeight), many shrink.
-- items: { aspect = height / width, toolbar }; returns their frames, or nil
-- when nothing fits at any height (a toolbar taller than the column).
function geometry.stackPlan(config, screenFrame, items)
    local column = geometry.rect(config, "column", screenFrame)
    local betweenX, betweenY = stackSpacing(config, screenFrame)
    local function at(height)
        local sizes = {}
        for index, item in ipairs(items) do
            sizes[index] = {
                w = height / item.aspect, h = height, toolbar = item.toolbar,
            }
        end
        return shelves(column, sizes, betweenX, betweenY)
    end
    local high = math.min(column.h, screenFrame.h * config.device.maxHeight)
    local height = largest(0, high, function(candidate)
        return select(3, at(candidate))
    end)
    if height > 0 then return (at(height)) end
end

-- share of the screen width the area grows by per try
local WIDEN_STEP = 0.01
-- points; an app rounding a planned size up must not cost a wider area
local FIT_SLACK = 1

-- The column, grown left over main only as far as the sizes need; past the
-- left edge the rows that do not fit are pulled up and overlap.
local function packed(config, screenFrame, sizes)
    local column = geometry.rect(config, "column", screenFrame)
    local betweenX, betweenY = stackSpacing(config, screenFrame)
    local right = column.x + column.w
    local leftmost =
        screenFrame.x + screenFrame.w * edgesFor(config, screenFrame).left
    local x = column.x
    while true do
        local area = { x = x, y = column.y, w = right - x, h = column.h }
        local frames, rows, fits =
            shelves(area, sizes, betweenX, betweenY, FIT_SLACK)
        if fits then return frames, rows, area end
        if x <= leftmost then
            -- Below the screen a window would land on a display under it.
            for _, frame in ipairs(frames) do
                frame.y = math.max(
                    area.y, math.min(frame.y, area.y + area.h - frame.h)
                )
            end
            return frames, rows, area
        end
        x = math.max(leftmost, x - screenFrame.w * WIDEN_STEP)
    end
end

-- Frames for the sizes the windows really took (an app has a minimum, some
-- refuse any size). sizes: { w, h, toolbar }.
function geometry.stackCells(config, screenFrame, sizes)
    return (packed(config, screenFrame, sizes))
end

-- How much each resizable window of a row may grow: up to the row's height,
-- the last row down to the bottom, and no wider than the area.
local function rowFactors(rows, sizes, area, betweenX, cap)
    local cells, factors = cellsOf(sizes), {}
    for position, row in ipairs(rows) do
        local limit = position == #rows
            and area.y + area.h - row.top or row.height
        local free = area.w - betweenX * (#row.members - 1)
        local growable, factor = 0, math.huge
        for _, index in ipairs(row.members) do
            local size = sizes[index]
            if size.fixed or size.h <= 0 then
                free = free - cells[index].w
            else
                free = free - (cells[index].w - size.w)
                growable = growable + size.w
                factor = math.min(factor, limit / size.h, cap / size.h)
            end
        end
        if growable > 0 then
            factor = math.max(1, math.min(factor, free / growable))
            for _, index in ipairs(row.members) do
                if not sizes[index].fixed then factors[index] = factor end
            end
        end
    end
    return factors
end

-- Resizable windows grow into the holes the packing leaves, within the area
-- the sizes already need: growing never takes more of main.
-- sizes: { w, h, toolbar, fixed }; returns the new sizes.
function geometry.stackGrow(config, screenFrame, sizes)
    local _, rows, area = packed(config, screenFrame, sizes)
    local betweenX, betweenY = stackSpacing(config, screenFrame)
    local factors = rowFactors(
        rows, sizes, area, betweenX, screenFrame.h * config.device.maxHeight
    )
    local function at(share)
        local grown = {}
        for index, size in ipairs(sizes) do
            local scale = 1 + ((factors[index] or 1) - 1) * share
            grown[index] = {
                w = size.w * scale, h = size.h * scale, toolbar = size.toolbar,
                fixed = size.fixed,
            }
        end
        return grown
    end
    -- A grown window can sort into another row; then all grow less.
    return at(largest(0, 1, function(share)
        return select(
            3, shelves(area, at(share), betweenX, betweenY, FIT_SLACK)
        )
    end))
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
