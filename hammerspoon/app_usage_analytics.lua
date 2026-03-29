-- App Usage Analytics
-- Silently tracks which app is focused and for how long
-- Writes daily JSON logs to ~/.local/share/hammerspoon/app-usage/
-- Toggle stats viewer via HotKeys fn handler

local M = {}
local log = hs.logger.new('AppUsage', 'info')

local dataDir = os.getenv("HOME") .. "/.local/share/hammerspoon/app-usage"
local currentApp = nil
local currentStart = nil
local todayEntries = {}
local flushTimer = nil
local statsWebview = nil
local statsEscHotkey = nil

-- Ensure data directory exists
hs.fs.mkdir(os.getenv("HOME") .. "/.local/share/hammerspoon")
hs.fs.mkdir(dataDir)

local function todayFile()
    return dataDir .. "/" .. os.date("%Y-%m-%d") .. ".json"
end

local function loadToday()
    local f = io.open(todayFile(), "r")
    if not f then return {} end
    local content = f:read("*all")
    f:close()
    local ok, data = pcall(hs.json.decode, content)
    if ok and data then return data end
    return {}
end

local function flushToday()
    local f = io.open(todayFile(), "w")
    if not f then return end
    f:write(hs.json.encode(todayEntries, true))
    f:close()
end

local function recordSwitch(appName, bundleId)
    local now = os.time()

    -- Close previous entry
    if currentApp and currentStart then
        local duration = now - currentStart
        if duration >= 2 then  -- ignore < 2s switches
            table.insert(todayEntries, {
                app = currentApp.name,
                bundle = currentApp.bundle,
                start = currentStart,
                duration = duration
            })
        end
    end

    currentApp = { name = appName, bundle = bundleId }
    currentStart = now
end

-- Load existing data on init
todayEntries = loadToday()

-- Register with centralized app watcher
appWatcherHub.register(function(appName, eventType, appObject)
    if eventType ~= hs.application.watcher.activated then return end
    if not appObject then return end
    local bundleId = appObject:bundleID() or "unknown"
    recordSwitch(appName or "unknown", bundleId)
end)

-- Flush to disk every 60 seconds
flushTimer = hs.timer.doEvery(60, flushToday)

-- Also flush on midnight rollover
local midnightTimer = hs.timer.doEvery(300, function()
    local file = todayFile()
    if todayEntries[1] and todayEntries[1].start then
        local entryDate = os.date("%Y-%m-%d", todayEntries[1].start)
        local today = os.date("%Y-%m-%d")
        if entryDate ~= today then
            flushToday()  -- flush old day
            todayEntries = {}  -- start fresh
            currentStart = os.time()
        end
    end
end)

-- Aggregate stats from entries
local function aggregateEntries(entries)
    local byApp = {}
    local totalTime = 0
    for _, entry in ipairs(entries) do
        local name = entry.app
        if not byApp[name] then
            byApp[name] = { name = name, duration = 0, sessions = 0 }
        end
        byApp[name].duration = byApp[name].duration + entry.duration
        byApp[name].sessions = byApp[name].sessions + 1
        totalTime = totalTime + entry.duration
    end

    local sorted = {}
    for _, v in pairs(byApp) do table.insert(sorted, v) end
    table.sort(sorted, function(a, b) return a.duration > b.duration end)

    return sorted, totalTime
end

local function loadDaysBack(days)
    local all = {}
    for i = 0, days - 1 do
        local date = os.date("%Y-%m-%d", os.time() - i * 86400)
        local file = dataDir .. "/" .. date .. ".json"
        local f = io.open(file, "r")
        if f then
            local content = f:read("*all")
            f:close()
            local ok, data = pcall(hs.json.decode, content)
            if ok and data then
                for _, entry in ipairs(data) do
                    table.insert(all, entry)
                end
            end
        end
    end
    -- Add current live session
    if currentApp and currentStart then
        table.insert(all, {
            app = currentApp.name,
            bundle = currentApp.bundle,
            start = currentStart,
            duration = os.time() - currentStart
        })
    end
    return all
end

local function formatDuration(seconds)
    if seconds >= 3600 then
        return string.format("%.1fh", seconds / 3600)
    elseif seconds >= 60 then
        return string.format("%dm", math.floor(seconds / 60))
    else
        return string.format("%ds", seconds)
    end
end

