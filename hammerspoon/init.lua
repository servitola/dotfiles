hs.console.clearConsole()
hs.console.consoleFont({ name = 'Meslo LG M for Powerline', size = 20.0 })

require "User/config_SpoonInstall";
spoon.SpoonInstall:andUse("Windows");
require "User/register_all_shortcuts"
require "User/config_Popup_TranslateSelection";
require "User/config_UrlDispatcher";
require "User/config_WiFiTransitions";
spoon.SpoonInstall:andUse("KSheet");
spoon.SpoonInstall:andUse("UnsplashZ"); 
spoon.SpoonInstall:andUse("ReloadConfiguration", { start = true });
spoon.SpoonInstall:andUse("FadeLogo", { start = true })