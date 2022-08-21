local wm = hs.webview.windowMasks
spoon.SpoonInstall:andUse("PopupTranslateSelection", {
    config = {
        popup_style = wm.utility | wm.HUD | wm.titled | wm.closable | wm.resizable
    },
    hotkeys = {
        translate_to_ru = {{"left_control", "left_option"}, "r"},
        translate_to_en = {{"left_control", "left_option"}, "e"},
        translate_to_el = {{"left_control", "left_option"}, "g"},
    }
})
