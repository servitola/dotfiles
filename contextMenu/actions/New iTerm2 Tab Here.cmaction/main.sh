export current_dir="$1"
osascript <<EOD
set current_dir to quoted form of (system attribute "current_dir")
  tell application "iTerm"
    tell current window
      create tab with default profile
      activate
tell the current tab
activate current session
launch session "Default Session"
tell the last session
write text "cd " & current_dir & "; clear"
end tell
end tell

    end tell
  end tell
EOD