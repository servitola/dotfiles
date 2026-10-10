-- Passive input logger: combos (key/mouse, always on) + text (keyDown chars, toggleable).

local log = hs.logger.new('InputLogger', 'info')

local dataDir = os.getenv("HOME") .. "/Library/Application Support/Hammerspoon/InputLogger"

local frontmostBundleId = nil
local textLayerEnabled = hs.settings.get("InputLogger.textLayerEnabled")
if textLayerEnabled == nil then textLayerEnabled = false end -- text is the riskier layer (spec 2.2): opt in, not opt out

local comboQueue = {}
local textQueue = {}

local function shellQuote(path)
    return "'" .. path:gsub("'", "'\\''") .. "'"
end

hs.fs.mkdir(os.getenv("HOME") .. "/Library/Application Support/Hammerspoon") -- did not exist on this machine; verified before writing this
hs.fs.mkdir(dataDir)
hs.execute("chmod 700 " .. shellQuote(dataDir))

do
    local app = hs.application.frontmostApplication()
    if app then frontmostBundleId = app:bundleID() end
end

appWatcherHub.register(function(appName, eventType, appObject)
    if eventType ~= hs.application.watcher.activated then return end
    if not appObject then return end
    frontmostBundleId = appObject:bundleID() or frontmostBundleId
end)

hs.settings.watchKey("InputLoggerTextToggle", "InputLogger.textLayerEnabled", function()
    local v = hs.settings.get("InputLogger.textLayerEnabled")
    textLayerEnabled = (v == true)
end)

local function nowMs()
    return math.floor(hs.timer.secondsSinceEpoch() * 1000)
end

local DOWN_TYPES = {
    [hs.eventtap.event.types.keyDown] = true,
    [hs.eventtap.event.types.leftMouseDown] = true,
    [hs.eventtap.event.types.rightMouseDown] = true,
    [hs.eventtap.event.types.otherMouseDown] = true,
}

local MOD_BY_KEYCODE = {
    [54] = "cmd", [55] = "cmd",
    [56] = "shift", [60] = "shift",
    [58] = "alt", [61] = "alt",
    [59] = "ctrl", [62] = "ctrl",
    [57] = "capslock", [63] = "fn",
}

local SIDE_BY_KEYCODE = {
    [54] = "right", [55] = "left",
    [56] = "left", [60] = "right",
    [58] = "left", [61] = "right",
    [59] = "left", [62] = "right",
}

local function mouseCode(eventType, event)
    if eventType == hs.eventtap.event.types.leftMouseDown or eventType == hs.eventtap.event.types.leftMouseUp then
        return "left"
    elseif eventType == hs.eventtap.event.types.rightMouseDown or eventType == hs.eventtap.event.types.rightMouseUp then
        return "right"
    else
        local buttonNumber = event:getProperty(hs.eventtap.event.properties.mouseEventButtonNumber)
        return "other" .. tostring(buttonNumber)
    end
end

local function onComboEvent(event)
    local eventType = event:getType()

    if eventType == hs.eventtap.event.types.flagsChanged then
        local keyCode = event:getKeyCode()
        local flags = event:getFlags()
        local modName = MOD_BY_KEYCODE[keyCode]

        table.insert(comboQueue, {
            type = "mod",
            code = keyCode,
            modifiers = flags,
            app = frontmostBundleId,
            ts = nowMs(),
            -- flagsChanged carries no down/up of its own: infer it from whether
            -- this modifier is still present in the resulting flag set
            state = (modName and flags[modName]) and "down" or "up",
            side = SIDE_BY_KEYCODE[keyCode],
            autorepeat = false,
        })

        return false
    end

    local isKey = (eventType == hs.eventtap.event.types.keyDown or eventType == hs.eventtap.event.types.keyUp)

    table.insert(comboQueue, {
        type = isKey and "key" or "mouse",
        code = isKey and event:getKeyCode() or mouseCode(eventType, event),
        modifiers = event:getFlags(),
        app = frontmostBundleId,
        ts = nowMs(),
        state = DOWN_TYPES[eventType] and "down" or "up",
        autorepeat = isKey and (event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) == 1) or false,
    })

    return false
end

local function onTextEvent(event)
    if not textLayerEnabled then return false end

    local char = event:getCharacters()
    if not char or #char == 0 then return false end

    table.insert(textQueue, {
        type = "key",
        code = event:getKeyCode(),
        modifiers = event:getFlags(),
        app = frontmostBundleId,
        ts = nowMs(),
        state = "down",
        autorepeat = event:getProperty(hs.eventtap.event.properties.keyboardEventAutorepeat) == 1,
        char = char,
    })

    return false
end

local function writeQueueToFile(queue, filePrefix)
    local path = dataDir .. "/" .. filePrefix .. "-" .. os.date("%Y-%m") .. ".jsonl"
    local file, err = io.open(path, "a")
    if not file then
        error("cannot open " .. path .. ": " .. tostring(err))
    end
    for _, entry in ipairs(queue) do
        file:write(hs.json.encode(entry), "\n")
    end
    file:close()
    hs.execute("chmod 600 " .. shellQuote(path))
end

local function flushLayer(queue, filePrefix)
    if #queue == 0 then return {} end
    local ok, err = pcall(writeQueueToFile, queue, filePrefix)
    if not ok then
        log.e("Failed to flush " .. filePrefix .. " log, dropping " .. #queue .. " queued entries: " .. tostring(err))
    end
    return {}
end

local function flush()
    comboQueue = flushLayer(comboQueue, "combos")
    textQueue = flushLayer(textQueue, "text")
end

local function purgeOldTextLogs()
    local today = os.date("%Y-%m-%d")
    if hs.settings.get("InputLogger.lastPurgeDate") == today then return end

    local cutoff = os.time() - 365 * 86400
    local iter, dirObj = hs.fs.dir(dataDir)
    if iter then
        for name in iter, dirObj do
            if name:match("^text%-%d%d%d%d%-%d%d%.jsonl$") then
                local path = dataDir .. "/" .. name
                local attrs = hs.fs.attributes(path)
                if attrs and attrs.modification and attrs.modification < cutoff then
                    local ok, removeErr = os.remove(path)
                    if ok then
                        log.i("Purged old text log: " .. name)
                    else
                        log.e("Failed to purge " .. name .. ": " .. tostring(removeErr))
                    end
                end
            end
        end
    end

    hs.settings.set("InputLogger.lastPurgeDate", today)
end

purgeOldTextLogs()

local comboTap = hs.eventtap.new({
    hs.eventtap.event.types.keyDown,
    hs.eventtap.event.types.keyUp,
    hs.eventtap.event.types.leftMouseDown,
    hs.eventtap.event.types.leftMouseUp,
    hs.eventtap.event.types.rightMouseDown,
    hs.eventtap.event.types.rightMouseUp,
    hs.eventtap.event.types.otherMouseDown,
    hs.eventtap.event.types.otherMouseUp,
    hs.eventtap.event.types.flagsChanged,
}, onComboEvent)
comboTap:start()

local textTap = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, onTextEvent)
textTap:start()

local flushTimer = hs.timer.doEvery(10, flush)

log.i("Active, text layer " .. (textLayerEnabled and "enabled" or "disabled"))

return {
    comboTap = comboTap,
    textTap = textTap,
    flushTimer = flushTimer,
}  -- referenced via package.loaded: GC kills running taps/timers
