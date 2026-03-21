Firefox = "org.mozilla.firefox"
Yandex = "ru.yandex.desktop.yandex-browser"
urlDispatcherSpoon = hs.loadSpoon("URLDispatcher")

urlDispatcherSpoon.default_handler = Yandex

urlDispatcherSpoon.url_patterns = {
    { ".*spotwa.*", Firefox },
    { ".*ctrader.*", Firefox },
    { "xd.adobe.com.*", Firefox }
  }

urlDispatcherSpoon.url_redir_decoders = {}
