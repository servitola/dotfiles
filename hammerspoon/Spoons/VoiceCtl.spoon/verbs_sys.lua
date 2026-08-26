-- Глаголы sys / text / info / tv.
-- Переключение VPN здесь отсутствует намеренно: глобальное правило запрещает
-- трогать VPN без прямой просьбы, а голосовой топик работает на быстрой модели.
return function(V)
    local function systemKey(name)
        hs.eventtap.event.newSystemKeyEvent(name, true):post()
        hs.eventtap.event.newSystemKeyEvent(name, false):post()
    end

    ---------------------------------------------------------------- sys
    -- Яркость: план читал hs.brightness.get() и при nil подставлял 50, из-за чего
    -- «яркость больше» прыгала на фиксированные 65 и рапортовала невиданное число.
    -- На этой машине get() = nil всегда (единственный экран — LG TV, встроенный
    -- дисплей в кламшелле). Поэтому шлём системную клавишу — ровно то же, что
    -- нажатие F1/F2 — и докладываем реальное значение, если оно вообще читается.
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
        -- Именно погасить экран, не заблокировать: «погаси экран» и «заблокируй» —
        -- разные просьбы, и подменять одну другой нельзя. hs.caffeinate
        -- гасить дисплей не умеет, поэтому pmset.
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
    -- Одна строка: что запущено с окнами и что спереди. Нужен модели,
    -- чтобы понять «включи видео дальше», не переспрашивая.
    V:register("info", function(_phrase, _ctx)
        local front = hs.application.frontmostApplication()
        local parts = {}
        for _, app in ipairs(hs.application.runningApplications()) do
            -- Только обычные приложения из дока (kind == 1). Фоновые хелперы
            -- вроде CursorUIViewService и «* Web Content» окон не имеют, но
            -- каждый съедает 1.5 с таймаута accessibility: три таких процесса
            -- уводили info за 4 с и роняли hs CLI по receive timeout.
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
    -- Тонкий проброс в ./tv: телевизор живёт в отдельном проекте, дублировать
    -- его протокол здесь нечего.
    local TV = os.getenv("HOME") .. "/projects/services/lgtv/tv"

    -- Фраза приезжает сырой из распознавания и уходит в шелл. Без кавычек любой
    -- «;» или бэктик в транскрипте — это выполненная команда, поэтому каждое
    -- слово экранируем отдельно, а не склеиваем строку.
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
