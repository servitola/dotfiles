export current_dir="$1"
osascript <<EOD
set current_dir to quoted form of (system attribute "current_dir")
tell application "Terminal"
    if not (exists window 1) then reopen
    activate
    delay 0.3
    tell application "System Events" to keystroke "t" using command down
    do script "cd " & current_dir in window 1
end tell
EOD
