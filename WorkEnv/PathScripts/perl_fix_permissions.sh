#!/bin/bash 
find ./ -type f  -iname "*.pm"  -exec chmod 644 {} \;
find ./ -type f  -iname "*.pl"  -exec chmod 755 {} \;