#!/bin/zsh

# Resize image(s) via sips with an AppleScript dialog for dimension input.
# Works with multiple selected files. Creates resized copies, not overwriting originals.

choice=$(osascript -e 'choose from list {"Width", "Height"} with prompt "Resize by:" default items {"Width"}')
[ "$choice" = "false" ] && exit 0

value=$(osascript -e "display dialog \"Enter ${choice:l} in pixels:\" default answer \"1200\" buttons {\"Cancel\", \"OK\"} default button \"OK\"" -e 'text returned of result' 2>/dev/null)
[ -z "$value" ] && exit 0

for file in "$@"; do
    ext="${file##*.}"
    base="${file%.*}"
    output="${base}_${value}px.${ext}"

    if [ "$choice" = "Width" ]; then
        sips --resampleWidth "$value" "$file" --out "$output" 2>/dev/null
    else
        sips --resampleHeight "$value" "$file" --out "$output" 2>/dev/null
    fi
done
