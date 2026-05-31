-- Thin Hammerspoon → NotifyDaemon client. Spawns the `notify-send` helper
-- (writes JSON to ~/.notifyd.sock) which renders a Tahoe Liquid Glass
-- banner via the resident Swift daemon.
--
-- Usage:
--   local notify = require("notify")
--   notify.show({
--     title    = "🔊 Audio System",
--     message  = "BE-RCA",
--     icon     = os.getenv("HOME") .. "/projects/dotfiles/hammerspoon/icons/speakers.png",
--     tint     = "green",     -- name ("green"/"red"/...) or "#rrggbb"
--     duration = 3,           -- seconds; daemon default = 3
--     sound    = "Glass",     -- macOS system sound name; optional
--   })
--
-- Daemon down? Check ~/Library/Logs/notifyd.log and rebuild via
-- ~/projects/dotfiles/notifier/build-daemon.sh

local M = {}

local NOTIFY_SEND = os.getenv("HOME") .. "/projects/dotfiles/notifier/notify-send"

function M.show(opts)
    opts = opts or {}
    local payload = { action = "show" }
    if opts.title       then payload.title       = opts.title end
    if opts.message     then payload.body        = opts.message end
    if opts.icon        then payload.icon        = opts.icon end
    if opts.tint        then payload.tint        = opts.tint end
    if opts.sound       then payload.sound       = opts.sound end
    if opts.duration    then payload.duration    = opts.duration end
    if opts.symbol      then payload.symbol      = opts.symbol end
    if opts.symbolColor then payload.symbolColor = opts.symbolColor end
    if opts.animate ~= nil then payload.animate  = opts.animate end

    local json = hs.json.encode(payload)
    hs.task.new(NOTIFY_SEND, nil, { json }):start()
end

function M.clear()
    hs.task.new(NOTIFY_SEND, nil, { '{"action":"clear"}' }):start()
end

return M
