hammerspoonConfigReloader = hs.pathwatcher.new("~/projects/dotfiles/hammerspoon", hs.reload)
hammerspoonConfigReloader:start() -- reload Hammerspoon config on change
