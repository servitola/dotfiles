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
    "UnsplashZ",
}   

-- appM environment keybindings. Bundle `id` is prefered, but application `name` will be ok.
-- app_list = {
--     -- {key = 'b', id = 'com.apple.ActivityMonitor'},
--     -- {key = '.', id = 'com.apple.systempreferences'},
-- }

apps_list = {
    { modifier="caps_lock", chords={
        -- {supported=true, key="1", map="F1" },
        -- {supported=true, key="2", map="F2" },
        -- {supported=true, key="3", map="F3" },
        -- {supported=true, key="4", map="F4" },
        -- {supported=true, key="5", map="F5" },
        -- {supported=true, key="6", map="F6" },
        -- {supported=true, key="7", map="F7" },
        -- {supported=true, key="8", map="F8" },
        -- {supported=true, key="9", map="F9" },
        -- {supported=true, key="0", map="F10" },
        {supported=true, key="-", app_name="TeamViewer" },
        --{supported=false, key="=" },
        --{supported=true, key="q", map="page_up" },
        --{supported=true, key="w", map="up_arrow" },
        --{supported=true, key="e", map="page_down" },  
        {supported=true, key="r", app_name="Rider" },
        {supported=true, key="t", app_name="Telegram", color="#2194CE", window_default_position="right" },
        {supported=true, key="y", app_name="Yandex" },
        {supported=true, key="u", app_name="Folx", app_nameWin="uTorrent" },
        --{supported=true, key="i" },
        {supported=true, key="o", map="up_arrow" },
        {supported=true, key="p", app_name="Music", app_nameWin="iTunes", hint="Player"},
        --{supported=true, key="[", map="previous_track"},
        --{supported=true, key="]", map="next_track" },
        {supported=true, key="a", map="left_arrow" },
        {supported=true, key="s", map="bottom_arrow"},
        {supported=true, key="d", map="right_arrow" },
        -- set in app settings {supported=true, key="f", app_name="Alfred", app_nameWin="keypirinha", hint="Find"},
        {supported=true, key="g", app_name="Fork", hint="Git"},
        {supported=true, key="h", app_name="Finder", app_nameWin="File Explorer", hint="Hub" },
        {supported=true, key="j", app_name="Safari", hint="Job" },
        -- {supported=true, key="k", map="left_arrow" },
        -- {supported=true, key="l", map="bottom_arrow"},
        -- {supported=true, key=";", map="right_arrow" },
        {supported=true, key="z", app_name="Punto Switcher" },
        -- {supported=true, key="x", map="home" },
        -- {supported=true, key="c", map="end" },
        {supported=true, key="v", app_name="iTerm", app_nameWin="Terminal", hint="vi" },
        {supported=false, key="b", app_name="Ableton", hint="blues" },
        {supported=true, key="n", app_name="Visual Studio Code" },
        {supported=false, key="m", app_name="YouTube", hint="movies"},
        -- {supported=true, key="space", map="play_track" }
    }}, 
    { modifier="caps_lock_shift", chords={
        {supported=false, key="i", map="mouse_right_button" },
        {supported=false, key="o", map="mouse_up" },
        {supported=false, key="p", map="mouse_left_button" },
        --{supported=false, key="a", app_name="Android Studio" },
        --{supported=false, key="s", app_name="Simulator" },
        --{supported=false, key="d", app_name="Android Emulator", hint="droid" },
        --{supported=false, key="j", app_name="Zoom", hint="Job" },
        {supported=false, key="k", map="mouse_left" },
        {supported=false, key="l", map="mouse_down" },
        {supported=false, key=";", map="mouse_right" }
    }},
    { modifier="ctrl_alt", chords={
        {supported=true, key="left", specific_function="window.left"},
        {supported=true, key="right", specific_function="window.right"},
        {supported=true, key="up", specific_function="window.fullscreen"},
        {supported=true, key="down", specific_function="window.set_all_to_default"}
    }},
    { modifier="cmd_win", chords={
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
    }},
    { modifier="alt", chords={
        { }
    }}
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

-- Launch Hammerspoon Search
hsearch_keys = {"alt", "G"}

-- Read Hammerspoon and Spoons API manual in default browser
hsman_keys = {"alt", "H"}

-- countdownM environment keybinding: Visual countdown
hscountdM_keys = {"alt", "p"}

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


apps_list2 = {
    {key="\\"},
    {key="1", caps_lock="f1", alt="¹", cmd={inner_function="Show Main Panel"}},
    {key="2", caps_lock="f2", alt="²"},
    {key="3", caps_lock="f3", alt="³"},
    {key="4", caps_lock="f4", alt="$"},
    {key="5", caps_lock="f5", alt="‰"},
    {key="6", caps_lock="f6", alt="↑"},
    {key="7", caps_lock="f7"},
    {key="8", caps_lock="f8", alt="∞"},
    {key="9", caps_lock="f9", alt="←"},
    {key="0", caps_lock="f10", alt="→"},
    {key="-", alt="—"},
    {key="=", alt="≠"},
    {key="backspace", alt={ mac="remove_a_word_back"}, fn="delete"},
    {key="tab", cmd={inner_function="switch application"}, ctrl={inner_function="switch_tab"}, ctrl_shift={inner_function="switch_tab_back"}},
    {key="q", caps_lock="page_up", cmd={ inner_function="close_app", taps="2"}},
    {key="w", caps_lock="up", alt="✓", cmd={ inner_function="close_tab"}},
    {key="e", caps_lock="page_down", alt="€"},
    {key="r", caps_lock={ app_name="Rider"}, alt="®", cmd={ inner_function="replace"}},
    {key="t", caps_lock={ app_name="Telegram"}},
    {key="y", caps_lock={ app_name="Yandex"}, alt="ѣ"},
    {key="u", caps_lock={ app_name="Folx"}, alt="ѵ"},
    {key="i", caps_lock={ inner_function="Get info"}},
    {key="o", caps_lock="up", alt="ѳ"},
    {key="p", caps_lock={ app_name="Music"}},
    {key="[", caps_lock="next_track"},
    {key="]", caps_lock="previous_tack"},
    {key="caps_lock"},
    {key="a", caps_lock="left", alt="≈", cmd={ inner_function="select_all"}},
    {key="s", caps_lock="down", alt="§", cmd={ inner_function="save"}},
    {key="d", caps_lock="right", cmd={ inner_function="du[icate"}, alt={inner_function="show_desktop"}, ctrl={inner_function="run in debug"}},
    {key="f", caps_lock={ app_name="Alfred"}, alt="£", cmd={ inner_function="find"}},
    {key="g", caps_lock={ app_name="Fork"}, alt={{ app_name="Rider", inner_function="VCS Operations"}}},
    {key="h", caps_lock={ app_name="Finder"}, alt={{ app_name="Rider", inner_function="Show in Finder"}}, cmd={inner_function="hide_application"}, cmd_alt={inner_function="hide other applications"}},
    {key="j", caps_lock={ app_name="Safari"}, alt="„" },
    {key="k", caps_lock="left", alt='“'},
    {key="l", caps_lock="down", alt="”"},
    {key=";", caps_lock="right", alt="‘"},
    {key="'", caps_lock="volume_up"},
    {key="z", cmd={inner_function="undo"}, cmd_shift={inner_function="redo"}},
    {key="x", caps_lock="end", cmd={inner_function="cut"}},
    {key="c", caps_lock="home", cmd={ inner_function="copy"}},
    {key="v", caps_lock={ app_name="iTerm"}, cmd={ inner_function="paste"}},
    {key="b"},
    {key="n", caps_lock={app_name="Visual Studio Code"}},
    {key="m", caps_lock={app_name="YouTube"}, alt="−"},
    {key=",", cmd={inner_function="Go To Settings"}, alt="«"},
    {key=".", alt="»"},
    {key="/", caps_lock="volume_down", alt="…", cmd={ inner_function="comment one line"}},
    {key="left", alt={inner_function="jump word left"}, ctrl={inner_function="Mission Control: desktop to the left"}, cmd="home"},
    {key="up", alt={inner_function="expand_selection"}, ctrl={inner_function="Mission Control: show all windows"}},
    {key="right", alt={inner_function="jump word left"}, ctrl={inner_function="Mission Control: desktop to the right"}, cmd="end"},
    {key="down", alt={inner_function="decrease_selection"}, ctrl={inner_function="Mission Control: show current app windows"}},
    {key="ctrl"},
    {key="alt", tap="Punto Switcher"},
    {key="cmd"}
}