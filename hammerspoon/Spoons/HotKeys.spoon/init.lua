local obj={}

hyper = { "right_command", "right_control", "right_option", "right_shift" }

apps_list = {
    -- {
        -- /------__MAIN_LAYER_EN__----------------------------------------------------------------\
        -- |  `  |  1  |  2  |  3  |  4  |  5  |  6  |  7  |  8  |  9  |  0  |  -  |  =  | BCKSPC  |
        -- |---------------------------------------------------------------------------------------+
        -- | TAB    |  q  |  w  |  e  |  r  |  t  |  y  |  u  |  i  |  o  |  p  |  [  |  ]  |      |
        -- |--------------------------------------------------------------------------------|  RET |
        -- | HYPER |  a  |  s  |  d  |  f  |  g  |  h  |  j  |  k  |  l  |  ;  |  '  |      |      |
        -- |---------------------------------------------------------------------------------------+
        -- | SHIFT  |  z  |  x  |  c  |  b  |  n  |  m  |  ,  |  .  |  /  |       SHIFT            |
        -- |---------------------------------------------------------------------------------------+
        -- | CTRL  |  ALT   | CMD  |              SPACE            |       |       |  ALT  |       |
        -- \---------------------------------------------------------------------------------------/
    -- },
    -- {
        -- /------__MAIN_LAYER_RU__----------------------------------------------------------------\
        -- |  ё  |     |     |     |     |     |     |     |     |     |     |     |     |         |
        -- |---------------------------------------------------------------------------------------+
        -- |        |  й  |  ц  |  у  |  к  |  е  |  н  |  г  |  ш  |  щ  |  з  |  х  |  ъ  |      |
        -- |--------------------------------------------------------------------------------|      |
        -- |       |  ф  |  ы  |  в  |  а  |  п  |  р  |  о  |  л  |  д  |  ж  |  э  |      |      |
        -- |---------------------------------------------------------------------------------------+
        -- |        |  я  |   ч  |  с  |  м  |  и  |  т  |  ь  |  б  |  ю  |  .  |                 |
        -- |---------------------------------------------------------------------------------------+
        -- |       |        |      |                               |       |       |       |       |
        -- \---------------------------------------------------------------------------------------/
    -- },
    -- {
        -- /------__MAIN_LAYER_GR_-----------------------------------------------------------------\
        -- |  §  |     |     |     |     |     |     |     |     |     |     |     |     |         |
        -- |---------------------------------------------------------------------------------------+
        -- |        |  ;  |  ς  |  ε  |  ρ  |  τ  |  υ  |  θ  |  ι  |  ο  |  π  |  [  |  ]  |      |
        -- |---------------------------------------------------------------------------------------+
        -- |       |  α  |  σ  |  δ  |  φ  |  γ  |  η  |  ξ  |  κ  |  λ  |  ΄  |  '  |  \   \      |
        -- |---------------------------------------------------------------------------------------+
        -- |        |  я  |   ч  |  с  |  м  |  и  |  т  |  ь  |  б  |  ю  |  .  |                 |
        -- |---------------------------------------------------------------------------------------+
        -- |       |        |      |                               |       |       |       |       |
        -- \---------------------------------------------------------------------------------------/
    -- },
    { modifier=left_shift, chords={
        -- /------__SHIFT_LAYER_EN__----------------------------------------------------------------\
        -- |  ~  |  !  |  @  |  #  |  $  |  %  |  ^  |  &  |  *  |  (  |  )  |  _  |  +  |          |
        -- |----------------------------------------------------------------------------------------+
        -- |        |  Q  |  W  |  E  |  R  |  T  |  Y  |  U  |  I  |  O  |  P  |  {  |  }  |   |   |
        -- |----------------------------------------------------------------------------------------+
        -- |       |  A  |  S  |  D  |  F  |  G  |  H  |  J  |  K  |  L  |  :  |  "  |              |
        -- |----------------------------------------------------------------------------------------+
        -- | TO_PRESS |  Z  | X |  C  |  V  |  B  |  N  |  M  |  <  |  >  |  ?  |     TO_PRESS      |
        -- |----------------------------------------------------------------------------------------+
        -- |      |       |       |                               |       |       |       |         |
        -- \----------------------------------------------------------------------------------------/
        -- tab - app - move block left
        -- left - select letter to the left
        -- right - select letter to the right
        -- up - move caret up and select text from the initial position
        -- down - move caret down and select text from the initial position
    }},
    { modifier=left_shift, chords={
      -- /------__SHIFT_LAYER_RU__---------------------------------------------------------------\
      -- |  Ё  |  !  |  "  |  №  |  ;  |  %  |  :  |  ?  |  *  |  ()  |  )  |  _  |  +  |        |
      -- |---------------------------------------------------------------------------------------+
      -- |        |  Й  |  Ц  |  У  |  К  |  Е  |  Н  |  Г  |  Ш  |  Щ  |  З  |  Х  |  Ъ  |      |
      -- |---------------------------------------------------------------------------------------+
      -- |       |  Ф  |  Ы  |  В  |  А  |  П  |  Р  |  О  |  Л  |  Д  |  Ж  |  Э  |             |
      -- |---------------------------------------------------------------------------------------+
      -- | TO_PRESS |  Я  | Ч |  С  |  М  |  И  |  Т  |  Ь  |  Б  |  Ю  |  ,  |     TO_PRESS     |
      -- |---------------------------------------------------------------------------------------+
      -- |      |       |       |                               |       |       |       |        |
      -- \---------------------------------------------------------------------------------------/
      -- tab - app - move block left
      -- left - select letter to the left
      -- right - select letter to the right
      -- up - move caret up and select text from the initial position
      -- down - move caret down and select text from the initial position
    }},
    { modifier=alt, chords={
        -- /------__ALT_LAYER___-------------------------------------------------------------------\
        -- |  `   |  ¹  |  ²  |  ³  |  $  |  ‰  |  ↑  |    |  ∞  |  ←  |  →  |  —  |   ≠  |        |
        -- |---------------------------------------------------------------------------------------+
        -- |       |     |  ✓  |  €  | ® |  ™  |  ѣ  |  ѵ  | і |  ѳ  |  ′  |   [   |   ]   | Rider |
        -- |---------------------------------------------------------------------------------------+
        -- |           |  ≈ |  §  |  °  | £ |     |  ₽  |  „  |  “  |  ”  |  ‘  |  ’  |            |
        -- |---------------------------------------------------------------------------------------+
        -- |             |    |  ×  |  ©  | ↓  |  ß  |     |  −  |  «  |  »  |  …  |               |
        -- |---------------------------------------------------------------------------------------+
        -- |      | TO_PRESS  |       |                            |      |      |  TO_PRESS  |    |
        -- \---------------------------------------------------------------------------------------/
        -- \ — Copilot Suggestion
        -- up — move line up
        -- left - jump a word to the left
        -- down — move line down
        -- right - jump a word to the right
    }},
    { modifier=left_command, chords={
        -- /------__CMD_LAYER___-------------------------------------------------------------------------------\
        -- |    |  Rider  |  Rider  |  Rider  | Rider  |   |    |    | Rider   |    |    |     |   Rider       |
        -- |---------------------------------------------------------------------------------------------------+
        -- |     |  macos  |  macos  |  Rider  |  Rider |     |    |    |    |    |    | Rider | Rider | Rider |
        -- |---------------------------------------------------------------------------------------------------+
        -- |       |  macos  |  macos  |  Rider  |  Rider  | Rider   | macos   |    |    |    |    |    |      |
        -- |---------------------------------------------------------------------------------------------------+
        -- |        |  macos | macos | macos |macos | Rider |    |  macos  | macos |    | Rider |              |
        -- |---------------------------------------------------------------------------------------------------+
        -- |     |       | TO_PRESS |            Rider                |  TO_PRESS |  macos  |       |  macos   |
        -- \---------------------------------------------------------------------------------------------------/
        -- ` -
        -- 1 - Rider - focus solution explorer
        -- 2 - Rider - focus debug window
        -- 3 - Rider - focus unit tests explorer
        -- 4 - Rider - focus build window
        -- 5 -
        -- 6 -
        -- 7 -
        -- 8 - Rider - focus logcat
        -- 9 -
        -- 0 - app - Reset zoom
        -- - - app - Zoom out
        -- = - app - Zoom in
        -- backspace - Rider - delete line
        -- q - macos - close current app
        -- w - macos - close current tab
        -- e - Rider - recent files dialog
        -- r - Rider - replace in current file
        -- t - macos - new tab
        -- y - app - show all history
        -- u -
        -- i -
        -- o - macos - open file
        -- p - macos - print
        -- [ - (Rider - navigate back) ; (Finder — navigate back) ; (Browser — navigate back)
        -- ] - (Rider - navigate forward) ; (Finder — navigate forward) ; (Browser — navigate forward)
        -- a - macos - select all
        -- s - app - save
        -- d - Rider - duplicate line
        -- f - macos - find (in current file)
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
        -- /------__CONTROL_LAYER___------------------------------------------------------------------\
        -- |     |  Rider  |       |      |    |    |    |    |    |    |    |    |     |             |
        -- |------------------------------------------------------------------------------------------+
        -- | Rider  |  Rider |  Rider  | Rider |  Rider  |   |    |   |    | Rider |    |    |    |   |
        -- |------------------------------------------------------------------------------------------+
        -- | Hyper   |  Rider  |  Rider  |  Rider  |  Rider  | Rider  |    |    |    |    |    |   |  |
        -- |------------------------------------------------------------------------------------------+
        -- | Rider   |      |       |      |       |      |    |    |     |    |    |                 |
        -- |------------------------------------------------------------------------------------------+
        -- | TO_PRESS |       |       |       macos                        |       |      |      |    |
        -- \------------------------------------------------------------------------------------------/
        -- F3 - macos - Move focus to Dock
        -- F5 - macos - Move focus to Window's Toolbar
        -- F6 - macos - Move focus to Floating Win
        -- tab - app - switch tab forward
        -- q - Rider - Stop all
        -- w - Rider - close all notifications
        -- e - Rider - Find Usages
        -- r - Rider - Run
        -- o - Rider - Override
        -- a - Rider - Git Annotate
        -- s - Rider - Save with format
        -- d - Rider - Debug
        -- f - Rider - Focus Find Window
        -- g - Rider - Fofus Git Window
        -- space - macos - change language layout
    }},
    { modifier=hyper, chords={
        -- /------__HYPER_LAYER___---------------------------------------------------------------------------------------\
        -- |    |  F1  |   F2    |  F3   | F4   | F5   | F6    | F7  | F8   | F9 |  F10   | F11    |  F12  | backspace   |
        -- |-------------------------------------------------------------------------------------------------------------+
        -- | toEn  | pageup | up | pagedown | Rider | Telegram |       | Torrent |  | up | Music | prtrack | nxttrack |  |
        -- |-------------------------------------------------------------------------------------------------------------+
        -- | TO_PRESS | left | down | right | Raycast  | Fork | Finder | Safari  | left | down | right | volume_up |     |
        -- |-------------------------------------------------------------------------------------------------------------+
        -- |      |  toRus  |  home   | end  |  Yandex | iTerm2  | VSCode | ElMedia  | home | end |  volume_down  |      |
        -- |-------------------------------------------------------------------------------------------------------------+
        -- |     |      |       |         play/stop                |       |       |       |                             |
        -- \-------------------------------------------------------------------------------------------------------------/
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
        -- alt + backspace — maccy delete row
        { key="tab", specific_function="set_english_language" },
        -- q - pageUp
        -- w - up
        -- e - pagedown
        { key="r", app="Rider" },
        { key="t", app="Telegram", window_default_position="right" },
        -- { key="y", app="" },
        { key="u", app="Transmission", window_default_position="right" },
        -- o - up
        { key="p", app="Music" },
        -- [ - previous track
        -- ] - next track
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
        { key="v", app="Yandex" },
        { key="b", app="iTerm" },
        { key="n", app="Visual Studio Code" },
        { key="m", app="Elmedia Player", window_default_position="bottom"},
        -- , - home
        -- . - end
        -- / - volume down
        -- left - Can't be pressed on AnnePro2
        -- right - Can't be pressed on AnnePro2
        -- up - Can't be pressed on AnnePro2
        -- down - Can't be pressed on AnnePro2
    }},
    { modifier={"left_command", "left_shift"}, chords={
        -- /------__CONTROL_LAYER___-----------------------------------------------------------------\
        -- |     |       |       |      |    |    |    |    |    |    |    |    |     |   Rider      |
        -- |-----------------------------------------------------------------------------------------+
        -- |      |  macos |  Rider  | Rider |  Rider  | Rider |    |   |    |    |    |    |    |     |
        -- |-----------------------------------------------------------------------------------------+
        -- |        |      |      |      |  Rider  | Rider  |    |    |    |    |    |    |   |
        -- |-----------------------------------------------------------------------------------------+
        -- |          | macos |       |      |       |      |    |    |     |    | Rider  |               |
        -- |-----------------------------------------------------------------------------------------+
        -- |      |       |       |       macos                        |       |       |       |     |
        -- \-----------------------------------------------------------------------------------------/
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
        -- / -
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
        -- c - maccy — show history of the texts from buffer
        -- v -
        -- b -
        -- n -
        -- m -
        -- , -
        -- . -
        -- / - Rider - comment
    }},
    { modifier={"left_command", "alt"}, chords={
        -- /------__CONTROL_LAYER___-------------------------------------------------------------------------\
        -- |     |     |       |      |    |    |    |    |    |    |    |    |     |            |           |
        -- |-------------------------------------------------------------------------------------------------+
        -- |      |     |    |  |    |   |    |   |    |    |    |    |    |     |                           |
        -- |-------------------------------------------------------------------------------------------------+
        -- |        |    |    |    | Rider |   | macos   |    |    | Finder  |    |    |      |              |
        -- |-------------------------------------------------------------------------------------------------+
        -- |          |      |       | Finder | Rider |      | Rider | Rider   |     |    |    |     |       |
        -- |-------------------------------------------------------------------------------------------------+
        -- |      | TO_PRESS_2 | TO_PRESS_1 |                              |       |     |      |    |       |
        -- \-------------------------------------------------------------------------------------------------/
        -- esc - macos - force quit current app
        -- f - macos - show/hide Dock
        -- f - Rider - extract field
        -- h - macos - hide all other windows
        -- l — (Finder — downloads) ; (Browser — downloads)
        -- c — Finder — Copy file's path
        -- v - (Rider - extract variable) ; (Finder — move items here)
        -- n - Rider - inline
        -- m - Rider - extract method
    }},
    { modifier={"left_command", "left_control"}, chords={
        -- /------__CONTROL_LAYER___-----------------------------------------------------------------\
        -- |     |     |       |      |    |    |    |    |    |    |    |    |     |                |
        -- |-----------------------------------------------------------------------------------------+
        -- |    |  macos |     |     |    |   |    |   |    |    |    |    |    |                    |
        -- |-----------------------------------------------------------------------------------------+
        -- |        |      |      |       | macos |      |    |    |    |    |    |    |             |
        -- |-----------------------------------------------------------------------------------------+
        -- |          |      |       |      |       |      |    |    |     |    |    |               |
        -- |-----------------------------------------------------------------------------------------+
        -- |      |       |       |                                |       |       |       |         |
        -- \-----------------------------------------------------------------------------------------/
        -- q - logout
        -- f - toggle fullscreen of current app
        -- d - macos - look up the selected word
        -- space - macos - emogies
    }},
    { modifier= {"left_control", "left_shift"}, chords={
        -- /------__CONTROL_LAYER___-----------------------------------------------------------------\
        -- |     |  Rider  |       |      |    |    |    |    |    |    |    |    |     |            |
        -- |-----------------------------------------------------------------------------------------+
        -- | Rider  |  Rider |  Rider  | Rider |  Rider  |   |    |   |    |    |    |    |    |     |
        -- |-----------------------------------------------------------------------------------------+
        -- |        |  Rider  |  Rider  |  Rider  |  Rider  | Rider  |    |    |   |   |    |    |   |
        -- |-----------------------------------------------------------------------------------------+
        -- |          |      |       |      |       |      |    |    |     |    |    |               |
        -- |-----------------------------------------------------------------------------------------+
        -- |      |       |       |       macos                        |       |       |       |     |
        -- \-----------------------------------------------------------------------------------------/
        { key="escape", app="Activity Monitor" },
        -- tab - Rider - go to previous tab
        -- q - macos - log out with dialogs
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
        -- /------__CONTROL_LAYER___-----------------------------------------------------------------\
        -- |     |     |       |      |    |    |    |    |    |    |    |    |     |                |
        -- |-----------------------------------------------------------------------------------------+
        -- |    |   |      |      |      |     |   |     |    |    |    |    |    |                  |
        -- |-----------------------------------------------------------------------------------------+
        -- |        |    |  |  Rider  |  Rider  | Rider  | Hammerspoon |    |    |    |    |    |    |
        -- |-----------------------------------------------------------------------------------------+
        -- |          |      | XCode |      |       |      |    |    |     |    |    |               |
        -- |-----------------------------------------------------------------------------------------+
        -- |      |       |       |       macos                        |       |       |       |     |
        -- \-----------------------------------------------------------------------------------------/
        { key="tab", specific_function="translate_to_english"},
        { key="h", app="Hammerspoon", window_default_position="right"},
        { key="x", app="XCode" },
        { key="i", specific_function="info.show_shortcuts"},
        -- macos d - Show desktop
        -- Rider | - GitHub Copilot - show suggestion
        { key="f", app="LaunchPad" },
        { key="a", app="Ableton Live 12 Suite"},
        { key="s", specific_function="android.show_all", apps_list={ "Android Emulator", "qemu-system-x86_64"} },
        { key="z", specific_function="translate_to_russian"},
        { key="g", specific_function="translate_to_greek"},
        -- itsical c - Show Calendar
        { key="left", specific_function="window.left"},
        { key="right", specific_function="window.right"},
        { key="up", specific_function="window.fullscreen"},
        { key="down", specific_function="window.set_all_to_default"},
    }},
    { modifier={"left_control", "left_shift"}, chords={
        -- /------__CONTROL+SHIFT_LAYER___-----------------------------------------------------------\
        -- |     |     |       |      |    |    |    |    |    |    |    |    |     |                |
        -- |-----------------------------------------------------------------------------------------+
        -- |    |   |      |      |      |     |   |     |    |    |    |    |    |                  |
        -- |-----------------------------------------------------------------------------------------+
        -- |        |    |  |    |    |   |  |    |    |    |    |    |                              |
        -- |-----------------------------------------------------------------------------------------+
        -- |          |      |  |      |       |      |    |    |     |    |    |                    |
        -- |-----------------------------------------------------------------------------------------+
        -- |      |       |       |                               |       |       |       |          |
        -- \-----------------------------------------------------------------------------------------/

    }},
    { modifier={"alt", "left_shift"}, chords={
        -- /------__CONTROL_LAYER___-----------------------------------------------------------------\
        -- |  `  |  ¡  |  ¹⁄₂  | ¹⁄₃ |  ¹⁄₄ |     |    |    |    |    |    |    |     |              |
        -- |-----------------------------------------------------------------------------------------+
        -- |      |      |       |    |      |   |    |   |    |    |    |    |    |                 |
        -- |-----------------------------------------------------------------------------------------+
        -- |        |       |      |      |      |     |    |    |    |    |    |    |               |
        -- |-----------------------------------------------------------------------------------------+
        -- |          |      |       |      |       |      |    |    |     |    |    |               |
        -- |-----------------------------------------------------------------------------------------+
        -- |      |       |       |                                 |       |       |       |        |
        -- \-----------------------------------------------------------------------------------------/
        -- ` - `
        -- 1 - ¡
        -- 2 - ¹⁄₂
        -- 3 - ¹⁄₃
        -- 4 - ¹⁄₄
        -- 5 -
        -- 6 - ˆ
        -- 7 - ¿
        -- 8 -
        -- 9 - ‹
        -- 0 - ›
        -- - - –
        -- = - ±
        -- q - ˘
        -- w - ⌃
        -- e - ⌥
        -- r - ˚
        -- t - #
        -- y - Ѣ
        -- u - Ѵ
        -- i -
        -- o - Ѳ
        -- p - ″
        -- [ - {
        -- ] - }
        -- a -
        -- s - ⇧
        -- d -
        -- f -
        -- g - 
        -- h - ˝
        -- j -
        -- k - ‘
        -- l - ’
        -- ; - ¨
        -- ' -
        -- z - ¸
        -- x -
        -- c - ¢
        -- v - ˇ
        -- b - ẞ
        -- n - ˜
        -- m - •
        -- , - „
        -- . - “
        -- / - ś
    }
    }}

