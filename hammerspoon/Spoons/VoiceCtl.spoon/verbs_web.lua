-- web and tg verbs.
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
        -- Search: «найди рецепт борща».
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

        -- «что играет» — bring up the playing tab.
        local special = V.resolve.pick(phrase, SPECIAL)
        if special and special.score >= 80 then
            if ctx.dry then return "DRY web playing" end
            if not spoon.BrowserTabOpener then return "ERR BrowserTabOpener не загружен" end
            spoon.BrowserTabOpener:open("youtube.com/watch", "https://youtube.com", { prefer = spoon.BrowserTabOpener.videoPlaying })
            return "OK поднял играющую вкладку"
        end

        -- We check a bare domain BEFORE the fuzzy alias match: otherwise «wikipedia.org»
        -- latches onto a letter-similar site from the table and goes to the wrong place.
        local domain = phrase:match("^%s*([%w%.%-]+%.[a-z][a-z]+)%s*$")
        if domain then
            if ctx.dry then return "DRY web " .. domain end
            hs.urlevent.openURL("https://" .. domain)
            return "OK открыл " .. domain
        end

        -- Site by alias.
        local best, answer = V:resolveOr("web", phrase, siteCandidates())
        if not best then return answer end
        if ctx.dry then return "DRY web " .. best.key end
        if answer then return answer end

        if spoon.BrowserTabOpener then
            spoon.BrowserTabOpener:open(best.key, "https://" .. best.key)
        else
            hs.urlevent.openURL("https://" .. best.key)
        end
        return "OK " .. best.key
    end)

    ---------------------------------------------------------------- tg
    -- Default tg handler: contended between Forkgram and the browser, so
    -- we address the client explicitly by bundleID (verified: Forkgram = com.tdesktop.Telegram).
    local TG_BUNDLE = "com.tdesktop.Telegram"

    V:register("tg", function(phrase, ctx)
        local chats = {}
        for name, aliases in pairs(V.aliases.chats or {}) do
            local list = { name }
            for _, a in ipairs(aliases) do list[#list + 1] = a end
            chats[#chats + 1] = { key = name, aliases = list }
        end

        local best = V.resolve.pick(phrase, chats)
        -- Unknown name — still search for it inside the client.
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

        -- Search inside the client: cmd+f and the name. We do NOT press Enter — deliberately.
        --
        -- The plan originally also had Down+Enter "open the first result". That
        -- can't live in code: if cmd+f fails to open search for any reason
        -- (different build, a modal, the window hasn't come to front yet), the name lands
        -- in the input field of whatever chat is open, and Enter SENDS it. Sending anything
        -- on the owner's behalf is listed in DESIGN.md as a missing feature, not
        -- as an acceptable risk. So the last step is left to the human.
        hs.timer.doAfter(0.25, function()
            hs.eventtap.keyStroke({ "cmd" }, "f", 0)
            hs.timer.doAfter(0.15, function()
                hs.eventtap.keyStrokes(query)
            end)
        end)
        return "OK поиск по «" .. query .. "» — выбери чат"
    end)
end
