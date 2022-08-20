local wm = hs.webview.windowMasks
spoon.SpoonInstall:andUse("PopupTranslateSelection", {
    config = {
        popup_style = wm.utility | wm.HUD | wm.titled | wm.closable | wm.resizable
    },
    hotkeys = {
        translate_to_ru = {ctrlAndAlt, "r"},
        translate_to_en = {ctrlAndAlt, "e"},
        translate_to_el = {ctrlAndAlt, "g"},
    }
})
