hs.hotkey.alertDuration = 0
hs.hints.showTitleThresh = 0
hs.window.animationDuration = 0

-- Specify Spoons which will be loaded
hspoon_list = {
    "Windows",
    "HotKeys",
    "AClock",
    --"BingDaily",
    "Calendar",
    "CircleClock",
    "ClipShow",
    "CountDown",
    "FnMate",
    --"HCalendar",
    "HSaria2",
    --"HSearch",
    --"KSheet",
    --"SpeedMenu",
    "TimeFlow",
    --"UnsplashZ",
}   

-- appM environment keybindings. Bundle `id` is prefered, but application `name` will be ok.
app_list = {
    {key = 'r', name = 'Rider'},
    {key = 't', name = 'Telegram'},
    {key = 'y', name = 'Yandex'},
    {key = 'u', name = 'Folx'},
    {key = 'p', name = 'Music'},
    {key = 'g', name = 'Fork'},
    {key = 'h', name = 'Finder'},
    {key = 'j', name = 'Safari'},
    {key = 'v', name = 'iTerm'},
    {key = 'n', name = 'Visual Studio Code'}
    -- {key = 'b', id = 'com.apple.ActivityMonitor'},
    -- {key = '.', id = 'com.apple.systempreferences'},
}

app_list2 = {
    caps_lock={
        {supported=true, key="1", map="F1" },
        {supported=true, key="2", map="F2" },
        {supported=true, key="3", map="F3" },
        {supported=true, key="4", map="F4" },
        {supported=true, key="5", map="F5" },
        {supported=true, key="6", map="F6" },
        {supported=true, key="7", map="F7" },
        {supported=true, key="8", map="F8" },
        {supported=true, key="9", map="F9" },
        {supported=true, key="0", map="F10" },
        {supported=false, key="-", app_name="TeamViewer" },
        {supported=true, key="q", map="page_up" },
        {supported=true, key="w", map="up_arrow" },
        {supported=true, key="e", map="page_down" },  
        {supported=true, key="r", app_name="Rider" },
        {supported=true, key="t", app_name="Telegram", color="#2194CE", window_default_position="right" },
        {supported=true, key="y", app_name="Yandex" },
        {supported=true, key="u", app_name="Folx", app_nameWin="uTorrent" },
        {supported=true, key="o", map="up_arrow" },
        {supported=true, key="p", app_name="Music", app_nameWin="iTunes", hint="Player"},
        {supported=true, key="[", map="previous_track"},
        {supported=true, key="]", map="next_track" },
        {supported=true, key="a", map="left_arrow" },
        {supported=true, key="s", map="bottom_arrow"},
        {supported=true, key="d", map="right_arrow" },
        {supported=true, key="f", app_name="Alfred", app_nameWin="keypirinha", hint="Find"},
        {supported=true, key="g", app_name="Fork", hint="Git"},
        {supported=true, key="h", app_name="Finder", app_nameWin="File Explorer", hint="Hub" },
        {supported=true, key="j", app_name="Safari", hint="Job" },
        {supported=true, key="k", map="left_arrow" },
        {supported=true, key="l", map="bottom_arrow"},
        {supported=true, key=";", map="right_arrow" },
        {supported=true, key="z", app_name="Punto Switcher" },
        {supported=true, key="x", map="home" },
        {supported=true, key="c", map="end" },
        {supported=true, key="v", app_name="iTerm", app_nameWin="Terminal", hint="vi" },
        {supported=false, key="b", app_name="Ableton", hint="blues" },
        {supported=true, key="n", app_name="Visual Studio Code" },
        {supported=false, key="m", app_name="YouTube", hint="movies"},
        {supported=true, key="space", map="play_track" }
       },
    caps_lock_shift={
        {supported=false, key="i", map="mouse_right_button" },
        {supported=false, key="o", map="mouse_up" },
        {supported=false, key="p", map="mouse_left_button" },
        {supported=false, key="a", app_name="Android Studio" },
        {supported=false, key="s", app_name="Simulator" },
        {supported=false, key="d", app_name="Android Emulator", hint="droid" },
        {supported=false, key="j", app_name="Zoom", hint="Job" },
        {supported=false, key="k", map="mouse_left" },
        {supported=false, key="l", map="mouse_down" },
        {supported=false, key=";", map="mouse_right" }
    },
    ctrl_alt={
        {supported=true, key="left_arrow", specific_function="window.left"},
        {supported=true, key="right_arrow", specific_function="window.right"},
        {supported=true, key="up_arrow", specific_function="window.fullscreen"},
        {supported=true, key="bottom_arrow", specific_function="window.set_all_to_default"}
    },
    cmd_win={
        {supported=true, key="q", specific_function="cmd.q", taps="2", hint="close app on double cmd+q"},
        {supported=true, key="w", specific_function="cmd.w"},
        {supported=true, key="t", specific_function="cmd.t"},
        {supported=true, key="h", specific_function="cmd.h"},
        {supported=true, key="c", specific_function="cmd.c"},
        {supported=true, key="v", specific_function="cmd.v"},
        {supported=true, key="x", specific_function="cmd.x"},
        {supported=true, key="z", specific_function="cmd.z"},
        {supported=true, key="s", specific_function="cmd.s"},
        {supported=true, key="n", specific_function="cmd.n"},
        {supported=true, key="d", specific_function="cmd.d"},
        {supported=true, key="o", specific_function="cmd.o"}
    }
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
