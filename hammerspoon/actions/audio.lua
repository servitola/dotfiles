return function(register)
    register("audio.internal", function() spoon.AudioSwitcher:switchToInternal() end)
    register("audio.external", function() spoon.AudioSwitcher:switchToExternal() end)
    register("audio.marshall", function() spoon.AudioSwitcher:switchToMarshall() end)
    register("audio.connect_marshall", function() spoon.AudioSwitcher:connectAndSwitchToMarshall() end)
    register("audio.bt", function() spoon.AudioSwitcher:connectAndSwitchToBT() end)
end
