find -maxdepth 1 -exec sh -c 'if [ -d {}/.git ]; then echo {} && git -C {} push ; fi' \;

