local M = {}

M.known = {
    Vivaldi = {
        app          = "Vivaldi",
        bundle       = "com.vivaldi.Vivaldi",
        title_suffix = " - Vivaldi",
    },
    Yandex = {
        app          = "Yandex",
        bundle       = "ru.yandex.desktop.yandex-browser",
        -- «— Yandex Browser» with nbsp before Browser in bytes
        title_suffix = string.char(226, 128, 148, 32, 89, 97, 110, 100, 101, 120,
                                   194, 160, 66, 114, 111, 119, 115, 101, 114),
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
