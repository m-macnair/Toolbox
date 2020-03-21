#!/bin/bash
#remove .bak-* files
find ./ -type f -iname "*.bak-*" -exec  rm {} \;
