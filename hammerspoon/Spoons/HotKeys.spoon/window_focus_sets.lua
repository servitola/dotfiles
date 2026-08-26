-- Раскладки фокуса рабочего стола: work / personal / comms / only-work.
--
-- Вынесено из init.lua дословно, чтобы раскладку можно было применить не только
-- с хоткея, но и вызовом функции (голосовой глагол VoiceCtl `win`). Синтез
-- чорда для этого не годится: hs.eventtap.keyStroke Carbon-хоткеем не ловится
-- (проверено — ни с нулевой задержкой, ни с дефолтной, ни через osascript).
--
-- Зависимости-глобали (Windows.spoon): set_window_default, set_window_left,
-- is_browser_video_player. Локальные хелперы init.lua приходят через deps.
return function(deps)
    local browsers = require "browsers"
    local browser_title_has_video = deps.browser_title_has_video

    local exceptionSets = {
        ["window.hide_all_except_work"] = { ["Zap"] = true, ["Workbot"] = true },
        ["window.focus_work"] = {
            ["Rider"] = true, ["Fork"] = true, ["Firefox"] = true,
            ["Zap"] = true, ["Code"] = true,
            ["Workbot"] = true
        },
        -- Оба браузера сразу: основной сейчас Vivaldi, Yandex оставлен на случай возврата.
        ["window.focus_personal"] = {
            ["Forkgram"] = true, ["Vivaldi"] = true, ["Yandex"] = true
        },
        ["window.focus_comms"] = {
            ["Forkgram"] = true, ["Messages"] = true,
            ["zoom.us"] = true, ["Yandex Telemost"] = true
        },
    }

    local focusApps = {
        ["window.hide_all_except_work"] = { "Zap" },
        ["window.focus_work"] = { "Firefox" },
        ["window.focus_personal"] = { "Forkgram" },
        ["window.focus_comms"] = { "zoom.us", "Yandex Telemost", "Forkgram" },
    }

    local M = {}

    -- Знает ли модуль такую раскладку. Нужно вызывающим, чтобы не гадать.
    function M.has(functionName)
        return exceptionSets[functionName] ~= nil
    end

    function M.apply(functionName)
        local exceptions = exceptionSets[functionName]
        local focusList = focusApps[functionName]
        if not exceptions then return false end

        hs.closeConsole()
        local browserPopupAsync = false
        for _, app in ipairs(hs.application.runningApplications()) do
            if app:kind() == 1 then
                local appName = app:name()
                local isException = exceptions[appName]
                if isException then
                    if app:isHidden() then app:unhide() end
                    for _, win in ipairs(app:allWindows()) do
                        if win:isMinimized() then win:unminimize() end
                        set_window_default(win)
                    end
                elseif browsers.by_app(appName) then
                    local browserApp = app
                    local keepVisibleNoVideo = (functionName == "window.focus_personal")

                    local function apply_browser_layout()
                        local popupWin = nil
                        for _, win in ipairs(browserApp:allWindows()) do
                            if is_browser_video_player(appName, win:title(), win) then
                                popupWin = win
                                break
                            end
                        end

                        if popupWin then
                            for _, win in ipairs(browserApp:allWindows()) do
                                if win == popupWin then
                                    set_window_left(win)
                                else
                                    win:minimize()
                                end
                            end
                        elseif keepVisibleNoVideo then
                            if browserApp:isHidden() then browserApp:unhide() end
                            for _, win in ipairs(browserApp:allWindows()) do
                                if win:isMinimized() then win:unminimize() end
                                set_window_default(win)
                            end
                        else
                            for _, win in ipairs(browserApp:allWindows()) do
                                win:minimize()
                            end
                            if not browserApp:isHidden() then browserApp:hide() end
                        end
                    end

                    local hasPopup = false
                    for _, win in ipairs(browserApp:allWindows()) do
                        if is_browser_video_player(appName, win:title(), win) then
                            hasPopup = true
                            break
                        end
                    end

                    local frontWin = browserApp:focusedWindow() or browserApp:mainWindow()
                    local frontTitle = frontWin and frontWin:title() or ""

                    if not hasPopup and browser_title_has_video(frontTitle) then
                        browserPopupAsync = true
                        local fnNameLocal = functionName
                        hs.timer.doAfter(0.18, function()
                            browserApp:activate()
                            hs.timer.doAfter(0.08, function()
                                hs.eventtap.keyStroke({"cmd", "alt"}, "right", 0)
                                hs.timer.doAfter(0.35, function()
                                    apply_browser_layout()
                                    local tg = hs.application.get("Forkgram")
                                    if tg then tg:activate() end
                                    if fnNameLocal == "window.focus_personal" then
                                        telegram_select_personal_folder(0.15)
                                    end
                                end)
                            end)
                        end)
                    else
                        apply_browser_layout()
                    end
                elseif appName == "Forkgram" then
                    local hasVideo = false
                    for _, win in ipairs(app:allWindows()) do
                        if not win:isStandard() then
                            hasVideo = true
                        else
                            win:minimize()
                        end
                    end
                    if not hasVideo and not app:isHidden() then app:hide() end
                else
                    if not app:isHidden() then app:hide() end
                end
            end
        end
        for _, name in ipairs(focusList) do
            local a = hs.application.get(name)
            if a then a:activate(); break end
        end
        return true
    end

    return M
end
