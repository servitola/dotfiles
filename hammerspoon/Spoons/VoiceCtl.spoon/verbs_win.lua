-- Глагол win: позиция активного окна и готовые раскладки рабочего стола.
return function(V)
    -- Раскладки живут в HotKeys.spoon/window_focus_sets.lua и вызываются напрямую.
    -- Синтез чорда (первоначальный план) не работает: hs.eventtap.keyStroke
    -- Carbon-хоткеем не ловится — проверено с нулевой и дефолтной задержкой,
    -- osascript отпадает по правам Accessibility. Поэтому раскладки вынесены
    -- в модуль и зовутся функцией.
    local function focusSet(setName)
        return function()
            local hk = spoon.HotKeys
            local sets = hk and hk.windowFocusSets
            if not sets then error("HotKeys.windowFocusSets недоступен", 0) end
            sets.apply(setName)
        end
    end

    local LAYOUTS = {
        { key = "left",       aliases = { "влево", "лево", "left", "налево" },
          fn = function() set_window_left() end },
        { key = "right",      aliases = { "вправо", "право", "right", "направо" },
          fn = function() set_window_right() end },
        { key = "half-left",  aliases = { "половину слева", "пол экрана слева", "половина слева", "half left" },
          fn = function() set_window_half_left() end },
        { key = "half-right", aliases = { "половину справа", "пол экрана справа", "половина справа", "half right" },
          fn = function() set_window_half_right() end },
        { key = "full",       aliases = { "на весь экран", "весь экран", "фуллскрин", "full", "fullscreen", "развернуть" },
          fn = function() set_window_fullscreen() end },
        { key = "top60",      aliases = { "вверх", "сверху", "верхние шестьдесят", "top" },
          fn = function() set_window_top_60() end },
        { key = "bottom40",   aliases = { "вниз", "снизу", "нижние сорок", "bottom" },
          fn = function() set_window_bottom_40() end },
        { key = "center",     aliases = { "по центру", "центр", "center", "посередине" },
          fn = function()
              local win = hs.window.frontmostWindow()
              if not win then return end
              local screen, frame = win:screen():frame(), win:frame()
              frame.x = screen.x + (screen.w - frame.w) / 2
              frame.y = screen.y + (screen.h - frame.h) / 2
              win:setFrame(frame, 0)
          end },
        { key = "default",    aliases = { "разложи всё", "разложи все", "по местам", "как обычно", "default" },
          fn = function() set_all_windows_positions() end },
        { key = "work",       aliases = { "под работу", "работа", "рабочее", "work" },
          fn = focusSet("window.focus_work") },
        { key = "personal",   aliases = { "под личное", "личное", "personal" },
          fn = focusSet("window.focus_personal") },
        { key = "comms",      aliases = { "под общение", "общение", "переписка", "comms" },
          fn = focusSet("window.focus_comms") },
        { key = "only-work",  aliases = { "только работа", "спрячь всё кроме работы", "убери лишнее" },
          fn = focusSet("window.hide_all_except_work") },
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
