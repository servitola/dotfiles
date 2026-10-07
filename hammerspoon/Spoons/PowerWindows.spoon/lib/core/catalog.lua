local CHROMIUM_PLAYER = {
    title = "^Picture in Picture$", sample = "Picture in Picture",
}
local GECKO_PLAYER = {
    title = "^Picture%-in%-Picture$", sample = "Picture-in-Picture",
}
-- Gecko browser.xhtml key_togglePictureInPicture;
-- Chromium has no default PiP chord.
local GECKO_PLAYER_CHORD = { mods = { "cmd", "alt", "shift" }, key = "]" }

local function pictureInPicture(bundle, player)
    return {
        bundle, "corner", title = player.title, sample = player.sample,
        keepAspect = true, popup = true,
    }
end

return function(lists)
    local catalog = { apps = {}, pictureInPictureChords = {} }
    local function add(entry) catalog.apps[#catalog.apps + 1] = entry end

    -- First match wins: entries told by title or size go before the plain ones.
    for _, entry in ipairs(lists.special) do add(entry) end
    for _, bundle in ipairs(lists.chromiumBrowsers) do
        add(pictureInPicture(bundle, CHROMIUM_PLAYER))
    end
    for _, bundle in ipairs(lists.geckoBrowsers) do
        add(pictureInPicture(bundle, GECKO_PLAYER))
        catalog.pictureInPictureChords[bundle] = GECKO_PLAYER_CHORD
    end
    for _, bundle in ipairs(lists.side) do add({ bundle, "side" }) end
    for _, bundle in ipairs(lists.players) do
        add({ bundle, "corner", keepAspect = true })
    end
    for _, bundle in ipairs(lists.leaveAlone) do add({ bundle, false }) end

    function catalog.popupBundles()
        local set = {}
        for _, entry in ipairs(catalog.apps) do
            if entry.popup then set[entry[1]] = true end
        end
        return set
    end

    return catalog
end
