-- Text Expansion Engine
-- Type abbreviation (e.g. ";date") → auto-expands to full text
-- Dictionary lives in text_expansion_dictionary.lua

local log = hs.logger.new('TextExpansion', 'info')

local keyBuffer = ""
local keyWatcher = nil
local expandTimer = nil  -- prevent GC
local cooldownTimer = nil  -- prevent GC
local expanding = false  -- suppress re-entrant events during expansion
local maxBufferLen = 30

local abbreviations = require "text_expansion_dictionary"

local triggerChars = { " ", "\t", "\r", "\n" }

local function isTrigger(char)
    for _, t in ipairs(triggerChars) do
        if char == t then return true end
    end
    return false
end

local function expandAbbreviation(abbr)
    local expansion = abbreviations[abbr]
    if not expansion then return nil end

    if type(expansion) == "function" then
        local ok, result = pcall(expansion)
        if ok then return result end
        log.e("Expansion error for " .. abbr .. ": " .. tostring(result))
        return nil
    end

    return expansion
end

local function deleteChars(n)
    for _ = 1, n do
        hs.eventtap.keyStroke({}, "delete", 0)
    end
end

local function onKeyEvent(event)
    if expanding then return false end

    local keyCode = event:getKeyCode()
    local flags = event:getFlags()

    if flags.cmd or flags.alt or flags.ctrl or flags.fn then
        keyBuffer = ""
        return false
    end

    local char = event:getCharacters()
    if not char or #char == 0 then return false end

    if keyCode == 53 or (keyCode >= 123 and keyCode <= 126) then
        keyBuffer = ""
        return false
    end

    if isTrigger(char) then
        for abbr, _ in pairs(abbreviations) do
            if keyBuffer:sub(-#abbr) == abbr then
                local expansion = expandAbbreviation(abbr)
                if expansion then
                    expanding = true
                    expandTimer = hs.timer.doAfter(0, function()
                        expandTimer = nil
                        deleteChars(#abbr)
                        hs.eventtap.keyStrokes(expansion)
                        cooldownTimer = hs.timer.doAfter(0.5, function()
                            cooldownTimer = nil
                            expanding = false
                            keyBuffer = ""
                        end)
                    end)
                    keyBuffer = ""
                    return true
                end
            end
        end
        keyBuffer = ""
        return false
    end

    keyBuffer = keyBuffer .. char
    if #keyBuffer > maxBufferLen then
        keyBuffer = keyBuffer:sub(-maxBufferLen)
    end

    return false
end

keyWatcher = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, onKeyEvent)
keyWatcher:start()

local count = 0
for _ in pairs(abbreviations) do count = count + 1 end
log.i("Active with " .. count .. " abbreviations")
