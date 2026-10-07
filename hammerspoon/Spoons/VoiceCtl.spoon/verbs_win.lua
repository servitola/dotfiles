-- Verb win: active-window position and ready-made desktop layouts.
return function(V)
    local pw = function(method) return function() spoon.PowerWindows[method](spoon.PowerWindows) end end
    local function focusSet(name)
        return function()
            hs.closeConsole()
            spoon.PowerWindows:focusSet(name)
        end
    end

    local LAYOUTS = {
        { key = "left",       aliases = { "влево", "лево", "left", "налево" },
          fn = pw("moveLeft") },
        { key = "right",      aliases = { "вправо", "право", "right", "направо" },
          fn = pw("moveRight") },
        { key = "half-left",  aliases = { "половину слева", "пол экрана слева", "половина слева", "half left" },
          fn = pw("halfLeft") },
        { key = "half-right", aliases = { "половину справа", "пол экрана справа", "половина справа", "half right" },
          fn = pw("halfRight") },
        { key = "full",       aliases = { "на весь экран", "весь экран", "фуллскрин", "full", "fullscreen", "развернуть" },
          fn = pw("moveFull") },
        { key = "top60",      aliases = { "вверх", "сверху", "верхние шестьдесят", "top" },
          fn = pw("top60") },
        { key = "bottom40",   aliases = { "вниз", "снизу", "нижние сорок", "bottom" },
          fn = pw("bottom40") },
        { key = "center",     aliases = { "по центру", "центр", "center", "посередине" },
          fn = pw("center") },
        { key = "default",    aliases = { "разложи всё", "разложи все", "по местам", "как обычно", "default" },
          fn = pw("arrangeAllNow") },
        { key = "work",       aliases = { "под работу", "работа", "рабочее", "work" },
          fn = focusSet("work") },
        { key = "personal",   aliases = { "под личное", "личное", "personal" },
          fn = focusSet("personal") },
        { key = "comms",      aliases = { "под общение", "общение", "переписка", "comms" },
          fn = focusSet("comms") },
        { key = "only-work",  aliases = { "только работа", "спрячь всё кроме работы", "убери лишнее" },
          fn = focusSet("only-work") },
    }

    V:register("win", function(phrase, ctx)
        local best, answer = V:resolveOr("win", phrase, LAYOUTS)
        if not best then return answer end
        if ctx.dry then return "DRY win " .. best.key end
        if answer then return answer end

        for _, layout in ipairs(LAYOUTS) do
            if layout.key == best.key then
                layout.fn()
                return "OK " .. best.key
            end
        end
        return "ERR раскладка " .. best.key .. " не найдена"
    end)
end
