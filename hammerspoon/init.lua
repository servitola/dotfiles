hs.console.clearConsole()
hs.console.consoleFont({ name = 'Meslo LG M for Powerline', size = 20.0 })

require "User/Configs/config_SpoonInstall";
spoon.SpoonInstall:andUse("Windows");
require "User/register_all_shortcuts"
require "User/Configs/config_Popup_TranslateSelection";
require "User/Configs/config_UrlDispatcher";
require "User/Configs/config_WiFiTransitions";
spoon.SpoonInstall:andUse("HoldToQuit", { start = true});
spoon.SpoonInstall:andUse("KSheet");
spoon.SpoonInstall:andUse("UnsplashZ"); 
spoon.SpoonInstall:andUse("ReloadConfiguration", { start = true });
spoon.SpoonInstall:andUse("FadeLogo", { start = true})