git config --global credential.helper 'cache --timeout=300'
find ./ -type d -maxdepth 1 -exec git -C {} push \;