-- Specify Spoons which will be loaded
hspoon_list = {
    "Windows",
    "AClock",
    "BingDaily",
    "Calendar",
    "CircleClock",
    "ClipShow",
    "CountDown",
    "FnMate",
    --"HCalendar",
    "HSaria2",
    --"HSearch",
    "KSheet",
    "SpeedMenu",
    "TimeFlow",
    "UnsplashZ"
}

-- appM environment keybindings. Bundle `id` is prefered, but application `name` will be ok.
hsapp_list = {
    {key = 'r', name = 'Rider'},
    {key = 't', name = 'Telegram'},
    {key = 'y', name = 'Yandex'},
    {key = 'u', name = 'Folx'},
    {key = 'p', name = 'Music'},
    {key = 'g', name = 'Fork'},
    {key = 'h', name = 'Finder'},
    {key = 'j', name = 'Safari'},
    {key = 'v', name = 'iTerm'},
    {key = 'n', name = 'Visual Studio Code'},
    {key = 'b', id = 'com.apple.ActivityMonitor'},
    {key = '.', id = 'com.apple.systempreferences'},
}

-- Modal supervisor keybinding, which can be used to temporarily disable ALL modal environments.
hsupervisor_keys = {{"cmd", "shift", "ctrl"}, "Q"}

-- Reload Hammerspoon configuration
hsreload_keys = {{"cmd", "shift", "ctrl"}, "R"}

-- Toggle help panel of this configuration.
hshelp_keys = {{"alt", "shift"}, "/"}

----------------------------------------------------------------------------------------------------
-- Those keybindings below could be disabled by setting to {"", ""} or {{}, ""}

-- Window hints keybinding: Focuse to any window you want
hswhints_keys = {"alt", "tab"}

-- appM environment keybinding: Application Launcher
hsappM_keys = {"alt", "A"}

-- clipshowM environment keybinding: System clipboard reader
hsclipsM_keys = {"alt", "C"}

-- Toggle the display of aria2 frontend
hsaria2_keys = {"", ""} --{"alt", "D"}

-- Launch Hammerspoon Search
hsearch_keys = {"alt", "G"}

-- Read Hammerspoon and Spoons API manual in default browser
hsman_keys = {"alt", "H"}

-- countdownM environment keybinding: Visual countdown
hscountdM_keys = {"alt", "I"}

-- Lock computer's screen
hslock_keys = {"alt", "L"}

-- resizeM environment keybinding: Windows manipulation
hsresizeM_keys = {"alt", "R"}

-- cheatsheetM environment keybinding: Cheatsheet copycat
hscheats_keys = {"ctrl", "S"}

-- Show digital clock above all windows
hsaclock_keys = {"alt", "T"}

-- Type the URL and title of the frontmost web page open in Google Chrome or Safari.
hstype_keys = {"alt", "V"}

-- Toggle Hammerspoon console
hsconsole_keys = {"alt", "Z"}
