hammerspoonConfigReloader = hs.pathwatcher.new(hs.configdir, hs.reload)
hammerspoonConfigReloader:start() -- reload Hammerspoon config on change
