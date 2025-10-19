appwatcher = hs.application.watcher.new(function(appName, eventType, appObject)
  if eventType == hs.application.watcher.activated or eventType == hs.application.watcher.unhidden then

      bundleId = appObject:bundleID()
      if(bundleId == "ru.keepcoder.Telegram"
         or bundleId == "one.ayugram.AyuGramDesktop")
      then
        hs.keycodes.setLayout("Ru Birman")
      else
        hs.keycodes.setLayout("En Birman")
      end
  end
end)
appwatcher:start()
