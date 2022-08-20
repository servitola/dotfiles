require "User/constants";
require "config";
require "User/Configs/config_SpoonInstall";
require "User/Configs/config_UrlDispatcher";
require "User/Configs/config_HeadphoneAutoPause";
require "User/Configs/config_WiFiTransitions";

spoon.SpoonInstall:andUse("KSheet")

require "User/Configs/config_Popup_TranslateSelection";
require "User/Configs/config_DeepLTranslate";

-- Load those Spoons
for _, v in pairs(hspoon_list) do
    hs.loadSpoon(v)
end

ksheet = false

require "User/register_all_shortcuts"
require "User/Configs/config_Griddle_MouseMoveWithKeyboard"

require "User/reload_hammerspoon_on_config_change"
require "User/Configs/config_FadeLogo";
