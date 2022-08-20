require "User/constants";
require "config";
require "User/Configs/config_SpoonInstall";
require "User/Configs/config_UrlDispatcher";
require "User/Configs/config_HeadphoneAutoPause";
require "User/Configs/config_WiFiTransitions";
require "User/Configs/config_Popup_TranslateSelection";
require "User/Configs/config_DeepLTranslate";

spoon.SpoonInstall:andUse("DeepLTranslate");
spoon.SpoonInstall:andUse("Windows");
spoon.SpoonInstall:andUse("HotKeys");
spoon.SpoonInstall:andUse("Griddle");
spoon.SpoonInstall:andUse("FnMate");
spoon.SpoonInstall:andUse("HSaria2");
spoon.SpoonInstall:andUse("KSheet");
spoon.SpoonInstall:andUse("UnsplashZ");

ksheet = false

require "User/register_all_shortcuts"
require "User/Configs/config_Griddle_MouseMoveWithKeyboard"

require "User/reload_hammerspoon_on_config_change"
require "User/Configs/config_FadeLogo";
