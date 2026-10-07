local ACTIVATE_DELAY, CHORD_DELAY, POPUP_DELAY = 0.18, 0.08, 0.35
local VIDEO_SLOTS = { main = "main", left = "main", corner = "corner" }
-- hs.application:kind(): an app with a Dock icon, not an agent or a background
-- app.
local REGULAR_APPLICATION = 1

local function focusFirstRunning(bundles)
    for _, bundle in ipairs(bundles) do
        local application = hs.application.get(bundle)
        if application then application:activate() return end
    end
end

return function(powerWindows, catalog)
    local focusSets = {}

    function focusSets.looksLikeVideo(title)
        local lowercaseTitle = (title or ""):lower()
        for _, marker in ipairs(powerWindows.config.videoTitleMarkers) do
            if lowercaseTitle:find(marker, 1, true) then return true end
        end
        return false
    end

    local function popups(application)
        local list = {}
        for _, window in ipairs(application:allWindows()) do
            local resolved = powerWindows:resolve(window)
            if resolved and resolved.popup then list[#list + 1] = window end
        end
        return list
    end

    local function hideExceptPopups(application, videoSlot, popupBundles)
        local popupWindows = popups(application)
        if #popupWindows == 0 then
            if popupBundles[application:bundleID()] then
                for _, window in ipairs(application:allWindows()) do
                    window:minimize()
                end
            end
            if not application:isHidden() then application:hide() end
            return
        end
        local popupIds = {}
        for _, window in ipairs(popupWindows) do
            if window:id() then popupIds[window:id()] = true end
            if not powerWindows:_skipped(window) then
                powerWindows:_place(
                    window, powerWindows:resolve(window), videoSlot
                )
            end
        end
        for _, window in ipairs(application:allWindows()) do
            if not popupIds[window:id()] and window:isStandard() then
                window:minimize()
            end
        end
    end

    -- The PiP window appears with a delay: send the browser's chord, lay out
    -- after.
    local function popOut(application, videoSlot, popupBundles, done)
        local chord = catalog.pictureInPictureChords[application:bundleID()]
        local frontWindow = application:focusedWindow()
            or application:mainWindow()
        if not chord or not frontWindow or #popups(application) > 0
            or not focusSets.looksLikeVideo(frontWindow:title()) then
            return false
        end
        local bundle = application:bundleID()
        powerWindows:_after(ACTIVATE_DELAY, function()
            application:activate()
            powerWindows:_after(CHORD_DELAY, function()
                hs.eventtap.keyStroke(chord.mods, chord.key, 0)
                powerWindows:_after(POPUP_DELAY, function()
                    hideExceptPopups(application, videoSlot, popupBundles)
                    done()
                end, "focus:tidy:" .. bundle)
            end, "focus:chord:" .. bundle)
        end, "focus:activate:" .. bundle)
        return true
    end

    local function restore(application)
        if application:isHidden() then application:unhide() end
        for _, window in ipairs(application:allWindows()) do
            if window:isMinimized() then window:unminimize() end
            if not powerWindows:_skipped(window) then
                powerWindows:placeDefault(window)
            end
        end
    end

    function focusSets.videoSlot(name, set)
        if set.video == nil then return "main" end
        return VIDEO_SLOTS[set.video]
            or error(
                "PowerWindows: focus set " .. name
                    .. ": video must be \"main\" (alias \"left\") \z
                        or \"corner\", not "
                    .. tostring(set.video),
                2
            )
    end

    function focusSets.apply(name)
        local set = powerWindows.config.focusSets[name]
        if not set then return false end
        local videoSlot = focusSets.videoSlot(name, set)
        local keptBundles, custom = {}, set.custom or {}
        for _, bundle in ipairs(set.keep or {}) do
            keptBundles[bundle] = true
        end
        local popupBundles = catalog.popupBundles()
        local function focusFirst() focusFirstRunning(set.focus or {}) end

        for _, application in ipairs(hs.application.runningApplications()) do
            if application:kind() == REGULAR_APPLICATION then
                local bundle = application:bundleID()
                if custom[bundle] then
                    -- One handler that raises must not leave the rest of
                    -- the apps half arranged.
                    local handled, problem =
                        pcall(custom[bundle], application, powerWindows)
                    if not handled then
                        print("PowerWindows: focus set " .. name .. ": "
                            .. tostring(problem))
                    end
                elseif keptBundles[bundle] then
                    restore(application)
                elseif not popOut(
                    application, videoSlot, popupBundles, focusFirst
                ) then
                    hideExceptPopups(application, videoSlot, popupBundles)
                end
            end
        end
        focusFirst()
        return true
    end

    return focusSets
end
