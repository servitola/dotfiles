Zoom = "us.zoom.xos"
Safari = "com.apple.Safari"
Firefox = "org.mozilla.firefox"
urlDispatcherSpoon = hs.loadSpoon("URLDispatcher")

urlDispatcherSpoon.default_handler = "org.mozilla.firefox"

urlDispatcherSpoon.url_patterns = {
    { "https?://.*zoom.us/j/", Zoom },
    { ".*spotwa.*", Safari },
    { ".*ctrader.*", Safari },
    { "xd.adobe.com.*", Safari }
  }

urlDispatcherSpoon.url_redir_decoders = {
    { "Fix broken Preview anchor URLs", "%%23", "#", false, "Preview" },
  }
