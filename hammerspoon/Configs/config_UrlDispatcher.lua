spoon.SpoonInstall:andUse("URLDispatcher", {
    config = {
        url_patterns = {{".*spotwa.*", Safari}, {".*ctrader.*", Safari}},
        url_redir_decoders = {{"Fix broken Preview anchor URLs", "%%23", "#", false, "Preview"}},
        default_handler = Yandex
    },
    start = true
    -- loglevel = 'debug'
})
