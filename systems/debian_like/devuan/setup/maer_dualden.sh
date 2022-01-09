#!/bin/bash
#Devuan setup

$TOOLBOXDIR/systems/debian_like/devuan/setup/basic.sh
#get the perl going
$TOOLBOXDIR/systems/cpan/universal.sh
$TOOLBOXDIR/systems/cpan/workstation.sh
$TOOLBOXDIR/systems/cpan/author.sh

apt-get install --assume-yes vlc libreoffice blender inkscape phpmyadmin
$TOOLBOXDIR/systems/debian_like/devuan/setup/prune.sh
$TOOLBOXDIR/systems/debian_like/shared_final.sh
