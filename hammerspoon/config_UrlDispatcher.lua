Safari = "com.apple.Safari"
Yandex = "ru.yandex.desktop.yandex-browser"
urlDispatcherSpoon = hs.loadSpoon("URLDispatcher")

urlDispatcherSpoon.default_handler = Yandex

urlDispatcherSpoon.url_patterns = {
    { ".*spotwa.*", Safari },
    { ".*ctrader.*", Safari },
    { "xd.adobe.com.*", Safari }
  }

urlDispatcherSpoon.url_redir_decoders = {}
