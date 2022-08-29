hs.console.clearConsole()
hs.console.consoleFont({ name = 'Meslo LG M for Powerline', size = 10.0 })

hs.loadSpoon("UnsplashZ")
hs.loadSpoon("Windows")
hs.loadSpoon("KSheet")
hs.loadSpoon("PopupTranslateSelection")
hs.loadSpoon("HotKeys")

require "config_UrlDispatcher";

hs.pathwatcher.new(hs.configdir, hs.reload):start()