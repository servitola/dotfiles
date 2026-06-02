local notify = require("notify")

-- All audio banners share the same id so rapid device switches morph the
-- single banner in place instead of piling new ones on top of each other.
local AUDIO_BANNER_ID = "audio-state"

function switchToAudioDevice(deviceName, displayName)
    -- Legacy plain entry point — used by the audio watcher.
    local device = findAudioDevice(deviceName)
    if device then
        device:setDefaultOutputDevice()
        notify.show({
            id       = AUDIO_BANNER_ID,
            title    = displayName or device:name(),
            tint     = "green",
            duration = 2,
        })
    else
        notify.show({
            id       = AUDIO_BANNER_ID,
            title    = "⚠️ " .. (displayName or deviceName) .. " not found",
            tint     = "red",
            duration = 4,
        })
    end
end

-- Preset variant — used by the hotkey switchers. The user sees only the
-- friendly preset title + subtitle; the raw device name (BE-RCA etc) is
-- never surfaced.
function switchToAudioDevicePreset(deviceName, preset)
    local device = findAudioDevice(deviceName)
    if device then
        device:setDefaultOutputDevice()
        notify.show({
            id          = AUDIO_BANNER_ID,
            title       = preset.title,
            message     = preset.subtitle,
            symbol      = preset.symbol,
            symbolColor = preset.symbolColor,
            tint        = preset.tint,
            animate     = true,
            duration    = 2,
        })
    else
        notify.show({
            id          = AUDIO_BANNER_ID,
            title       = "⚠️ " .. preset.title .. " not found",
            message     = preset.subtitle,
            tint        = "red",
            duration    = 4,
        })
    end
end
