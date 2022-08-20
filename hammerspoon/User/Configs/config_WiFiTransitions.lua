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