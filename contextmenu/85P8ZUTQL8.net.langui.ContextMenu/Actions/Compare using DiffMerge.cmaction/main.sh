file1="$1"
file2="$2"
# both files or directories
if [[ (-f "$file1" && -f "$file2") || (-d "$file1" && -d "$file2") ]]; then
  /Applications/DiffMerge.app/Contents/Resources/diffmerge.sh "$file1" "$file2"
fi
