-- Centralized application watcher hub
-- Single hs.application.watcher that dispatches to registered handlers
-- Prevents multiple watchers reacting to the same events

appWatcherHub = {
    _handlers = {}
}

function appWatcherHub.register(handler)
    table.insert(appWatcherHub._handlers, handler)
end

appWatcherHub._watcher = hs.application.watcher.new(function(appName, eventType, appObject)
    for _, handler in ipairs(appWatcherHub._handlers) do
        handler(appName, eventType, appObject)
    end
end)
appWatcherHub._watcher:start()
