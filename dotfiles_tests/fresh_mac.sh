#!/bin/zsh
# Runs inside the VM before make: turns the CI image into a new user's Mac.
setopt err_exit
constants=~/projects/dotfiles/constants.env
brewfile=~/projects/dotfiles/homebrew/brewfile

sed -i '' -e 's/^DOCKER=.*/DOCKER=no/' \
          -e 's/^APP_TELEGRAM=.*/APP_TELEGRAM=Telegram/' \
          -e 's/^APP_TELEGRAM_BUNDLE=.*/APP_TELEGRAM_BUNDLE=ru.keepcoder.Telegram/' $constants
grep -qx DOCKER=no $constants && grep -qx APP_TELEGRAM=Telegram $constants

skip=(
    'brew "facebook/fb/idb-companion"'   # needs a full Xcode, i.e. an Apple ID
    'cask "servitola/tap/glasswings"'    # release download broken everywhere since 2026-10-10
)
for entry in $skip; do
    grep -v -F "$entry" $brewfile > /tmp/brewfile && mv /tmp/brewfile $brewfile
done

sudo rm /usr/local/lib/TartMetalCapabilities.dylib
PATH=/opt/homebrew/bin:$PATH npm rm -g --silent yarn pnpm
