#!/bin/zsh
# What compress.sh keeps APFS-compressed
# targets that do not exist are skipped.

COMPRESS_TARGETS=(
    "$HOME/Library/Android"
    "$HOME/.dotnet/packs"   # never $HOME/.dotnet — a compressed CoreCLR host tree SIGKILLs every dotnet run
    "$HOME/.rustup"
    "$HOME/.konan"
)

# Compress All Apps in Application folder
#   {,*/}  also one level down
#   N      an empty match is fine
#   /      real directories, so a symlinked .app never matches
#   U      owned by me — root-owned wants sudo, not the App Management grant
#   :A     the path with every symlink resolved
COMPRESS_APPS=()
for app in /Applications/{,*/}*.app(N/U) ~/Applications/{,*/}*.app(N/U); do
    [[ ${app:A} == $app ]] || continue
    COMPRESS_APPS+=( $app )
done