function unsubscribe()
    if hideKSheetShortCut then
        hideKSheetShortCut:disable();
   end
end

function obj:init()

    hideKSheetShortCut = hs.hotkey.new({}, "escape", function()
        spoon.KSheet:hide()
        ksheet = not ksheet
        unsubscribe()
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
                if chord_row.window_default_position then
                    if chord_row.window_default_position == "right" then
                        spoon.Windows:add_right_window_type_app(chord_row.app)
                    elseif chord_row.window_default_position == "bottom" then
                        spoon.Windows:add_bottom_window_type_app(chord_row.app)
                    end
                end
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
                        for _, window in ipairs(hs.window.allWindows()) do
                            local window_title = window:title()
                            local app_title = window:application():title()
                            for _, app in ipairs(chord_row.apps_list) do
                                if app_title == app or string.find(window_title, app) then
                                    window:focus()
                                end
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
                        hs.keycodes.setLayout("Russian – Ilya Birman Typography")
                    end)
                elseif chord_row.specific_function == "set_english_language" then
                    hs.hotkey.bind(row.modifier, chord_row.key, function()
                        hs.keycodes.setLayout("English - Ilya Birman Typography")
                    end)
                elseif chord_row.specific_function == "translate_to_russian" then
                    spoon.PopupTranslateSelection:bindHotkeys({
                        translate_to_ru = {row.modifier, chord_row.key},
                    })
                elseif chord_row.specific_function == "translate_to_english" then
                    spoon.PopupTranslateSelection:bindHotkeys({
                        translate_to_en = {row.modifier, chord_row.key},
                    })
                elseif chord_row.specific_function == "translate_to_greek" then
                    spoon.PopupTranslateSelection:bindHotkeys({
                        translate_to_el = {row.modifier, chord_row.key},
                    })
                end
            end
        end
    end
end

return obj
