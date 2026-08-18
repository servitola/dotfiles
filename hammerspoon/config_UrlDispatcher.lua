local browsers = require "browsers"

Firefox = "org.mozilla.firefox"
Yandex = "ru.yandex.desktop.yandex-browser"
Chrome = "com.google.Chrome"

spoon.URLDispatcher.default_handler = browsers.main.bundle

spoon.URLDispatcher.url_patterns = {
    { "https?://localhost[:/]",           Chrome },
    { "https?://127%.0%.0%.1[:/]",        Chrome },
    { "https?://0%.0%.0%.0[:/]",          Chrome },
    { "https?://192%.168%.",              Chrome },
    { "https?://10%.",                    Chrome },
    { "https?://172%.1[6-9]%.",           Chrome },
    { "https?://172%.2%d%.",              Chrome },
    { "https?://172%.3[01]%.",            Chrome },
    { ".*workname.*",                       Firefox },
    { ".*workproject.*",                      Firefox },
    { "xd.adobe.com.*",                   Firefox },
  }

spoon.URLDispatcher.url_redir_decoders = {}
