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