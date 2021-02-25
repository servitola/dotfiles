require "Configs/constants";
require "config";
require "Configs/config_SpoonInstall";
require "Configs/config_UrlDispatcher";
require "Configs/config_HeadphoneAutoPause";

spoon.SpoonInstall:andUse("WiFiTransitions", {
    config = {
        actions = {{ -- Enable proxy config when joining corp network
            to = "corpnet01",
            fn = {hs.fnutils.partial(reconfigSpotifyProxy, true), hs.fnutils.partial(reconfigAdiumProxy, true),
                  hs.fnutils.partial(forceKillProcess, "Dropbox"), hs.fnutils.partial(stopApp, "Evernote")}
        }, { -- Disable proxy config when leaving corp network
            from = "corpnet01",
            fn = {hs.fnutils.partial(reconfigSpotifyProxy, false), hs.fnutils.partial(reconfigAdiumProxy, false),
                  hs.fnutils.partial(startApp, "Dropbox")}
        }}
    },
    start = true
})

local wm = hs.webview.windowMasks

require "Configs/PopupTranslateSelection";
require "Configs/config_DeepLTranslate";

-- ModalMgr Spoon must be loaded explicitly, because this repository heavily relies upon it.
hs.loadSpoon("ModalMgr")

-- Load those Spoons
for _, v in pairs(hspoon_list) do
    hs.loadSpoon(v)
end

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
                spoon.Windows:bindWindowLeft(modifier, chord_row.key)
            elseif chord_row.specific_function == "window.right" then
                spoon.Windows:bindWindowRight(modifier, chord_row.key)
            elseif chord_row.specific_function == "window.fullscreen" then
                spoon.Windows:bindWindowFullScreen(modifier, chord_row.key)
            elseif chord_row.specific_function == "window.set_all_to_default" then
                spoon.Windows:bindAllWindowsToDefault(modifier, chord_row.key)
            end
        end
    end
end

spoon.ModalMgr.supervisor:bind(hswhints_keys[1], hswhints_keys[2], 'Show Window Hints', function()
    spoon.ModalMgr:deactivateAll()
    hs.hints.windowHints()
end)

----------------------------------------------------------------------------------------------------
-- appM modal environment
spoon.ModalMgr:new("appM")
local cmodal = spoon.ModalMgr.modal_list["appM"]
cmodal:bind('', 'escape', 'Deactivate appM', function()
    spoon.ModalMgr:deactivate({"appM"})
end)
cmodal:bind('', 'Q', 'Deactivate appM', function()
    spoon.ModalMgr:deactivate({"appM"})
end)
cmodal:bind('', 'tab', 'Toggle Cheatsheet', function()
    spoon.ModalMgr:toggleCheatsheet()
end)
-- for _, shortcut_info in ipairs(apps_list.caps_lock) do
--     if shortcut_info.id then
--         local located_name = hs.application.nameForBundleID(v.id)
--         if located_name then
--             cmodal:bind('', v.key, located_name, function()
--                 hs.application.launchOrFocusByBundleID(v.id)
--                 spoon.ModalMgr:deactivate({"appM"})
--             end)
--         end
--     elseif shortcut_info.app_name then
--         cmodal:bind('', shortcut_info.key, shortcut_info.app_name, function()
--             hs.application.launchOrFocus(v.app_name)
--             spoon.ModalMgr:deactivate({"appM"})
--         end)
--     end
-- end

-- Then we register some keybindings with modal supervisor
-- hsappM_keys = hsappM_keys or {"alt", "A"}
-- if string.len(hsappM_keys[2]) > 0 then
--     spoon.ModalMgr.supervisor:bind(hsappM_keys[1], hsappM_keys[2], "Enter AppM Environment", function()
--         spoon.ModalMgr:deactivateAll()
--         -- Show the keybindings cheatsheet once appM is activated
--         spoon.ModalMgr:activate({"appM"}, "#FFBD2E", true)
--     end)
-- end

