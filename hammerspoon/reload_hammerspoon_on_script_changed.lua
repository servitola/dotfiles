-- reload Hammerspoon config on .lua file changes (debounced)
local reloadTimer = hs.timer.delayed.new(0.5, hs.reload)

hammerspoonConfigReloader =
    hs.pathwatcher.new(
        "~/projects/dotfiles/hammerspoon",
        function(paths)
            for _, p in ipairs(paths) do
                if p:match("%.lua$") then
                    reloadTimer:start()
                    return
                end
            end
        end)

hammerspoonConfigReloader:start()
