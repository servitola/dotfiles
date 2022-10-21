appwatcher = hs.application.watcher.new(function(appName, eventType, appObject)
  if eventType == hs.application.watcher.activated or eventType == hs.application.watcher.unhidden then
     if(appObject:bundleID() == "ru.keepcoder.Telegram") then
       hs.keycodes.setLayout("Russian - Ilya Birman Typography")
     else
       hs.keycodes.setLayout("English - Ilya Birman Typography")
     end
   end
 end)
 appwatcher:start()
