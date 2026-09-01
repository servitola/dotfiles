#!/bin/zsh
# What compress.sh keeps APFS-compressed. Add a path, nothing else.
# Missing on another Mac is fine — targets that do not exist are skipped.

COMPRESS_TARGETS=(
    "$HOME/Library/Android"
    "$HOME/.dotnet/packs"   # never $HOME/.dotnet — a compressed CoreCLR host tree SIGKILLs every dotnet run
    "$HOME/.rustup"
    "$HOME/.konan"
    "$HOME/.hermes"
    "$HOME/Library/Application Support/MstyStudio"
)

# Bundles: skipped while the app runs, and need App Management on the terminal.
COMPRESS_APPS=(
    "$HOME/Applications/Rider.app"
    "$HOME/Applications/WebStorm.app"
    "$HOME/Applications/Forkgram.app"
    "/Applications/Ableton Live 12 Suite.app"
    "/Applications/Visual Studio Code.app"
    "/Applications/GeForceNOW.app"
    "/Applications/Blender.app"
    "/Applications/OrbStack.app"
    "/Applications/Yandex.Telemost.app"
    "/Applications/Guitar Pro 8.app"
    "/Applications/Pages.app"
    "/Applications/LibreOffice.app"
    "/Applications/WorkFlowy.app"
    "/Applications/Discord.app"
    "/Applications/JetBrains Toolbox.app"
    "/Applications/DB Browser for SQLite.app"
    "/Applications/VLC.app"
    "/Applications/KiCad/KiCad.app"
)
