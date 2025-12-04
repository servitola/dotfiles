#!/bin/zsh

source "$HOME/projects/dotfiles/zsh/functions.sh"
echo 'Check the link for MacOS types identifiers:'
echo 'https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/UTIRef/Articles/System-DeclaredUniformTypeIdentifiers.html'

echo "Setting text editor"
duti -s com.microsoft.VSCode com.netscape.javascript-source all
duti -s com.microsoft.VSCode net.daringfireball.markdown all
duti -s com.microsoft.VSCode public.css all
duti -s com.microsoft.VSCode public.json all
duti -s com.microsoft.VSCode public.php-script all
duti -s com.microsoft.VSCode public.plain-text all
duti -s com.microsoft.VSCode public.python-script all
duti -s com.microsoft.VSCode public.ruby-script all
duti -s com.microsoft.VSCode public.shell-script all
duti -s com.microsoft.VSCode public.source-code all
duti -s com.microsoft.VSCode public.text all
duti -s com.microsoft.VSCode public.unix-executable all
duti -s com.microsoft.VSCode public.xml all
duti -s com.microsoft.VSCode .asc all
duti -s com.microsoft.VSCode .applescript all
duti -s com.microsoft.VSCode .bashrc all
duti -s com.microsoft.VSCode .bat all
duti -s com.microsoft.VSCode .bib all
duti -s com.microsoft.VSCode Brewfile all
duti -s com.microsoft.VSCode .c all
duti -s com.microsoft.VSCode .cake all
duti -s com.microsoft.VSCode .coffee all
duti -s com.microsoft.VSCode .conf all
duti -s com.microsoft.VSCode .config all
duti -s com.microsoft.VSCode .cpp all
duti -s com.microsoft.VSCode .css all
duti -s com.microsoft.VSCode .csv all
duti -s com.microsoft.VSCode .dart all
duti -s com.microsoft.VSCode .dat all
duti -s com.microsoft.VSCode .eslintrc all
duti -s com.microsoft.VSCode .gitconfig all
duti -s com.microsoft.VSCode .gitignore all
duti -s com.microsoft.VSCode .go all
duti -s com.microsoft.VSCode .gradle all
duti -s com.microsoft.VSCode .h all
duti -s com.microsoft.VSCode .hpp all
duti -s com.microsoft.VSCode .hs all
duti -s com.microsoft.VSCode .ini all
duti -s com.microsoft.VSCode .java all
duti -s com.microsoft.VSCode .jl all
duti -s com.microsoft.VSCode .js all
duti -s com.microsoft.VSCode .json all
duti -s com.microsoft.VSCode .jsx all
duti -s com.microsoft.VSCode .key all
duti -s com.microsoft.VSCode .kt all
duti -s com.microsoft.VSCode .kts all
duti -s com.microsoft.VSCode .less all
duti -s com.microsoft.VSCode LICENSE all
duti -s com.microsoft.VSCode .lock all
duti -s com.microsoft.VSCode .log all
duti -s com.microsoft.VSCode .lua all
duti -s com.microsoft.VSCode .m all
duti -s com.microsoft.VSCode .markdown all
duti -s com.microsoft.VSCode .md all
duti -s com.microsoft.VSCode .mdx all
duti -s com.microsoft.VSCode Podfile all
duti -s com.microsoft.VSCode .php all
duti -s com.microsoft.VSCode .phpt all
duti -s com.microsoft.VSCode .pl all
duti -s com.microsoft.VSCode .plist all
duti -s com.microsoft.VSCode .pom all
duti -s com.microsoft.VSCode .prettierrc all
duti -s com.microsoft.VSCode .properties all
duti -s com.microsoft.VSCode .proto all
duti -s com.microsoft.VSCode .py all
duti -s com.microsoft.VSCode .R all
duti -s com.microsoft.VSCode .rb all
duti -s com.microsoft.VSCode .rs all
duti -s com.microsoft.VSCode .sass all
duti -s com.microsoft.VSCode .scss all
duti -s com.microsoft.VSCode .sh all
duti -s com.microsoft.VSCode .srt all
duti -s com.microsoft.VSCode .stub all
duti -s com.microsoft.VSCode .svg all
duti -s com.microsoft.VSCode .swift all
duti -s com.microsoft.VSCode .tex all
duti -s com.microsoft.VSCode .toml all
duti -s com.microsoft.VSCode .tf all
duti -s com.microsoft.VSCode .ts all
duti -s com.microsoft.VSCode .tsv all
duti -s com.microsoft.VSCode .tsx all
duti -s com.microsoft.VSCode .txt all
duti -s com.microsoft.VSCode .vue all
duti -s com.microsoft.VSCode .xml all
duti -s com.microsoft.VSCode .v all
duti -s com.microsoft.VSCode .wkt all
duti -s com.microsoft.VSCode .wxml all
duti -s com.microsoft.VSCode .wxss all
duti -s com.microsoft.VSCode .yaml all
duti -s com.microsoft.VSCode .yml all
duti -s com.microsoft.VSCode .zsh all
duti -s com.microsoft.VSCode .zshrc all
duti -s com.microsoft.VSCode Makefile all
duti -s com.microsoft.VSCode .settings all
duti -s com.microsoft.VSCode .gitignore all
duti -s com.microsoft.VSCode .opml all
duti -s com.microsoft.VSCode .keylayout all

echo "Setting audio/video player"
duti -s com.colliderli.iina public.audio all
duti -s com.colliderli.iina public.movie all

duti -s com.colliderli.iina .3gp all
duti -s com.colliderli.iina .avi all
duti -s com.colliderli.iina .flac all
duti -s com.colliderli.iina .flv all
duti -s com.colliderli.iina .m4a all
duti -s com.colliderli.iina .m4v all
duti -s com.colliderli.iina .mka all
duti -s com.colliderli.iina .mkv all
duti -s com.colliderli.iina .mks all
duti -s com.colliderli.iina .mov all
duti -s com.colliderli.iina .mp3 all
duti -s com.colliderli.iina .mpeg all
duti -s com.colliderli.iina .mpg all
duti -s com.colliderli.iina .mp4 all
duti -s com.colliderli.iina .ogg all
duti -s com.colliderli.iina .ogm all
duti -s com.colliderli.iina .ogv all
duti -s com.colliderli.iina .opus all
duti -s com.colliderli.iina .wav all
duti -s com.colliderli.iina .webm all
duti -s com.colliderli.iina .wmv all

echo "Setting image preview"
duti -s com.apple.Preview public.image all
duti -s com.apple.Preview .bmp all
duti -s com.apple.Preview .gif all
duti -s com.apple.Preview .jpg all
duti -s com.apple.Preview .jpeg all
duti -s com.apple.Preview .pdf all
duti -s com.apple.Preview .png all
duti -s com.apple.Preview .tif all
duti -s com.apple.Preview .tiff all

duti -s com.jetbrains.rider .sln all

duti -s com.ableton.AbletonLive12 .alp all
duti -s com.ableton.AbletonLive12 .als all
