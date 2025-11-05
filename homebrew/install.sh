#!/bin/zsh

echo "installing homebrew if needed"
command -v brew > /dev/null 2>&1 || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
