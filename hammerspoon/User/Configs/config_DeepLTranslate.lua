local wm = hs.webview.windowMasks

spoon.SpoonInstall:andUse("DeepLTranslate", {
    disable = true,
    config = {
        popup_style = wm.utility | wm.HUD | wm.titled | wm.closable | wm.resizable
    },
    hotkeys = {
        translate = {hyper, "i"}
    }
})