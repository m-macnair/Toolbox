#!/bin/bash
dpkg --add-architecture i386
#required to load in the above apparently 
apt-get update 
apt-get install -y wget gdebi-core libgl1-mesa-dri:i386 libgl1-mesa-glx:i386 libc6:amd64 libc6:i386 libegl1:amd64 libegl1:i386 libgbm1:amd64 libgbm1:i386 libgl1-mesa-dri:amd64 libgl1-mesa-dri:i386 libgl1:amd64 libgl1:i386 steam-libs-amd64:amd64 steam-libs-i386:i386 xdg-desktop-portal-kde xterm

if [[ -e ./steam.deb ]]
then
echo "steam.deb already downloaded"
else
wget http://media.steampowered.com/client/installer/steam.deb 
fi
#this may not be set correctly and will throw an error 
export PATH=$PATH:/sbin
gdebi --o "APT::Get::Assume-Yes=1" steam.deb
