#!/bin/bash
#Standard work environment for all Debian Derivatives
echo "Running Shared Basic setup for Debian Derivatives";
apt-get update --assume-yes
apt-get upgrade --assume-yes
apt-get install --assume-yes screen build-essential iptables git net-tools screen sudo  htop rsync perl ntpdate gparted mtools pass sqlite3 >> ~/apt_install.log
bash $TOOLBOXDIR/systems/cpan_universal.sh
echo "/sbin/ is not added to path by default - ifconfig and several friends are to be found here!";
