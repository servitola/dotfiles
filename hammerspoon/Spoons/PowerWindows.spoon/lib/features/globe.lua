-- kVK_Function: Globe is down while its latest flagsChanged carries fn.
local GLOBE = 63

return function(powerWindows, settings)
    function powerWindows:_startGlobe()
        local byCode, needsGlobe = settings.macosKeys(
            self.config.macosKeys, settings.ACTIONS, hs.keycodes.map
        )
        if not byCode then return end
        local actionByCode = {}
        for code, action in pairs(byCode) do
            actionByCode[code] = function() self[action](self) end
        end
        local types = hs.eventtap.event.types
        local keyDown = types.keyDown
        local autorepeat = hs.eventtap.event.properties.keyboardEventAutorepeat
        local globeDown = false
        -- Sees every keystroke: the keyCode lookup comes before anything that
        -- allocates.
        self._globeTap = hs.eventtap.new({
            keyDown, types.flagsChanged,
        }, function(event)
            local code = event:getKeyCode()
            if code == GLOBE then
                globeDown = event:getFlags().fn == true
                return false
            end
            if not actionByCode[code] or event:getType() ~= keyDown then
                return false
            end
            local flags = event:getFlags()
            if not (flags.fn and flags.ctrl)
                or flags.cmd or flags.alt or flags.shift then
                return false
            end
            if needsGlobe[code] and not globeDown then return false end
            if event:getProperty(autorepeat) == 0 then
                -- Off the tap callback: a slow AX call there gets the tap
                -- disabled by timeout.
                self:_after(0, actionByCode[code], "globe")
            end
            return true
        end):start()
    end

    function powerWindows:_stopGlobe()
        if self._globeTap then
            self._globeTap:stop()
            self._globeTap = nil
        end
        self:_cancel("globe")
    end
end
