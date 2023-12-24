#!/bin/bash
#Devuan setup

$TOOLBOXDIR/systems/debian_like/devuan/setup/basic.sh
$TOOLBOXDIR/systems/cpan/universal.sh
$TOOLBOXDIR/systems/cpan/workstation.sh
$TOOLBOXDIR/systems/cpan/author.sh

apt-get install -y vlc inkscape obs-studio blender openscad default-mysql-server default-mysql-client phpmyadmin libdbd-mysql-perl
sudo ln -s /usr/share/phpmyadmin/ /var/www/phpmyadmin
sudo apt-get install unace  zip unzip p7zip-full  sharutils uudeview mpack arj cabextract file-roller xdotool  xsel sqlite3
