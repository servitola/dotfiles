"""Key tables: Karabiner key codes, the physical keys they sit on, and the glyphs the tables are written in."""

HYPER = {"right_command", "right_control", "right_option", "right_shift"}

# Karabiner key_code → physical key name (matching config.BUTTON_FILES)
TO_PHYS = {
    "a":"a","b":"b","c":"c","d":"d","e":"e","f":"f","g":"g","h":"h","i":"i",
    "j":"j","k":"k","l":"l","m":"m","n":"n","o":"o","p":"p","q":"q","r":"r",
    "s":"s","t":"t","u":"u","v":"v","w":"w","x":"x","y":"y","z":"z",
    "1":"1","2":"2","3":"3","4":"4","5":"5","6":"6","7":"7","8":"8","9":"9","0":"0",
    "grave_accent_and_tilde":"tilde", "non_us_backslash":"tilde",
    "hyphen":"minus", "equal_sign":"equal",
    "open_bracket":"bracketleft", "close_bracket":"bracketright",
    "backslash":"backslash", "semicolon":"semicolon", "quote":"apostrophe",
    "comma":"comma", "period":"period", "slash":"slash",
    "spacebar":"space", "tab":"tab", "return_or_enter":"return",
    "delete_or_backspace":"backspace", "caps_lock":"capslock",
    "left_shift":"shift", "left_arrow":"left", "right_arrow":"right",
    "up_arrow":"up", "down_arrow":"down",
}

# Output key_code → display symbol
KEY_SYM = {
    **{f"keypad_{n}": f"num{n}" for n in range(10)},
    "hyphen":"-", "equal_sign":"=", "slash":"/", "comma":",", "period":".", "semicolon":";",
    "quote":"'", "open_bracket":"[", "close_bracket":"]", "backslash":"\\", "spacebar":"␣",
    "up_arrow":"↑", "down_arrow":"↓", "left_arrow":"←", "right_arrow":"→",
    "page_up":"PgUp", "page_down":"PgDn",
    "return_or_enter":"↩", "escape":"⎋",
    "delete_or_backspace":"⌫", "delete_forward":"⌦",
    "tab":"⇥", "spacebar":"␣",
    "grave_accent_and_tilde":"`", "non_us_backslash":"`",
    "open_bracket":"[", "close_bracket":"]",
}
CONSUMER_SYM = {
    "volume_increment":"Vol ↑", "volume_decrement":"Vol ↓", "mute":"Mute",
    "play_or_pause":"▶/⏸", "rewind":"⏪", "fastforward":"⏩",
    "fast_forward":"⏩",
    "al_previous_track":"⏮", "al_next_track":"⏭",
    "display_brightness_increment":"☀↑", "display_brightness_decrement":"☀↓",
    "illumination_increment":"🔆", "illumination_decrement":"🔅",
    "vk_consumer_previous":"⏮", "vk_consumer_next":"⏭",
    "vk_consumer_play":"▶/⏸",
}

MOD_DISPLAY = {"hyper": "\u21ea", "shift": "\u21e7", "ctrl": "\u2303",
               "alt": "\u2325", "cmd": "\u2318", "tab_mod": "\u21e5", "fn": "fn "}

# Physical key id \u2192 display glyph (used when rendering source chords like
# `\u21e7\u2303\u2325\u2318\u2193` from a karabiner-output active chord like `\u21e7F13`).
KEY_DISPLAY = {
    "down": "\u2193", "up": "\u2191", "left": "\u2190", "right": "\u2192",
    "tab": "\u21e5", "tilde": "~", "space": "\u2423", "return": "\u21a9",
    "backspace": "\u232b", "comma": ",", "period": ".", "semicolon": ";",
    "apostrophe": "'", "slash": "/", "bracketleft": "[",
    "bracketright": "]", "backslash": "\\", "minus": "-", "equal": "=",
}
