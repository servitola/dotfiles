-- Verb app: focus, launch, hide, quit.
-- The phrase may start with an action word: «закрой зум», «спрячь музыку».
return function(V)
    local ACTIONS = {
        focus = { "перейди", "открой", "покажи", "запусти", "включи", "переключись",
                  "focus", "open", "switch", "launch" },
        hide  = { "спрячь", "скрой", "убери", "hide" },
        quit  = { "закрой", "выключи", "убей", "quit", "close" },
    }

    -- Prepositions after the action word: «перейди НА форк», «перейди В код».
    -- Keys are transliterated, because we compare against translit(), not the raw word.
    local PREPOSITIONS = { ["na"] = true, ["v"] = true, ["k"] = true, ["vo"] = true, ["to"] = true }

    local function stripPreposition(phrase)
        local first, rest = phrase:match("^%s*(%S+)%s+(.+)$")
        if first and PREPOSITIONS[V.resolve.translit(first)] then return rest end
        return phrase
    end

    local function splitAction(phrase)
        local first = phrase:match("^%s*(%S+)")
        if not first then return "focus", phrase end
        for action, words in pairs(ACTIONS) do
            for _, w in ipairs(words) do
                if V.resolve.score(first, w) >= 90 then
                    local rest = phrase:gsub("^%s*%S+%s*", "", 1)
                    return action, stripPreposition(rest)
                end
            end
        end
        return "focus", stripPreposition(phrase)
    end

    -- hs.application.get matches the name as a SUBSTRING: get("Fork") reliably returns
    -- Forkgram. So we search strictly — first by bundleID, then by exact name.
    local function findRunning(name, bundleID)
        if bundleID then
            local byId = hs.application.applicationsForBundleID(bundleID)
            if byId and #byId > 0 then return byId[1] end
        end
        local lower = name:lower()
        for _, app in ipairs(hs.application.runningApplications()) do
            local n = app:name()
            if n and n:lower() == lower then return app end
        end
        return nil
    end

    V:register("app", function(phrase, ctx)
        local action, target = splitAction(phrase)
        if target == "" then return "NOTFOUND app: пустая цель" end

        local best, answer = V:resolveOr("app", target, V:appCandidates())
        if not best then return answer end
        if ctx.dry then return "DRY app " .. best.key end
        if answer then return answer end   -- ambiguous: don't act, ask

        local app = findRunning(best.key, best.value)

        if action == "quit" then
            if not app then return "OK " .. best.key .. " и так не запущен" end
            app:kill()
            return "OK закрыл " .. best.key
        end

        if action == "hide" then
            if not app then return "OK " .. best.key .. " и так не запущен" end
            app:hide()
            return "OK спрятал " .. best.key
        end

        -- focus: launch if needed, unminimize what's minimized, raise it.
        if not app then
            local launched = hs.application.open(best.value or best.key, 5, true)
            if not launched then return "ERR не смог запустить " .. best.key end
            return "OK запустил " .. best.key
        end

        for _, win in ipairs(app:allWindows()) do
            if win:isMinimized() then win:unminimize() end
        end
        if app:isHidden() then app:unhide() end
        app:activate()

        -- Report what actually ended up in front, not what the resolver
        -- resolved to: a mismatch here is the only sign of a miss.
        local front = hs.application.frontmostApplication()
        local frontName = front and front:name()
        if frontName and frontName ~= app:name() then
            return "OK " .. app:name() .. " (спереди " .. frontName .. ")"
        end
        return "OK " .. app:name()
    end)
end
