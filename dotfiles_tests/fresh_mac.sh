#!/bin/zsh
# Runs inside the VM before make: turns the CI image into a new user's Mac.
setopt err_exit
constants=~/projects/dotfiles/constants.env
brewfile=~/projects/dotfiles/homebrew/brewfile

cp ~/projects/dotfiles/constants.example.env $constants
sed -i '' 's/^DOCKER=.*/DOCKER=no/' $constants
grep -qx DOCKER=no $constants

skip=(
    'brew "facebook/fb/idb-companion"'   # needs a full Xcode, i.e. an Apple ID
    'cask "servitola/tap/glasswings"'    # release download broken everywhere since 2026-10-10
)
for entry in $skip; do
    grep -v -F "$entry" $brewfile > /tmp/brewfile && mv /tmp/brewfile $brewfile
done

sudo rm /usr/local/lib/TartMetalCapabilities.dylib
PATH=/opt/homebrew/bin:$PATH npm rm -g --silent yarn pnpm

# SIP is off in this image, so Hammerspoon gets the Accessibility a person would
# click in System Settings; the apps stage needs it to press keys.
for service in kTCCServiceAccessibility kTCCServicePostEvent; do
    sudo sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" \
        "insert or replace into access (service, client, client_type, auth_value, auth_reason, auth_version, indirect_object_identifier, boot_uuid)
         values ('$service', 'org.hammerspoon.Hammerspoon', 0, 2, 0, 1, 'UNUSED', 'UNUSED')"
done
