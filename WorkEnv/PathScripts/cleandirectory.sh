#!/bin/bash
#remove files we don't we don't care about in a git directory
find ./ -type f -a \( -iname "*.bak" -o -iname "*~" -o -iname ".directory" \) -exec  rm {} \;
#remove empty directories, -depth goes to the end of each path first
find ./ -depth -empty -delete
find ./ -depth -empty -delete