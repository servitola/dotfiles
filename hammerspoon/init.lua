local hyper = {"left_command","left_control", "left_option", "left_shift"}

hs.loadSpoon("WindowsManager")
hs.window.animationDuration = 0.08
spoon.WindowsManager:bindWindowsHotkeys({
    up = {{"ctrl", "alt"}, "up"},
    right = {{"ctrl", "alt"}, "right"},
    down = {{"ctrl", "alt"}, "down"},
    left = {{"ctrl", "alt"}, "left"}
})

spoon.WindowsManager:bindHotkey({
    chord = { hyper, "t"},
    appname = "Telegram"
})

spoon.WindowsManager:bindHotkey({
    chord = { hyper, "r"},
    appname = "Rider"
})

spoon.WindowsManager:bindHotkey({
    chord = { hyper, "y"},
    appname = "Yandex"
})

spoon.WindowsManager:bindHotkey({
    chord = { hyper, "f"},
    appname = "Finder"
})

spoon.WindowsManager:bindHotkey({
    chord = { hyper, "g"},
    appname = "Fork"
})

spoon.WindowsManager:bindHotkey({
    chord = { hyper, "j"},
    appname = "Safari"
})

spoon.WindowsManager:bindHotkey({
    chord = { hyper, "c"},
    appname = "iTerm"
})

spoon.WindowsManager:bindHotkey({
    chord = { hyper, "n"},
    appname = "Visual Studio Code"
})



