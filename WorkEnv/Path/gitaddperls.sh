find ./ -type f -a \( -iname "*.pm" -o -iname "*.pl" -o -iname "*.t" \) -exec git add {} \;