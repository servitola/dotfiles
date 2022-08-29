hs.console.clearConsole()
hs.console.consoleFont({ name = 'Meslo LG M for Powerline', size = 20.0 })

hs.loadSpoon("UnsplashZ")
hs.loadSpoon("Windows")
hs.loadSpoon("HotKeys")
require "User/config_Popup_TranslateSelection";
require "User/config_UrlDispatcher";
hs.loadSpoon("KSheet")
hs.loadSpoon("ReloadConfiguration",{ start = true }, true)
hs.loadSpoon("FadeLogo",{ start = true }, true)