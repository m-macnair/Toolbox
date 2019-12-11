#!/bin/bash
#remove files we don't we don't care about in a git directory
find ./ -type f -a \( -iname "*.bak" -o -iname "*~" \) -exec  rm {} \;