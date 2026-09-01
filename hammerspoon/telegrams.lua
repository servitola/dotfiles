local M = {}

M.known = {
    Forkgram = {
        app    = "Forkgram",
        bundle = "com.tdesktop.Telegram",
    },
    Telegram = {
        app    = "Telegram",
        bundle = "ru.keepcoder.Telegram",
    },
    AyuGram = {
        app    = "AyuGram",
        bundle = "one.ayugram.AyuGramDesktop",
    },
}

function M.by_app(app_title)
    if not app_title then return nil end
    for _, client in pairs(M.known) do
        if client.app == app_title then return client end
    end
    return nil
end

function M.is_bundle(bundle_id)
    if not bundle_id then return false end
    for _, client in pairs(M.known) do
        if client.bundle == bundle_id then return true end
    end
    return false
end

local chosen = require("constants").APP_TELEGRAM
M.main = assert(M.by_app(chosen), "telegrams: APP_TELEGRAM is not in M.known: " .. tostring(chosen))

return M
