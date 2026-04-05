-- Auto-dismiss Fork "Please Purchase Fork" dialog

local log = hs.logger.new('forkDismiss', 'info')
local pollTimer = nil
local stopTimer = nil

local function dismissForkDialog()
    local app = hs.application.find("com.DanPristupov.Fork")
    if not app then return false end

    local axApp = hs.axuielement.applicationElement(app)
    local windows = axApp:attributeValue("AXChildren") or {}

    for _, win in ipairs(windows) do
        if win:attributeValue("AXRole") ~= "AXWindow" then goto continue_win end
        local children = win:attributeValue("AXChildren") or {}
        for _, child in ipairs(children) do
            if child:attributeValue("AXRole") == "AXSheet" then
                local sheetChildren = child:attributeValue("AXChildren") or {}
                local hasActivate, cancelButton = false, nil
                for _, el in ipairs(sheetChildren) do
                    if el:attributeValue("AXRole") == "AXButton" then
                        local title = el:attributeValue("AXTitle")
                        if title == "Activate" then hasActivate = true end
                        if title == "Cancel" then cancelButton = el end
                    end
                end
                if hasActivate and cancelButton then
                    cancelButton:performAction("AXPress")
                    log.i("Dismissed Fork purchase dialog")
                    return true
                end
            end
        end
        ::continue_win::
    end
    return false
end

local function stopPolling()
    if pollTimer then pollTimer:stop(); pollTimer = nil end
    if stopTimer then stopTimer:stop(); stopTimer = nil end
end

local function startPolling()
    if pollTimer and pollTimer:running() then return end
    pollTimer = hs.timer.doEvery(2, function()
        if dismissForkDialog() then stopPolling() end
    end)
    stopTimer = hs.timer.doAfter(60, stopPolling)
end

appWatcherHub.register(function(appName, eventType, appObject)
    if not appObject then return end
    if appObject:bundleID() ~= "com.DanPristupov.Fork" then return end

    if eventType == hs.application.watcher.activated then
        if dismissForkDialog() then return end
        startPolling()
    elseif eventType == hs.application.watcher.deactivated then
        stopPolling()
    end
end)
