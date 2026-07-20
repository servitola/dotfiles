-- Punto Switcher-style layout reconversion.
-- Right Option+Space (→ F14 via Karabiner rule 26) retypes the selection, or
-- the previous word if nothing is selected, in the other Birman layout.
--
-- Fully async: no usleep — the Hammerspoon main thread (and its event taps,
-- e.g. text expansion) is never blocked. Waits are event-driven: modifier
-- release before synthetic keystrokes, pasteboard changeCount instead of
-- fixed sleeps.

local en_ru = {
    { "q", "й" }, { "w", "ц" }, { "e", "у" }, { "r", "к" }, { "t", "е" },
    { "y", "н" }, { "u", "г" }, { "i", "ш" }, { "o", "щ" }, { "p", "з" },
    { "[", "х" }, { "]", "ъ" },
    { "a", "ф" }, { "s", "ы" }, { "d", "в" }, { "f", "а" }, { "g", "п" },
    { "h", "р" }, { "j", "о" }, { "k", "л" }, { "l", "д" },
    { ";", "ж" }, { "'", "э" },
    { "z", "я" }, { "x", "ч" }, { "c", "с" }, { "v", "м" }, { "b", "и" },
    { "n", "т" }, { "m", "ь" }, { ",", "б" }, { ".", "ю" }, { "`", "ё" },
    { "Q", "Й" }, { "W", "Ц" }, { "E", "У" }, { "R", "К" }, { "T", "Е" },
    { "Y", "Н" }, { "U", "Г" }, { "I", "Ш" }, { "O", "Щ" }, { "P", "З" },
    { "{", "Х" }, { "}", "Ъ" },
    { "A", "Ф" }, { "S", "Ы" }, { "D", "В" }, { "F", "А" }, { "G", "П" },
    { "H", "Р" }, { "J", "О" }, { "K", "Л" }, { "L", "Д" },
    { ":", "Ж" }, { '"', "Э" },
    { "Z", "Я" }, { "X", "Ч" }, { "C", "С" }, { "V", "М" }, { "B", "И" },
    { "N", "Т" }, { "M", "Ь" }, { "<", "Б" }, { ">", "Ю" }, { "~", "Ё" },
}

local en_to_ru, ru_to_en = {}, {}
for _, p in ipairs(en_ru) do en_to_ru[p[1]] = p[2]; ru_to_en[p[2]] = p[1] end

local function detectDirection(text)
    for _, cp in utf8.codes(text) do
        if cp >= 0x0400 and cp <= 0x04FF then return "ru_to_en" end
        if (cp >= 0x41 and cp <= 0x5A) or (cp >= 0x61 and cp <= 0x7A) then return "en_to_ru" end
    end
    return hs.keycodes.currentLayout() == "Ru Birman" and "ru_to_en" or "en_to_ru"
end

local function convert(text, direction)
    local map = direction == "ru_to_en" and ru_to_en or en_to_ru
    local out = {}
    for _, cp in utf8.codes(text) do
        local ch = utf8.char(cp)
        out[#out + 1] = map[ch] or ch
    end
    return table.concat(out)
end

-- Async plumbing: retain timers until they fire, guard against re-entry.
local timers = {}
local busy = false
local gen = 0

local function after(delay, fn)
    local t
    t = hs.timer.doAfter(delay, function() timers[t] = nil; fn() end)
    timers[t] = true
end

-- Poll `pred` every 20ms; done(true) when it holds, done(false) at timeout.
local function waitFor(pred, timeout, done)
    local deadline = hs.timer.secondsSinceEpoch() + timeout
    local t
    t = hs.timer.waitUntil(
        function() return pred() or hs.timer.secondsSinceEpoch() > deadline end,
        function() timers[t] = nil; done(pred()) end,
        0.02)
    timers[t] = true
end

local function finish()
    busy = false
end

-- Copy whatever is selected; done(text) with nil if the clipboard didn't
-- change (i.e. there was no selection to copy).
local function copySelection(done)
    local before = hs.pasteboard.changeCount()
    hs.eventtap.keyStroke({ "cmd" }, "c", 0)
    waitFor(function() return hs.pasteboard.changeCount() ~= before end, 0.4, function(ok)
        done(ok and hs.pasteboard.getContents() or nil)
    end)
end

local function convertGrabbed(text, saved, autoSelected)
    local direction = text and text ~= "" and detectDirection(text) or nil
    local converted = direction and convert(text, direction) or nil
    if not converted or converted == text then
        -- Nothing to convert (digits/symbols, or copy failed). If we made
        -- the selection ourselves, collapse it back to the caret.
        if autoSelected then hs.eventtap.keyStroke({}, "right", 0) end
        finish()
        return
    end
    hs.pasteboard.setContents(converted)
    hs.eventtap.keyStroke({ "cmd" }, "v", 0)
    after(0.3, function()
        if saved then hs.pasteboard.setContents(saved) else hs.pasteboard.clearContents() end
    end)
    -- Deterministic: match the layout to the direction we converted into,
    -- instead of blindly toggling.
    hs.keycodes.setLayout(direction == "en_to_ru" and "Ru Birman" or "En Birman")
    finish()
end

local function run()
    if busy then return end
    busy = true
    gen = gen + 1
    local myGen = gen
    after(2.5, function() if gen == myGen then busy = false end end)  -- safety net

    -- Wait for the physical chord (Right Option) to be released so it
    -- doesn't contaminate the synthetic Cmd+C / Cmd+V.
    waitFor(function()
        local f = hs.eventtap.checkKeyboardModifiers()
        return not (f.cmd or f.alt or f.ctrl or f.shift or f.fn)
    end, 1, function()
        local saved = hs.pasteboard.getContents()
        copySelection(function(text)
            if text then
                convertGrabbed(text, saved, false)
            else
                -- No selection — grab the previous word.
                hs.eventtap.keyStroke({ "alt", "shift" }, "left", 0)
                after(0.05, function()
                    copySelection(function(word)
                        convertGrabbed(word, saved, true)
                    end)
                end)
            end
        end)
    end)
end

hs.hotkey.bind({}, "f14", run)
