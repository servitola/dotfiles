export current_dir="$1"
osascript <<EOD
set current_dir to quoted form of (system attribute "current_dir")
  tell application "iTerm"
    create window with default profile
    activate
tell the current window
activate current session
tell current session
write text "cd " & current_dir & "; clear"
end tell
end tell
  end tell
EOD