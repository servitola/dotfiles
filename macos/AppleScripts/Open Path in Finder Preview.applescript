tell application "Finder" to open selection using path to application "Preview"
tell application "Finder"
	activate
	close Finder window id 4178
	set target of Finder window 1 to folder "Греческий" of folder "Documents" of folder "servitola" of folder "Users" of startup disk
end tell
