return function(powerWindows, actions)
    local boundDefaults, boundByUser = {}, {}

    --- PowerWindows:defaultHotkeys() -> table
    --- Method
    --- The `{ action = { {mods, key}, ... } }` mapping `start()` binds from
    --- `config.keys`.
    function powerWindows:defaultHotkeys()
        local mapping = {}
        local function add(chords, mods)
            for action, key in pairs(chords) do
                mapping[action] = mapping[action] or {}
                table.insert(mapping[action], { mods, key })
            end
        end
        local keys = self.config.keys
        add(keys.arrows, keys.mods)
        add(keys.shiftedArrows, keys.shiftMods)
        if self.config.wasd then
            add(keys.letters, keys.mods)
            add(keys.shiftedLetters, keys.shiftMods)
        end
        return mapping
    end

    local function bind(self, mapping, into)
        for action, chordOrChords in pairs(mapping) do
            assert(
                actions[action],
                "PowerWindows: unknown action " .. tostring(action)
            )
            local chords = type(chordOrChords[2]) == "string"
                and { chordOrChords } or chordOrChords
            for _, chord in ipairs(chords) do
                table.insert(into, hs.hotkey.bind(
                    chord[1], chord[2], function() self[action](self) end
                ))
            end
        end
    end

    --- PowerWindows:bindHotkeys(mapping) -> self
    --- Method
    --- Binds `{ action = {mods, key} }` or a list of chords per action;
    --- `stop()` pauses them, `start()` resumes.
    function powerWindows:bindHotkeys(mapping)
        bind(self, mapping, boundByUser)
        return self
    end

    function powerWindows:_startHotkeys()
        if self.config.hotkeys then
            bind(self, self:defaultHotkeys(), boundDefaults)
        end
        for _, hotkey in ipairs(boundByUser) do hotkey:enable() end
    end

    function powerWindows:_stopHotkeys()
        for _, hotkey in ipairs(boundDefaults) do hotkey:delete() end
        boundDefaults = {}
        for _, hotkey in ipairs(boundByUser) do hotkey:disable() end
    end
end
