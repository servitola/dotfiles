local wm = hs.webview.windowMasks
spoon.SpoonInstall:andUse("PopupTranslateSelection", {
    config = {
        popup_style = wm.utility | wm.HUD | wm.titled | wm.closable | wm.resizable
    },
    hotkeys = {
        translate_to_ru = {hyper, "="},
        translate_to_en = {hyper, "0"},
        --    translate_to_de = { hyper, "d" },
        --    translate_to_es = { hyper, "s" },
        --    translate_de_en = { shift_hyper, "e" },
        --    translate_en_de = { shift_hyper, "d" },
    }
})
