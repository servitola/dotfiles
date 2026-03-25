Firefox = "org.mozilla.firefox"
Yandex = "ru.yandex.desktop.yandex-browser"
Chrome = "com.google.Chrome"

spoon.URLDispatcher.default_handler = Yandex

spoon.URLDispatcher.url_patterns = {
    { "https?://localhost[:/]",           Chrome },
    { "https?://127%.0%.0%.1[:/]",        Chrome },
    { "https?://0%.0%.0%.0[:/]",          Chrome },
    { "https?://192%.168%.",              Chrome },
    { "https?://10%.",                    Chrome },
    { "https?://172%.1[6-9]%.",           Chrome },
    { "https?://172%.2%d%.",              Chrome },
    { "https?://172%.3[01]%.",            Chrome },
    { ".*spotwa.*",                       Firefox },
    { ".*ctrader.*",                      Firefox },
    { "xd.adobe.com.*",                   Firefox },
  }

spoon.URLDispatcher.url_redir_decoders = {}
