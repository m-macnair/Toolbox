#!/bin/bash
#Devuan setup
read -n 1 -p "You NEED to set the devuan repositories manually! Continue?" 
bash $TOOLBOXDIR/systems/debian_like/shared_basic.sh
bash $TOOLBOXDIR/systems/debian_like/shared_final.sh
