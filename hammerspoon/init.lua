hs.console.clearConsole()
hs.console.consoleFont({ name = 'JetBrainsMono Nerd Font Mono', size = 11.0 })
hs.keycodes.setLayout("ABC")

hs.loadSpoon("UnsplashZ") -- download new wallpaper
hs.loadSpoon("Windows") -- window management
hs.loadSpoon("KSheet") -- shortcuts cheatsheet
hs.loadSpoon("PopupTranslateSelection") -- translate selected text
hs.loadSpoon("HotKeys") -- all hotkeys
require "config_UrlDispatcher"; -- open urls in different browsers


appwatcher = hs.application.watcher.new(function(appName, eventType, appObject)
 if eventType == hs.application.watcher.activated then
    if(appObject:bundleID() == "ru.keepcoder.Telegram") then
      hs.keycodes.setLayout("Russian – PC")
    else
      hs.keycodes.setLayout("ABC")
    end
  end
end)

appwatcher:start()

hs.pathwatcher.new(hs.configdir, hs.reload):start() -- reload Hammerspoon config on change
