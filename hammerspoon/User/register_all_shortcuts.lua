hyper = {"right_command", "right_control", "right_option", "right_shift"}

apps_list = {
    { modifier=left_shift, chords={
        --/*/-----__SHIFT_LAYER___-------------------------------------------------------------------.
        --* |  ~  |  !  |  @  |  #  |  $  |  %  |  ^  |  &  |  *  |  (  |  )  |  _  |  +  |          |
        --* |----------------------------------------------------------------------------------------+
        --* |        |  Q  |  W  |  E  |  R  |  T  |  Y  |  U  |  I  |  O  |  P  |  {  |  }  |   |   |
        --* |----------------------------------------------------------------------------------------+
        --* | Hyper |  A  |  S  |  D  |  F  |  G  |  H  |  J  |  K  |  L  |  :  |  "  |              |
        --* |----------------------------------------------------------------------------------------+
        --* | TO_PRESS |  X  |  C  |  V  |  B  |  N  |  M  |  <  |  >  |  ?  |       macos           |
        --* |----------------------------------------------------------------------------------------+
        --* |      |       |       |                               |       | macos | macos | macos   |
        --* \----------------------------------------------------------------------------------------/
        -- tab - app - move block left
        -- left - select letter to the left
        -- right - select letter to the right
        -- up - move caret up and select text from the initial position
        -- down - move caret down and select text from the initial position
    }},
    { modifier={"alt"}, chords={
        --/*/-----__ALT_LAYER___----------------------------------------------------------------------.
        --* |     |  ¡  |  ™  |  £  |  ¢  |  ∞  |  §  |  ¶  |  •  |  ª  |  º  |  –  |   ≠  |          |
        --* |-----------------------------------------------------------------------------------------+
        --* |    |  œ  |  ∑  |  ´  | Simulators |  †  |  ¥  |  ¨  | hotkeys |  ø  | π | “ | ‘ | Rider |
        --* |-----------------------------------------------------------------------------------------+
        --* | Hyper |    |     | macos | macos |  ©  | ˙ |  ∆  |  ˚  |  ¬  |  …  |  æ  |              |
        --* |-----------------------------------------------------------------------------------------+
        --* |          |    |  ≈  |  ©  | Ableton  |  ∫  |  ˜  |  µ  |  ≤  |  ≥  |  ÷  |    macos     |
        --* |-----------------------------------------------------------------------------------------+
        --* |      | TO_PRESS  |       |                               |       | macos | macos | macos|
        --* \-----------------------------------------------------------------------------------------/
        --{ key="w", send_key={ modifier={ ""}}},
        -- { key="i", specific_function="info.show_shortcuts"},
        -- macos d - Show desktop
        -- Rider | - GitHub Copilot - show suggestion
        -- macos f - Open LaunchPad
        -- { key="c", sendKey="©" },
        -- up 
        -- left - jump a word to the left
        -- down
        -- right - jump a word to the right
    }},
    { modifier=left_command, chords={
        --/*/-----__CMD_LAYER___----------------------------------------------------------------------------------.
        --* |     |  Rider  |  Rider  |  Rider  | Rider  |   |    |    |    |    |    |    |     |  Rider         |
        --* |-----------------------------------------------------------------------------------------------------+
        --* |      |  macos  |  Rider  |  Rider  |  Rider |     |    |    |    |    |    | Rider | Rider  | Rider |
        --* |-----------------------------------------------------------------------------------------------------+
        --* |        |  macos  |  macos  |  Rider  |  Rider  | Rider   | macos   |    |    |    |    |    |       |
        --* |-----------------------------------------------------------------------------------------------------+
        --* |         |  macos | macos | macos |macos | Rider |    |  macos  | macos |    | Rider |               |
        --* |-----------------------------------------------------------------------------------------------------+
        --* |      |       |       |       Rider                        |           |  macos  |       |  macos    |
        --* \-----------------------------------------------------------------------------------------------------/
        -- ` -
        -- 1 - Rider - focus solution explorer
        -- 2 - Rider - focus debug window
        -- 3 - Rider - focus unit tests explorer
        -- 4 - Rider - focus build window
        -- 5 - 
        -- 6 -
        -- 7 -
        -- 8 -
        -- 9 -
        -- 0 - app - Reset zoom
        -- - - app - Zoom out
        -- + - app - Zoom in
        -- delete - Rider - delete line
        -- q - macos - close current app
        -- w - app - close current tab
        -- e - Rider - recent files dialog
        -- r - Rider - replace in current file
        -- t - app - new tab
        -- y - app - show all history
        -- u - 
        -- i - 
        -- o - app - open file
        -- p - app - print
        -- [ - Rider - navigate back
        -- ] - Rider - navigate forward
        -- a - macos - select all
        -- s - app - save
        -- d - Rider - duplicate line
        -- f - app - find (in current file)
        -- g - Rider - git operations popup
        -- h - macos - hide current app
        -- j - 
        -- k -
        -- l -
        -- ; - 
        -- ' -
        -- z - macos - undo
        -- x - macos - cut text
        -- c - macos - copy text
        -- v - macos - paste text
        -- b - Rider - go to declaration
        -- n - app - new window
        -- m - macos - minimize window
        -- , - macos - show settings of current app
        -- . -
        -- Rider / - comment line
        -- Rider space - Basic code completion
    }},
    { modifier=left_control, chords={
        --/*/-----__CONTROL_LAYER___-------------------------------------------------------------------.
        --* |     |  Rider  |       |      |    |    |    |    |    |    |    |    |     |             |
        --* |------------------------------------------------------------------------------------------+
        --* | Rider  |  Rider |  Rider  | Rider |  Rider  |   |    |   |    | Rider |    |    |    |   |
        --* |------------------------------------------------------------------------------------------+
        --* | Hyper   |  Rider  |  Rider  |  Rider  |  Rider  | Rider  |    |    |    |    |    |   |  |
        --* |------------------------------------------------------------------------------------------+
        --* | Rider   |      |       |      |       |      |    |    |     |    |    |                 |
        --* |------------------------------------------------------------------------------------------+
        --* | TO_PRESS |       |       |       macos                        |       |      |      |    |
        --* \------------------------------------------------------------------------------------------/
        -- tab - app - switch tab forward
        -- q -- Rider - Stop all
        -- w - Rider - close all notifications
        -- e - Rider - Find Usages
        -- r - Rider - Run
        -- o - Rider - Override
        -- a - Rider - Git Annotate
        -- s - Rider - Save with format
        -- d - Rider - Debug
        -- f - Rider - Focus Find Window
        -- g - Rider - Fofus Git Window
        -- Rider shift + tab - switch tab backward
        -- macos space - change language
    }},
    { modifier=hyper, chords={  
        --/*/-----__HYPER_LAYER___------------------------------------------------------------------------------------------.
        --* |     |  F1  |   F2    |  F3   | F4   | F5   | F6    | F7   | F8   | F9 |  F10   | F11    |  F12  | backspace   |
        --* |---------------------------------------------------------------------------------------------------------------+
        --* |    | pageup | up | pagedown | Rider | Telegram | DroidStudio | Transmission |   | up | Music | prtrack | nxttrack |  |
        --* |---------------------------------------------------------------------------------------------------------------+
        --* | TO_PRESS |  left  |  down  | right  | Raycast  | Fork | Finder | Safari  | left | down | right | volume_up |   |
        --* |--------------------------------------------------------------------------------------------------------------+
        --* |      |  toRus  |  home   | end  |  Firefox | iTerm2  | VSCode | ElMedia  | home | end |  volume_down  |      |
        --* |--------------------------------------------------------------------------------------------------------------+
        --* |      |       |       |         play/stop                |       |       |       |                             |
        --* \--------------------------------------------------------------------------------------------------------------/
        -- karabiner escape - tilda/ё
        -- 1 - F1
        -- 2 - F2
        -- 3 - F3
        -- 4 - F4
        -- 5 - F5
        -- 6 - F6
        -- 7 - F7
        -- 8 - F8
        -- 9 - F9
        -- 0 - F10
        -- - - F11
        -- = - F12
        -- backspace - delete
        -- tab TODO:
        -- q - pageUp
        -- w - up
        -- e - pagedown
        { key="r", app="Rider" },
        { key="t", app="Telegram", window_default_position="right" },
        { key="y", app="Android Studio"},
        { key="u", app="Transmission" },
        -- o - up
        { key="p", app="Music" },
        -- [ - previous track
        -- ] - next track
        { key="\\", app="Ableton Live 11 Suite"},
        -- a - left
        -- s - down
        -- d - right
        -- f - RayCast
        { key="g", app="Fork" },
        { key="h", app="Finder" },
        { key="j", app="Safari" },
        -- k - left
        -- l - down
        -- ; - right
        -- ' - volume up
        -- return
        { key="z", specific_function="set_russian_language"},
        -- x - home
        -- c - end
        { key="v", app="Firefox" },
        { key="b", app="iTerm" },
        { key="n", app="Visual Studio Code" },
        { key="m", app="Elmedia Player" },
        -- , - home
        -- . - end
        -- / - volume down
        { key="left", specific_function="window.left"},
        { key="right", specific_function="window.right"},
        { key="up", specific_function="window.fullscreen"},
        { key="down", specific_function="window.set_all_to_default"},
    }}, 
    { modifier={"left_command", "left_shift"}, chords={
        --/*/-----__CONTROL_LAYER___-----------------------------------------------------------------.
        --* |     |       |       |      |    |    |    |    |    |    |    |    |     |   Rider      |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |  macos |  Rider  | Rider |  Rider  | Rider |    |   |    |    |    |    |    |     |
        --* |-----------------------------------------------------------------------------------------+
        --* |        |      |      |      |  Rider  | Rider  |    |    |    |    |    |    |   |
        --* |-----------------------------------------------------------------------------------------+
        --* |          | macos |       |      |       |      |    |    |     |    | Rider  |               |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |       |       |       macos                        |       |       |       |     |
        --* \-----------------------------------------------------------------------------------------/
        -- ` -
        -- 1 - 
        -- 2 -
        -- 3 -
        -- 4 -
        -- 5 -
        -- 6 -
        -- 7 -
        -- 8 -
        -- 9 -
        -- 0 -
        -- - -
        -- + -
        -- delete - Rider -go to last edit location
        -- q - macos - quit all applications
        -- w - macos - close window
        -- e - Rider - recent locations popup
        -- r - Rider - replace in files
        -- t - macos - reopen closed tab
        -- y -
        -- u -
        -- i -
        -- o -
        -- p -
        -- [ -
        -- ] -
        -- \ -
        -- a -
        -- s -
        -- d -
        -- f - Rider - search in files
        -- g -
        -- h -
        -- j -
        -- k -
        -- l -
        -- ; -
        -- ' - 
        -- z - macos - redo
        -- x - 
        -- c -
        -- v -
        -- b -
        -- n -
        -- m -
        -- , -
        -- . -
        -- / - Rider - comment
    }},  
    { modifier={"left_command", "alt"}, chords={
        --/*/-----__CONTROL_LAYER___-----------------------------------------------------------------.
        --* |     |     |       |      |    |    |    |    |    |    |    |    |     |            |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |     |    |  |    |   |    |   |    |    |    |    |    |     |
        --* |-----------------------------------------------------------------------------------------+
        --* |        |    |    |    | Rider |   | macos   |    |    |    |    |    |   |
        --* |-----------------------------------------------------------------------------------------+
        --* |          |      |       |      | Rider |      | Rider | Rider   |     |    |    |               |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |       |       |                               |       |       |       |     |
        --* \-----------------------------------------------------------------------------------------/
        -- f - Rider - extract field
        -- h - macos - hide all other windows
        -- v - Rider - extract variable
        -- n - Rider - inline
        -- m - Rider - extract method
    }},
    { modifier={"left_command", "left_control"}, chords={
        --/*/-----__CONTROL_LAYER___-----------------------------------------------------------------.
        --* |     |     |       |      |    |    |    |    |    |    |    |    |     |            |
        --* |-----------------------------------------------------------------------------------------+
        --* |    |  macos |     |     |    |   |    |   |    |    |    |    |    |     |
        --* |-----------------------------------------------------------------------------------------+
        --* |        |      |      |       | macos |      |    |    |    |    |    |    |   |
        --* |-----------------------------------------------------------------------------------------+
        --* |          |      |       |      |       |      |    |    |     |    |    |               |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |       |       |                                |       |       |       |     |
        --* \-----------------------------------------------------------------------------------------/
        -- mac q - logout
        -- mac f - toggle fullscreen of current app 
    }},
    { modifier= {"left_control", "left_shift"}, chords={
        --/*/-----__CONTROL_LAYER___-----------------------------------------------------------------.
        --* |     |  Rider  |       |      |    |    |    |    |    |    |    |    |     |            |
        --* |-----------------------------------------------------------------------------------------+
        --* | Rider  |  Rider |  Rider  | Rider |  Rider  |   |    |   |    |    |    |    |    |     |
        --* |-----------------------------------------------------------------------------------------+
        --* |        |  Rider  |  Rider  |  Rider  |  Rider  | Rider  |    |    |    |    |    |    |   |
        --* |-----------------------------------------------------------------------------------------+
        --* |          |      |       |      |       |      |    |    |     |    |    |               |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |       |       |       macos                        |       |       |       |     |
        --* \-----------------------------------------------------------------------------------------/
        { key="escape", app="Activity Monitor" },
        -- p - app - open private window
        -- g - Rider - current file git history
        -- { key="i", map="mouse_right_button" },
        -- { key="o", map="mouse_up" },
        -- { key="p", map="mouse_left_button" },
        -- { key="s", app="Simulator" },
        -- { key="d", app="Android Emulator" },
        -- { key="k", map="mouse_left" },
        -- { key="l", map="mouse_down" },
        -- { key=";", map="mouse_right" }
    }},
    { modifier={"left_control", "alt"}, chords={
        --/*/-----__CONTROL_LAYER___-----------------------------------------------------------------.
        --* |     |     |       |      |    |    |    |    |    |    |    |    |     |            |
        --* |-----------------------------------------------------------------------------------------+
        --* |    |   |      |      |      |     |   |     |    |    |    |    |    |     |
        --* |-----------------------------------------------------------------------------------------+
        --* |        |    |  |  Rider  |  Rider  | Rider  | Hammerspoon |    |    |    |    |    |   |
        --* |-----------------------------------------------------------------------------------------+
        --* |          |      | XCode |      |       |      |    |    |     |    |    |               |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |       |       |       macos                        |       |       |       |     |
        --* \-----------------------------------------------------------------------------------------/
        { key="left", specific_function="window.left"},
        { key="right", specific_function="window.right"},
        { key="up", specific_function="window.fullscreen"},
        { key="down", specific_function="window.set_all_to_default"},
        { key="h", app="Hammerspoon"},
        { key="x", app="XCode"},
        { key="i", specific_function="info.show_shortcuts"},
        -- macos d - Show desktop
        -- Rider | - GitHub Copilot - show suggestion
        -- macos f - Open LaunchPad
        --{ key="c", sendKey="©" },
        { key="a", app="Ableton Live 11 Suite"},
        { key="s", specific_function="android.show_all" }
        -- itsical c - Show Calendar
    }},
    { modifier={"left_control", "left_shift"}, chords={
        --/*/-----__CONTROL+SHIFT_LAYER___-----------------------------------------------------------------.
        --* |     |     |       |      |    |    |    |    |    |    |    |    |     |            |
        --* |-----------------------------------------------------------------------------------------+
        --* |    |   |      |      |      |     |   |     |    |    |    |    |    |     |
        --* |-----------------------------------------------------------------------------------------+
        --* |        |    |  |    |    |   |  |    |    |    |    |    |   |
        --* |-----------------------------------------------------------------------------------------+
        --* |          |      |  |      |       |      |    |    |     |    |    |               |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |       |       |                               |       |       |       |     |
        --* \-----------------------------------------------------------------------------------------/
        
    }},
    { modifier={"alt", "left_shift"}, chords={
        --/*/-----__CONTROL_LAYER___------------------------------------------------------------------.
        --* |     |       |       |      |    |    |    |    |    |    |    |    |     |              |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |      |       |    |      |   |    |   |    |    |    |    |    |                 |
        --* |-----------------------------------------------------------------------------------------+
        --* |        |       |      |      |      |     |    |    |    |    |    |    |               |
        --* |-----------------------------------------------------------------------------------------+
        --* |          |      |       |      |       |      |    |    |     |    |    |               |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |       |       |                                 |       |       |       |        |
        --* \-----------------------------------------------------------------------------------------/
        -- ` - `
        -- 1 - ⁄
        -- 2 - €
        -- 3 - ‹
        -- 4 - ›
        -- 5 - ﬁ
        -- 6 - ﬂ
        -- 7 - ‡
        -- 8 - °
        -- 9 - ·
        -- 0 - ‚
        -- - - —
        -- = - ±
        -- q - Œ
        -- w - „
        -- e - ´
        -- r - ‰
        -- t - ˇ
        -- y - Á
        -- u - ¨
        -- i - 
        -- o - Ø
        -- p - ∏
        -- [ - ”
        -- ] - ’
        -- a - Å
        -- s - Í
        -- d - 
        -- f - 
        -- g - ˝
        -- h - Ó
        -- j - Ô
        -- k - 
        -- l - Ò
        -- ; - Ú
        -- ' - Æ
        -- z - ¸
        -- x - ˛
        -- c - Ç
        -- v - ◊
        -- b - ı
        -- n - ˜
        -- m - Â
        -- , - ¯
        -- . - ˘
        -- / - ¿
    }},
 }

hideKSheetShortCut = hs.hotkey.new({}, "escape", function()
    spoon.KSheet:hide()
    ksheet = not ksheet
    hideKSheetShortCut:disable();
end)

for _, row in pairs(apps_list) do
    for _, chord_row in pairs(row.chords) do
        if chord_row.app then
            hs.hotkey.bind(row.modifier, chord_row.key, function()
                local app = hs.application.find(chord_row.app)
                if not app or app:isHidden() then
                    hs.application.launchOrFocus(chord_row.app)
                elseif hs.application.frontmostApplication() ~= app then
                    app:activate()
                else
                    app:hide()
                end
            end)
        elseif chord_row.sendKey then
            hs.hotkey.bind(row.modifier, chord_row.key, function()
                hs.eventtap.keyStrokes(chord_row.sendKey)
            end)
        elseif chord_row.specific_function then
            if chord_row.specific_function == "window.left" then
                spoon.Windows:bind_window_left(row.modifier, chord_row.key)
            elseif chord_row.specific_function == "window.right" then
                spoon.Windows:bind_window_right(row.modifier, chord_row.key)
            elseif chord_row.specific_function == "window.fullscreen" then
                spoon.Windows:bind_window_fullscreen(row.modifier, chord_row.key)
            elseif chord_row.specific_function == "window.set_all_to_default" then
                spoon.Windows:bind_all_windows_to_default(row.modifier, chord_row.key)
            elseif chord_row.specific_function == "android.show_all" then
                hs.hotkey.bind(row.modifier, chord_row.key, function()
                    local wins = hs.window.visibleWindows()
                    for _, window in ipairs(wins) do
                        local window_title = window:title()
                        local app_title = window:application():title()
                        if app_title == "qemu-system-x86_64" or string.find(window_title, "Android Emulator") then
                            window:focus()
                        end
                    end
                end)
            elseif chord_row.specific_function == "info.show_shortcuts" then
                hs.hotkey.bind(row.modifier, chord_row.key, function()
                    if ksheet then
                        spoon.KSheet:hide()
                    else
                        hideKSheetShortCut:enable();
                        spoon.KSheet:show()
                    end

                    ksheet = not ksheet
                end)
            elseif chord_row.specific_function == "set_russian_language" then
                hs.hotkey.bind(row.modifier, chord_row.key, function()
                    hs.keycodes.setLayout(hs.keycodes.layouts()[2])
                end)
            end
        end
    end
end

