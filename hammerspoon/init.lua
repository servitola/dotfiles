require "Configs/constants";
require "config";
require "Configs/config_SpoonInstall";
require "Configs/config_UrlDispatcher";
require "Configs/config_HeadphoneAutoPause";

spoon.SpoonInstall:andUse("WiFiTransitions", {
    config = {
        actions = {{ -- Enable proxy config when joining corp network
            to = "Bulat",
            fn = {
                hs.notify.new({
                title = "Hammerspoon launch",
                informativeText = "Boss, at your service"
            }):send()}
        }, {
            
        }}
    },
    start = true
})

spoon.SpoonInstall:andUse("KSheet")

local wm = hs.webview.windowMasks

require "Configs/PopupTranslateSelection";
require "Configs/config_DeepLTranslate";

 hs.loadSpoon("ModalMgr")

-- Load those Spoons
for _, v in pairs(hspoon_list) do
    hs.loadSpoon(v)
end

ksheet = false

local logger = hs.logger.new("window", 'verbose')
logger.d(" ")

for _, row in pairs(apps_list) do
    modifier = hyper

    if row.modifier == "ctrl_alt" then
        modifier = ctrlAndAlt
    end

    for _, chord_row in pairs(row.chords) do
        if chord_row.app_name then
            spoon.HotKeys:bindOpenApp(modifier, chord_row.key, chord_row.app_name)
        elseif chord_row.specific_function then
            if chord_row.specific_function == "window.left" then
                spoon.Windows:bind_window_left(modifier, chord_row.key)
            elseif chord_row.specific_function == "window.right" then
                spoon.Windows:bind_window_right(modifier, chord_row.key)
            elseif chord_row.specific_function == "window.fullscreen" then
                spoon.Windows:bind_window_fullscreen(modifier, chord_row.key)
            elseif chord_row.specific_function == "window.set_all_to_default" then
                spoon.Windows:bind_all_windows_to_default(modifier, chord_row.key)
            elseif chord_row.specific_function == "android.show_all" then
                hs.hotkey.bind(modifier, chord_row.key, function()
                    local wins = hs.window.visibleWindows()
                    for _, window in ipairs(wins) do
                        local window_title = window:title()
                        local app_title = window:application():title()
                        if app_title == "qemu-system-x86_64" or string.find(window_title, "Android Emulator") then
                            window:focus()
                        end
                    end
                end)
            elseif chord_row.specific_function == "info.show_shortcuts" then
                hs.hotkey.bind(modifier, chord_row.key, function()
                    if ksheet then
                        spoon.KSheet:hide()
                    else
                        spoon.KSheet:show()
                    end

                    ksheet = not ksheet
                end)
                -- elseif chord_row.specific_function == "volume_up" then
                --     logger.d(" up")
                --     hs.hotkey.bind(modifier, chord_row.key, changeVolume(3))
                -- elseif chord_row.specific_function == "volume_down" then
                --     logger.d(" down")
                --     hs.hotkey.bind(modifier, '/', changeVolume(-3))
            end

        end
    end
end

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
if spoon.Griddle then
    spoon.Griddle:bindHotkeys({ enter = { ctrlAndAlt, "m" } })
    print("Griddle binded its keys")
    spoon.Griddle:start()
end

----------------------------------------------------------------------------------------------------
spoon.ModalMgr.supervisor:enter()

function reloadConfig(paths)
    doReload = false
    for _, file in pairs(paths) do
        if file:sub(-4) == ".lua" then
            print("A lua config file changed, reload")
            doReload = true
        end
    end
    if not doReload then
        print("No lua file changed, skipping reload test")
        return
    end

    hs.reload()
end

configFileWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig)
configFileWatcher:start()

require "Configs/config_FadeLogo";
