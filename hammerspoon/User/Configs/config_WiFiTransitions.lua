spoon.SpoonInstall:andUse("WiFiTransitions", {
    config = {
        actions = {{
            to = "Bulat",
            fn = {
                hs.notify.new({
                title = "Hammerspoon launch",
                informativeText = "You're at home"
            }):send()}
        }, {
            
        }}
    },
    start = true
})