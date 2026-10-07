-- Add an app: put its bundle ID into the list that says where its windows go.
-- Bundle ID: osascript -e 'id of app "Telegram"'
return {
    -- Right column.
    side = {
        "ru.keepcoder.Telegram",
        "com.tdesktop.Telegram",
        "one.ayugram.AyuGramDesktop",
        "net.whatsapp.WhatsApp",
        "org.whispersystems.signal-desktop",
        "com.tinyspeck.slackmacgap",
        "com.hnc.Discord",
        "com.apple.MobileSMS",
        "com.microsoft.teams2",
        "im.riot.app",
        "com.viber.osx",
    },

    -- Corner of the right column, under `side`; proportions kept.
    players = {
        "com.colliderli.iina",
        "org.videolan.vlc",
    },

    -- Never moved automatically.
    leaveAlone = {
        "com.raycast.macos",
        "com.runningwithcrayons.Alfred",
        "theboringteam.boringnotch",
        "com.servitola.polaska",
    },

    -- The picture-in-picture window goes to the corner; the browser itself
    -- stays in the main area.
    chromiumBrowsers = {
        "com.google.Chrome",
        "com.vivaldi.Vivaldi",
        "com.microsoft.edgemac",
        "com.operasoftware.Opera",
        "com.brave.Browser",
        "company.thebrowser.Browser",
        "ru.yandex.desktop.yandex-browser",
    },
    geckoBrowsers = {
        "org.mozilla.firefox",
        "app.zen-browser.zen",
    },

    -- Everything the lists above cannot say: { bundle or "*", slot, fields },
    -- fields in docs/apps.md. Checked before the lists, top to bottom: the
    -- first match wins.
    special = {
        { "com.apple.Music",           "corner",
            title = "^Mini Player$", sample = "Mini Player" },
        { "com.sertacozercan.Kaset",   "corner",
            identifier = "youtubeContent.videoWindow", keepAspect = true,
            popup = true },
        { "com.apple.iphonesimulator", "stack",
            keepAspect = true, device = true },
        { "*",                         "stack",
            title = "^Android Emulator",
            sample = "Android Emulator - Pixel_8:5554" },
        { "com.apple.ActivityMonitor", "corner",
            title = "^CPU History$", sample = "CPU History" },
        { "com.apple.ActivityMonitor", "corner",
            title = "^GPU History$", sample = "GPU History" },
        { "com.apple.ActivityMonitor", "corner", maxSize = { 600, 400 } },
    },
}
