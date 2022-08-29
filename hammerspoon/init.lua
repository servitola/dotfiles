hs.console.clearConsole()
hs.console.consoleFont({ name = 'Meslo LG M for Powerline', size = 20.0 })

hs.spoons.use("Windows", nil, true)
require "User/register_all_shortcuts"
require "User/config_Popup_TranslateSelection";
require "User/config_UrlDispatcher";
hs.spoons.use("KSheet", nil, true)
hs.spoons.use("UnsplashZ", nil, true)
hs.spoons.use("ReloadConfiguration", { start = true }, true)
hs.spoons.use("FadeLogo", { start = true }, true)