local function escapeHtml(str)
    if not str then return "" end
    return str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local function buildHtml()
    -- Today stats
    local todayAll = loadDaysBack(1)
    local todayApps, todayTotal = aggregateEntries(todayAll)

    -- 7-day stats
    local weekAll = loadDaysBack(7)
    local weekApps, weekTotal = aggregateEntries(weekAll)

    local function renderTable(apps, total, maxRows)
        local html = ""
        for i, app in ipairs(apps) do
            if i > maxRows then break end
            local pct = total > 0 and (app.duration / total * 100) or 0
            local barWidth = math.floor(pct * 2)
            local color = pct > 25 and "#fb4934" or (pct > 10 and "#fabd2f" or "#b8bb26")
            html = html .. string.format(
                '<div class="row">' ..
                '<span class="name">%s</span>' ..
                '<span class="bar" style="width:%dpx;background:%s"></span>' ..
                '<span class="time">%s</span>' ..
                '<span class="pct">%d%%</span>' ..
                '</div>',
                escapeHtml(app.name), barWidth, color,
                formatDuration(app.duration), math.floor(pct))
        end
        return html
    end

    return [[<!DOCTYPE html><html><head><meta charset="UTF-8"><style>
* { margin: 0; padding: 0; box-sizing: border-box; }
body { background: #1d2021; color: #ebdbb2; font-family: "JetBrainsMono Nerd Font", monospace;
       font-size: 12px; padding: 16px; user-select: none; -webkit-user-select: none; }
.header { color: #fe8019; font-size: 14px; font-weight: bold; margin-bottom: 12px;
           padding-bottom: 8px; border-bottom: 1px solid #3c3836; }
.section { margin-bottom: 16px; }
.section-title { color: #83a598; font-size: 11px; font-weight: bold; text-transform: uppercase;
                  letter-spacing: 1px; margin-bottom: 8px; }
.total { color: #928374; font-size: 11px; margin-bottom: 8px; }
.row { display: flex; align-items: center; padding: 3px 0; gap: 8px; }
.name { width: 140px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.bar { height: 10px; border-radius: 2px; min-width: 2px; }
.time { width: 50px; text-align: right; color: #d5c4a1; }
.pct { width: 35px; text-align: right; color: #928374; font-size: 11px; }
.footer { text-align: center; color: #665c54; font-size: 10px; margin-top: 12px;
           padding-top: 8px; border-top: 1px solid #3c3836; }
</style></head><body>
<div class="header">App Usage</div>
<div class="section">
  <div class="section-title">Today</div>
  <div class="total">Total: ]] .. formatDuration(todayTotal) .. [[</div>
  ]] .. renderTable(todayApps, todayTotal, 12) .. [[
</div>
<div class="section">
  <div class="section-title">Last 7 Days</div>
  <div class="total">Total: ]] .. formatDuration(weekTotal) .. [[</div>
  ]] .. renderTable(weekApps, weekTotal, 15) .. [[
</div>
<div class="footer">Press Esc to close</div>
</body></html>]]
end

function M.toggle()
    if statsWebview then
        statsWebview:delete()
        statsWebview = nil
        if statsEscHotkey then statsEscHotkey:disable() end
        return
    end

    -- Flush current data first
    recordSwitch(currentApp and currentApp.name or "unknown",
                 currentApp and currentApp.bundle or "unknown")
    flushToday()

    local screen = hs.screen.mainScreen():frame()
    local width = 420
    local height = 520
    local x = screen.x + (screen.w - width) / 2
    local y = screen.y + (screen.h - height) / 2

    statsWebview = hs.webview.new({ x = x, y = y, w = width, h = height })
    statsWebview:windowStyle({ "titled", "closable" })
    statsWebview:shadow(true)
    statsWebview:windowTitle("App Usage")
    statsWebview:html(buildHtml())
    statsWebview:bringToFront(true)
    statsWebview:show()

    statsWebview:windowCallback(function(action)
        if action == "closing" then
            statsWebview = nil
            if statsEscHotkey then statsEscHotkey:disable() end
        end
        return false
    end)

    if not statsEscHotkey then
        statsEscHotkey = hs.hotkey.new({}, "escape", function()
            if statsWebview then
                statsWebview:delete()
                statsWebview = nil
            end
            statsEscHotkey:disable()
        end)
    end
    statsEscHotkey:enable()
end

-- Public flush for other modules (e.g., meeting detector)
function M.flush()
    flushToday()
end

return M
