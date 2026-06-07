#!/bin/zsh
# Opens audio/video file(s) in VoiceInk for transcription.
# VoiceInk's Info.plist declares audio/movie as document types — `open -a` triggers transcription.

for file in "$@"; do
    [ -f "$file" ] || continue
    open -a VoiceInk "$file"
done
