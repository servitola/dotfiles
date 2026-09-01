local M = {}

M.known = {
    Zen = {
        app         = "Zen",
        bundle      = "app.zen-browser.zen",
        video_title = GECKO_VIDEO_TITLE,
        pip_chord   = GECKO_PIP_CHORD,
    },
    Firefox = {
        app         = "Firefox",
        bundle      = "org.mozilla.firefox",
        video_title = GECKO_VIDEO_TITLE,
        pip_chord   = GECKO_PIP_CHORD,
    },
    Vivaldi = {
        app          = "Vivaldi",
        bundle       = "com.vivaldi.Vivaldi",
        video_title      = CHROMIUM_VIDEO_TITLE,
        title_suffix = " - Vivaldi",
        applescript_tabs = true,
    },
    Yandex = {
        app          = "Yandex",
        bundle       = "ru.yandex.desktop.yandex-browser",
        video_title      = CHROMIUM_VIDEO_TITLE,
        -- «— Yandex Browser» with nbsp before Browser in bytes
        title_suffix = string.char(226, 128, 148, 32, 89, 97, 110, 100, 101, 120,
                                   194, 160, 66, 114, 111, 119, 115, 101, 114),
        applescript_tabs = true,
    },
    ["Google Chrome"] = {
        app              = "Google Chrome",
        bundle           = "com.google.Chrome",
        video_title      = CHROMIUM_VIDEO_TITLE,
        applescript_tabs = true,
    },
    Opera = {
        app              = "Opera",
        bundle           = "com.operasoftware.Opera",
        video_title      = CHROMIUM_VIDEO_TITLE,
        applescript_tabs = true,
    },
}

function M.by_app(app_title)
    if not app_title then return nil end
    for _, browser in pairs(M.known) do
        if browser.app == app_title then return browser end
    end
    return nil
end

local chosen = require("constants").APP_BROWSER
M.main = assert(M.by_app(chosen), "browsers: APP_BROWSER is not in M.known: " .. tostring(chosen))

return M
