alias up='
    sudo -v

    sudo softwareupdate -i -a
    xcode-select --install
    
    rm -rf "brew --cache"
    brew cu --all -y -q;
    brew update
    brew upgrade
    mas upgrade
    brew cleanup
    brew doctor 
    omz update
    
    brew bundle dump --force --file=~/projects/pc-scripts/homebrew/.brewfile

    tldr --update
    
    npm config set fund false --global
    
    setopt rm_star_silent
    rm -rf ~/Library/Caches/*
    rm -rf /Library/Caches/*
    rm -rf ~/Library/Developer/Xcode/DerivedData/*
    setopt no_rm_star_silent

    reload
'