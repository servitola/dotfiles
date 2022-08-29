local Zoom = "us.zoom.xos"
local Safari = "com.apple.Safari"
local Firefox = "org.mozilla.firefox"

spoon.SpoonInstall:andUse("URLDispatcher", {
    config = {
        url_patterns = {
            { "https?://zoom.us/j/", Zoom },
            { "https?://%w+.zoom.us/j/", Zoom },
            { "https?://%w+.workname", Zoom },
            { ".*workname.*", Safari }, 
            { ".*workproject.*", Safari },
            { "xd.adobe.com.*", Safari }
        },
        --url_redir_decoders = {{"Fix broken Preview anchor URLs", "%%23", "#", false, "Preview"}},
        default_handler = Firefox
    },
    start = true,
    --loglevel = 'debug'
})
