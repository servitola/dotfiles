hyper = {"right_command", "right_control", "right_option", "right_shift"}

apps_list = {
    { modifier=left_shift, chords={
        --/*/-----__BASE_LAYER___-------------------------------------------------------------.
--* |     |  !  |  @  |  #  |  $  |  %  |  ^  |  &  |  *  |  (  |  )  |  _  |  +  |           |
--* |-----------------------------------------------------------------------------------------+
--* | Rider  |  Q  |  W  |  E  |  R  |  T  |  Y  |  U  |  I  |  O  |  P  |  {  |  }  |   |    |
--* |-----------------------------------------------------------------------------------------+
--* |        |  A  |  S  |  D  |  F  |  G  |  H  |  J  |  K  |  L  |  :  |  "  |              |
--* |-----------------------------------------------------------------------------------------+
--* |          |  Z  |  X  |  C  |  V  |  B  |  N  |  M  |  <  |  >  |  ?  |                  |
--* |-----------------------------------------------------------------------------------------+
--* |      |       |       |                               |       |       |       |          |
--* \-----------------------------------------------------------------------------------------/
        -- tab Rider -> move block left
        -- left -> select text to the left
        -- right -> select text to the right
        -- up -> select text above
        -- down -> select text below
    }},
    { modifier=left_option, chords={
--/*/-----__BASE_LAYER___---------------------------------------------------------------------.
--* |     |  ¡  |  ™  |  £  |  ¢  |  ∞  |  §  |  ¶  |  •  |  ª  |  º  |  –  |   ≠  |          |
--* |-----------------------------------------------------------------------------------------+
--* |      |  œ  |  ∑  |  ´  |  ®  |  †  |  ¥  |  ¨  |  ˆ  |  ø  |  π  |  “  |  ‘  |  Rider   |
--* |-----------------------------------------------------------------------------------------+
--* |        |  å  |  ß  |  macos  |  ƒ  |  ©  |  ˙  |  ∆  |  ˚  |  ¬  |  …  |  æ  |          |
--* |-----------------------------------------------------------------------------------------+
--* |          |    |  ≈  |  ç  |  √  |  ∫  |  ˜  |  µ  |  ≤  |  ≥  |  ÷  |                   |
--* |-----------------------------------------------------------------------------------------+
--* |      |       |       |                               |       |       |       |          |
--* \-----------------------------------------------------------------------------------------/
        -- macos d -> Show desktop
        -- Rider | -> GitHub Copilot - show suggestion
        
    }},
    { modifier=left_command, chords={
        -- Rider 1 -> focus solution explorer
        -- Rider 2 -> 
        -- Rider 3 -> focus unit tests explorer
        -- Rider 4 ->
        -- Rider 5 ->
        -- Rider 6 ->
        -- Rider 7 ->
        -- Rider 8 ->
        -- Rider 9 ->
        -- macos q -> close current app
        -- Rider w -> close current tab
        -- macos a -> select all
        -- Rider s -> save
        -- Rider d -> duplicate line
        -- Rider f -> find in current file
        -- macos z -> undo
        -- macos x -> cut text
        -- macos c -> copy text
        -- macos v -> paste text
    }},
    { modifier={left_command, left_shift}, chords={
        -- Rider w -> reopen closed tab
        -- macos z -> redo
    }},
    { modifier=left_control, chords={
        -- Rider w -> close all notifications
        -- Rider e -> Find Usages
        -- Rider r -> Run
        -- Rider a -> Git Annotate
        -- Rider s -> Save with format
        -- Rider d -> Debug
        -- Rider f -> Focus Find Window
    }},
    { modifier=hyper, chords={  
        -- karabiner escape -> tilda/ё
        -- karabiner 1 -> f1
        -- karabiner 2 -> f2
        -- karabiner 3 -> f3
        -- karabiner 4 -> f4
        -- karabiner 5 -> f5
        -- karabiner 6 -> f6
        -- karabiner 7 -> f7
        -- karabiner 8 -> f8
        -- karabiner 9 -> f9
        -- karabiner 0 -> f10
        -- karabiner - -> f11
        -- karabiner = -> f12
        -- karabiner backspace -> delete
        -- FREE { key="tab", }, 
        -- karabiner q -> page up
        -- karabiner w -> up
        -- karabiner e -> page down
        { key="r", app_name="Rider" },
        { key="t", app_name="Telegram", window_default_position="right" },
        { key="y", app_name="Android Studio"},
        { key="u", app_name="Transmission" },
        --{ key="i" },
        -- karabiner o -> up
        { key="p", app_name="Music" },
        -- karabiner [ -> previous track
        -- karabiner ] -> next track
        -- FREE |
        -- karabiner a -> left
        -- karabiner s -> down
        -- karabiner d -> right
        -- RayCast f 
        { key="g", app_name="Fork" },
        { key="h", app_name="Finder" },
        { key="j", app_name="Safari" },
        -- karabiner k -> left
        -- karabiner l -> down
        -- karabiner ; -> right
        -- karabiner ' -> volume up
        -- FREE Enter
        { key="z", specific_function="set_russian_language"},
        -- karabiner x -> home
        -- karabiner c -> end
        { key="v", app_name="Firefox" },
        { key="b", app_name="iTerm" },
        { key="n", app_name="Visual Studio Code" },
        { key="m", app_name="Elmedia Player" },
        -- karabiner < -> home
        -- karabiner > -> end
        -- karabiner , -> volume down
    }}, 
    { modifier= {"left_control", "left_shift"}, chords={
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

