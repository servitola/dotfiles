-- Punto Switcher-style layout reconversion.
-- Right Option+Space (→ F14 via Karabiner rule 26) retypes the selection, or
-- the previous word if nothing is selected, in the other Birman layout.

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

local function grabText()
    local pb = hs.pasteboard
    local saved, savedCount = pb.getContents(), pb.changeCount()

    hs.eventtap.keyStroke({ "cmd" }, "c", 0)
    hs.timer.usleep(80 * 1000)

    if pb.changeCount() == savedCount then
        hs.eventtap.keyStroke({ "alt", "shift" }, "left", 0)
        hs.timer.usleep(30 * 1000)
        hs.eventtap.keyStroke({ "cmd" }, "c", 0)
        hs.timer.usleep(80 * 1000)
    end
    return pb.getContents(), saved
end

local function replaceWith(newText, saved)
    hs.pasteboard.setContents(newText)
    hs.eventtap.keyStroke({ "cmd" }, "v", 0)
    hs.timer.doAfter(0.25, function()
        if saved then hs.pasteboard.setContents(saved) else hs.pasteboard.clearContents() end
    end)
end

local function toggleLayout()
    hs.keycodes.setLayout(hs.keycodes.currentLayout() == "En Birman" and "Ru Birman" or "En Birman")
end

local function run()
    hs.timer.doAfter(0.12, function()
        local text, saved = grabText()
        if not text or text == "" then return end
        local converted = convert(text, detectDirection(text))
        if converted == text then return end
        replaceWith(converted, saved)
        toggleLayout()
    end)
end

hs.hotkey.bind({}, "f14", run)
