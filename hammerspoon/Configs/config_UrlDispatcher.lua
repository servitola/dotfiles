local Zoom = "us.zoom.xos"
local Safari = "com.apple.Safari"

spoon.SpoonInstall:andUse("URLDispatcher", {
    config = {
        url_patterns = {
            {"https?://zoom.us/j/", Zoom},
            {"https?://%w+.zoom.us/j/", Zoom},
            {"https?://%w+.workname", Zoom},
            {".*workname.*", Safari}, 
            {".*workproject.*", Safari}
        },
        url_redir_decoders = {{"Fix broken Preview anchor URLs", "%%23", "#", false, "Preview"}},
        default_handler = Chrome
    },
    start = true,
    --loglevel = 'debug'
})
