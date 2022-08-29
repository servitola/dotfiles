local wm = hs.webview.windowMasks
hs.loadSpoon("PopupTranslateSelection", {
    hotkeys = {
        translate_to_ru = {{"left_control", "left_option"}, "z"},
        translate_to_en = {{"left_control", "left_option"}, "tab"},
        translate_to_el = {{"left_control", "left_option"}, "g"},
    }}, true)