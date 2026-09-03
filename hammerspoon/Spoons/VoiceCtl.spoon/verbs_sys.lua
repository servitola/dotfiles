-- sys / text / info / tv verbs.
-- VPN switching is deliberately absent here: the global rule forbids
-- touching the VPN without a direct request, and this voice topic runs on a fast model.
return function(V)
    local function systemKey(name)
        hs.eventtap.event.newSystemKeyEvent(name, true):post()
        hs.eventtap.event.newSystemKeyEvent(name, false):post()
    end

    ---------------------------------------------------------------- sys
    -- Brightness: the plan read hs.brightness.get() and substituted 50 on nil, so
    -- «яркость больше» jumped to a fixed 65 and reported a number never actually seen.
    -- On this machine get() = nil always (the only screen is an LG TV, the built-in
    -- display is in clamshell). So we send the system key — exactly what pressing
    -- F1/F2 does — and report the real value if it's readable at all.
    local function brightnessStep(keyName)
        systemKey(keyName)
        local level = hs.brightness.get()
        if not level then
            local screen = hs.screen.mainScreen()
            return "нажал клавишу яркости; уровень не читается (экран " ..
                ((screen and screen:name()) or "?") .. ")"
        end
        return "яркость " .. math.floor(level)
    end

    local SYS = {
        { key = "lock",           aliases = { "заблокируй", "залочь", "блокировка", "lock" },
          fn = function() hs.caffeinate.lockScreen() return "экран заблокирован" end },
        { key = "sleep",          aliases = { "спи", "усни", "в сон", "sleep" },
          fn = function() hs.caffeinate.systemSleep() return "ушёл в сон" end },
        -- Specifically turn off the screen, not lock it: «погаси экран» and «заблокируй» —
        -- are different requests, and one must not substitute for the other. hs.caffeinate
        -- can't turn off the display, hence pmset.
        { key = "display-sleep",  aliases = { "погаси экран", "выключи экран", "экран спать", "display sleep" },
          fn = function()
              hs.execute("/usr/bin/pmset displaysleepnow")
              return "экран погашен"
          end },
        { key = "brightness-up",  aliases = { "яркость больше", "яркче", "светлее", "brightness up" },
          fn = function() return brightnessStep("BRIGHTNESS_UP") end },
        { key = "brightness-down", aliases = { "яркость меньше", "темнее", "потемнее", "brightness down" },
          fn = function() return brightnessStep("BRIGHTNESS_DOWN") end },
    }

    V:register("sys", function(phrase, ctx)
        local best, answer = V:resolveOr("sys", phrase, SYS)
        if not best then return answer end
        if ctx.dry then return "DRY sys " .. best.key end
        if answer then return answer end
        for _, s in ipairs(SYS) do
            if s.key == best.key then return "OK " .. s.fn() end
        end
        return "ERR sys " .. best.key
    end)

    ---------------------------------------------------------------- text
    local TEXT = {
        { key = "paste",        aliases = { "вставь без формата", "вставь как текст", "вставь без форматирования", "paste plain" },
          fn = function()
              local contents = hs.pasteboard.getContents()
              if not contents then return "буфер пуст" end
              if #contents > 10000 then return "буфер слишком большой (" .. #contents .. ")" end
              hs.eventtap.keyStrokes(contents)
              return "вставил " .. #contents .. " символов"
          end },
        { key = "translate-en", aliases = { "переведи на английский", "на английский", "translate to english" },
          fn = function()
              if not spoon.PopupTranslateSelection then return "PopupTranslateSelection не загружен" end
              spoon.PopupTranslateSelection:translateSelectionPopup("en")
              return "перевод на английский"
          end },
        { key = "translate-ru", aliases = { "переведи на русский", "на русский", "translate to russian" },
          fn = function()
              if not spoon.PopupTranslateSelection then return "PopupTranslateSelection не загружен" end
              spoon.PopupTranslateSelection:translateSelectionPopup("ru")
              return "перевод на русский"
          end },
    }

    V:register("text", function(phrase, ctx)
        local best, answer = V:resolveOr("text", phrase, TEXT)
        if not best then return answer end
        if ctx.dry then return "DRY text " .. best.key end
        if answer then return answer end
        for _, t in ipairs(TEXT) do
            if t.key == best.key then return "OK " .. t.fn() end
        end
        return "ERR text " .. best.key
    end)

    ---------------------------------------------------------------- info
    -- One line: what's running with windows and what's frontmost. The model needs
    -- this to understand «включи видео дальше» without asking back.
    V:register("info", function(_phrase, _ctx)
        local front = hs.application.frontmostApplication()
        local parts = {}
        for _, app in ipairs(hs.application.runningApplications()) do
            -- Only regular dock apps (kind == 1). Background helpers
            -- like CursorUIViewService and "* Web Content" have no windows, but
            -- each eats 1.5s of accessibility timeout: three such processes
            -- pushed info past 4s and made the hs CLI fail with a receive timeout.
            if app:kind() == 1 then
            local wins = app:allWindows()
            if #wins > 0 then
                local titles = {}
                for _, w in ipairs(wins) do
                    local t = w:title()
                    if t and t ~= "" then titles[#titles + 1] = t:sub(1, 45) end
                end
                parts[#parts + 1] = app:name() .. "[" .. table.concat(titles, "; ") .. "]"
            end
            end
        end
        local line = "front=" .. ((front and front:name()) or "?") .. " " .. table.concat(parts, " ")
        return "OK " .. (line:gsub("%s+", " "))
    end)

    ---------------------------------------------------------------- tv
    -- Thin passthrough to ./tv: the TV lives in a separate project, no reason
    -- to duplicate its protocol here.
    local TV = os.getenv("HOME") .. "/projects/services/lgtv/tv"

    -- The phrase arrives raw from speech recognition and goes into the shell. Without quoting, any
    -- «;» or backtick in the transcript is an executed command, so we
    -- escape each word separately instead of concatenating one string.
    local function shellQuote(s)
        return "'" .. (tostring(s):gsub("'", "'\\''")) .. "'"
    end

    V:register("tv", function(phrase, ctx)
        if ctx.dry then return "DRY tv " .. phrase end
        if not hs.fs.attributes(TV) then return "ERR tv CLI не найден: " .. TV end

        local args = {}
        for word in phrase:gmatch("%S+") do args[#args + 1] = shellQuote(word) end
        local cmd = shellQuote(TV) .. " " .. table.concat(args, " ")

        local out, ok = hs.execute(cmd, true)
        local line = (out or ""):gsub("%s+", " "):gsub("^%s", ""):sub(1, 200)
        if not ok then return "ERR tv: " .. line end
        return "OK tv: " .. line
    end)
end
