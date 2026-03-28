-- Centralized application watcher hub
-- Single hs.application.watcher that dispatches to registered handlers
-- Prevents multiple watchers reacting to the same events

appWatcherHub = {
    _handlers = {},
    _log = hs.logger.new('appWatcherHub', 'info')
}

function appWatcherHub.register(handler)
    table.insert(appWatcherHub._handlers, handler)
end

appWatcherHub._watcher = hs.application.watcher.new(function(appName, eventType, appObject)
    for _, handler in ipairs(appWatcherHub._handlers) do
        local ok, err = pcall(handler, appName, eventType, appObject)
        if not ok then
            appWatcherHub._log.e("handler error: " .. tostring(err))
        end
    end
end)
appWatcherHub._watcher:start()
