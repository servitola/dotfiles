"""Map fn names to labels and app icons; get display label for any entry."""
FN_LABELS = {
    "window.left": "Window \u2190", "window.right": "Window \u2192", "window.fullscreen": "Fullscr",
    "window.center": "Center", "window.half_left": "\u00bd Left", "window.half_right": "\u00bd Right",
    "window.top_60": "Top 60%", "window.bottom_40": "Bot 40%", "window.set_all_to_default": "Win Reset",
    "window.hide_current": "Hide Win", "window.hide_all_except_work": "Focus Work",
    "window.focus_work": "Focus Work", "window.focus_personal": "Focus Prsnl",
    "window.focus_comms": "Focus Comms", "warp.launch_default": "Warp",
    "browser_git": "GitHub", "browser_git_dotfiles": "GH Dotfiles",
    "browser_youtube": "YouTube", "browser_youtube_playing": "YT Playing",
    "youtube_stream": "YT Stream", "translate_to_russian": "\u2192 RU",
    "translate_to_english": "\u2192 EN", "translate_to_greek": "\u2192 EL",
    "musicapp.play_pause": "\u25b6/\u23f8", "android.show_all": "Android",
    "vpn.toggle_globalprotect": "VPN", "audio.internal": "Audio Int",
    "audio.external": "Audio Ext", "audio.bt": "Audio BT",
    "audio.marshall": "Marshall", "audio.connect_marshall": "Marshall",
    "system_health": "Sys Health", "clipboard_llm": "Clip LLM", "screenshot_ai": "AI Screen",
    "hammerspoon_reload": "Reload", "wallpaper_refresh": "Wallpaper",
    "paste_bypass": "Paste Raw", "press_return": "Enter", "browser_search_selected": "Search Sel",
    "info.show_shortcuts": "Shortcuts", "set_russian_language": "Lang RU",
    "set_english_language": "Lang EN", "vscode.dotfiles": "VS Dotfiles",
    "fork.dotfiles": "Fork Dots", "fork.ctraderdev": "Fork cTrader",
    "app_usage_stats": "App Stats", "interview.toggle": "Interview",
    "show_youtrack": "YouTrack", "show_youtrack_tasks": "YT Tasks",
}
FN_APP = {  # fn → app name for icon (use _terminal/_browser for defaults)
    "browser_git": "_browser", "browser_git_dotfiles": "_browser",
    "browser_youtube": "_browser", "browser_youtube_playing": "_browser",
    "browser_search_selected": "_browser", "youtube_stream": "_browser",
    "warp.launch_default": "_terminal", "hammerspoon_reload": "Hammerspoon",
    "system_health": "Hammerspoon", "wallpaper_refresh": "Hammerspoon",
    "info.show_shortcuts": "Hammerspoon", "clipboard_llm": "Hammerspoon",
    "screenshot_ai": "Hammerspoon", "app_usage_stats": "Hammerspoon",
    "interview.toggle": "Hammerspoon", "vscode.dotfiles": "Visual Studio Code",
    "fork.dotfiles": "Fork", "fork.ctraderdev": "Fork",
}
COMMENT_OUTPUT_LABELS = {
    "prev_track": "\u23ee", "next_track": "\u23ed", "rewind": "\u23ea", "fast_forward": "\u23e9",
    "volume up": "Vol \u2191", "volume down": "Vol \u2193", "volume_up": "Vol \u2191",
    "volume_down": "Vol \u2193", "play/pause": "\u25b6/\u23f8", "play_or_pause": "\u25b6/\u23f8",
    "\u2318\u2192": "End", "\u2318\u2190": "Home", "\u2318\u2191": "Top", "\u2318\u2193": "Bottom",
}
COMMENT_DESC_LABELS = {"play_or_pause": "\u25b6/\u23f8", "play/pause": "\u25b6/\u23f8"}
_S = {"Visual Studio Code": "VS Code", "zoom.us": "Zoom", "Android Studio": "A.Studio",
      "Activity Monitor": "Activity", "Google Chrome": "Chrome",
      "System Settings": "Settings", "Heroes of the Storm": "HotS"}

def get_label(entry):
    if entry.get("app"): return _S.get(entry["app"], entry["app"])
    if entry.get("fn"): return FN_LABELS.get(entry["fn"], entry["fn"])
    return entry.get("label", "")
