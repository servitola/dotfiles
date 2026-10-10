-- Desktop layouts for ⇧⌃⌥⌘ + arrows and the voice verb `win`.
local telegram = require("telegrams").main.bundle

local ZAP = "dev.zap.Zap"
local FIREFOX = "org.mozilla.firefox" -- work pages open there (link_router.lua)

-- Telegram's main window is titled "Telegram" ("(N) Telegram" with unread messages);
-- a detached chat carries the chat's name. The personal layout splits on that:
-- the open chat goes left, the inbox right.
local function isInbox(title)
    return (title or ""):gsub("^%(%d+%)%s*", "") == "Telegram"
end

-- orderedWindows skips minimized windows, so the second pass takes any chat window;
-- otherwise the left half would stay empty.
local function topChat(app)
    for _, win in ipairs(hs.window.orderedWindows()) do
        local owner = win:application()
        if owner and owner:pid() == app:pid() and win:isStandard() and not isInbox(win:title()) then
            return win
        end
    end
    for _, win in ipairs(app:allWindows()) do
        if win:isStandard() and not isInbox(win:title()) then return win end
    end
end

-- Telegram's two non-standard windows are untitled shadows mirroring real windows
-- with a 0.01 offset; they are left alone.
local function personalTelegram(app, pw)
    if app:isHidden() then app:unhide() end
    local chat = topChat(app)
    for _, win in ipairs(app:allWindows()) do
        if win:isStandard() then
            if win == chat then
                if win:isMinimized() then win:unminimize() end
                pw:moveLeft(win)
            elseif isInbox(win:title()) then
                if win:isMinimized() then win:unminimize() end
                pw:moveRight(win)
            else
                win:minimize()
            end
        end
    end
end

return {
    ["only-work"] = {
        keep = { ZAP, telegram },
        focus = { ZAP },
    },
    work = {
        keep = { "com.jetbrains.rider", "com.DanPristupov.Fork", ZAP, "com.microsoft.VSCode",
                 "com.jetbrains.WebStorm", "com.apple.dt.Xcode", FIREFOX, telegram },
        focus = { FIREFOX, "com.jetbrains.rider", ZAP },
    },
    personal = {
        keep = { "com.colliderli.iina" },
        focus = { telegram },
        video = "corner", -- the right column is the inbox, so video goes below it
        custom = { [telegram] = personalTelegram },
    },
    comms = {
        keep = { telegram, "us.zoom.xos", "ru.yandex.desktop.telemost" },
        focus = { "us.zoom.xos", "ru.yandex.desktop.telemost", telegram },
    },
}
