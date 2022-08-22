hyper = {"right_command", "right_control", "right_option", "right_shift"}

apps_list = {
    { modifier=left_shift, chords={
        --/*/-----__SHIFT_LAYER___-------------------------------------------------------------------.
        --* |  ~  |  !  |  @  |  #  |  $  |  %  |  ^  |  &  |  *  |  (  |  )  |  _  |  +  |          |
        --* |----------------------------------------------------------------------------------------+
        --* | Rider  |  Q  |  W  |  E  |  R  |  T  |  Y  |  U  |  I  |  O  |  P  |  {  |  }  |   |   |
        --* |----------------------------------------------------------------------------------------+
        --* | Hyper |  A  |  S  |  D  |  F  |  G  |  H  |  J  |  K  |  L  |  :  |  "  |             |
        --* |----------------------------------------------------------------------------------------+
        --* | TO_PRESS |  X  |  C  |  V  |  B  |  N  |  M  |  <  |  >  |  ?  |                       |
        --* |----------------------------------------------------------------------------------------+
        --* |      |       |       |                               |       |       |       |         |
        --* \----------------------------------------------------------------------------------------/
        -- tab Rider -> move block left
        -- left -> select text to the left
        -- right -> select text to the right
        -- up -> select text above
        -- down -> select text below
    }},
    { modifier=left_option, chords={
        --/*/-----__ALT_LAYER___---------------------------------------------------------------------.
        --* |     |  ¡  |  ™  |  £  |  ¢  |  ∞  |  §  |  ¶  |  •  |  ª  |  º  |  –  |   ≠  |          |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |  œ  |  ∑  |  ´  |  ®  |  †  |  ¥  |  ¨  |  ˆ  |  ø  |  π  |  “  |  ‘  |  Rider   |
        --* |-----------------------------------------------------------------------------------------+
        --* | Hyper |  å  |  ß  |  macos  |  ƒ  |  ©  |  ˙  |  ∆  |  ˚  |  ¬  |  …  |  æ  |          |
        --* |-----------------------------------------------------------------------------------------+
        --* |          |    |  ≈  |  ç  |  √  |  ∫  |  ˜  |  µ  |  ≤  |  ≥  |  ÷  |                   |
        --* |-----------------------------------------------------------------------------------------+
        --* |      | TO_PRESS  |       |                               |       |       |       |          |
        --* \-----------------------------------------------------------------------------------------/
        -- macos d -> Show desktop
        -- Rider | -> GitHub Copilot - show suggestion
        
    }},
    { modifier=left_command, chords={
        --/*/-----__CMD_LAYER___-----------------------------------------------------------------------------.
        --* |     |  Rider  |  Rider  |  Rider  | Rider  |   |    |    |    |    |    |    |     |  Rider        |
        --* |----------------------------------------------------------------------------------------------------+
        --* |      |  macos  |  Rider  |  Rider  |  Rider |     |    |    |    |    |    |  Rider  |  Rider  |  Rider   |
        --* |-------------------------------------------------------------------------------------------------------+
        --* |        |  macos  |  macos  |  Rider  |  Rider  | Rider   | macos   |    |    |    |    |    |          |
        --* |-----------------------------------------------------------------------------------------+
        --* |          |  macos  |  macos  |  macos  |  macos  |  Rider    |    |  macos  | macos |    | Rider |                   |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |       |       |       Rider                        |       |       |       |          |
        --* \-----------------------------------------------------------------------------------------/
        -- Rider 1 -> focus solution explorer
        -- Rider 2 -> focus debug window
        -- Rider 3 -> focus unit tests explorer
        -- Rider 4 -> focus run window
        -- Rider delete -> delete line
        -- macos q -> close current app
        -- Rider w -> close current tab
        -- Rider e -> recent files dialog
        -- Rider r -> replace in current file
        -- Rider [ -> navigate back
        -- Rider ] -> navigate forward
        -- macos a -> select all
        -- Rider s -> save
        -- Rider d -> duplicate line
        -- Rider f -> find in current file
        -- Rider g -> git operations popup
        -- macos h -> hide current app
        -- macos z -> undo
        -- macos x -> cut text
        -- macos c -> copy text
        -- macos v -> paste text
        -- Rider b -> go to declaration
        -- macos m -> minimize window
        -- macos , -> show settings of current app
        -- Rider / -> comment line
        -- Rider space -> Basic code completion
    }},
    { modifier=left_control, chords={
        --/*/-----__CONTROL_LAYER___-----------------------------------------------------------------.
        --* |     |  Rider  |       |      |    |    |    |    |    |    |    |    |     |            |
        --* |-----------------------------------------------------------------------------------------+
        --* | Rider  |  Rider |  Rider  | Rider |  Rider  |   |    |   |    | Rider |    |    |    |     |
        --* |-----------------------------------------------------------------------------------------+
        --* | Hyper   |  Rider  |  Rider  |  Rider  |  Rider  | Rider  |    |    |    |    |    |    |   |
        --* |-----------------------------------------------------------------------------------------+
        --* | Rider   |      |       |      |       |      |    |    |     |    |    |               |
        --* |-----------------------------------------------------------------------------------------+
        --* | TO_PRESS |       |       |       macos                        |       |       |       |     |
        --* \-----------------------------------------------------------------------------------------/
        -- Rider tab -> switch tab forward
        -- Rider q --> Stop all
        -- Rider w -> close all notifications
        -- Rider e -> Find Usages
        -- Rider r -> Run
        -- Rider o -> Override
        -- Rider a -> Git Annotate
        -- Rider s -> Save with format
        -- Rider d -> Debug
        -- Rider f -> Focus Find Window
        -- Rider g -> Fofus Git Window
        -- Rider shift + tab -> switch tab backward
        -- macos space -> change language
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
        -- karabiner escape -> tilda/ё
        { key="r", app_name="Rider" },
        { key="t", app_name="Telegram", window_default_position="right" },
        { key="y", app_name="Android Studio"},
        { key="u", app_name="Transmission" },
        { key="p", app_name="Music" },
        { key="g", app_name="Fork" },
        { key="h", app_name="Finder" },
        { key="j", app_name="Safari" },
        { key="z", specific_function="set_russian_language"},
        { key="v", app_name="Firefox" },
        { key="b", app_name="iTerm" },
        { key="n", app_name="Visual Studio Code" },
        { key="m", app_name="Elmedia Player" },
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
        -- Rider delete -> go to last edit location
        -- macos q -> quit all applications
        -- Rider w -> reopen closed tab
        -- Rider e -> recent locations popup
        -- Rider r -> replace in files
        -- Rider t -> reopen last tab
        -- Rider f -> search in all files
        -- macos z -> redo
        -- Rider / -> comment
    }},  
    { modifier={"left_command", "left_option"}, chords={
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
        -- Rider f -> extract field
        -- macos h -> hide all other windows
        -- Rider v -> extract variable
        -- Rider n -> inline
        -- Rider m -> extract method
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
        -- mac q -> logout
        -- mac f -> toggle fullscreen of current app 
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
        { key="escape", app_name="Activity Monitor" },
        -- Rider g -> Git history
        -- { key="i", map="mouse_right_button" },
        -- { key="o", map="mouse_up" },
        -- { key="p", map="mouse_left_button" },
        -- { key="s", app_name="Simulator" },
        -- { key="d", app_name="Android Emulator" },
        -- { key="k", map="mouse_left" },
        -- { key="l", map="mouse_down" },
        -- { key=";", map="mouse_right" }
    }},
    { modifier={"left_control", "left_option"}, chords={
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
        { key="left", specific_function="window.left"},
        { key="right", specific_function="window.right"},
        { key="up", specific_function="window.fullscreen"},
        { key="down", specific_function="window.set_all_to_default"},
        { key="i", specific_function="info.show_shortcuts"},
        { key="s", specific_function="android.show_all"},
        { key="a", app_name="Ableton Live 11 Suite"},
        { key="h", app_name="Hammerspoon"},
        { key="x", app_name="XCode"},
        -- itsical c -> Show Calendar
    }},
    { modifier={"left_option", "left_shift"}, chords={
        --/*/-----__CONTROL_LAYER___-----------------------------------------------------------------.
        --* |     |       |       |      |    |    |    |    |    |    |    |    |     |            |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |      |       |    |      |   |    |   |    |    |    |    |    |     |
        --* |-----------------------------------------------------------------------------------------+
        --* |        |       |      |      |      |     |    |    |    |    |    |    |   |
        --* |-----------------------------------------------------------------------------------------+
        --* |          |      |       |      |       |      |    |    |     |    |    |               |
        --* |-----------------------------------------------------------------------------------------+
        --* |      |       |       |                                 |       |       |       |     |
        --* \-----------------------------------------------------------------------------------------/
    }},
 }

hideKSheetShortCut = hs.hotkey.new({}, "escape", function()
    spoon.KSheet:hide()
    ksheet = not ksheet
    hideKSheetShortCut:disable();
end)

for _, row in pairs(apps_list) do
    for _, chord_row in pairs(row.chords) do
        if chord_row.app_name then
            hs.hotkey.bind(row.modifier, chord_row.key, function()
                local app = hs.application.get(chord_row.app_name)
                if not app or app:isHidden() then
                    hs.application.launchOrFocus(chord_row.app_name)
                elseif hs.application.frontmostApplication() ~= app then
                    app:activate()
                else
                    app:hide()
                end
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