----------------------------------------------------------------------------------------------------
-- clipshowM modal environment
if spoon.ClipShow then
    spoon.ModalMgr:new("clipshowM")
    local cmodal = spoon.ModalMgr.modal_list["clipshowM"]
    cmodal:bind('', 'escape', 'Deactivate clipshowM', function()
        spoon.ClipShow:toggleShow()
        spoon.ModalMgr:deactivate({"clipshowM"})
    end)
    cmodal:bind('', 'Q', 'Deactivate clipshowM', function()
        spoon.ClipShow:toggleShow()
        spoon.ModalMgr:deactivate({"clipshowM"})
    end)
    cmodal:bind('', 'N', 'Save this Session', function()
        spoon.ClipShow:saveToSession()
    end)
    cmodal:bind('', 'R', 'Restore last Session', function()
        spoon.ClipShow:restoreLastSession()
    end)
    cmodal:bind('', 'B', 'Open in Browser', function()
        spoon.ClipShow:openInBrowserWithRef()
        spoon.ClipShow:toggleShow()
        spoon.ModalMgr:deactivate({"clipshowM"})
    end)
    cmodal:bind('', 'S', 'Search with Bing', function()
        spoon.ClipShow:openInBrowserWithRef("https://www.bing.com/search?q=")
        spoon.ClipShow:toggleShow()
        spoon.ModalMgr:deactivate({"clipshowM"})
    end)
    cmodal:bind('', 'M', 'Open in MacVim', function()
        spoon.ClipShow:openWithCommand("/usr/local/bin/mvim")
        spoon.ClipShow:toggleShow()
        spoon.ModalMgr:deactivate({"clipshowM"})
    end)
    cmodal:bind('', 'F', 'Save to Desktop', function()
        spoon.ClipShow:saveToFile()
        spoon.ClipShow:toggleShow()
        spoon.ModalMgr:deactivate({"clipshowM"})
    end)
    cmodal:bind('', 'H', 'Search in Github', function()
        spoon.ClipShow:openInBrowserWithRef("https://github.com/search?q=")
        spoon.ClipShow:toggleShow()
        spoon.ModalMgr:deactivate({"clipshowM"})
    end)
    cmodal:bind('', 'G', 'Search with Google', function()
        spoon.ClipShow:openInBrowserWithRef("https://www.google.com/search?q=")
        spoon.ClipShow:toggleShow()
        spoon.ModalMgr:deactivate({"clipshowM"})
    end)
    cmodal:bind('', 'L', 'Open in Sublime Text', function()
        spoon.ClipShow:openWithCommand("/usr/local/bin/subl")
        spoon.ClipShow:toggleShow()
        spoon.ModalMgr:deactivate({"clipshowM"})
    end)

    -- Register clipshowM with modal supervisor
    hsclipsM_keys = hsclipsM_keys or {"alt", "C"}
    if string.len(hsclipsM_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(hsclipsM_keys[1], hsclipsM_keys[2], "Enter clipshowM Environment", function()
            -- We need to take action upon hsclipsM_keys is pressed, since pressing another key to showing ClipShow panel is redundant.
            spoon.ClipShow:toggleShow()
            -- Need a little trick here. Since the content type of system clipboard may be "URL", in which case we don't need to activate clipshowM.
            if spoon.ClipShow.canvas:isShowing() then
                spoon.ModalMgr:deactivateAll()
                spoon.ModalMgr:activate({"clipshowM"})
            end
        end)
    end
end

----------------------------------------------------------------------------------------------------
-- countdownM modal environment
if spoon.CountDown then
    spoon.ModalMgr:new("countdownM")
    local cmodal = spoon.ModalMgr.modal_list["countdownM"]
    cmodal:bind('', 'escape', 'Deactivate countdownM', function()
        spoon.ModalMgr:deactivate({"countdownM"})
    end)
    cmodal:bind('', 'Q', 'Deactivate countdownM', function()
        spoon.ModalMgr:deactivate({"countdownM"})
    end)
    cmodal:bind('', 'tab', 'Toggle Cheatsheet', function()
        spoon.ModalMgr:toggleCheatsheet()
    end)
    cmodal:bind('', '0', '5 Minutes Countdown', function()
        spoon.CountDown:startFor(5)
        spoon.ModalMgr:deactivate({"countdownM"})
    end)
    for i = 1, 9 do
        cmodal:bind('', tostring(i), string.format("%s Minutes Countdown", 10 * i), function()
            spoon.CountDown:startFor(10 * i)
            spoon.ModalMgr:deactivate({"countdownM"})
        end)
    end
    cmodal:bind('', 'return', '25 Minutes Countdown', function()
        spoon.CountDown:startFor(25)
        spoon.ModalMgr:deactivate({"countdownM"})
    end)
    cmodal:bind('', 'space', 'Pause/Resume CountDown', function()
        spoon.CountDown:pauseOrResume()
        spoon.ModalMgr:deactivate({"countdownM"})
    end)

    -- Register countdownM with modal supervisor
    hscountdM_keys = hscountdM_keys or {"alt", "I"}
    if string.len(hscountdM_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(hscountdM_keys[1], hscountdM_keys[2], "Enter countdownM Environment", function()
            spoon.ModalMgr:deactivateAll()
            -- Show the keybindings cheatsheet once countdownM is activated
            spoon.ModalMgr:activate({"countdownM"}, "#FF6347", true)
        end)
    end
end

----------------------------------------------------------------------------------------------------
-- cheatsheetM modal environment
-- spoon.SpoonInstall:andUse("KSheet", {
--     hotkeys = {
--       toggle = { hyper, "'" }
--     }
-- })

----------------------------------------------------------------------------------------------------
-- Register AClock
if spoon.AClock then
    hsaclock_keys = hsaclock_keys or {"alt", "T"}
    if string.len(hsaclock_keys[2]) > 0 then
        spoon.ModalMgr.supervisor:bind(hsaclock_keys[1], hsaclock_keys[2], "Toggle Floating Clock", function()
            spoon.AClock:toggleShow()
        end)
    end
end

----------------------------------------------------------------------------------------------------
-- Register browser tab typist: Type URL of current tab of running browser in markdown format. i.e. [title](link)
hstype_keys = hstype_keys or {"alt", "V"}
if string.len(hstype_keys[2]) > 0 then
    spoon.ModalMgr.supervisor:bind(hstype_keys[1], hstype_keys[2], "Type Browser Link", function()
        local safari_running = hs.application.applicationsForBundleID("com.apple.Safari")
        local chrome_running = hs.application.applicationsForBundleID("com.google.Chrome")
        if #safari_running > 0 then
            local stat, data = hs.applescript('tell application "Safari" to get {URL, name} of current tab of window 1')
            if stat then
                hs.eventtap.keyStrokes("[" .. data[2] .. "](" .. data[1] .. ")")
            end
        elseif #chrome_running > 0 then
            local stat, data = hs.applescript(
                                   'tell application "Google Chrome" to get {URL, title} of active tab of window 1')
            if stat then
                hs.eventtap.keyStrokes("[" .. data[2] .. "](" .. data[1] .. ")")
            end
        end
    end)
end

spoon.ModalMgr.supervisor:enter()

require "Configs/config_FadeLogo";