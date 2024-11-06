bbdiff_path1="/Applications/BBEdit.app/Contents/Helpers/bbdiff"
bbdiff_path2="/usr/local/bin/bbdiff"
if [ -f "$bbdiff_path1" ]; then
  bbdiff_path="$bbdiff_path1"
elif [ -f "$bbdiff_path2" ]; then
  bbdiff_path="$bbdiff_path2"
fi

if ! [[ -z "$bbdiff_path" ]]; then
    "$bbdiff_path" "$@"
fi