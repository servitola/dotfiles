-- Thin Hammerspoon → glasswings client. Spawns `glasswings-send`
-- (writes JSON to ~/.glasswings.sock) which renders a Tahoe Liquid Glass
-- banner via the resident Swift daemon.
--
-- The daemon lives in its own project — https://github.com/servitola/glasswings —
-- and is installed by the `servitola/tap/glasswings` cask (homebrew/brewfile): the app,
-- its LaunchAgent, and the CLI as a Homebrew binary artifact in /opt/homebrew/bin.
--
-- Usage:
--   local notify = require("notify")
--   notify.show({
--     title    = "Audio",
--     message  = "BE-RCA",
--     tint     = "green",
--     animate  = true,
--     layered  = true,
--     duration = 3,
--   })
--
-- Daemon down? `tail -f ~/Library/Logs/glasswings.log` and re-run install.

local M = {}

local GLASSWINGS_SEND = "/opt/homebrew/bin/glasswings-send"

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
    if opts.id          then payload.id          = opts.id end
    if opts.persistent ~= nil then payload.persistent = opts.persistent end  -- no auto-dismiss; the same id with persistent=false ends it
    if opts.symbolBefore      then payload.symbolBefore      = opts.symbolBefore end
    if opts.symbolBeforeColor then payload.symbolBeforeColor = opts.symbolBeforeColor end
    if opts.shape             then payload.shape             = opts.shape end
    if opts.layered ~= nil    then payload.layered           = opts.layered end

    local json = hs.json.encode(payload)
    hs.task.new(GLASSWINGS_SEND, nil, { json }):start()
end

function M.clear()
    hs.task.new(GLASSWINGS_SEND, nil, { '{"action":"clear"}' }):start()
end

return M
