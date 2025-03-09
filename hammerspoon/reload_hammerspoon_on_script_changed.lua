hammerspoonConfigReloader =
    hs.pathwatcher.new(
        "~/projects/dotfiles/hammerspoon",
        hs.reload)

-- reload Hammerspoon config on change
hammerspoonConfigReloader:start()
