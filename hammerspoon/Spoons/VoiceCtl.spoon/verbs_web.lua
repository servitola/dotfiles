-- Глаголы web и tg.
return function(V)
    ---------------------------------------------------------------- web
    local SPECIAL = {
        { key = "playing", aliases = { "что играет", "где играет", "к видео", "к плееру", "playing" } },
    }

    local function siteCandidates()
        local out = {}
        for url, aliases in pairs(V.aliases.sites or {}) do
            local list = { url }
            for _, a in ipairs(aliases) do list[#list + 1] = a end
            out[#out + 1] = { key = url, aliases = list }
        end
        return out
    end

    local SEARCH_PREFIX = { "найди", "поищи", "загугли", "найти", "search", "google" }

    V:register("web", function(phrase, ctx)
        -- Поиск: «найди рецепт борща».
        local first, rest = phrase:match("^%s*(%S+)%s+(.+)$")
        if first then
            for _, w in ipairs(SEARCH_PREFIX) do
                if V.resolve.score(first, w) >= 80 then
                    if ctx.dry then return "DRY web search:" .. rest end
                    local url = "https://yandex.ru/search/?text=" .. hs.http.encodeForQuery(rest)
                    hs.urlevent.openURL(url)
                    return "OK ищу «" .. rest .. "»"
                end
            end
        end

        -- «что играет» — поднять играющую вкладку.
        local special = V.resolve.pick(phrase, SPECIAL)
        if special and special.score >= 80 then
            if ctx.dry then return "DRY web playing" end
            if not spoon.BrowserTabOpener then return "ERR BrowserTabOpener не загружен" end
            spoon.BrowserTabOpener:focusPlayingTab("youtube.com/watch")
            return "OK поднял играющую вкладку"
        end

        -- Голый домен проверяем ДО фаззи-матча по алиасам: «wikipedia.org» иначе
        -- цепляется за похожий по буквам сайт из таблицы и уезжает не туда.
        local domain = phrase:match("^%s*([%w%.%-]+%.[a-z][a-z]+)%s*$")
        if domain then
            if ctx.dry then return "DRY web " .. domain end
            hs.urlevent.openURL("https://" .. domain)
            return "OK открыл " .. domain
        end

        -- Сайт по алиасу.
        local best, answer = V:resolveOr("web", phrase, siteCandidates())
        if not best then return answer end
        if ctx.dry then return "DRY web " .. best.key end
        if answer then return answer end

        if spoon.BrowserTabOpener then
            spoon.BrowserTabOpener:openTab(best.key)
        else
            hs.urlevent.openURL("https://" .. best.key)
        end
        return "OK " .. best.key
    end)

    ---------------------------------------------------------------- tg
    -- Дефолтный обработчик tg: спорит между Forkgram и браузером, поэтому
    -- адресуем клиент явно по bundleID (проверено: Forkgram = com.tdesktop.Telegram).
    local TG_BUNDLE = "com.tdesktop.Telegram"

    V:register("tg", function(phrase, ctx)
        local chats = {}
        for name, aliases in pairs(V.aliases.chats or {}) do
            local list = { name }
            for _, a in ipairs(aliases) do list[#list + 1] = a end
            chats[#chats + 1] = { key = name, aliases = list }
        end

        local best = V.resolve.pick(phrase, chats)
        -- Неизвестное имя — всё равно ищем по нему внутри клиента.
        local query = best and best.key or (phrase:gsub("^%s+", ""):gsub("%s+$", ""))
        if query == "" then return "NOTFOUND tg: пустое имя" end
        if ctx.dry then return "DRY tg " .. query end

        local app = hs.application.get(TG_BUNDLE)
        if not app then
            hs.application.open(TG_BUNDLE, 5, true)
            app = hs.application.get(TG_BUNDLE)
            if not app then return "ERR Forkgram не запустился" end
        end
        for _, win in ipairs(app:allWindows()) do
            if win:isMinimized() then win:unminimize() end
        end
        if app:isHidden() then app:unhide() end
        app:activate()

        -- Поиск внутри клиента: cmd+f и имя. Enter НЕ жмём — осознанно.
        --
        -- В плане тут стояло ещё Down+Enter «открыть первый результат». Это
        -- нельзя держать в коде: если cmd+f по любой причине не откроет поиск
        -- (другая сборка, модалка, окно не успело выйти вперёд), то имя уходит
        -- в поле ввода открытого чата, а Enter его ОТПРАВЛЯЕТ. Отправка чего-либо
        -- от имени хозяина в DESIGN.md значится как отсутствующая функция, а не
        -- как риск, который можно принять. Поэтому последний шаг делает человек.
        hs.timer.doAfter(0.25, function()
            hs.eventtap.keyStroke({ "cmd" }, "f", 0)
            hs.timer.doAfter(0.15, function()
                hs.eventtap.keyStrokes(query)
            end)
        end)
        return "OK поиск по «" .. query .. "» — выбери чат"
    end)
end
