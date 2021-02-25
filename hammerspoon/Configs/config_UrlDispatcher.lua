spoon.SpoonInstall:andUse("URLDispatcher", {
    config = {
        url_patterns = {{".*workname.*", Safari}, {".*workproject.*", Safari}},
        url_redir_decoders = {{"Fix broken Preview anchor URLs", "%%23", "#", false, "Preview"}},
        default_handler = Yandex
    },
    start = true
    -- loglevel = 'debug'
})
