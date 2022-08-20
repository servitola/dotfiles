require "User/constants";
require "config";
require "User/Configs/config_SpoonInstall";
require "User/Configs/config_UrlDispatcher";
require "User/Configs/config_HeadphoneAutoPause";
require "User/Configs/config_WiFiTransitions";

spoon.SpoonInstall:andUse("KSheet")

local wm = hs.webview.windowMasks

require "User/Configs/config_Popup_TranslateSelection";
require "User/Configs/config_DeepLTranslate";

hs.loadSpoon("ModalMgr")

-- Load those Spoons
for _, v in pairs(hspoon_list) do
    hs.loadSpoon(v)
end

ksheet = false

require "User/register_all_shortcuts"
require "User/Configs/config_Griddle_MouseMoveWithKeyboard"

----------------------------------------------------------------------------------------------------
-- appM modal environment
-- spoon.ModalMgr:new("appM")
-- local cmodal = spoon.ModalMgr.modal_list["appM"]
-- cmodal:bind('', 'escape', 'Deactivate appM', function()
--     spoon.ModalMgr:deactivate({"appM"})
-- end)
-- cmodal:bind('', 'Q', 'Deactivate appM', function()
--     spoon.ModalMgr:deactivate({"appM"})
-- end)
-- cmodal:bind('', 'tab', 'Toggle Cheatsheet', function()
--     spoon.ModalMgr:toggleCheatsheet()
-- end)

-- Then we register some keybindings with modal supervisor
-- hsappM_keys = hsappM_keys or {"alt", "A"}
-- if string.len(hsappM_keys[2]) > 0 then
--     spoon.ModalMgr.supervisor:bind(hsappM_keys[1], hsappM_keys[2], "Enter AppM Environment", function()
--         spoon.ModalMgr:deactivateAll()
--         -- Show the keybindings cheatsheet once appM is activated
--         spoon.ModalMgr:activate({"appM"}, "#FFBD2E", true)\
--     end)
-- end

---- Mouse Movement Griddle


----------------------------------------------------------------------------------------------------
spoon.ModalMgr.supervisor:enter()

require "User/reload_hammerspoon_on_config_change"

require "User/Configs/config_FadeLogo";
