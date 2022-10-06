#!/bin/zsh
source zsh/functions.sh

echo "installing XCode if needed"

if ! xcode-select --print-path &> /dev/null;
then
    xcode-select --install &> /dev/null

    until xcode-select --print-path &> /dev/null;
    do
        sleep 5
    done

    print_result $? 'Install XCode Command Line Tools'

    sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer
    print_result $? 'Make "xcode-select" developer directory point to Xcode'

    sudo xcodebuild -license
    print_result $? 'Agree with the XCode Command Line Tools licence'
fi

echo "setup xcode symlinks"
rm -rf ~/Library/Developer/Xcode/UserData/KeyBindings
ln -sfvh ~/projects/dotfiles/xcode/KeyBindings ~/Library/Developer/Xcode/UserData/KeyBindings
