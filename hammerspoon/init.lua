hs.console.clearConsole()
hs.console.consoleFont({ name = 'Meslo LG M for Powerline', size = 20.0 })

hs.loadSpoon("UnsplashZ")
hs.loadSpoon("Windows")
hs.loadSpoon("HotKeys")
hs.loadSpoon("PopupTranslateSelection", {
    hotkeys = {
        translate_to_ru = {{"left_control", "left_option"}, "z"},
        translate_to_en = {{"left_control", "left_option"}, "tab"},
        translate_to_el = {{"left_control", "left_option"}, "g"},
    }}, true)
require "config_UrlDispatcher";
hs.loadSpoon("KSheet")
hs.loadSpoon("ReloadConfiguration",{ start = true }, true)