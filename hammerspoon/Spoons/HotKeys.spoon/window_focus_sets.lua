-- Desktop focus layouts: work / personal / comms / only-work.
--
-- Moved out of init.lua verbatim, so the layout can be applied not only
-- from a hotkey but also by calling the function directly (VoiceCtl voice
-- verb `win`). Synthesizing a chord doesn't work for this: hs.eventtap.keyStroke
-- isn't caught by a Carbon hotkey (verified — zero delay, default delay, and
-- via osascript all failed).
--
-- Global dependencies (Windows.spoon): set_window_default, set_window_left,
-- is_browser_video_player.
return function()
    local browsers = require "browsers"
    local telegrams = require "telegrams"
    local TELEGRAM = telegrams.main.app

    local exceptionSets = {
        ["window.hide_all_except_work"] = { ["Zap"] = true, [TELEGRAM] = true },
        ["window.focus_work"] = {
            ["Rider"] = true, ["Fork"] = true, ["Zap"] = true, ["Code"] = true,
            ["WebStorm"] = true, ["Xcode"] = true,
            -- Firefox, а не основной браузер: config_UrlDispatcher уводит туда
            -- workname/workproject, так что рабочие страницы живут именно в нём.
            ["Firefox"] = true,
            [TELEGRAM] = true,
        },
        ["window.focus_personal"] = {
            [TELEGRAM] = true, [browsers.main.app] = true,
        },
        ["window.focus_comms"] = {
            [TELEGRAM] = true, ["zoom.us"] = true, ["Yandex.Telemost"] = true,
        },
    }

    local focusApps = {
        ["window.hide_all_except_work"] = { "Zap" },
        ["window.focus_work"] = { "Firefox", "Rider", "Zap" },
        ["window.focus_personal"] = { TELEGRAM },
        ["window.focus_comms"] = { "zoom.us", "Yandex.Telemost", TELEGRAM },
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
                    local browser = browsers.by_app(appName)
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

                    -- Video is playing in a tab and there's no popup yet: ask the
                    -- browser to pop it out with its own chord and lay out only
                    -- after — the window doesn't appear instantly. A browser
                    -- without pip_chord (every Chromium one: it has no default
                    -- chord of its own) is laid out immediately, without trying
                    -- to pop the video out.
                    if not hasPopup and browser.pip_chord
                        and browsers.title_looks_like_video(frontTitle) then
                        local chord = browser.pip_chord
                        hs.timer.doAfter(0.18, function()
                            browserApp:activate()
                            hs.timer.doAfter(0.08, function()
                                hs.eventtap.keyStroke(chord.mods, chord.key, 0)
                                hs.timer.doAfter(0.35, function()
                                    apply_browser_layout()
                                    local tg = hs.application.get(TELEGRAM)
                                    if tg then tg:activate() end
                                end)
                            end)
                        end)
                    else
                        apply_browser_layout()
                    end
                elseif telegrams.by_app(appName) then
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
