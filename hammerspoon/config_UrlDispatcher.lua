Zoom = "us.zoom.xos"
Safari = "com.apple.Safari"
Firefox = "org.mozilla.firefox"

hs.loadSpoon("URLDispatcher", {
    config = {
        url_patterns = {
            { "https?://.*zoom.us/j/", Zoom },
            { ".*spotwa.*", Safari }, 
            { ".*ctrader.*", Safari },
            { "xd.adobe.com.*", Safari }
        },
        --url_redir_decoders = {{"Fix broken Preview anchor URLs", "%%23", "#", false, "Preview"}},
        default_handler = Firefox
    }
}, true)
