#!/bin/bash
#Devuan setup

$TOOLBOXDIR/systems/debian_like/devuan/setup/basic.sh
$TOOLBOXDIR/systems/cpan/universal.sh
$TOOLBOXDIR/systems/cpan/workstation.sh
$TOOLBOXDIR/systems/cpan/author.sh
#get the perl going
apt-get install vlc >> ~/apt_install.log
